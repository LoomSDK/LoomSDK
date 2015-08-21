package
{
    import loom.gameframework.TimeManager;
    import system.Number;
    import system.Math;
    import loom.Application;
    import loom.graphics.Shader;
    import loom2d.display.Image;
    import loom2d.display.DisplayObject;
    import loom2d.display.StageScaleMode;
    import loom2d.math.Matrix;
    import loom2d.textures.Texture;
    import system.Void;

    /*
     * Shows how to use custom shaders in Loom. Shaders are loaded from strings
     * or assets and set to the 'shader' property of a Quad or QuadBatch.
     *
     * Every shader is required to have attributes (a_position, a_color0, a_texcoord0)
     * with the same name and order. Model-view-projection matrix (MVP) and texture ID (ID
     * of the active texture, should be 0) can be read from the shader properties.
     *
     * When Loom binds the shader before rendering, onBind delegate is invoked and
     * this is where uniforms are set (including MVP and texture ID). If they are set
     * anywhere else, it will most likely be ignored by the driver and an error flag
     * will be set in OpenGL.
     */

    public class ShaderExample extends Application
    {
        private var grayscaleShader:Shader;
        private var invertShader:Shader;

        // This one is typed so it's properties are accessible
        private var brightnessShader:BrightnessShader;

        private var time:TimeManager;

        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;
            stage.color = 0x888888;

            grayscaleShader = new GrayscaleShader();
            invertShader = new InvertColorShader();
            brightnessShader = new BrightnessShader();

            var square = Texture.fromAsset("assets/square.png");

            // Create 4 quads, each with different shader

            // The first one uses the default shader
            var quad = new Image(square);
            quad.x = stage.stageWidth / 4;
            quad.y = stage.stageHeight / 4;
            quad.width = 100;
            quad.height = 100;
            quad.center();
            stage.addChild(quad);

            quad = new Image(square);
            quad.x = stage.stageWidth / 4 * 3;
            quad.y = stage.stageHeight / 4;
            quad.width = 100;
            quad.height = 100;
            quad.center();
            quad.shader = grayscaleShader;
            stage.addChild(quad);

            quad = new Image(square);
            quad.x = stage.stageWidth / 4;
            quad.y = stage.stageHeight / 4 * 3;
            quad.width = 100;
            quad.height = 100;
            quad.center();
            quad.shader = brightnessShader;
            stage.addChild(quad);

            quad = new Image(square);
            quad.x = stage.stageWidth / 4 * 3;
            quad.y = stage.stageHeight / 4 * 3;
            quad.width = 100;
            quad.height = 100;
            quad.center();
            quad.shader = invertShader;
            stage.addChild(quad);

            // For FPS independent rotation
            time = new TimeManager();
            time.start();
        }

        override public function onTick()
        {
            // Rotate the objects so any stuttering becomes visible
            for (var i = 0; i < stage.numChildren; i++)
            {
                var obj:DisplayObject = stage.getChildAt(i) as DisplayObject;

                if (obj == null)
                    continue;

                obj.rotation += time.deltaTime;
            }

            // Calculate intensity based on time, this will make the quad pulsate
            brightnessShader.intensity = Math.sin(time.platformTime / 100) / 2.0 + 0.5;
        }
    }

    /*
     * This just holds a string literal to be used by multiple shaders
     */

    public static class Common
    {
        public static var vertexShader:String =
"attribute vec4 a_position;                                                 \n" +
"attribute vec4 a_color0;                                                   \n" +
"attribute vec2 a_texcoord0;                                                \n" +
"varying vec2 v_texcoord0;                                                  \n" +
"varying vec4 v_color0;                                                     \n" +
"uniform mat4 u_mvp;                                                        \n" +
"void main()                                                                \n" +
"{                                                                          \n" +
"    gl_Position = u_mvp * a_position;                                      \n" +
"    v_color0 = a_color0;                                                   \n" +
"    v_texcoord0 = a_texcoord0;                                             \n" +
"}";
    }

    /*
     * These are three examples of custom shaders. Two are loaded from string literals,
     * one from assets.
     */

    public class InvertColorShader extends Shader
    {
        private var fragmentShader:String =
"uniform sampler2D u_texture;                                               \n" +
"varying vec2 v_texcoord0;                                                  \n" +
"varying vec4 v_color0;                                                     \n" +
"void main()                                                                \n" +
"{                                                                          \n" +
"    vec4 c = texture2D(u_texture, v_texcoord0);                            \n" +
"    gl_FragColor =  vec4(1.0 - c.r, 1.0 - c.g, 1.0 - c.b, c.a) * v_color0; \n" +
"}";

        // Variables to store uniform locations
        private var u_mvp_loc:Number;
        private var v_texture_loc:Number;

        public function InvertColorShader()
        {
            // Load the shader first
            load(Common.vertexShader, fragmentShader);

            // Read and store uniform locations
            u_mvp_loc = getUniformLocation("u_mvp");
            v_texture_loc = getUniformLocation("u_texture");

            onBind += bind;
        }

        private function bind():void
        {
            // Set uniform values after binding.
            setUniformMatrix4f(u_mvp_loc, false, MVP);
            setUniform1i(v_texture_loc, textureId);
        }
    }

    public class GrayscaleShader extends Shader
    {
        private var fragmentShader:String =
"uniform sampler2D u_texture;                                               \n" +
"varying vec2 v_texcoord0;                                                  \n" +
"varying vec4 v_color0;                                                     \n" +
"void main()                                                                \n" +
"{                                                                          \n" +
"    vec4 c = texture2D(u_texture, v_texcoord0);                            \n" +
"    float gray = c.r + c.g + c.b / 3.0;                                    \n" +
"    gl_FragColor =  vec4(vec3(gray), c.a) * v_color0;                      \n" +
"}";

        // Variables to store uniform locations
        private var u_mvp_loc:Number;
        private var v_texture_loc:Number;

        public function GrayscaleShader()
        {
            // Load the shader first
            load(Common.vertexShader, fragmentShader);

            // Read and store uniform locations
            u_mvp_loc = getUniformLocation("u_mvp");
            v_texture_loc = getUniformLocation("u_texture");

            onBind += bind;
        }

        private function bind():void
        {
            // Set uniform values after binding.
            setUniformMatrix4f(u_mvp_loc, false, MVP);
            setUniform1i(v_texture_loc, textureId);
        }
    }

    public class BrightnessShader extends Shader
    {
        // Variables to store uniform locations
        private var u_mvp_loc:Number;
        private var v_texture_loc:Number;
        private var u_intensity_loc:Number;

        public var intensity:Number;

        public function BrightnessShader()
        {
            // Load the shader first, this one from assets
            loadFromAssets("assets/brightness.vert", "assets/brightness.frag");

            // Read and store uniform locations
            // This shaderhas an additional uniform
            u_mvp_loc = getUniformLocation("u_mvp");
            v_texture_loc = getUniformLocation("u_texture");
            u_intensity_loc = getUniformLocation("u_intensity");

            intensity = 0;

            onBind += bind;
        }

        private function bind():void
        {
            // Set uniform values after binding.
            setUniformMatrix4f(u_mvp_loc, false, MVP);
            setUniform1i(v_texture_loc, textureId);

            // Set the uniform based on the value calculated in 'onTick'
            setUniform1f(u_intensity_loc, intensity);
        }
    }
}
