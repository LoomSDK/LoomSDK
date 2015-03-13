/*
 * $Id$
 */

package loom.modestmaps.events
{
    import loom.modestmaps.geo.Location; 
    
    import loom2d.events.Event;
    import loom2d.display.DisplayObject;
    
    public class MarkerEvent extends Event
    {
        // these are prefixed marker to avoid conflicts with MouseEvent
        public static const MARKER_ROLL_OVER:String = 'markerRollOver';
        public static const MARKER_ROLL_OUT:String = 'markerRollOut';
        public static const MARKER_CLICK:String = 'markerClick';

        protected var _marker:DisplayObject;
        protected var _location:Location;
        
        public function MarkerEvent(type:String, marker:DisplayObject, location:Location, bubbles:Boolean, cancelable:Boolean)
        {
            super(type, bubbles, cancelable);
            _marker = marker;
            _location = location;
        }

        public function get marker():DisplayObject
        {
            return _marker;
        }

        public function get location():Location
        {
            return _location;
        }
    }
}