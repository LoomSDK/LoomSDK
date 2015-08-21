/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
===========================================================================
*/

package loom.graphics
{
    import loom2d.math.Matrix;
    import loom2d.textures.Texture;

    delegate ShaderBindDelegate();

    /**
      * Shader allows custom GLSL shaders to be used when drawing Quads and QuadBatches.
      *
      * Shader needs to be initialized after being created with 'load()' or 'loadFromAssets()'.
      * When you are done using the shader, you should release the GPU resources by calling 'dispose()'.
      *
      * Every time the renderer binds the shader, 'onBind' delegte is invoked, where all needed uniforms
      * should be set.
      */

    [Native(managed)]
    public native class Shader
    {
        public native var MVP:Matrix;
        public native var textureId:Number;

        /**
          * Creates a new Shader object. It needs to be initialized with
          * load() or loadFromAssets().
          */
        public function Shader()
        {
        }

        /**
          * Releases GPU resources used by this shader.
          */
        public function dispose():void
        {
            deleteNative();
        }

        /**
          * Loads the shader from strings. The parameters are plain source of shaders.
          */
        public native function load(vertexShader:String, fragmentShader:String):void;

        /**
          * Loads the shader from asset files.
          */
        public native function loadFromAssets(vertexShaderPath:String, fragmentShaderPath:String):void;

        /**
          * Returns the location of the named uniform. This value is then passed to 'setUniform' methods.
          */
        public native function getUniformLocation(name:String):Number;

        /**
          * Sets one 'float' uniform.
          */
        public native function setUniform1f(location:Number, v0:Number);

        /**
          * Sets an array of 'float' uniforms.
          */
        public native function setUniform1fv(location:Number, x1:Number, x2:Number, value:Vector.<Number>);

        /**
          * Sets one 'vec2' uniform
          */
        public native function setUniform2f(location:Number, v0:Number, v1:Number);

        /**
          * Sets an array of 'vec2' uniforms. value size must me a multiple of 2
          */
        public native function setUniform2fv(location:Number, value:Vector.<Number>);

        /**
          * Sets one 'vec3' uniform
          */
        public native function setUniform3f(location:Number, v0:Number, v1:Number, v2:Number);

        /**
          * Sets an array of 'vec3' uniforms. value size must me a multiple of 3
          */
        public native function setUniform3fv(location:Number, value:Vector.<Number>);

        /**
          * Sets one 'int' uniform.
          */
        public native function setUniform1i(location:Number, v0:Number);

        /**
          * Sets an array of 'int' uniforms.
          */
        public native function setUniform1iv(location:Number, value:Vector.<Number>);

        /**
          * Sets one 'ivec2' uniform
          */
        public native function setUniform2i(location:Number, v0:Number, v1:Number);

        /**
          * Sets an array of 'ivec2' uniforms. value size must me a multiple of 2
          */
        public native function setUniform2iv(location:Number, value:Vector.<Number>);

        /**
          * Sets one 'ivec3' uniform
          */
        public native function setUniform3i(location:Number, v0:Number, v1:Number, v2:Number);

        /**
          * Sets and array of 'ivec3' uniforms. value size must me a multiple of 3
          */
        public native function setUniform3iv(location:Number, value:Vector.<Number>);

        /**
          * Sets one 3x3 float Matrix uniform
          */
        public native function setUniformMatrix3f(location:Number, transpose:Boolean, value:Matrix);

        /**
          * Sets an array of 3x3 float Matrix uniforms
          */
        public native function setUniformMatrix3fv(location:Number, transpose:Boolean, value:Vector.<Matrix>);

        /**
          * Sets one 4x4 float Matrix uniform
          */
        public native function setUniformMatrix4f(location:Number, transpose:Boolean, value:Matrix);

        /**
          * Sets an array of 4x4 float Matrix uniforms
          */
        public native function setUniformMatrix4fv(location:Number, transpose:Boolean, value:Vector.<Matrix>);

        /**
          * This is a utility function used by 'defaultShader'.
          */
        private static native function getDefaultShader():Shader;

        /**
          * Returns the default shader.
          */
        public static function get defaultShader():Shader
        {
            return getDefaultShader();
        }

        /**
          * A delegate that gets fired every time renderer binds the shader. This is at least once per frame
          * or when switching between shaders.
          */
        public native var onBind:ShaderBindDelegate;
    }
}