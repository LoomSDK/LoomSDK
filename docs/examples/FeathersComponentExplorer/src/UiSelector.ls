package {
    import system.reflection.Type;
    
    public enum BoolParam {
        FALSE = 0,
        TRUE = 1,
        UNSET = 2,
    }
    
    public class UiSelector {
        
        public function resetState() {
            _stateInstance = 0;
        }
        
        public var _checkable = BoolParam.UNSET;
        public function checkable(val:Boolean):UiSelector {
            _checkable = val ? BoolParam.TRUE : BoolParam.FALSE;
            return this;
        }
        
        public var _checked = BoolParam.UNSET;
        public function checked(val:Boolean):UiSelector {
            _checked = val ? BoolParam.TRUE : BoolParam.FALSE;
            return this;
        }
        
        public var _childSelector:UiSelector = null;
        public function childSelector(selector:UiSelector):UiSelector {
            _childSelector = selector;
            return this;
        }
        
        public var _classType:Type = null;
        public function className(val:String):UiSelector {
            _classType = Type.getTypeByName(val);
            Debug.assert(_classType, "Provided selector class name not found: " + val);
            return this;
        }
        public function classType(classTypeValue:Type):UiSelector {
            _classType = classTypeValue;
            return this;
        }
        
        public var _classNameMatches:String = null;
        public function classNameMatches(regex:String):UiSelector {
            _classNameMatches = regex;
            return this;
        }
        
        public var _clickable = BoolParam.UNSET;
        public function clickable(val:Boolean):UiSelector {
            _clickable = val ? BoolParam.TRUE : BoolParam.FALSE;
            return this;
        }
        
        public var _enabled = BoolParam.UNSET;
        public function enabled(val:Boolean):UiSelector {
            _enabled = val ? BoolParam.TRUE : BoolParam.FALSE;
            return this;
        }
        
        public var _focusable = BoolParam.UNSET;
        public function focusable(val:Boolean):UiSelector {
            _focusable = val ? BoolParam.TRUE : BoolParam.FALSE;
            return this;
        }
        
        public var _focused = BoolParam.UNSET;
        public function focused(val:Boolean):UiSelector {
            _focused = val ? BoolParam.TRUE : BoolParam.FALSE;
            return this;
        }
        
        public var _fromParent:UiSelector = null;
        public function fromParent(selector:UiSelector):UiSelector {
            _fromParent = selector;
            return this;
        }
        
        public var _index:int = -1;
        public function index(val:int):UiSelector {
            Debug.assert(val >= 0, "Index value should be 0 or greater");
            _index = val;
            return this;
        }
        
        public var _instance:int = -1;
        public var _stateInstance:int;
        public function instance(val:int):UiSelector {
            Debug.assert(val >= 0, "Provided instance number should be 0 or greater");
            _instance = val;
            return this;
        }
        
        public var _text:String = null;
        public function text(val:String):UiSelector {
            _text = val;
            return this;
        }
        
        public var _textContains:String = null;
        public function textContains(val:String):UiSelector {
            _textContains = val;
            return this;
        }
        
        public var _textMatches:String = null;
        public function textMatches(val:String):UiSelector {
            _textMatches = val;
            return this;
        }
        
        public var _textStartsWith:String = null;
        public function textStartsWith(val:String):UiSelector {
            _textStartsWith = val;
            return this;
        }
        
    }
    
}