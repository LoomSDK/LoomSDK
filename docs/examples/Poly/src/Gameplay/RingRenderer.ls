package poly.gameplay
{
   import loom.gameframework.AnimatedComponent;
   import loom2d.display.Image;
   import loom2d.display.Sprite;
   import loom2d.textures.Texture;

   /**
    * Component to manage the reaction explosion's visual state.
    */
   public class RingRenderer extends AnimatedComponent
   {
      [Inject]
      public var playfield:Sprite;

      public var sprite:Image;
      public var spriteFile:String = "assets/images/ring.png";

      public function set x(value:Number):void
      {
         if(sprite)
            sprite.x = value;
      }

      public function set y(value:Number):void
      {
         if(sprite)
            sprite.y = value;
      }

      public function set scale(value:Number):void
      {
         if(sprite)
            sprite.scale = value;
      }

      protected function onAdd():Boolean
      {
         if(!super.onAdd())
            return false;

         sprite = new Image(Texture.fromAsset(spriteFile));
         sprite.pivotX = sprite.width / 2;
         sprite.pivotY = sprite.height / 2;
         playfield.addChild(sprite);

         return true;
      }

      protected function onRemove():void
      {
         playfield.removeChild(sprite);
         sprite = null;
         playfield = null;

         super.onRemove();
      }
   }
}