package
{

    import loom.Application;

    import system.platform.Platform;
    import loom2d.display.StageScaleMode;    
    import loom2d.display.Image;
    import loom2d.display.QuadBatch;
    import loom2d.textures.Texture;

    import loom2d.text.BitmapFont;

    import loom.box2d.*;

    public class Box2DExample extends Application
    {
        override public function run():void
        {

            stage.scaleMode = StageScaleMode.LETTERBOX;

            var bg = new Image(Texture.fromAsset("assets/bg.png"));

            var ascale_w:Number = stage.stageWidth / bg.width;
            var ascale_h:Number = stage.stageHeight / bg.height;
            var assetScale:Number = (ascale_w > ascale_h) ? ascale_w : ascale_h;

            bg.x = 0;
            bg.y = 0;
            bg.scale = assetScale;
            stage.addChild(bg);

            // *******

            // create the world and set up gravity
            var gravity:b2Vec2 = new b2Vec2(0,-10);
            var world:b2World = new b2World(gravity);

            // create a body
            var bodyDef:b2BodyDef = new b2BodyDef();
            bodyDef.position = new b2Vec2(0,4);
            var body:b2Body = world.createBody(bodyDef);

            // create a shape
            var dynamicBox:b2PolygonShape = new b2PolygonShape();
            dynamicBox.setAsBox(1,1);

            // create a fixture for the body with the shape
            var fixtureDef:b2FixtureDef = new b2FixtureDef();
            fixtureDef.shape = dynamicBox;
            fixtureDef.density = 1;
            fixtureDef.friction = 0.3;
            body.createFixture(fixtureDef);

            // set up step vars
            var timeStep:Number = 1/60;
            var velocityIterations:int = 6;
            var positionIterations:int = 2;

            // run a second worth of simulation for the body
            for (var i=0;i<60;++i)
            {
                world.step(timeStep, velocityIterations, positionIterations);
                
                var position:b2Vec2 = body.getPosition();
                var angle:Number = body.getAngle();

                trace("Body position: " + position.x + ":" + position.y + ", angle: " + angle);
            }

        }

    }
}