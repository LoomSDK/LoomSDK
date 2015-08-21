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

#pragma once

#include "loom/graphics/gfxGraphics.h"
#include "loom/engine/loom2d/l2dMatrix.h"
#include "loom/script/native/lsNativeDelegate.h"

namespace GFX {

/*
 * A class to handle custom GLSL shaders. Once constructed, they must be loaded
 * from strings or assets. After binding uniforms should be set using 'setUniform' set
 * of methods - this can be achieved using a delegate 'onBind'.
 *
 * 'mvp' and 'textureId' are automatically set by the renderer before binding.
 *
 * By default, Quads and QuadBatches are assigned DefaultShader.
 */

class Shader
{
public:

    static Shader* defaultShader;
    static Shader* getDefaultShader();

protected:

    GLuint programId;
    GLuint vertexShaderId;
    GLuint fragmentShaderId;

    GLint posAttribLoc;
    GLint posColorLoc;
    GLint posTexCoordLoc;

    Loom2D::Matrix mvp;
    GLuint textureId;

    // Disable copy constructor
    Shader(const Shader& copy);

public:

    Shader();
    virtual ~Shader();

    bool operator== (const Shader& other) const;
    bool operator!= (const Shader& other) const;

    GLuint getProgramId() const;

    void load(const char* vertexShaderSource, const char* fragmentShaderSource);
    void loadFromAssets(const char* vertexShaderPath, const char* fragmentShaderPath);

    GLint getUniformLocation(const char* name);
    void setUniform1f(GLint location, GLfloat v0);
    int setUniform1fv(lua_State *L);
    void setUniform2f(GLint location, GLfloat v0, GLfloat v1);
    int setUniform2fv(lua_State *L);
    void setUniform3f(GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
    int setUniform3fv(lua_State *L);
    void setUniform1i(GLint location, GLint v0);
    int setUniform1iv(lua_State *L);
    void setUniform2i(GLint location, GLint v0, GLint v1);
    int setUniform2iv(lua_State *L);
    void setUniform3i(GLint location, GLint v0, GLint v1, GLint v2);
    int setUniform3iv(lua_State *L);
    void setUniformMatrix3f(GLint location, bool transpose, Loom2D::Matrix* value);
    int setUniformMatrix3fv(lua_State *L);
    void setUniformMatrix4f(GLint location, bool transpose, Loom2D::Matrix* value);
    int setUniformMatrix4fv(lua_State *L);

    Loom2D::Matrix getMVP() const;
    void setMVP(Loom2D::Matrix _mvp);

    GLuint getTextureId() const;
    void setTextureId(GLuint _id);

    virtual void bind();

    LOOM_DELEGATE(onBind);
};

class DefaultShader : public Shader
{
protected:

GLint uTexture;
GLint uMVP;

public:
    DefaultShader();

    virtual void bind();
};

}
