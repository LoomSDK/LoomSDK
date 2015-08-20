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

// TODO! Asset reloading?

#include "loom/graphics/gfxShader.h"
#include "loom/graphics/gfxQuadRenderer.h"
#include "loom/common/assets/assets.h"

lmDefineLogGroup(gGFXShaderLogGroup, "GFXShader", 1, LoomLogInfo);

GFX::Shader* GFX::Shader::getDefaultShader()
{
    if (defaultShader == NULL)
    {
        // TODO how is this properly allocated (memory managment)
        defaultShader = new GFX::DefaultShader();
    }

    return defaultShader;
}

GFX::Shader::Shader()
: programId(0)
, vertexShaderId(0)
, fragmentShaderId(0)
{

}

GFX::Shader::~Shader()
{
    if (programId == 0)
        return;

    GFX::GL_Context* ctx = Graphics::context();

    ctx->glDetachShader(programId, vertexShaderId);
    ctx->glDetachShader(programId, fragmentShaderId);

    ctx->glDeleteProgram(programId);
}

bool GFX::Shader::operator==(const GFX::Shader& other) const
{
    return programId == other.programId;
}

bool GFX::Shader::operator!=(const GFX::Shader& other) const
{
    return programId != other.programId;
}

GLuint GFX::Shader::getProgramId() const
{
    return programId;
}

void GFX::Shader::load(const char* vss, const char* fss)
{
    GFX::GL_Context* ctx = Graphics::context();

    vertexShaderId = ctx->glCreateShader(GL_VERTEX_SHADER);
    fragmentShaderId = ctx->glCreateShader(GL_FRAGMENT_SHADER);

    programId = ctx->glCreateProgram();

    // Store local pointers and lengths because of the GL API
    const GLchar *vssp = static_cast<const GLchar*>(vss);
    const GLint vssl = strlen(vss);
    const GLchar *fssp = static_cast<const GLchar*>(fss);
    const GLint fssl = strlen(fss);

    // Compile VS and FS
    ctx->glShaderSource(vertexShaderId, 1, &vssp, &vssl);
    Graphics::context()->glCompileShader(vertexShaderId);
    GFX_SHADER_CHECK(vertexShaderId);

    ctx->glShaderSource(fragmentShaderId, 1, &fssp, &fssl);
    ctx->glCompileShader(fragmentShaderId);
    GFX_SHADER_CHECK(fragmentShaderId);

    // Link the program
    ctx->glAttachShader(programId, fragmentShaderId);
    ctx->glAttachShader(programId, vertexShaderId);
    ctx->glLinkProgram(programId);
    GFX_PROGRAM_CHECK(programId);

    // Lookup vertex attribute array locations
    posAttribLoc = Graphics::context()->glGetAttribLocation(programId, "a_position");
    posColorLoc = Graphics::context()->glGetAttribLocation(programId, "a_color0");
    posTexCoordLoc = Graphics::context()->glGetAttribLocation(programId, "a_texcoord0");
}

void GFX::Shader::loadFromAssets(const char* vertexShaderPath, const char* fragmentShaderPath)
{
    void * vertData = loom_asset_lock(vertexShaderPath, LATVertexShader, 1);
    if (vertData == NULL)
    {
        lmLogWarn(gGFXShaderLogGroup, "Unable to lock the asset for shader %s", vertexShaderPath);
        return;
    }
    loom_asset_unlock(vertexShaderPath);

    void * fragData = loom_asset_lock(fragmentShaderPath, LATFragmentShader, 1);
    if (fragData == NULL)
    {
        lmLogWarn(gGFXShaderLogGroup, "Unable to lock the asset for shader %s", vertexShaderPath);
        return;
    }
    loom_asset_unlock(vertexShaderPath);

    const char *vert = static_cast<char *>(vertData);
    const char *frag = static_cast<char *>(fragData);

    load(vert, frag);
}

GLint GFX::Shader::getUniformLocation(const char* name)
{
    GFX::GL_Context* ctx = Graphics::context();
    return ctx->glGetUniformLocation(programId, name);
}

#include "loom/common/platform/platformTime.h"

void GFX::Shader::setUniform1f(GLint location, GLfloat v0)
{
    Graphics::context()->glUniform1f(location, v0);
}

int GFX::Shader::setUniform1fv(lua_State *L)
{
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

void GFX::Shader::setUniform2f(GLint location, GLfloat v0, GLfloat v1)
{
    Graphics::context()->glUniform2f(location, v0, v1);
}

int GFX::Shader::setUniform2fv(lua_State *L)
{
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

    // Pop the vector
    lua_pop(L, 3);
    // Pop location
    lua_pop(L, 2);

    Graphics::context()->glUniform2fv(location, values.size(), values.ptr());
    return 0;
}

void GFX::Shader::setUniform3f(GLint location, GLfloat v0, GLfloat v1, GLfloat v2)
{
    Graphics::context()->glUniform3f(location, v0, v1, v2);
}

int GFX::Shader::setUniform3fv(lua_State *L)
{
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

    // Pop the vector
    lua_pop(L, 3);
    // Pop location
    lua_pop(L, 2);

    Graphics::context()->glUniform3fv(location, values.size(), values.ptr());
    return 0;
}

void GFX::Shader::setUniform1i(GLint location, GLint v0)
{
    Graphics::context()->glUniform1i(location, v0);
}

int GFX::Shader::setUniform1iv(lua_State *L)
{
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

void GFX::Shader::setUniform2i(GLint location, GLint v0, GLint v1)
{
    Graphics::context()->glUniform2i(location, v0, v1);
}

int GFX::Shader::setUniform2iv(lua_State *L)
{
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

    Graphics::context()->glUniform2iv(location, values.size(), values.ptr());
    return 0;
}

void GFX::Shader::setUniform3i(GLint location, GLint v0, GLint v1, GLint v2)
{
    Graphics::context()->glUniform3i(location, v0, v1, v2);
}

int GFX::Shader::setUniform3iv(lua_State *L)
{
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

    Graphics::context()->glUniform3iv(location, values.size(), values.ptr());
    return 0;
}

void GFX::Shader::setUniformMatrix3f(GLint location, bool transpose, Loom2D::Matrix* value)
{
    static float v[9] = {0, 0, 0, 0, 0, 0, 0, 0 ,0};
    value->copyToMatrix3f(v);
    Graphics::context()->glUniformMatrix3fv(location, 1, transpose, v);
}

int GFX::Shader::setUniformMatrix3fv(lua_State *L)
{
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

void GFX::Shader::setUniformMatrix4f(GLint location, bool transpose, Loom2D::Matrix* value)
{
    static float v[16] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    value->copyToMatrix4f(v);
    Graphics::context()->glUniformMatrix4fv(location, 1, transpose, v);
}

int GFX::Shader::setUniformMatrix4fv(lua_State *L)
{
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

Loom2D::Matrix GFX::Shader::getMVP() const
{
    return mvp;
}

void GFX::Shader::setMVP(Loom2D::Matrix mat)
{
    mvp = mat;
}

GLuint GFX::Shader::getTextureId() const
{
    return textureId;
}

void GFX::Shader::setTextureId(GLuint id)
{
    textureId = id;
}

void GFX::Shader::bind()
{
    if (programId == 0)
    {
        lmLogError(gGFXShaderLogGroup, "Binding an uninitalized shader!");

        // Don't return here, let it bind to 0
        // It would be wierd if it started using
        // the wrong shader
    }

    GFX::GL_Context* ctx = Graphics::context();

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

GFX::Shader* GFX::Shader::defaultShader = NULL;

GFX::DefaultShader::DefaultShader()
{
    load(defaultVertexShader, defaultFragmentShader);

    GFX::GL_Context* ctx = Graphics::context();

    uTexture = ctx->glGetUniformLocation(programId, "u_texture");
    uMVP = ctx->glGetUniformLocation(programId, "u_mvp");
}

void GFX::DefaultShader::bind()
{
    GFX::Shader::bind();

    Graphics::context()->glUniformMatrix4fv(uMVP, 1, GL_FALSE, Graphics::getMVP());
    Graphics::context()->glUniform1i(uTexture, textureId);
}
