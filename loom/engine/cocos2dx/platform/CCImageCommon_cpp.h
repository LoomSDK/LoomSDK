/****************************************************************************
*  Copyright (c) 2010 cocos2d-x.org
*
*  http://www.cocos2d-x.org
*
*  Permission is hereby granted, free of charge, to any person obtaining a copy
*  of this software and associated documentation files (the "Software"), to deal
*  in the Software without restriction, including without limitation the rights
*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*  copies of the Software, and to permit persons to whom the Software is
*  furnished to do so, subject to the following conditions:
*
*  The above copyright notice and this permission notice shall be included in
*  all copies or substantial portions of the Software.
*
*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
*  THE SOFTWARE.
****************************************************************************/

#ifndef __CC_PLATFORM_IMAGE_CPP__
#error "CCFileUtilsCommon_cpp.h can only be included for CCFileUtils.cpp in platform/win32(android,...)"
#endif /* __CC_PLATFORM_IMAGE_CPP__ */

#include "CCImage.h"
#include "CCCommon.h"
#include "CCStdC.h"
#include "CCFileUtils.h"
#include <string>
#include <ctype.h>
#include "stb_image.h"
#include "loom/common/core/assert.h"

#if (CC_TARGET_PLATFORM != CC_PLATFORM_IOS && CC_TARGET_PLATFORM != CC_PLATFORM_MAC)

NS_CC_BEGIN

// premultiply alpha, or the effect will wrong when want to use other pixel format in CCTexture2D,
// such as RGB888, RGB5A1
#define CC_RGB_PREMULTIPLY_APLHA(vr, vg, vb, va)                                          \
    (unsigned)(((unsigned)((unsigned char)(vr) * ((unsigned char)(va) + 1)) >> 8) |       \
               ((unsigned)((unsigned char)(vg) * ((unsigned char)(va) + 1) >> 8) << 8) |  \
               ((unsigned)((unsigned char)(vb) * ((unsigned char)(va) + 1) >> 8) << 16) | \
               ((unsigned)(unsigned char)(va) << 24))

// on ios, we should use platform/ios/CCImage_ios.mm instead


//////////////////////////////////////////////////////////////////////////
// Impliment CCImage
//////////////////////////////////////////////////////////////////////////

CCImage::CCImage()
    : m_nWidth(0)
      , m_nHeight(0)
      , m_nBitsPerComponent(0)
      , m_pData(0)
      , m_bHasAlpha(false)
      , m_bPreMulti(false)
{
}


CCImage::~CCImage()
{
    CC_SAFE_DELETE_ARRAY(m_pData);
}


bool CCImage::initWithImageFile(const char *strPath, EImageFormat eImgFmt /* = eFmtPng*/)
{
    bool          bRet     = false;
    unsigned long nSize    = 0;
    unsigned char *pBuffer = CCFileUtils::sharedFileUtils()->getFileData(CCFileUtils::sharedFileUtils()->fullPathFromRelativePath(strPath), "rb", &nSize);

    if ((pBuffer != NULL) && (nSize > 0))
    {
        bRet = initWithImageData(pBuffer, nSize, eImgFmt);
    }
    CC_SAFE_DELETE_ARRAY(pBuffer);
    return bRet;
}


bool CCImage::initWithImageFileThreadSafe(const char *fullpath, EImageFormat imageType)
{
    bool          bRet     = false;
    unsigned long nSize    = 0;
    unsigned char *pBuffer = CCFileUtils::sharedFileUtils()->getFileData(fullpath, "rb", &nSize);

    if ((pBuffer != NULL) && (nSize > 0))
    {
        bRet = initWithImageData(pBuffer, nSize, imageType);
    }
    CC_SAFE_DELETE_ARRAY(pBuffer);
    return bRet;
}


bool CCImage::initWithImageData(void         *pData,
                                int          nDataLen,
                                EImageFormat eFmt /* = eSrcFmtPng*/,
                                int          nWidth /* = 0*/,
                                int          nHeight /* = 0*/,
                                int          nBitsPerComponent /* = 8*/)
{
    // Let the mighty STBI process this!
    int           x, y, n;
    unsigned char *decompressedData = stbi_load_from_memory((unsigned char *)pData, nDataLen, &x, &y, &n, 0);

    if (!decompressedData)
    {
        return false;
    }

    _initWithRawData(decompressedData, -1, x, y, n);
    stbi_image_free(decompressedData);

    return true;
}


bool CCImage::_initWithRawData(void *pData, int nDatalen, int nWidth, int nHeight, int nBitsPerComponent)
{
    bool bRet = false;

    do
    {
        CC_BREAK_IF(0 == nWidth || 0 == nHeight);

        m_nBitsPerComponent = nBitsPerComponent;
        m_nHeight           = (short)nHeight;
        m_nWidth            = (short)nWidth;
        m_bHasAlpha         = true;

        // only RGBA8888 surported
        int nBytesPerComponent = 4;
        int nSize = nHeight * nWidth * nBytesPerComponent;
        m_pData = new unsigned char[nSize];
        CC_BREAK_IF(!m_pData);
        memcpy(m_pData, pData, nSize);

        bRet = true;
    } while (0);
    return bRet;
}


bool CCImage::saveToFile(const char *pszFilePath, bool bIsToRGB)
{
    bool bRet = false;

    do
    {
        CC_BREAK_IF(NULL == pszFilePath);

        std::string strFilePath(pszFilePath);
        CC_BREAK_IF(strFilePath.size() <= 4);

        std::string strLowerCasePath(strFilePath);
        for (unsigned int i = 0; i < strLowerCasePath.length(); ++i)
        {
            strLowerCasePath[i] = tolower(strFilePath[i]);
        }

        if (std::string::npos != strLowerCasePath.find(".png"))
        {
            CC_BREAK_IF(!_saveImageToPNG(pszFilePath, bIsToRGB));
        }
        else if (std::string::npos != strLowerCasePath.find(".jpg"))
        {
            CC_BREAK_IF(!_saveImageToJPG(pszFilePath));
        }
        else
        {
            break;
        }

        bRet = true;
    } while (0);

    return bRet;
}


bool CCImage::_saveImageToPNG(const char *pszFilePath, bool bIsToRGB)
{
    lmAssert(false, "Not implemented in order to save space.");
    return false;
}


bool CCImage::_saveImageToJPG(const char *pszFilePath)
{
    lmAssert(false, "Not implemented in order to save space.");
    return false;
}


NS_CC_END
#endif // (CC_TARGET_PLATFORM != TARGET_OS_IPHONE && CC_TARGET_PLATFORM != CC_PLATFORM_MAC)

/* ios/CCImage_ios.mm uses "mm" as the extension,
 * so we cannot inclue it in this CCImage.cpp.
 * It makes a little difference on ios */
