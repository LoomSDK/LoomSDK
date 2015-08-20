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

    public class ShaderExample extends Application
    {


        private var vertexShader:String =
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

        private var invertFragmentShader:String =
"uniform sampler2D u_texture;                                               \n" +
"varying vec2 v_texcoord0;                                                  \n" +
"varying vec4 v_color0;                                                     \n" +
"void main()                                                                \n" +
"{                                                                          \n" +
"    vec4 c = texture2D(u_texture, v_texcoord0);                            \n" +
"    gl_FragColor =  vec4(1.0 - c.r, 1.0 - c.g, 1.0 - c.b, c.a) * v_color0; \n" +
"}";

        private var grayscaleFragmentShader:String =
"uniform sampler2D u_texture;                                               \n" +
"varying vec2 v_texcoord0;                                                  \n" +
"varying vec4 v_color0;                                                     \n" +
"void main()                                                                \n" +
"{                                                                          \n" +
"    vec4 c = texture2D(u_texture, v_texcoord0);                            \n" +
"    float gray = c.r + c.g + c.b / 3.0;                                    \n" +
"    gl_FragColor =  vec4(vec3(gray), c.a) * v_color0;                      \n" +
"}";

        private var grayscaleShader:Shader;
        private var invertShader:Shader;
        private var brightnessShader:Shader;

        private var time:TimeManager;

        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;
            stage.color = 0x888888;

            // Load the shaders from string literals
            grayscaleShader = new Shader();
            grayscaleShader.load(vertexShader, grayscaleFragmentShader);
            grayscaleShader.onBind += OnGrayscaleShaderBind;

            invertShader = new Shader();
            invertShader.load(vertexShader, invertFragmentShader);
            invertShader.onBind += OnInvertShaderBind;

            // Load this one from assets
            brightnessShader = new Shader();
            brightnessShader.loadFromAssets("assets/pulse.vert", "assets/pulse.frag");
            brightnessShader.onBind += OnBrightnessShaderBind;

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
        }

        // When a shader binds, we need to bind the model-view-projection matrix and the texture
        // Brightness shader also binds a 'pulse' uniform, which tells the shader the intensity of it's effect.

        public function OnGrayscaleShaderBind():void
        {
            var umvp:Number = grayscaleShader.getUniformLocation("u_mvp");
            var utexture:Number = grayscaleShader.getUniformLocation("u_texture");

            grayscaleShader.setUniformMatrix4f(umvp, false, grayscaleShader.MVP);
            grayscaleShader.setUniform1i(utexture, grayscaleShader.textureId);
        }

        public function OnInvertShaderBind():void
        {
            var umvp:Number = invertShader.getUniformLocation("u_mvp");
            var utexture:Number = invertShader.getUniformLocation("u_texture");

            invertShader.setUniformMatrix4f(umvp, false, invertShader.MVP);
            invertShader.setUniform1i(utexture, invertShader.textureId);
        }

        public function OnBrightnessShaderBind():void
        {
            var umvp:Number = brightnessShader.getUniformLocation("u_mvp");
            var utexture:Number = brightnessShader.getUniformLocation("u_texture");
            var upulse:Number = brightnessShader.getUniformLocation("pulse");

            brightnessShader.setUniformMatrix4f(umvp, false, brightnessShader.MVP);
            brightnessShader.setUniform1i(utexture, brightnessShader.textureId);
            brightnessShader.setUniform1f(upulse, Math.sin(time.platformTime / 100) / 2.0 + 0.5);
        }
    }
}
