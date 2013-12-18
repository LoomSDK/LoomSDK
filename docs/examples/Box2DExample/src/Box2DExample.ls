package
{

    import loom.Application;

    import system.platform.Platform;
    import loom2d.display.StageScaleMode;    
    import loom2d.display.Image;
    import loom2d.display.QuadBatch;
    import loom2d.textures.Texture;

    import loom2d.text.BitmapFont;

    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;  

    import loom.gameframework.LoomGroup;
    import loom.gameframework.TimeManager;
    import loom.box2d.*;

    public class PhysicsGameObject extends Object
    {
        public var sprite:Image;
    }

    public class Box2DExample extends Application
    {
        // Pixels-To-Meter ratio
        var ptmRatio:Number = 32;

        var simulationEnabled:Boolean = false;
        var tickRate:Number = 1/60;
        var velocityIterations:int = 6;
        var positionIterations:int = 2;

        var bodyScale:Number = 1;

        var world:b2World;

        public function onFrame():void
        {
            if (!simulationEnabled)
                return;

            world.step(tickRate, velocityIterations, positionIterations);
            
            var b:b2Body = world.getBodyList();
            while (b)
            {
                var pgo = b.getUserData() as PhysicsGameObject;
                if (!pgo)
                    continue;

                // make objects update their sprites
                pgo.sprite.x = b.getPosition().x * ptmRatio;
                pgo.sprite.y = b.getPosition().y * ptmRatio;
                pgo.sprite.rotation = b.getAngle();

                // clean up bodies that fall out of the visible area
                if (b.getPosition().y > (stage.stageHeight + Math.max(pgo.sprite.width, pgo.sprite.height))/ptmRatio)
                {
                    stage.removeChild(pgo.sprite);
                    world.destroyBody(b);
                }
                
                b = b.getNext();
            }
        }

        public function createBox(world:b2World, type:int, position:b2Vec2, rotation:Number, dimensions:b2Vec2, imagePath:String, density:Number, friction:Number, restitution:Number):b2Body
        {
            return createBody(world, type, position, rotation, dimensions, dimensions.x/2, imagePath, density, friction, restitution, "box");
        }

        public function createCircle(world:b2World, type:int, position:b2Vec2, rotation:Number, radius:Number, imagePath:String, density:Number, friction:Number, restitution:Number):b2Body
        {
            return createBody(world, type, position, rotation, new b2Vec2(radius*2, radius*2), radius, imagePath, density, friction, restitution, "circle");
        }

        public function createGameObject(body:b2Body, position:b2Vec2, rotation:Number, dimensions:b2Vec2, imagePath:String):PhysicsGameObject
        {
            // a physics game object is just an arbitrary class that would take care of keeping game related data,
            // such as storing the sprite of the player's avatar, the number of bullets left, behavior, health status, etc.. 
            // in this example, we only have a single sprite.
            
            var goBody:PhysicsGameObject = new PhysicsGameObject();
            goBody.sprite = new Image(Texture.fromAsset(imagePath));
            goBody.sprite.center();
            goBody.sprite.scale = bodyScale;
            goBody.sprite.width = dimensions.x * ptmRatio;
            goBody.sprite.height = dimensions.y * ptmRatio;
            goBody.sprite.x = body.getPosition().x * ptmRatio;
            goBody.sprite.y = body.getPosition().y * ptmRatio;
            goBody.sprite.rotation = rotation;

            return goBody;
        }

        public function createBody(world:b2World, type:int, position:b2Vec2, rotation:Number, dimensions:b2Vec2, radius:Number, imagePath:String, density:Number, friction:Number, restitution:Number, shapeType:String="box"):b2Body
        {
            // create a body
            var bodyDef:b2BodyDef = new b2BodyDef();
            bodyDef.type = type; // 2-dynamic, 1-kinematic, 0-static
            bodyDef.position = position;
            bodyDef.allowSleep = true;
            var body:b2Body = world.createBody(bodyDef);
            body.setTransform(position, rotation);

            // create a game object for the body
            var goBody:PhysicsGameObject = createGameObject(body, position, rotation, dimensions, imagePath);
            stage.addChild(goBody.sprite);

            // attach the body game object to the body body
            body.setUserData(goBody as Object);

            // create a fixture for the body body with the body shape
            var fixtureBody:b2FixtureDef = new b2FixtureDef();
            fixtureBody.density = density;
            fixtureBody.friction = friction;
            fixtureBody.restitution = restitution;

            // create a shape for the body - one of a few different shapes
            switch (shapeType)
            {
                case "circle":
                    var circShape:b2CircleShape = new b2CircleShape();
                    circShape.radius = radius * bodyScale;
                    fixtureBody.shape = circShape;
                    break;
                default: // box
                    var rectShape:b2PolygonShape = new b2PolygonShape();
                    rectShape.setAsBox(dimensions.x/2 * bodyScale, dimensions.y/2 * bodyScale);
                    fixtureBody.shape = rectShape;
                    break;
            }

            body.createFixture(fixtureBody);

            return body;
        }

        public function loadBody(world:b2World, type:int, position:b2Vec2, rotation:Number, dimensions:b2Vec2, scale:b2Vec2, imagePath:String, plistPath:String, shapeName:String):b2Body
        {
            // create a body
            var bodyDef:b2BodyDef = new b2BodyDef();
            bodyDef.type = type; // 2-dynamic, 1-kinematic, 0-static
            bodyDef.position = position;
            bodyDef.allowSleep = true;

            var body:b2Body = world.createBody(bodyDef);

            // reference the global shape cache
            var shapeCache:b2ShapeCache = b2ShapeCache.sharedB2ShapeCache();

            // load the shape into the shape cache
            shapeCache.addShapesWithFile(plistPath, scale, ptmRatio);

            // add the fixtures to the body
            shapeCache.addFixturesToBody(body, shapeName);

            // create a game object for the body
            var goBody:PhysicsGameObject = createGameObject(body, position, rotation, new b2Vec2(Math.abs(dimensions.x * scale.x), Math.abs(dimensions.y * scale.y)), imagePath);
            stage.addChild(goBody.sprite);

            // attach the body game object to the body body
            body.setUserData(goBody as Object);
            body.setTransform(position, rotation);

            return body;
        }

        public function createRandomShape(px:Number, py:Number)
        {
            var dens:Number = 1;//Math.random()*2;
            var fric:Number = 0.6;//Math.random()*1.2;
            var rest:Number = 0.3;//Math.random()*0.6;

            // find a random shape
            var body:b2Body;
            var rnd:Number = Math.random();
            if (rnd<0.333)
                body = createBox(world, 2, new b2Vec2(px, py), 0, new b2Vec2(Math.random()*2+0.25, Math.random()*2+0.25), "assets/square.png", dens, fric, rest);
            else if (rnd>0.666)
                body = createCircle(world, 2, new b2Vec2(px, py), 0, Math.random()+0.125, "assets/circle.png", dens, fric, rest);
            else
            {
                var scale:Number = Math.random() * 1.25 + 0.25;
                // we're using a negative scale.y because Physics Editor uses a positive up coordinate system for Y while Loom has Y increasing downwards
                body = loadBody(world, 2, new b2Vec2(px, py), 0, new b2Vec2(64/ptmRatio, 62/ptmRatio), new b2Vec2(1 * scale, -1 * scale), "assets/star.png", "assets/star.box2d-generic.plist", "star");
            }
    
            if (!body)
                return;

            // apply a random force
            body.applyForceToCenter(new b2Vec2(Math.random()*2000-1000, Math.random()*2000-1000), true);
            body.applyTorque(Math.random()*2000-1000, true);

            // make less dense bodies be slightly transparent as if they were baloons
            var pgo:PhysicsGameObject = body.getUserData() as PhysicsGameObject;
            pgo.sprite.alpha = Math.clamp(dens, 0.4, 1);
        }

        override public function run():void
        {

            stage.scaleMode = StageScaleMode.NONE;

            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.x = 0;
            bg.y = 0;
            bg.width = stage.nativeStageWidth;
            bg.height = stage.nativeStageHeight;
            stage.addChild(bg);

            // set a scale, so that objects are relatively the same size on the stage on all devices
            bodyScale = Math.min(stage.nativeStageWidth / stage.stageWidth, stage.nativeStageHeight / stage.stageHeight);

            // *******

            // Create the world and set up gravity.
            // Earth (9.78), Moon (1.622), Mars (3.711), Venus (8.87)
            // Using a gravity vector pointing downwards on the screen.
            var gravity:b2Vec2 = new b2Vec2(0, 9.78);
            world = new b2World(gravity);

            // stage in meters
            var mWidth:Number = stage.stageWidth/ptmRatio;
            var mHeight:Number = stage.stageHeight/ptmRatio;

            // create a ceiling and a floor (center, bottom) and two side walls (rotated CCW & CW by 90 degrees)
            createBox(world, 0, new b2Vec2(mWidth * 0.5, mHeight * 0.05), 0, new b2Vec2(mWidth * 0.75, mHeight * 0.05), "assets/rect.png", 1, 0.6, 0.3);
            createBox(world, 0, new b2Vec2(mWidth * 0.5, mHeight * 0.95), 0, new b2Vec2(mWidth * 0.75, mHeight * 0.05), "assets/rect.png", 1, 0.6, 0.3);
            createBox(world, 0, new b2Vec2(mWidth * 0.05, mHeight * 0.5), Math.PI/2, new b2Vec2(mHeight * 0.5, mHeight * 0.05), "assets/rect.png", 1, 0.6, 0.3);
            createBox(world, 0, new b2Vec2(mWidth * 0.95, mHeight * 0.5), 3*Math.PI/2, new b2Vec2(mHeight * 0.5, mHeight * 0.05), "assets/rect.png", 1, 0.6, 0.3);

            // create a few static platforms at an angle
            createBox(world, 0, new b2Vec2(mWidth * 0.25, mHeight * 0.35), Math.PI/6, new b2Vec2(mWidth * 0.25, mHeight * 0.025), "assets/rect.png", 1, 0.6, 0.3);
            createBox(world, 0, new b2Vec2(mWidth * 0.75, mHeight * 0.35), -Math.PI/6, new b2Vec2(mWidth * 0.25, mHeight * 0.025), "assets/rect.png", 1, 0.6, 0.3);


            // listen for touch and generate a new shape on touch
            stage.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent)
            {
                var touch = e.getTouch(stage, TouchPhase.BEGAN);
                if (touch && simulationEnabled)
                    createRandomShape(touch.globalX/ptmRatio, touch.globalY/ptmRatio);
            });            

            // set up tick rate and iterations
            var timeManager = (LoomGroup.rootGroup.getManager(TimeManager) as TimeManager);
            tickRate = timeManager.TICK_RATE;

            // enable the simulation so that onFrame handles physics stepping
            simulationEnabled = true;
        }

    }
}