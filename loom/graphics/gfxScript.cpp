/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#include "loom/graphics/gfxMath.h"

#include "loom/script/loomscript.h"

#include "loom/common/core/log.h"

#include "loom/graphics/gfxGraphics.h"
#include "loom/graphics/gfxTexture.h"
#include "loom/graphics/gfxShader.h"
#include "loom/graphics/gfxBitmapData.h"

// Includes for the resize operation.
#include "loom/common/platform/platformThread.h"
#include "loom/common/platform/platformTime.h"
#include "loom/vendor/geldreich/jpge.h"
#include "loom/vendor/geldreich/resampler.h"
#include "loom/vendor/stb/stb_image.h"

#include "loom/common/core/allocator.h"
#include "loom/common/assets/assets.h"
#include "loom/common/assets/assetsImage.h"

// for exif encoding
#include "loom/vendor/jheadexif/jhead.h"

lmDeclareLogGroup(gGFXTextureLogGroup);
loom_allocator_t *gRescalerAllocator = NULL;

namespace GFX
{
/**
 * This is the implementation of the background-threaded image rescaling API.
 * Someday it should live elsewhere than in this file. For the meanwhile, it
 * is a cozy home!
 */
struct RescaleEventStatus
{
    utString path, assetPath;
    float progress;
};

struct RescaleNote
{
    utString outPath;
    utString inPath;
    int      outWidth;
    int      outHeight;
    bool     preserveAspect;
    bool     skipPreload;
};

static MutexHandle                gEventQueueMutex = NULL;
static utList<RescaleEventStatus> gEventQueue;
static LS::NativeDelegate         gImageScaleProgressDelegate;

static void pollScaling()
{
    // Check the event queue.
    if (gEventQueueMutex == NULL)
    {
        return;
    }

    loom_mutex_lock(gEventQueueMutex);

    while (gEventQueue.size() > 0)
    {
        RescaleEventStatus curItem = gEventQueue.front();

        gImageScaleProgressDelegate.pushArgument(curItem.path.c_str());
        gImageScaleProgressDelegate.pushArgument(curItem.progress);
        gImageScaleProgressDelegate.invoke();

        // Flush the asset (only works on main thread atm)
        if (curItem.progress == 1.0f)
        {
            loom_asset_flush(curItem.assetPath.c_str());
        }

        gEventQueue.pop_front();
    }

    loom_mutex_unlock(gEventQueueMutex);
}

static void postResampleEvent(const char *path, float progress, const char *assetPath)
{
    if (gEventQueueMutex == NULL)
    {
        gEventQueueMutex = loom_mutex_create();
    }

    loom_mutex_lock(gEventQueueMutex);

    RescaleEventStatus res;
    res.path = path;
    res.assetPath = assetPath;
    res.progress = progress;
    gEventQueue.push_back(res);

    loom_mutex_unlock(gEventQueueMutex);
}

static int __stdcall scaleImageOnDisk_body(void *param)
{
    // Grab our arguments.
    RescaleNote *rn            = (RescaleNote *)param;
    const char  *outPath       = rn->outPath.c_str();
    const char  *inPath        = rn->inPath.c_str();
    int         outWidth       = rn->outWidth;
    int         outHeight      = rn->outHeight;
    bool        preserveAspect = rn->preserveAspect;

    // Load the image. We always work in 4 components (rgba).
    int t0 = platform_getMilliseconds();

    loom_asset_image *lai = NULL;

    // Load async since we're in a background thread.
    loom_asset_preload(inPath);
    loom_thread_yield();
    while((lai = (loom_asset_image *)loom_asset_lock(inPath, LATImage, 0)) == NULL)
        loom_thread_yield();

    int     imageX     = lai->width;
    int     imageY     = lai->height;
    stbi_uc *imageBits = (stbi_uc *)lai->bits;

    lmLog(gGFXTextureLogGroup, "Image setup took %dms", t0 - platform_getMilliseconds());

    int t1 = platform_getMilliseconds();

    // Resize to fit within the specified size preserving aspect ratio, if flag is set.
    if (preserveAspect)
    {
        float scaleX = float(outWidth) / float(imageX);
        float scaleY = float(outHeight) / float(imageY);

        float actualScale = (scaleX < scaleY) ? scaleX : scaleY;

        outWidth  = (int)(imageX * actualScale);
        outHeight = (int)(imageY * actualScale);
        lmLog(gGFXTextureLogGroup, "Scale to %d %d due to scale %f %f actual=%f", outWidth, outHeight, scaleX, scaleY, actualScale);
    }

    // Build a buffer for byte->float conversions...
    Resampler::Sample *buffRed   = (Resampler::Sample *)lmAlloc(gRescalerAllocator, sizeof(Resampler::Sample) * imageX);
    Resampler::Sample *buffGreen = (Resampler::Sample *)lmAlloc(gRescalerAllocator, sizeof(Resampler::Sample) * imageX);
    Resampler::Sample *buffBlue  = (Resampler::Sample *)lmAlloc(gRescalerAllocator, sizeof(Resampler::Sample) * imageX);

    // And the downsampled image. Give a slight margin because the scaling routine above can give
    // up to outWidth inclusive as an output value.
    stbi_uc *outBuffer = (stbi_uc*)lmAlloc(gRescalerAllocator, sizeof(stbi_uc) * 3 * (outWidth+1) * (outHeight+1));

    // Set up the resamplers, reusing filter constants.
    const char *pFilter = "blackman";
    float filter_scale = 1.0;
    Resampler resizeR(imageX, imageY, outWidth, outHeight, Resampler::BOUNDARY_CLAMP, 0.0f, 1.0f, pFilter, NULL, NULL, filter_scale, filter_scale);
    Resampler resizeG(imageX, imageY, outWidth, outHeight, Resampler::BOUNDARY_CLAMP, 0.0f, 1.0f, pFilter,
                      resizeR.get_clist_x(), resizeR.get_clist_y(), filter_scale, filter_scale);
    Resampler resizeB(imageX, imageY, outWidth, outHeight, Resampler::BOUNDARY_CLAMP, 0.0f, 1.0f, pFilter,
                      resizeR.get_clist_x(), resizeR.get_clist_y(), filter_scale, filter_scale);

    int resultY = 0;

    lmLog(gGFXTextureLogGroup, "Resample setup took %dms", t1 - platform_getMilliseconds());

    int t2 = platform_getMilliseconds();

    // Process each row of the image.
    for (int y = 0; y < imageY; y++)
    {
        // Deinterleave each row.
        for (int x = 0; x < imageX; x++)
        {
            buffRed[x]   = Resampler::Sample(imageBits[(y * imageX * 4) + (x * 4) + 0]) / Resampler::Sample(255.f);
            buffGreen[x] = Resampler::Sample(imageBits[(y * imageX * 4) + (x * 4) + 1]) / Resampler::Sample(255.f);
            buffBlue[x]  = Resampler::Sample(imageBits[(y * imageX * 4) + (x * 4) + 2]) / Resampler::Sample(255.f);
        }

        // Submit to resampler.
        lmAssert(resizeR.put_line(buffRed), "bad red");
        lmAssert(resizeG.put_line(buffGreen), "bad green");
        lmAssert(resizeB.put_line(buffBlue), "bad blue");

        // If there are results, reinterleave and consume them.
        while (resizeR.check_line() && resizeG.check_line() && resizeB.check_line() && resultY < outHeight)
        {
            const Resampler::Sample *outRowR = resizeR.get_line();
            const Resampler::Sample *outRowG = resizeG.get_line();
            const Resampler::Sample *outRowB = resizeB.get_line();

            if (outRowR || outRowG || outRowB)
            {
                lmAssert(outRowR && outRowG && outRowB, "Somehow got one line without others!");
            }
            else
            {
                break;
            }

            // Find the row for output.
            stbi_uc *imageOutBits = outBuffer + (resultY * outWidth * 3);
            resultY++;

            for (int i = 0; i < outWidth; i++)
            {
                imageOutBits[i * 3 + 0] = int(outRowR[i] * Resampler::Sample(255.f));
                imageOutBits[i * 3 + 1] = int(outRowG[i] * Resampler::Sample(255.f));
                imageOutBits[i * 3 + 2] = int(outRowB[i] * Resampler::Sample(255.f));
            }

            // Every hundred lines post an update.
            if(resultY % 100 == 0)
            {
                // calculate the progress, but keep from reporting 1.0 as this is used to 
                // mark completion
                float value = (float)resultY / (float)outHeight;
                if (value == 1.0f)
                    value = .99f;
                postResampleEvent(outPath, value , inPath);
            }
        }
    }

    lmLog(gGFXTextureLogGroup, "Resample took %dms", t2 - platform_getMilliseconds());

    // Release the image, we are done with it!
    loom_asset_unlock(inPath);

    // Write it back out.
    int t3 = platform_getMilliseconds();
    jpge::compress_image_to_jpeg_file(outPath, outWidth, outHeight, 3, outBuffer);
    lmLog(gGFXTextureLogGroup, "JPEG output took %dms", t3 - platform_getMilliseconds());

    // preserve orientation (but only if we need to)
    if (lai->orientation > IMAGE_ORIENTATION_UPPER_LEFT)
    {
        ResetJpgfile();

        // read in the jpg data (does not decompress it!)
        if (ReadJpegFile(outPath, READ_ALL))
        {
            // create the exif segment and attach it to jpeg image
            create_EXIF(lai->orientation);            

            // write it out with exif data
            WriteJpegFile(outPath);    

            // free all data
            DiscardData();
        }
    }

    // Free everything!
    lmFree(gRescalerAllocator, buffRed);
    lmFree(gRescalerAllocator, buffGreen);
    lmFree(gRescalerAllocator, buffBlue);
    lmFree(gRescalerAllocator, outBuffer);

    // Post completion event.
    postResampleEvent(outPath, 1.0, inPath);

    Texture::enableAssetNotifications(true);

    if(rn->skipPreload == false)
        loom_asset_preload(outPath);

    delete rn;

    return 0;
}


static void scaleImageOnDisk(const char *outPath, const char *inPath, int outWidth, int outHeight, bool preserveAspect, bool skipPreload)
{
    RescaleNote *rn = new RescaleNote();

    rn->outPath   = outPath;
    rn->inPath    = inPath;
    rn->outWidth  = outWidth;
    rn->outHeight = outHeight;
    rn->preserveAspect = preserveAspect;
    rn->skipPreload = skipPreload;

    Texture::enableAssetNotifications(false);

    loom_thread_start(scaleImageOnDisk_body, rn);    
}


static const NativeDelegate *getImageScaleProgressDelegate()
{
    return &gImageScaleProgressDelegate;
}


static int registerLoomGraphics(lua_State *L)
{
    beginPackage(L, "loom.graphics")

       .beginClass<Texture> ("Texture2D")
       .addStaticMethod("initFromAsset", &Texture::initFromAssetManager)
       .addStaticMethod("initFromBytes", &Texture::initFromBytes)
       .addStaticMethod("initFromAssetAsync", &Texture::initFromAssetManagerAsync)
       .addStaticMethod("initFromBytesAsync", &Texture::initFromBytesAsync)
       .addStaticMethod("initEmptyTexture", &Texture::initEmptyTexture)
       .addStaticMethod("updateFromBytes", &Texture::updateFromBytes)
       .addStaticMethod("updateFromBytesAsync", &Texture::updateFromBytesAsync)
	   .addStaticMethod("clear", &Texture::clear)
	   .addStaticMethod("setRenderTarget", &Texture::setRenderTarget)
       .addStaticMethod("dispose", &Texture::dispose)
       .addStaticMethod("scaleImageOnDisk", &scaleImageOnDisk)
       .addStaticMethod("pollScaling", &pollScaling)
       .addStaticProperty("imageScaleProgress", &getImageScaleProgressDelegate)
       .endClass()

	   .beginClass<Graphics>("Graphics")
	   .addStaticLuaFunction("render", &Graphics::render)
       .addStaticMethod("handleContextLoss", &Graphics::handleContextLoss)
       .addStaticMethod("screenshot", &Graphics::screenshot)
       .addStaticMethod("screenshotData", &Graphics::screenshotData)
       .addStaticMethod("setDebug", &Graphics::setDebug)
       .addStaticMethod("setFillColor", &Graphics::setFillColor)
       .addStaticProperty("onScreenshotData", &Graphics::getonScreenshotDataDelegate)
       .endClass()

       .beginClass<TextureInfo> ("TextureInfo")
       .addVar("width", &TextureInfo::width)
       .addVar("height", &TextureInfo::height)
       .addVar("smoothing", &TextureInfo::smoothing)
       .addVar("visible", &TextureInfo::visible)
       .addVar("wrapU", &TextureInfo::wrapU)
       .addVar("wrapV", &TextureInfo::wrapV)
       .addVar("id", &TextureInfo::id)
       .addVarAccessor("update", &TextureInfo::getUpdateDelegate)
       .addVarAccessor("asyncLoadComplete", &TextureInfo::getAsyncLoadCompleteDelegate)
       .addProperty("handleID", &TextureInfo::getHandleID)
       .addProperty("path", &TextureInfo::getTexturePath)
       .endClass()

       .beginClass<ShaderProgram>("Shader")
       .addConstructor<void(*)(void)>()
       .addVarAccessor("onBind", &ShaderProgram::getonBindDelegate)
       .addVarAccessor("MVP", &ShaderProgram::getMVP)
       .addVarAccessor("textureId", &ShaderProgram::getTextureId)
       .addMethod("load", &ShaderProgram::load)
       .addMethod("loadFromAssets", &ShaderProgram::loadFromAssets)
       .addMethod("getUniformLocation", &ShaderProgram::getUniformLocation)
       .addMethod("setUniform1f", &ShaderProgram::setUniform1f)
       .addLuaFunction("setUniform1fv", &ShaderProgram::setUniform1fv)
       .addMethod("setUniform2f", &ShaderProgram::setUniform2f)
       .addLuaFunction("setUniform2fv", &ShaderProgram::setUniform2fv)
       .addMethod("setUniform3f", &ShaderProgram::setUniform3f)
       .addLuaFunction("setUniform3fv", &ShaderProgram::setUniform3fv)
       .addMethod("setUniform1i", &ShaderProgram::setUniform1i)
       .addLuaFunction("setUniform1iv", &ShaderProgram::setUniform1iv)
       .addMethod("setUniform2i", &ShaderProgram::setUniform2i)
       .addLuaFunction("setUniform2iv", &ShaderProgram::setUniform2iv)
       .addMethod("setUniform3i", &ShaderProgram::setUniform3i)
       .addLuaFunction("setUniform3iv", &ShaderProgram::setUniform3iv)
       .addMethod("setUniformMatrix3f", &ShaderProgram::setUniformMatrix3f)
       .addLuaFunction("setUniformMatrix3fv", &ShaderProgram::setUniformMatrix3fv)
       .addMethod("setUniformMatrix4f", &ShaderProgram::setUniformMatrix4f)
       .addLuaFunction("setUniformMatrix4fv", &ShaderProgram::setUniformMatrix4fv)
       .addStaticMethod("getDefaultShader", &ShaderProgram::getDefaultShader)
       .endClass()

       .beginClass<BitmapData>("BitmapData")
       .addMethod("save", &BitmapData::save)
       .addStaticMethod("fromFramebuffer", &BitmapData::fromFramebuffer)
       .addStaticMethod("fromAsset", &BitmapData::fromAsset)
       .addStaticMethod("compare", &BitmapData::compare)
       .addStaticMethod("diff", &BitmapData::diff)
       .endClass()

       .endPackage();

    return 0;
}
}

void installLoomGraphics()
{
    LOOM_DECLARE_NATIVETYPE(GFX::Graphics, GFX::registerLoomGraphics);
    LOOM_DECLARE_NATIVETYPE(GFX::Texture, GFX::registerLoomGraphics);
    LOOM_DECLARE_NATIVETYPE(GFX::TextureInfo, GFX::registerLoomGraphics);
    LOOM_DECLARE_MANAGEDNATIVETYPE(GFX::ShaderProgram, GFX::registerLoomGraphics);
    LOOM_DECLARE_NATIVETYPE(GFX::BitmapData, GFX::registerLoomGraphics);
}
