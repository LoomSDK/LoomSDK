package {
    import system.reflection.Type;
    
    public class UiSelector {
        
        public var _textExact:String = null;
        public var _classType:Type = null;
        public var _instance:int = -1;
        
        /** State instance count */
        public var _stateInstance:int;
        
        public function resetState() {
            _stateInstance = 0;
        }
        
        public function text(textValue:String):UiSelector {
            _textExact = textValue;
            return this;
        }
        
        public function className(classNameValue:String):UiSelector {
            _classType = Type.getTypeByName(classNameValue);
            Debug.assert(_classType, "Provided selector class name not found: " + classNameValue);
            return this;
        }
        
        public function instance(instanceValue:int):UiSelector {
            Debug.assert(instanceValue >= 0, "Provided instance number should be 0 or greater");
            _instance = instanceValue;
            return this;
        }
        
    }
    
}