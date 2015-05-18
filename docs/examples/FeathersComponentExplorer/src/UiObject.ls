package {
    import feathers.core.IFeathersControl;
    import feathers.core.ILabel;
    import loom.Application;
    import loom2d.display.DisplayObject;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.Stage;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.Loom2D;
    import loom2d.math.Point;
    
    public class UiObject {
        
        private static var touchID = 1e6;
        
        private var selector:UiSelector;
        
        public function UiObject(selector:UiSelector) {
            this.selector = selector;
        }
        
        protected function findDisplayObject():DisplayObject {
            var root:DisplayObject = Loom2D.stage;
            selector.resetState();
            var d:DisplayObject = findBySelector(root, selector);
            //trace("findDisplayObject returned", d);
            return d;
        }
        
        static protected function findBySelector(d:DisplayObject, selector:UiSelector):DisplayObject {
            if (!d) return null;
            if (matches(d, selector)) {
                //trace("Return", d.getType().getFullName(), _getText(d));
                return d;
            }
            var dc = d as DisplayObjectContainer;
            if (dc) {
                var n = dc.numChildren;
                for (var i:int = 0; i < n; i++) {
                    var child = dc.getChildAt(i);
                    var found = findBySelector(child, selector);
                    if (found) return found;
                }
            }
            return null;
        }
        
        static protected function matches(d:DisplayObject, selector:UiSelector):Boolean {
            //trace("Match", d.getType().getFullName(), _getText(d));
            
            // Property match
            if (selector._textExact && _getText(d) != selector._textExact) return false;
            if (selector._classType && d.getType() is selector._classType) return false;
            
            // Instance match
            if (selector._instance >= 0 && selector._stateInstance != selector._instance) {
                selector._stateInstance++;
                return false;
            }
            
            return true;
        }
        
        /*
            PROPERTIES
        */
        
        public function exists():Boolean {
            return findDisplayObject() != null;
        }
        
        public function enabled():Boolean {
            var d:DisplayObject = findDisplayObject();
            var fc:IFeathersControl = d as IFeathersControl;
            if (fc && !fc.isEnabled) return false;
            return true;
        }
        
        public function getText():String {
            return _getText(findDisplayObject());
        }
        
        /*
            METHODS
        */
        
        public function click() {
            var d = findDisplayObject();
            assertObject(d);
            clickAt(d, d.width/2, d.height/2);
        }
        
        protected function clickAt(d:DisplayObject, x:Number, y:Number) {
            var id = touchID++;
            dispatchTouch(d, id, x, y, TouchPhase.BEGAN);
            dispatchTouch(d, id, x, y, TouchPhase.ENDED);
        }
        
        private function dispatchTouch(d:DisplayObject, id:Number, x:Number, y:Number, phase:String) {
            var g = d.localToGlobal(new Point(x, y));
            trace(x, y, g);
            Application.application.touchProcessor.enqueue(id, phase, g.x, g.y);
            //d.dispatchEvent(new TouchEvent(TouchEvent.TOUCH, [new Touch(id, g.x, g.y, phase, d)]));
        }
        
        /*
            UTILITY
        */
        
        static protected function assertObject(d:DisplayObject) {
            Debug.assert(d, "UiObject not found");
        }
        
        
        static protected function _getText(d:DisplayObject):String {
            assertObject(d);
            var dl:ILabel = d as ILabel;
            if (dl) return dl.label;
            return d.name;
        }
        
    }
    
}