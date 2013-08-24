package
{
    import loom.Application;    
    import loom2d.display.StageScaleMode;
    import loom2d.textures.Texture;

    /**
     * Loom version of the DaisyMark benchmark
     * Please note that some mobile devices, such as the Nexus7
     * are currently GPU fillrate constrained on this benchmark
     */
    public class LoomDaisyMark extends Application
    {
        public static var screenWidth:int;
        public static var screenHeight:int;
        
        public var particles:Vector.<Particle>;

        protected var pScale:Number;
        protected var numParticles:int = 2000;
        protected var speed:int = 20;

        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;
            screenHeight = stage.stageHeight;
            screenWidth = stage.stageWidth;
            createParticles();
        }

        override public function onFrame():void 
        {
             for(var i:int = 0, l:int = particles.length; i < l; i++)
             {
                var particle = particles[i];
                particle.rotation += .05;
                particle.x += particle.vx;
                particle.y += particle.vy;
                particle.vy += .35;
                particle.vx *= 0.99;                
                if(particle.y > screenHeight)
                {
                   initParticle(particle);
                }
             }
        }

        protected function createParticles():void 
        {
            particles = [];
            particles.length = numParticles;

            var texture = Texture.fromAsset("assets/daisy.png");

            for(var i:int = 0; i < numParticles; i++)
            {
                var particle = particles[i] = new Particle(texture);

                if (!pScale)
                {
                    var pHeight = particle.height;    
                    pScale = (screenHeight * .0125)/pHeight;
                }
                
                initParticle(particle);
                stage.addChild(particle);                
            }
        }

        protected function initParticle(particle:Particle) 
        {
            var a = Math.PI/2*Math.random()-Math.PI*0.75;
            var v = Math.random()*speed;
            particle.vx = Math.cos(a)*v;

            // TODO: LOOM-1299
            // Math.min takes a vararg, which generates a new Vector to handle the args
            v = -10 - 10 * Math.random();
            a = Math.sin(a)*v;
            particle.vy = ( v < a ? v : a);
            particle.x = screenWidth >> 1;
            particle.y = screenHeight;

            particle.pivotX = 32;
            particle.pivotY = 32;
           
            var scale = (pScale * .5) + (Math.random() * pScale * .5);
            particle.scale = scale;
            particle.alpha = .5 + Math.random() * .5;
            
        }
    }
}