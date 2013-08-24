package poly.views
{
   import poly.ui.View;
   import loom2d.ui.SimpleLabel;

   import poly.gameplay.PolyLevel;

   import loom.gameframework.LoomGroup;
   
   import loom2d.display.DisplayObjectContainer;

   /**
    * View that manages the simulation.
    */
   public class GamePlayView extends View
   {
      public var group:LoomGroup;
      public var level:PolyLevel;

      public function enter(owner:DisplayObjectContainer):void
      {
         super.enter(owner);

         // Spin up game!
         if(!level)
         {
            level = new PolyLevel();
            level.owningGroup = group;
            level.initialize();
         }
      }

      public function exit():void
      {
         // Shut down game.
         if(level)
         {
            level.destroy();
            level = null;            
         }

         super.exit();
      }
   }
}