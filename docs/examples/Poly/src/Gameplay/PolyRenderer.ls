package poly.gameplay
{
   import loom2d.display.DisplayObjectContainer;
   import loom2d.display.Image;
   import loom2d.display.Sprite;
   import loom.gameframework.AnimatedComponent;

   import loom2d.ui.TextureAtlasSprite;

   /**
    * Component to manage a Poly's visual appearance.
    */
   public class PolyRenderer extends AnimatedComponent
   {
      [Inject]
      public var playfield:Sprite;

      public var mover:PolyMover;

      public var COLOR_SPRITES:Vector.<String>;
      public var bodyColor:String;

      public var sprite:Sprite;
      public var body:TextureAtlasSprite;
      public var eyes:TextureAtlasSprite;
      public var mouth:TextureAtlasSprite;

      public function set x(value:Number):void
      {
         if(sprite)
            sprite.x = value;
      }

      public function set y(value:Number):void
      {
         if (sprite)
            sprite.y = value;
      }

      public function set scale(value:Number):void
      {
         if (sprite)
            sprite.scaleX = sprite.scaleY = value;
      }

      protected function onAdd():Boolean
      {
         if(!super.onAdd())
            return false;

         COLOR_SPRITES = ["blue", "yellow", "purple", "red"];

         bodyColor = randomBody();

         sprite = new Sprite();
         sprite.touchable = false;
         PolyLevel.polyBatch.addChild(sprite);
         
         body = new TextureAtlasSprite();
         body.atlasName = "polySprites";
         body.textureName = "circle_" + bodyColor + "_down.png";
         body.x = body.y = -50;

         eyes = new TextureAtlasSprite();
         eyes.atlasName = "polySprites";
         eyes.textureName = "eyes_" + Math.ceil(Math.random() * 4) + ".png";
         eyes.x = eyes.y = -50;

         mouth = new TextureAtlasSprite();
         mouth.atlasName = "polySprites";
         mouth.textureName = "mouths_" + Math.ceil(Math.random() * 5) + ".png";
         mouth.x = mouth.y = -50;

         sprite.addChild(body);
         sprite.addChild(eyes);
         sprite.addChild(mouth);

         // Make sure we start at correct position.
         onFrame();

         return true;
      }

      public function collide():void
      {
         body.textureName = "circle_" + bodyColor + "_puff.png";
      }

      public function randomBody():String
      {
         return COLOR_SPRITES[Math.floor(Math.random() * COLOR_SPRITES.length)];
      }

      protected function onRemove():void
      {
         PolyLevel.polyBatch.removeChild(sprite);
         playfield = null;

         super.onRemove();
      }
   }
}