package
{

    import loom.Application;    

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;    
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;

    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;    

    import loom.gameframework.AnimatedComponent;
    import loom.gameframework.LoomComponent;
    import loom.gameframework.LoomGroup;
    import loom.gameframework.LoomGameObject;    

    import loom.physics.Physics;
    import loom.physics.PhysicsWall;
    import loom.physics.PhysicsBall;

    public class BallRenderer extends AnimatedComponent
    {
        public var x:Number = 10, y:Number, rotation:Number;
        public var sprite:Image;

        public function onFrame():void
        {
            super.onFrame();

            if(!sprite)
                return;

            sprite.x = x;
            sprite.y = y;
            sprite.rotation = rotation;
        }

        public function onRemove():void
        {
            if(sprite)
            {                   
                sprite.parent.removeChild(sprite, true);
            }

            super.onRemove();
        }
    }

    public class PhysicsMover extends LoomComponent
    {
        public var ball:PhysicsBall;

        public function onRemove():void
        {
            super.onRemove();

            // tell the native side we are done with the ball
            ball.deleteNative();
            ball = null;
        }
    }

    public class BallPhysicsDemo extends Application
    {
        public var wallGroup = new LoomGroup();
        public var walls = new Vector.<PhysicsWall>();
        public var physicsActive = false;

        public function onFrame():void
        {
            //tick physics simulation
            if(physicsActive)
                Physics.tick();
        }

        function spawnBall(x:Number, y:Number) 
        {
            // create a new ball game object
            var ballGO = new LoomGameObject();
            
            // create a new physics component.
            var physicsComp = new PhysicsMover();
            var rad:Number = Math.random() * 20 + 5;
            physicsComp.ball = Physics.spawnBall(x, y, rad, 1);
            ballGO.addComponent(physicsComp, "mover");            

            // Sprite for the ball
            var sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.width = sprite.height = rad * 2;

            // We want the pivot point of the ball to be in the center
            sprite.center();
            sprite.x = x;
            sprite.y = y;

            sprite.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                    var touch = e.getTouch(sprite, TouchPhase.BEGAN);
                    if (touch)
                    {   
                        e.stopImmediatePropagation();                     
                        ballGO.destroy();
                    }
                } );        
                        
            // add the sprite to the scenegraph
            stage.addChild(sprite);

            // And set up the renderer.
            var renderComp = new BallRenderer();
            renderComp.sprite = sprite;       

            // initialize the data bindings     
            renderComp.addBinding("x", "@mover.ball.x");
            renderComp.addBinding("y", "@mover.ball.y");
            renderComp.addBinding("rotation", "@mover.ball.angle");
            ballGO.addComponent(renderComp, "renderer");

            // Initialize the GO.
            ballGO.initialize();

        }
    
        // Add any managers to group here
        override public function installManagers():void
        {
            Physics.init();
            physicsActive = true;            
        }

        override public function run():void
        {

            // setup our physics wall constraints based on display size
            var width = stage.stageWidth;
            var height = stage.stageHeight;

            stage.scaleMode = StageScaleMode.FILL;

            // Setup anything else, like UI, or game objects.

            // Create a nice background
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = width;
            bg.height = height;
            stage.addChild(bg);

            // Listen for touch.
            stage.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) {   

                var touch = e.getTouch(stage, TouchPhase.BEGAN);
                if (touch)
                    spawnBall(touch.globalX, touch.globalY);

            });

            // Setup wall physics colliders
                        
            // Top wall
            walls.push(Physics.spawnWall(  0,   width,  height,   height + 16));
            
            // Bottom wall
            walls.push(Physics.spawnWall(  0,   width,  0, -16));
            
            // Left wall
            walls.push(Physics.spawnWall( -16,   0,  0,   height));
            
            // Right wall
            walls.push(Physics.spawnWall(  width, width + 16,  0,   height));
            

            // Spawn some initial balls
            for (var cnt = 0; cnt < 100; cnt++)
            {
                var x = (cnt % 10) * (width / 12);
                var y = (cnt / 10) * (height / 12);
                
                spawnBall(x, y);
            }

            // Ensure that we don't have gravity turned on between objects.
            Physics.setInterObjectGravityEnabled(false); 
            
            // add some gravity
            Physics.setGravity(0, 256);            
        }
    }
}