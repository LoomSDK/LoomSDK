package poly.gameplay
{
   import loom2d.display.DisplayObjectContainer;
   import loom2d.display.Image;
   import loom2d.display.Sprite;
   import loom2d.events.Event;
   import loom2d.events.Touch;
   import loom2d.events.TouchEvent;
   import loom2d.events.TouchPhase;

   import loom2d.math.Point;

   import loom.gameframework.LoomGroup;
   import loom.gameframework.LoomGameObject;
   import loom.gameframework.IAnimated;
   import loom.gameframework.TimeManager;

   import loom.sound.SimpleAudioEngine;

   import loom.Application;
   import loom2d.textures.Texture;

   import loom2d.ui.SimpleLabel;

   import loom.animation.LoomTween;
   import loom.animation.LoomEaseType;

   delegate PolyLevelCompletionCallback(exploded:int, total:int):void;

   /**
    * Simulation logic for chain reaction game.
    */
   public class PolyLevel extends LoomGroup implements IAnimated
   {
      public var polyCount:int = 25;

      [Inject]
      public var timeManager:TimeManager;

      [Inject]
      public var playfield:Sprite;

      [Inject]
      public var overlay:Sprite;

      static public var polyBatch:DisplayObjectContainer;

      public var onCompletion:PolyLevelCompletionCallback = new PolyLevelCompletionCallback();
      public var polySounds:Vector.<String> = new Vector.<String>["Hooray.mp3","WooHoo.mp3","Yipee.mp3","Yay.mp3","YeeHah.mp3"];

      public var reaction:Image;
      public var reacted:Boolean = false;
      public var roundDone:Boolean = false;
      public var reactions:Vector.<PolyMover> = new Vector.<PolyMover>();
      public var polies:Vector.<PolyMover> = new Vector.<PolyMover>();

      public var onFinished:PolyLevelCompletionCallback;
      
      public function initialize(_name:String = null):void
      {
         super.initialize(_name);

         // Set up the batch for polies!
         polyBatch = new Sprite();
         polyBatch.name = "polyBatch";
         playfield.addChild(polyBatch);

         // Spawn some critters!
         for(var i:int=0; i<polyCount; i++)
            spawnPoly();

         Debug.assert(playfield, "No playfield found!");

         reaction = new Image(Texture.fromAsset("assets/images/ring.png"));
         reaction.scaleX = reaction.scaleY = 0;
         playfield.addChild(reaction);

         timeManager.addAnimatedObject(this);

         // Listen for input!
         playfield.stage.addEventListener(TouchEvent.TOUCH, onTouchBegan);
      }

      public function destroy():void
      {
         Console.print("Destroying level.");

         timeManager.removeAnimatedObject(this);

         playfield.stage.removeEventListener(TouchEvent.TOUCH, onTouchBegan);

         super.destroy();

         playfield.removeChild(polyBatch);
         playfield.removeChild(reaction);
      }
      
      public function spawnPoly():LoomGameObject
      {
         var lgo = new LoomGameObject();
         lgo.owningGroup = this;

         var mover = new PolyMover();
         mover.positionRandomly();
         mover.scale = 0.5;
         polies.pushSingle(mover);
         lgo.addComponent(mover, "mover");

         var renderer = new PolyRenderer();
         renderer.addBinding("x", "@mover.x");
         renderer.addBinding("y", "@mover.y");
         renderer.addBinding("scale", "@mover.scale");
         renderer.mover = mover;
         lgo.addComponent(renderer, "renderer");
         lgo.initialize();

         return lgo;
      }

      public function spawnReaction(x:Number, y:Number):LoomGameObject
      {
         var lgo = new LoomGameObject();
         lgo.owningGroup = this;

         var mover = new PolyMover();
         mover.x = x;
         mover.y = y;
         mover.scale = 0;
         mover.stopped = true;
         lgo.addComponent(mover, "mover");

         var renderer = new RingRenderer();
         renderer.addBinding("x", "@mover.x");
         renderer.addBinding("y", "@mover.y");
         renderer.addBinding("scale", "@mover.scale");
         lgo.addComponent(renderer, "renderer");
         lgo.initialize();

         return lgo;         
      }

      public function reactionStage2(tween:LoomTween):void
      {
         LoomTween.to(tween.targetObj, 0.3, {"scale": 1, "ease": LoomEaseType.EASE_OUT_BOUNCE}).onComplete += reactionStage3;
      }

      public function reactionStage3(tween:LoomTween):void
      {
         LoomTween.to(tween.targetObj, 0.3, {"scale": 0, "ease": LoomEaseType.EASE_OUT_BOUNCE}).onComplete += reactionStage4;
      }

      public function reactionStage4(tween:LoomTween):void
      {
         reactions.remove(tween.targetObj);
      }

      public function onTouchBegan(te:TouchEvent):void
      {
         // Filter to only consider new touches.
         var touch = te.getTouch(playfield.stage, TouchPhase.BEGAN);
         if(touch == null)
            return;

         trace("Triggering reaction!");
         if(!reacted)
         {
            reacted = true;

            var p:Point = touch.getLocation(playfield);
            var lgo:LoomGameObject = spawnReaction(p.x, p.y);
            var mover:PolyMover = lgo.lookupComponentByName("mover") as PolyMover;

            LoomTween.to(mover, 0.3, {"scale": 1, "ease": LoomEaseType.EASE_OUT_BOUNCE}).onComplete += reactionStage2;

            reactions.pushSingle(mover);
         }
      }

      public function onFrame():void
      {
         calculateCollisions();

         if(reacted && reactions.length == 0 && !roundDone)
         {
            roundDone = true;
            onFinished(polies.length, polyCount);
         }
      }

      public function pause(value:Boolean)
      {
         if(value)
            timeManager.stop();
         else
            timeManager.start();
      }

      public function calculateCollisions():void
      {
         var polyRadius = PolyMover.BASE_RADIUS;

         for(var j = 0; j < reactions.length; j++)
         {
            var r:PolyMover = reactions[j];

            var reactionX = r.x;
            var reactionY = r.y;
            var reactionRadius = r.scale * PolyMover.BASE_RADIUS;

            for(var i:Number=0; i < polies.length; i++)
            {
               var poly:PolyMover = polies[i];
               if(poly.stopped)
                  continue;

               var polyX = poly.x;
               var polyY = poly.y;

               var xDist = (reactionX-polyX);
               var yDist = (reactionY-polyY);

               var distSqr = xDist * xDist + yDist * yDist;

               if(distSqr <= (polyRadius + reactionRadius) * (polyRadius + reactionRadius))
               {
                  onPolyCollide(poly);
               }
            }
         }
      }

      public function onPolyCollide(poly:PolyMover):void
      {
         var soundIndex:int = Math.floor(Math.random() * polySounds.length);
         var sound:String = polySounds[soundIndex];
         SimpleAudioEngine.sharedEngine().playEffect("assets/sound/" + sound);

         poly.stopped = true;

         LoomTween.to(poly, 0.4, {"scale": 1, "ease": LoomEaseType.EASE_OUT_BOUNCE}).onComplete += onPolyComplete;

         reactions.pushSingle(poly);
         polies.remove(poly);
      }

      public function onPolyComplete(tween:LoomTween):void
      {
         LoomTween.to(tween.targetObj, 0.5, {"scale": 1, "ease": LoomEaseType.EASE_OUT_BOUNCE}).onComplete += onPolyReadyToDie;
      }

      public function onPolyReadyToDie(tween:LoomTween):void
      {
         LoomTween.to(tween.targetObj, 0.3, {"scale": 0, "ease": LoomEaseType.EASE_OUT_BOUNCE}).onComplete += onPolyGone;
      }

      public function onPolyGone(tween:LoomTween):void
      {
         reactions.remove(tween.targetObj as PolyMover);
      }
   }
}