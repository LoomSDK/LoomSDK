package {
    import feathers.controls.Button;
    import feathers.core.IFeathersControl;
    import feathers.core.IFocusDisplayObject;
    import feathers.core.ILabel;
    import feathers.core.IToggle;
    import loom.Application;
    import loom2d.display.DisplayObject;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.Stage;
    import loom2d.display.D;
    import loom2d.events.EventDispatcher;
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
            
            if (d) D.rect(d);
            return d;
        }
        
        static protected function findBySelector(d:DisplayObject, selector:UiSelector, level:int = 0):DisplayObject {
            if (!d) return null;
            if (matches(d, selector, level)) {
                //trace("Return", d.getType().getFullName(), _getText(d));
                if (selector._childSelector) {
                    d = findBySelector(d, selector._childSelector, level);
                }
                if (selector._fromParent) {
                    d = findBySelector(d.parent, selector._fromParent, level);
                }
                return d;
            }
            var dc = d as DisplayObjectContainer;
            if (dc) {
                var n = dc.numChildren;
                for (var i:int = 0; i < n; i++) {
                    var child = dc.getChildAt(i);
                    var found = findBySelector(child, selector, level+1);
                    if (found) return found;
                }
            }
            return null;
        }
        
        /**
         * All of the matches here are internally inverted (return false on failed match) to
         * allow for multiple matches to work in combination
         * @param d
         * @param selector
         * @param level
         * @return
         */
        static protected function matches(d:DisplayObject, selector:UiSelector, level:int = 0):Boolean {
            
            //var prefix = ""; while (prefix.length < level) prefix += " ";
            //trace(prefix, d.getType().getFullName(), _getText(d), d.getType().isDerivedFrom(selector._classType));
            
            //if (selector._classType) {
                //trace(selector._classType.getFullName());
                //trace(d.getType().getFullName());
            //}
            
            // Property match
            if (selector._checkable != BoolParam.UNSET) {
                var b = d as Button;
                if (!b) return false;
                // Logical XOR
                if (!selector._checkable != !b.isToggle) return false;
            }
            if (selector._checked != BoolParam.UNSET) {
                var t = d as IToggle;
                if (!t) return false;
                if (!selector._checked != !t.isSelected) return false;
            }
            if (selector._classType && !d.getType().isDerivedFrom(selector._classType)) return false;
            if (selector._classNameMatches) {
                //trace(d.getType().getFullName(), selector._classNameMatches, d.getType().getFullName().find("("+selector._classNameMatches+")").length);
                if (d.getType().getFullName().find("("+selector._classNameMatches+")").length == 0) return false;
                //trace(d, d.name, (d as Button).label);
                //return false;
            }
            if (selector._clickable != BoolParam.UNSET) {
                var ed = d as EventDispatcher;
                if (!selector._clickable != !ed) return false;
            }
            if (selector._enabled != BoolParam.UNSET) {
                var fc = d as IFeathersControl;
                // Non-IFeathersControls are always enabled
                if (!selector._enabled != (fc && !fc.isEnabled)) return false;
            }
            if (selector._focusable != BoolParam.UNSET) {
                var fd = d as IFocusDisplayObject;
                if (!selector._focusable != !fd) return false;
            }
            if (selector._focused != BoolParam.UNSET) {
                // TODO implement
                Debug.assert(false, "Unimplemented for now");
                //var fd = d as IFocusDisplayObject;
                //if (!selector._focused != (fd && fd.isFocusEnabled) return false;
            }
            if (selector._index != -1 && (!d.parent || d.parent.getChildIndex(d) != selector._index)) return false; 
            if (selector._text && _getText(d) != selector._text) return false;
            if (selector._textContains && _getText(d).indexOf(selector._textContains) == -1) return false;
            if (selector._textMatches) {
                var dt = _getText(d);
                if (!dt) return false;
                if (dt.find("("+selector._textMatches+")").length == 0) return false;
            }
            if (selector._textStartsWith && _getText(d).indexOf(selector._textStartsWith) != 0) return false;
            
            // Instance match
            if (selector._instance >= 0 && selector._stateInstance != selector._instance) {
                selector._stateInstance++;
                return false;
            }
            
            //trace("Matched");
            //trace("  ", selector._stateInstance);
            //trace("  ", selector._textExact, selector._classType, selector._instance);
            //trace("  ", selector._textExact == _getText(d), d.getType().isDerivedFrom(selector._classType));
            
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
            var d = findDisplayObject();
            if (!d) return null;
            return _getText(d);
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
            //trace(x, y, g);
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