package loom2d.events
{
    
    /** A ScrollEvent is dispatched by the Stage when the user scrolls their mouse wheel
     */
    public class ScrollWheelEvent extends Event
    {        

        /** Event type for a scroll wheel event. */
        public static const SCROLLWHEEL:String = "scrollWheel";

        /** Creates a new ScrollWheelEvent. */
        public function ScrollWheelEvent(type:String, delta:Number, bubbles:Boolean=false)
        {
            super(type, bubbles, delta);
        }
        
        /** The updated width of the player. */
        public function get delta():Number { return (data as Number); }
        
    }
}