package unittest {
    import system.reflection.Type;
    
    public class AssertResult {
        public var callStack:Vector.<CallStackInfo>;
        public var message = "";
        public var info = "";
        public function AssertResult() {}
    }
    
    public class Assert {
        
        private static const CALL_STACK_SKIP = 2; // +1
        public static const RESULT_SUCCESS = new AssertResult();
        
        private static var asserts = new Vector.<AssertResult>();
        
        static public function popResults():Vector.<AssertResult> {
            var results = asserts;
            asserts = new Vector.<AssertResult>();
            return results;
        }
        
        
        
        static public function fail(msg:String = null) {
            failure(msg, "");
        }
        
        static public function isTrue(o:Object, msg:String = null) {
            o == true ? success() : failure(msg, "expected true got "+o);
        }
        
        static public function isFalse(o:Object, msg:String = null) {
            o == false ? success() : failure(msg, "expected false got "+o);
        }
        
        static public function isNull(o:Object, msg:String = null) {
            o == null ? success() : failure(msg, "expected null got "+o);
        }
        
        static public function isNotNull(o:Object, msg:String = null) {
            o != null ? success() : failure(msg, "unexpected null");
        }
        
        static public function isNaN(n:Number, msg:String = null) {
            n != n ? success() : failure(msg, "expected NaN got "+n);
        }
        
        static public function isNotNaN(n:Number, msg:String = null) {
            n == n ? success() : failure(msg, "unexpected NaN");
        }
        
        
        static public function instanceOf(o:Object, type:Type, msg:String = null) {
            isNotNull(type, "instanceOf type is null");
            o is type ? success() : failure(msg, o+" is not of type "+type.getFullName());
        }
        
        static public function notInstanceOf(o:Object, type:Type, msg:String = null) {
            isNotNull(type, "notInstanceOf type is null");
            !(o is type) ? success() : failure(msg, o+" should not be of type "+type.getFullName());
        }
        
        
        static public function compare(expected:Object, actual:Object, msg:String = null) {
            expected == actual ? success() : failure(msg, "expected "+expected+" got "+actual);
        }
        
        
        static public function equal(a:Object, b:Object, msg:String = null) {
            a == b ? success() : failure(msg, a+" does not equal "+b);
        }
        
        static public function notEqual(a:Object, b:Object, msg:String = null) {
            a != b ? success() : failure(msg, a+" is equal to "+b);
        }
        
        
        static private function internalNumberEqualRelative(a:Number, b:Number, maxRelativeDifference:Number):Boolean {
            Assert.greater(maxRelativeDifference, 0, "Max. relative difference should be greater than 0");
            Assert.less   (maxRelativeDifference, 1, "Max. relative difference should be less than 1");
            var d = Math.abs(a-b);
            var aa = Math.abs(a);
            var ab = Math.abs(b);
            var m = ab > aa ? ab : aa;
            return d <= m*maxRelativeDifference;
        }
        
        static private const FLOAT_EPSILON = 1.192092896e-7;
        
        static public function compareNumber(expected:Number, actual:Number, msg:String = null, maxRelativeDifference:Number = NaN) {
            if (maxRelativeDifference != maxRelativeDifference) maxRelativeDifference = 2*FLOAT_EPSILON;
            internalNumberEqualRelative(expected, actual, maxRelativeDifference) ?
            success() : failure(msg, "expected "+expected+" got "+actual+" with a max rel. diff. of "+maxRelativeDifference);
        }
        
        static public function equalNumber(a:Number, b:Number, msg:String = null, maxRelativeDifference:Number = NaN) {
            if (maxRelativeDifference != maxRelativeDifference) maxRelativeDifference = 2*FLOAT_EPSILON;
            internalNumberEqualRelative(a, b, maxRelativeDifference) ?
            success() : failure(msg, a+" does not equal "+b+" with a max rel. diff. of "+maxRelativeDifference);
        }
        
        static public function notEqualNumber(a:Number, b:Number, msg:String = null, maxRelativeDifference:Number = NaN) {
            if (maxRelativeDifference != maxRelativeDifference) maxRelativeDifference = 2*FLOAT_EPSILON;
            !internalNumberEqualRelative(a, b, maxRelativeDifference) ?
            success() : failure(msg, a+" is equal to "+b+" with a max rel. diff. of "+maxRelativeDifference);
        }
        
        
        static public function greater(a:Object, b:Object, msg:String = null) {
            a > b ? success() : failure(msg, a+" is not greater than "+b);
        }
        
        static public function less(a:Object, b:Object, msg:String = null) {
            a < b ? success() : failure(msg, a+" is not less than "+b);
        }
        
        static public function greaterOrEqual(a:Object, b:Object, msg:String = null) {
            a >= b ? success() : failure(msg, a+" is not greater than or equal to "+b);
        }
        
        static public function lessOrEqual(a:Object, b:Object, msg:String = null) {
            a <= b ? success() : failure(msg, a+" is not less than or equal to "+b);
        }
        
        
        static public function contains(needle:Object, haystack:Object, msg:String = null) {
            if (needle is String && haystack is String) {
                var sn:String = needle as String;
                var sh:String = haystack as String;
                sh.indexOf(sn) != -1 ? success() : failure(msg, '"'+sh+'" does not contain "'+sn+'"');
            } else if (haystack is Vector.<Object>) {
                var vh:Vector.<Object> = haystack as Vector.<Object>;
                vh.contains(needle) ? success() : failure(msg, vh+" does not contain "+needle);
            } else {
                failure(msg, "contains can only be called with String needle and haystack or Object needle and Vector haystack");
            }
        }
        
        
        static private function success() {
            asserts.push(RESULT_SUCCESS);
        }
        
        static private function failure(msg:String, info:String) {
            var result = new AssertResult();
            result.callStack = getStack();
            result.message = msg;
            var func = (result.callStack[0] as CallStackInfo).method.getName();
            result.info = func+" "+info;
            asserts.push(result);
        }
        
        static private function getStack():Vector.<CallStackInfo> {
            var infos:Vector.<CallStackInfo> = Debug.getCallStack();
            Debug.assert(infos != null, "Unable to get call stack");
            infos.splice(0, CALL_STACK_SKIP);
            return infos;
        }
        
    }
    
}