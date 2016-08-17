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

#include "loom/graphics/gfxShader.h"
#include "loom/graphics/gfxQuadRenderer.h"
#include "loom/common/assets/assets.h"

#include <stdlib.h>

lmDefineLogGroup(gGFXShaderLogGroup, "gfx.shader", 1, LoomLogInfo);

static const GFX::ShaderProgram *lastBoundShader = NULL;

// A hash table of live shaders that are currently compiled on the GPU
// Contains reference counting since we are devoid of smart pointers
utHashTable<utCharHashKey, GFX::ShaderEntry> GFX::Shader::liveShaders;

// Adds a shader to liveShaders or increases reference count
void GFX::Shader::addShaderRef(const utString& name, GFX::Shader* sp)
{
    utCharHashKey key(name.c_str());
    if (liveShaders.find(key) != UT_NPOS)
    {
        ShaderEntry* se = liveShaders[key];
        se->refcount++;
    }
    else
    {
        ShaderEntry se;
        se.ref = sp;
        se.refcount = 1;
        liveShaders.insert(key, se);
    }
}

// Decreases reference count and deletes the shader if there are no references left
void GFX::Shader::removeShaderRef(const utString& name)
{
    utCharHashKey key(name.c_str());
    if (liveShaders.find(key) != UT_NPOS)
    {
        ShaderEntry* se = liveShaders[key];
        se->refcount--;

        if (se->refcount == 0)
        {
            lmDelete(NULL, se->ref);
            liveShaders.remove(key);
        }
    }
}

// Looks up the shader by name. If we already have a compiled shader from the same file, return that.
GFX::Shader* GFX::Shader::getShader(const utString& name)
{
    utCharHashKey key(name.c_str());
    if (liveShaders.find(key) != UT_NPOS)
    {
        ShaderEntry* se = liveShaders[key];
        return se->ref;
    }

    return NULL;
}

// If _name is empty, the constructor will not compile anything.
// In that case, load() should be called.
GFX::Shader::Shader(const utString& _name, GLenum _type)
: id(0)
, type(_type)
, name(_name)
{
    lmLogDebug(gGFXShaderLogGroup, "Creating shader %s", name.c_str());

    if (name.size() > 0)
    {
        char* source = getSourceFromAsset();
        loom_asset_subscribe(name.c_str(), &Shader::reloadCallback, this, false);
        load(source);
    }
}

GFX::Shader::~Shader()
{
    lmLogDebug(gGFXShaderLogGroup, "Deleting shader %s", name.c_str());

    if (id != 0)
    {
        GFX::GL_Context* ctx = Graphics::context();
        ctx->glDeleteShader(id);
    }

    if (name.size() > 0)
    {
        loom_asset_unsubscribe(name.c_str(), &Shader::reloadCallback, this);
    }
}

GLuint GFX::Shader::getId() const
{
    return id;
}

utString GFX::Shader::getName() const
{
    if (name.size() == 0)
    {
        // Android NDK doesn't know std::to_string
        // Is there no other cross-platform way?
        static char buf[20];
        sprintf(buf, "%d", id);
        return buf;
    }
    else
    {
        return name;
    }
}

const utString& GFX::Shader::getAssetName() const
{
    return name;
}


bool GFX::Shader::load(const char* source)
{
    lmAssert(id == 0, "Shader already loaded, clean up first");

    GFX::GL_Context* ctx = Graphics::context();

    id = ctx->glCreateShader(type);

#if LOOM_RENDERER_OPENGLES2
    utString processed;
    if (type == GL_FRAGMENT_SHADER)
    {
        processed = "precision mediump float;\n";
        processed += source;
        source = processed.c_str();
    }
#endif

    const GLchar *glsource = static_cast<const GLchar*>(source);
    const GLint length = strlen(source);

    ctx->glShaderSource(id, 1, &glsource, &length);
    Graphics::context()->glCompileShader(id);

    if (!validate())
    {
        ctx->glDeleteShader(id);
        id = 0;
        return false;
    }

    return true;
}

bool GFX::Shader::validate()
{
    GFX::GL_Context* ctx = GFX::Graphics::context();

    GLint status;
    ctx->glGetShaderiv(id, GL_COMPILE_STATUS, &status);

    int infoLen;
    ctx->glGetShaderiv(id, GL_INFO_LOG_LENGTH, &infoLen);
    GLchar* info = NULL;
    if (infoLen > 1)
    {
        info = (GLchar*)lmAlloc(NULL, infoLen);
        ctx->glGetShaderInfoLog(id, infoLen, NULL, info);
    }

    utString name_ = getName();
    if (status == GL_TRUE)
    {
        if (info != NULL)
        {
            lmLogDebug(gGFXShaderLogGroup, "OpenGL shader %s info: %s", name_.c_str(), info);
        }
        else
        {
            lmLogDebug(gGFXShaderLogGroup, "OpenGL shader %s compilation successful", name_.c_str());
        }
    }
    else
    {
        if (info != NULL)
        {
            lmLogError(gGFXShaderLogGroup, "OpenGL shader %s error: %s", name_.c_str(), info);
        }
        else
        {
            lmLogError(gGFXShaderLogGroup, "OpenGL shader %s error: No additional information provided.", name_.c_str());
        }

        GFX_DEBUG_BREAK

        return false;
    }

    if (info != NULL)
        lmFree(NULL, info);

    return true;
}

char* GFX::Shader::getSourceFromAsset()
{
    void * source = loom_asset_lock(name.c_str(), LATText, 1);
    if (source == NULL)
    {
        lmLogWarn(gGFXShaderLogGroup, "Unable to lock the asset for shader %s", name.c_str());
        return NULL;
    }
    loom_asset_unlock(name.c_str());

    return static_cast<char*>(source);
}

void GFX::Shader::reload()
{
    GFX::GL_Context* ctx = Graphics::context();
    ctx->glDeleteShader(id);
    id = 0;

    char* source = getSourceFromAsset();
    load(source);

}

void GFX::Shader::reloadCallback(void *payload, const char *name)
{
    Shader* sp = static_cast<Shader*>(payload);
    sp->reload();
}

GFX::ShaderProgram* GFX::ShaderProgram::getDefaultShader()
{
    if (defaultShader.get() == NULL)
    {
        defaultShader.reset(lmNew(NULL) GFX::DefaultShader());
    }

    return defaultShader.get();
}

GFX::ShaderProgram* GFX::ShaderProgram::getTintlessDefaultShader()
{
    if (tintlessDefaultShader.get() == NULL)
    {
        tintlessDefaultShader.reset(lmNew(NULL) GFX::TintlessDefaultShader());
    }

    return tintlessDefaultShader.get();
}

GFX::ShaderProgram::ShaderProgram()
: programId(0)
{

}

GFX::ShaderProgram::~ShaderProgram()
{
    if (programId == 0)
        return;

    GFX::GL_Context* ctx = Graphics::context();

    ctx->glDetachShader(programId, vertexShader->getId());
    ctx->glDetachShader(programId, fragmentShader->getId());

    Shader::removeShaderRef(vertexShader->getAssetName());
    Shader::removeShaderRef(fragmentShader->getAssetName());

    ctx->glDeleteProgram(programId);
}

bool GFX::ShaderProgram::operator==(const GFX::ShaderProgram& other) const
{
    return programId == other.programId;
}

bool GFX::ShaderProgram::operator!=(const GFX::ShaderProgram& other) const
{
    return programId != other.programId;
}

GLuint GFX::ShaderProgram::getProgramId() const
{
    return programId;
}

void GFX::ShaderProgram::load(const char* vss, const char* fss)
{
    vertexShader = lmNew(NULL) Shader("", GL_VERTEX_SHADER);
    vertexShader->load(vss);

    fragmentShader = lmNew(NULL) Shader("", GL_FRAGMENT_SHADER);
    fragmentShader->load(fss);

    link();
}

void GFX::ShaderProgram::loadFromAssets(const char* vertexShaderPath, const char* fragmentShaderPath)
{
    vertexShader = Shader::getShader(vertexShaderPath);
    if (vertexShader == NULL)
    {
        vertexShader = lmNew(NULL) Shader(vertexShaderPath, GL_VERTEX_SHADER);
    }
    Shader::addShaderRef(vertexShaderPath, vertexShader);

    fragmentShader = Shader::getShader(fragmentShaderPath);
    if (fragmentShader == NULL)
    {
        fragmentShader = lmNew(NULL) Shader(fragmentShaderPath, GL_FRAGMENT_SHADER);
    }
    Shader::addShaderRef(fragmentShaderPath, fragmentShader);

    link();
}

void GFX::ShaderProgram::link()
{
    GFX::GL_Context* ctx = Graphics::context();

    lmAssert(programId == 0, "Shader program already linked, clean up first!");

    programId = ctx->glCreateProgram();

    // Link the program
    ctx->glAttachShader(programId, fragmentShader->getId());
    ctx->glAttachShader(programId, vertexShader->getId());
    ctx->glLinkProgram(programId);

    if (!validate())
    {
        ctx->glDeleteProgram(programId);
        programId = 0;
        return;
    }

    fragmentShaderId = fragmentShader->getId();
    vertexShaderId = vertexShader->getId();

    // Lookup vertex attribute array locations
    posAttribLoc = Graphics::context()->glGetAttribLocation(programId, "a_position");
    posColorLoc = Graphics::context()->glGetAttribLocation(programId, "a_color0");
    posTexCoordLoc = Graphics::context()->glGetAttribLocation(programId, "a_texcoord0");
}


bool GFX::ShaderProgram::validate()
{
    GLint status;
    GFX::Graphics::context()->glGetProgramiv(programId, GL_LINK_STATUS, &status);

    int infoLen;
    GFX::Graphics::context()->glGetProgramiv(programId, GL_INFO_LOG_LENGTH, &infoLen);
    GLchar* info = NULL;
    if (infoLen > 1)
    {
        info = (GLchar*)lmAlloc(NULL, infoLen);
        GFX::Graphics::context()->glGetProgramInfoLog(programId, infoLen, NULL, info);
    }

    if (status == GL_TRUE)
    {
        if (info != NULL)
        {
            lmLogDebug(gGFXShaderLogGroup, "OpenGL program name %s & %s info: %s", vertexShader->getName().c_str(), fragmentShader->getName().c_str(), info);
        }
        else
        {
            lmLogDebug(gGFXShaderLogGroup, "OpenGL program name %s & %s linking successful", vertexShader->getName().c_str(), fragmentShader->getName().c_str());
        }
    }
    else
    {
        if (info != NULL)
        {
            lmLogError(gGFXShaderLogGroup, "OpenGL program name %s & %s error: %s", vertexShader->getName().c_str(), fragmentShader->getName().c_str(), info);
        }
        else
        {
            lmLogError(gGFXShaderLogGroup, "OpenGL program name %s & %s error: No additional information provided.", vertexShader->getName().c_str(), fragmentShader->getName().c_str());
        }

        GFX_DEBUG_BREAK

        return false;
    }
    if (info != NULL)
        lmFree(NULL, info);

    return true;
}

GLint GFX::ShaderProgram::getUniformLocation(const char* name)
{
    GFX::GL_Context* ctx = Graphics::context();
    return ctx->glGetUniformLocation(programId, name);
}

void GFX::ShaderProgram::bindTexture(GLuint textureId, GLuint boundTextureId)
{
    lmAssert(boundTextureId < 32, "Texture unit out of range. Valid texture units are 0 to 31");

    TextureInfo &tinfo = *Texture::getTextureInfo(textureId);

    GL_Context* ctx = Graphics::context();
    ctx->glActiveTexture(GL_TEXTURE0 + boundTextureId);
    ctx->glBindTexture(GL_TEXTURE_2D, tinfo.handle);

    if (tinfo.clampOnly)
    {
        tinfo.wrapU = TEXTUREINFO_WRAP_CLAMP;
        tinfo.wrapV = TEXTUREINFO_WRAP_CLAMP;
    }

    switch (tinfo.wrapU)
    {
        case TEXTUREINFO_WRAP_CLAMP:
            ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            break;
        case TEXTUREINFO_WRAP_MIRROR:
            ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
            break;
        case TEXTUREINFO_WRAP_REPEAT:
            ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
            break;
        default:
            lmAssert(false, "Unsupported wrapU: %d", tinfo.wrapU);
    }

    switch (tinfo.wrapV)
    {
        case TEXTUREINFO_WRAP_CLAMP:
            ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            break;
        case TEXTUREINFO_WRAP_MIRROR:
            ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
            break;
        case TEXTUREINFO_WRAP_REPEAT:
            ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
            break;
        default:
            lmAssert(false, "Unsupported wrapV: %d", tinfo.wrapV);
    }

    switch (tinfo.smoothing)
    {
        case TEXTUREINFO_SMOOTHING_NONE:
            ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, tinfo.mipmaps ? GL_NEAREST_MIPMAP_NEAREST : GL_NEAREST);
            ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            break;
        case TEXTUREINFO_SMOOTHING_BILINEAR:
            ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, tinfo.mipmaps ? GL_LINEAR_MIPMAP_LINEAR : GL_LINEAR);
            ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            break;
        default:
            lmAssert(false, "Unsupported smoothing: %d", tinfo.smoothing);
    }
}

void GFX::ShaderProgram::setUniform1f(GLint location, GLfloat v0)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    Graphics::context()->glUniform1f(location, v0);
}

int GFX::ShaderProgram::setUniform1fv(lua_State *L)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    GLint location = (GLint)lua_tonumber(L, 2);
    int length = lsr_vector_get_length(L, 3);

    utArray<float> values;

    lua_rawgeti(L, 3, LSINDEXVECTOR);
    int vidx = lua_gettop(L);

    for (int i = 0; i < length; i++)
    {
        lua_rawgeti(L, vidx, i);
        float value = (float)lua_tonumber(L, -1);
        values.push_back(value);
    }

    Graphics::context()->glUniform1fv(location, values.size(), values.ptr());
    return 0;
}

void GFX::ShaderProgram::setUniform2f(GLint location, GLfloat v0, GLfloat v1)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    Graphics::context()->glUniform2f(location, v0, v1);
}

int GFX::ShaderProgram::setUniform2fv(lua_State *L)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    GLint location = (GLint)lua_tonumber(L, 2);
    int length = lsr_vector_get_length(L, 3);

    lmAssert(length % 2 == 0, "values size must be a multiple of 2");

    utArray<float> values;

    lua_rawgeti(L, 3, LSINDEXVECTOR);
    int vidx = lua_gettop(L);

    for (int i = 0; i < length; i++)
    {
        lua_rawgeti(L, vidx, i);
        float value = (float)lua_tonumber(L, -1);
        values.push_back(value);
    }

    // Pop the vector
    lua_pop(L, 3);
    // Pop location
    lua_pop(L, 2);

    lmAssert(length % 2 == 0, "values size must be a multiple of 2");

    Graphics::context()->glUniform2fv(location, values.size(), values.ptr());
    return 0;
}

void GFX::ShaderProgram::setUniform3f(GLint location, GLfloat v0, GLfloat v1, GLfloat v2)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    Graphics::context()->glUniform3f(location, v0, v1, v2);
}

int GFX::ShaderProgram::setUniform3fv(lua_State *L)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    GLint location = (GLint)lua_tonumber(L, 2);
    int length = lsr_vector_get_length(L, 3);

    lmAssert(length % 3 == 0, "values size must be a multiple of 3");

    utArray<float> values;

    lua_rawgeti(L, 3, LSINDEXVECTOR);
    int vidx = lua_gettop(L);

    for (int i = 0; i < length; i++)
    {
        lua_rawgeti(L, vidx, i);
        float value = (float)lua_tonumber(L, -1);
        values.push_back(value);
    }

    // Pop the vector
    lua_pop(L, 3);
    // Pop location
    lua_pop(L, 2);

    Graphics::context()->glUniform3fv(location, values.size(), values.ptr());
    return 0;
}

void GFX::ShaderProgram::setUniform1i(GLint location, GLint v0)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    Graphics::context()->glUniform1i(location, v0);
}

int GFX::ShaderProgram::setUniform1iv(lua_State *L)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    GLint location = (GLint)lua_tonumber(L, 2);
    int length = lsr_vector_get_length(L, 3);

    utArray<int> values;

    lua_rawgeti(L, 3, LSINDEXVECTOR);
    int vidx = lua_gettop(L);

    for (int i = 0; i < length; i++)
    {
        lua_rawgeti(L, vidx, i);
        int value = (int)lua_tonumber(L, -1);
        values.push_back(value);
    }

    // Pop the vector
    lua_pop(L, 3);
    // Pop location
    lua_pop(L, 2);

    Graphics::context()->glUniform1iv(location, values.size(), values.ptr());
    return 0;
}

void GFX::ShaderProgram::setUniform2i(GLint location, GLint v0, GLint v1)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    Graphics::context()->glUniform2i(location, v0, v1);
}

int GFX::ShaderProgram::setUniform2iv(lua_State *L)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    GLint location = (GLint)lua_tonumber(L, 2);
    int length = lsr_vector_get_length(L, 3);
    lmAssert(length % 2 == 0, "values size must be a multiple of 2");

    utArray<int> values;

    lua_rawgeti(L, 3, LSINDEXVECTOR);
    int vidx = lua_gettop(L);

    for (int i = 0; i < length; i++)
    {
        lua_rawgeti(L, vidx, i);
        int value = (int)lua_tonumber(L, -1);
        values.push_back(value);
    }

    // Pop the vector
    lua_pop(L, 3);
    // Pop location
    lua_pop(L, 2);

    Graphics::context()->glUniform2iv(location, values.size(), values.ptr());
    return 0;
}

void GFX::ShaderProgram::setUniform3i(GLint location, GLint v0, GLint v1, GLint v2)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    Graphics::context()->glUniform3i(location, v0, v1, v2);
}

int GFX::ShaderProgram::setUniform3iv(lua_State *L)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    GLint location = (GLint)lua_tonumber(L, 2);
    int length = lsr_vector_get_length(L, 3);
    lmAssert(length % 3 == 0, "values size must be a multiple of 3");


    utArray<int> values;

    lua_rawgeti(L, 3, LSINDEXVECTOR);
    int vidx = lua_gettop(L);

    for (int i = 0; i < length; i++)
    {
        lua_rawgeti(L, vidx, i);
        int value = (int)lua_tonumber(L, -1);
        values.push_back(value);
    }

    // Pop the vector
    lua_pop(L, 3);
    // Pop location
    lua_pop(L, 2);

    Graphics::context()->glUniform3iv(location, values.size(), values.ptr());
    return 0;
}

void GFX::ShaderProgram::setUniformMatrix3f(GLint location, bool transpose, const Loom2D::Matrix* value)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    static float v[9] = {0, 0, 0, 0, 0, 0, 0, 0 ,0};
    value->copyToMatrix3f(v);
    Graphics::context()->glUniformMatrix3fv(location, 1, transpose, v);
}

int GFX::ShaderProgram::setUniformMatrix3fv(lua_State *L)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    GLint location = (GLint)lua_tonumber(L, 2);
    bool transpose = lua_toboolean(L, 3) != 0;
    int length = lsr_vector_get_length(L, 4);

    lua_rawgeti(L, 4, LSINDEXVECTOR);
    int vidx = lua_gettop(L);

    utArray<float> values;

    values.resize(9 * length);
    for (int i = 0; i < length; i++)
    {
        lua_rawgeti(L, vidx, i);
        Loom2D::Matrix* mat = (Loom2D::Matrix *)lualoom_getnativepointer(L, -1);
        mat->copyToMatrix3f(values.ptr() + i * 9);
    }

    Graphics::context()->glUniformMatrix3fv(location, length, transpose, values.ptr());

    // Pop the vector
    lua_pop(L, 4);
    // Pop transpose
    lua_pop(L, 3);
    // Pop location
    lua_pop(L, 2);

    return 0;
}

void GFX::ShaderProgram::setUniformMatrix4f(GLint location, bool transpose, const Loom2D::Matrix* value)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    static float v[16] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    value->copyToMatrix4f(v);
    Graphics::context()->glUniformMatrix4fv(location, 1, transpose, v);
}

int GFX::ShaderProgram::setUniformMatrix4fv(lua_State *L)
{
    lmAssert(this == lastBoundShader, "You are setting a uniform for a shader that is not currently bound!");

    GLint location = (GLint)lua_tonumber(L, 2);
    bool transpose = lua_toboolean(L, 3) != 0;
    int length = lsr_vector_get_length(L, 4);

    lua_rawgeti(L, 4, LSINDEXVECTOR);
    int vidx = lua_gettop(L);

    utArray<float> values;

    values.resize(16 * length);
    for (int i = 0; i < length; i++)
    {
        lua_rawgeti(L, vidx, i);
        Loom2D::Matrix* mat = (Loom2D::Matrix *)lualoom_getnativepointer(L, -1);
        mat->copyToMatrix4f(values.ptr() + i * 16);
    }

    Graphics::context()->glUniformMatrix4fv(location, length, transpose, values.ptr());

    // Pop the vector
    lua_pop(L, 4);
    // Pop transpose
    lua_pop(L, 3);
    // Pop location
    lua_pop(L, 2);

    return 0;
}

const Loom2D::Matrix& GFX::ShaderProgram::getMVP() const
{
    return mvp;
}

void GFX::ShaderProgram::setMVP(const Loom2D::Matrix& mat)
{
    mvp = mat;
}

GLuint GFX::ShaderProgram::getTextureId() const
{
    return textureId;
}

void GFX::ShaderProgram::setTextureId(GLuint id)
{
    textureId = id;
}

void GFX::ShaderProgram::bind()
{
    if (programId == 0)
    {
        lmLogError(gGFXShaderLogGroup, "Binding an uninitalized shader!");

        // Don't return here, let it bind to 0
        // It would be weird if it started using
        // the wrong shader
    }

    lastBoundShader = this;

    GFX::GL_Context* ctx = Graphics::context();

    if (fragmentShaderId != fragmentShader->getId() ||
        vertexShaderId != vertexShader->getId())
    {
        ctx->glDetachShader(programId, fragmentShaderId);
        ctx->glDetachShader(programId, vertexShaderId);
        ctx->glDeleteProgram(programId);
        programId = 0;

        link();
    }

    ctx->glUseProgram(programId);

    if (posAttribLoc != -1)
    {
        ctx->glEnableVertexAttribArray(posAttribLoc);
        ctx->glVertexAttribPointer(posAttribLoc, 3, GL_FLOAT, false,
                                   sizeof(VertexPosColorTex),
                                   (void*)offsetof(VertexPosColorTex, x));
    }

    if (posColorLoc != -1)
    {
        ctx->glEnableVertexAttribArray(posColorLoc);
        ctx->glVertexAttribPointer(posColorLoc, 4, GL_UNSIGNED_BYTE, true,
                                   sizeof(VertexPosColorTex),
                                   (void*)offsetof(VertexPosColorTex, abgr));
    }

    if (posTexCoordLoc != -1)
    {
        ctx->glEnableVertexAttribArray(posTexCoordLoc);
        ctx->glVertexAttribPointer(posTexCoordLoc,
                                   2, GL_FLOAT, false, sizeof(VertexPosColorTex),
                                   (void*)offsetof(VertexPosColorTex, u));
    }

    _onBindDelegate.invoke();
}

void GFX::ShaderProgram::bindTextures()
{
    _onBindTexturesDelegate.invoke();
}

const char * defaultVertexShader =
"                                                                    \n"
"attribute vec4 a_position;                                          \n"
"attribute vec4 a_color0;                                            \n"
"attribute vec2 a_texcoord0;                                         \n"
"varying vec2 v_texcoord0;                                           \n"
"varying vec4 v_color0;                                              \n"
"uniform mat4 u_mvp;                                                 \n"
"void main()                                                         \n"
"{                                                                   \n"
"    gl_Position = u_mvp * a_position;                               \n"
"    v_color0 = a_color0;                                            \n"
"    v_texcoord0 = a_texcoord0;                                      \n"
"}                                                                   \n";

const char * defaultFragmentShader =
"                                                                    \n"
#if LOOM_RENDERER_OPENGLES2
"precision mediump float;                                            \n"
#endif
"uniform sampler2D u_texture;                                        \n"
"varying vec2 v_texcoord0;                                           \n"
"varying vec4 v_color0;                                              \n"
"void main()                                                         \n"
"{                                                                   \n"
"    gl_FragColor = v_color0 * texture2D(u_texture, v_texcoord0);    \n"
"}                                                                   \n";

lmAutoPtr<GFX::ShaderProgram> GFX::ShaderProgram::defaultShader;

GFX::DefaultShader::DefaultShader()
{
    load(defaultVertexShader, defaultFragmentShader);

    GFX::GL_Context* ctx = Graphics::context();

    uTexture = ctx->glGetUniformLocation(programId, "u_texture");
    uMVP = ctx->glGetUniformLocation(programId, "u_mvp");
}

void GFX::DefaultShader::bind()
{
    GFX::ShaderProgram::bind();

    Graphics::context()->glUniformMatrix4fv(uMVP, 1, GL_FALSE, Graphics::getMVP());
    Graphics::context()->glUniform1i(uTexture, textureId);
}

const char * tintlessFragmentShader =
"                                                                    \n"
#if LOOM_RENDERER_OPENGLES2
"precision mediump float;                                            \n"
#endif
"uniform sampler2D u_texture;                                        \n"
"varying vec2 v_texcoord0;                                           \n"
"void main()                                                         \n"
"{                                                                   \n"
"    gl_FragColor = texture2D(u_texture, v_texcoord0);    \n"
"}                                                                   \n";

lmAutoPtr<GFX::ShaderProgram> GFX::ShaderProgram::tintlessDefaultShader;

GFX::TintlessDefaultShader::TintlessDefaultShader()
{
    load(defaultVertexShader, tintlessFragmentShader);

    GFX::GL_Context* ctx = Graphics::context();

    uTexture = ctx->glGetUniformLocation(programId, "u_texture");
    uMVP = ctx->glGetUniformLocation(programId, "u_mvp");
}

void GFX::TintlessDefaultShader::bind()
{
    GFX::ShaderProgram::bind();

    Graphics::context()->glUniformMatrix4fv(uMVP, 1, GL_FALSE, Graphics::getMVP());
    Graphics::context()->glUniform1i(uTexture, textureId);
}
