/*
 * vim:et sts=4 sw=4 cindent:
 * $Id$
 */

package loom.modestmaps.core
{
    import loom2d.Loom2D;
    import loom2d.animation.Transitions;
    
    public class TweenTile extends Tile
    {
        public static var FADE_TIME:Number = 0.25;
                
        public function TweenTile(col:int, row:int, zoom:int)
        {
            super(col, row, zoom);
        } 

        override public function hide():void
        {
            // *** don't *** kill the tweens when hiding
            // it seems there's a harmless bug where hide might get called after show
            // if there's a tween running it will correct it though :)
            //Loom2D.juggler.removeTweens(this);
            this.alpha = 0;
        }
        
        override public function show():void 
        {
            if (alpha < 1) {
                Loom2D.juggler.tween(this, FADE_TIME, {"alpha": 1.0, "transition": Transitions.LINEAR});   
            }
        }       

        override public function showNow():void 
        {
            Loom2D.juggler.removeTweens(this);
            this.alpha = 1;
        }       

        override public function destroy():void 
        {
            Loom2D.juggler.removeTweens(this);
            super.destroy();
        }                       
    }

}
