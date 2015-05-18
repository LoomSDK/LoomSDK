package unittest {
    import system.reflection.Type;
    
    /**
     * Contains the result of an assertion test.
     * Generally only unique for failed assertions.
     */
    public class AssertResult {
        /**
         * The call stack at the assertion test point.
         */
        public var callStack:Vector.<CallStackInfo>;
        
        /**
         * The test-provided custom message to go with the assertion test result.
         */
        public var message = "";
        
        /**
         * An auto-generated informational message about the specifics of the assertion test.
         */
        public var info = "";
        
        public function AssertResult() {}
    }
    
    public class Assert {
        
        /**
         * Defines how many calls are skipped from the top of the stack,
         * to avoid from internal Assert calls showing up in every result.
         */
        private static const CALL_STACK_SKIP = 2; // +1
        
        /**
         * Successful assert results aren't saved individually as you usually
         * aren't interested in detailed specifics of successfully ran assertions.
         * This object is inserted as a placeholder for all successful assertions.
         */
        public static const RESULT_SUCCESS = new AssertResult();
        
        /**
         * Internal list of results, gets returned and reset when popResults is called.
         */
        private static var asserts = new Vector.<AssertResult>();
        private static var assertStack = new Vector.<Vector.<AssertResult>>();
        
        static public function pushResults() {
            assertStack.push(asserts);
            asserts = new Vector.<AssertResult>();
        }
        
        /**
         * Return all the results since the last time this function was called.
         * @return  All the assertion results since the last popResults call.
         */
        static public function popResults():Vector.<AssertResult> {
            var results = asserts;
            asserts = assertStack.length > 0 ? assertStack.pop() : new Vector.<AssertResult>();
            return results;
        }
        
        
        /**
         * Unconditional assertion failure, useful for custom branching paths,
         * when you just want to log a failure without any additional logic.
         * @param msg   A custom message to attach to the result.
         */
        static public function fail(msg:String = null) {
            failure(msg, "");
        }
        
        /**
         * Assertion passes if the provided Object equals true.
         * @param o The Object to compare to true.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function isTrue(o:Object, msg:String = null) {
            o == true ? success() : failure(msg, "expected true got "+o);
        }
        
        /**
         * Assertion passes if the provided Object equals false.
         * @param o The Object to compare to false.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function isFalse(o:Object, msg:String = null) {
            o == false ? success() : failure(msg, "expected false got "+o);
        }
        
        /**
         * Assertion passes if the provided Object equals null.
         * @param o The Object to compare to null.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function isNull(o:Object, msg:String = null) {
            o == null ? success() : failure(msg, "expected null got "+o);
        }
        
        /**
         * Assertion passes if the provided Object does not equal null.
         * @param o The Object to compare to null.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function isNotNull(o:Object, msg:String = null) {
            o != null ? success() : failure(msg, "unexpected null");
        }
        
        /**
         * Assertion passes if the provided Number is NaN (Not a Number).
         * NaN equality is tested using self-equality i.e. n != n, which is only true for NaN values.
         * @param n The Number to test.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function isNaN(n:Number, msg:String = null) {
            n != n ? success() : failure(msg, "expected NaN got "+n);
        }
        
        /**
         * Assertion passes if the provided Number is not NaN (is a valid Number).
         * NaN equality is tested using self-equality i.e. n == n, which is only true for non-NaN values.
         * @param n The Number to test.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function isNotNaN(n:Number, msg:String = null) {
            n == n ? success() : failure(msg, "unexpected NaN");
        }
        
        /**
         * Assertion passes if the provided Object is an instance of the provided Type.
         * @param o The instance to check.
         * @param type  The type to check the instance against.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function instanceOf(o:Object, type:Type, msg:String = null) {
            isNotNull(type, "instanceOf type is null");
            o is type ? success() : failure(msg, o+" is not of type "+type.getFullName());
        }
        
        /**
         * Assertion passes if the provided Object is not an instance of the provided type.
         * @param o The instance to check.
         * @param type  The type to check the instance against.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function notInstanceOf(o:Object, type:Type, msg:String = null) {
            isNotNull(type, "notInstanceOf type is null");
            !(o is type) ? success() : failure(msg, o+" should not be of type "+type.getFullName());
        }
        
        /**
         * Assertion passes if the expected value equals the actual value.
         * Functionally equivalent to equal, but with added semantics and terminology.
         * @param expected  The expected value, which is usually some sort of a constant.
         * @param actual    The actual value, which is usually what you want to verify.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function compare(expected:Object, actual:Object, msg:String = null) {
            expected == actual ? success() : failure(msg, "expected "+expected+" got "+actual);
        }
        
        /**
         * Assertion passes if the two Objects pass the equality test.
         * See compare if you want to compare an expected value to an actual one.
         * @param a First object to compare.
         * @param b Second object to compare with the first one.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function equal(a:Object, b:Object, msg:String = null) {
            a == b ? success() : failure(msg, a+" does not equal "+b);
        }
        
        /**
         * Assertion passes if the two Objects do not pass the equality test.
         * @param a First object to compare.
         * @param b Second object to compare.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function notEqual(a:Object, b:Object, msg:String = null) {
            a != b ? success() : failure(msg, a+" is equal to "+b);
        }
        
        /**
         * Internal Number comparison function with a relative tolerance.
         * @param a First number.
         * @param b Second number.
         * @param maxRelativeDifference The maximum relative difference between the numbers that still counts as being equal.
         * @return  True if the two numbers are equal within the maxRelativeDifference, false otherwise.
         */
        static private function internalNumberEqualRelative(a:Number, b:Number, maxRelativeDifference:Number):Boolean {
            Assert.greater(maxRelativeDifference, 0, "Max. relative difference should be greater than 0");
            var d = Math.abs(a-b);
            var aa = Math.abs(a);
            var ab = Math.abs(b);
            var m = ab > aa ? ab : aa;
            return d <= m*maxRelativeDifference;
        }
        
        /**
         * This should be the smallest difference between two floats.
         * Loom uses doubles, so this could potentially be even smaller.
         */
        static private const FLOAT_EPSILON = 1.192092896e-7;
        
        /**
         * Assertion passes if the expected number equals the actual number within the tolerance of maxRelativeDifference.
         * @param expected  The expected number, which is usually a constant.
         * @param actual    The actual number, which is usually a result you want to verify.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         * @param maxRelativeDifference The maximum relative difference between the numbers that still counts as being equal.
         *                              It should be greater than 0, but a small number (near the epsilon of floats). By default
         *                              it is twice the float epsilon i.e. 2.192092896e-7.
         */
        static public function compareNumber(expected:Number, actual:Number, msg:String = null, maxRelativeDifference:Number = NaN) {
            if (maxRelativeDifference != maxRelativeDifference) maxRelativeDifference = 2*FLOAT_EPSILON;
            internalNumberEqualRelative(expected, actual, maxRelativeDifference) ?
            success() : failure(msg, "expected "+expected+" got "+actual+" with a max rel. diff. of "+maxRelativeDifference);
        }
        
        /**
         * Assertion passes if the first number equals the second number within the tolerance of maxRelativeDifference.
         * @param a The first number.
         * @param b The second number.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         * @param maxRelativeDifference The maximum relative difference between the numbers that still counts as being equal.
         *                              It should be greater than 0, but a small number (near the epsilon of floats). By default
         *                              it is twice the float epsilon i.e. 2.192092896e-7.
         */
        static public function equalNumber(a:Number, b:Number, msg:String = null, maxRelativeDifference:Number = NaN) {
            if (maxRelativeDifference != maxRelativeDifference) maxRelativeDifference = 2*FLOAT_EPSILON;
            internalNumberEqualRelative(a, b, maxRelativeDifference) ?
            success() : failure(msg, a+" does not equal "+b+" with a max rel. diff. of "+maxRelativeDifference);
        }
        
        /**
         * Assertion passes if the first number does not equal the second number within the tolerance of maxRelativeDifference.
         * @param a The first number.
         * @param b The second number.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         * @param maxRelativeDifference The maximum relative difference between the numbers that still counts as being equal.
         *                              It should be greater than 0, but a small number (near the epsilon of floats). By default
         *                              it is twice the float epsilon i.e. 2.192092896e-7.
         */
        static public function notEqualNumber(a:Number, b:Number, msg:String = null, maxRelativeDifference:Number = NaN) {
            if (maxRelativeDifference != maxRelativeDifference) maxRelativeDifference = 2*FLOAT_EPSILON;
            !internalNumberEqualRelative(a, b, maxRelativeDifference) ?
            success() : failure(msg, a+" is equal to "+b+" with a max rel. diff. of "+maxRelativeDifference);
        }
        
        /**
         * Assertion passes if the first value is greater than the second value.
         * @param a The first value, e.g. a Number or a String. This should be greater than the second value.
         * @param b The second value, e.g. a Number or a String. This should be less than the first value.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function greater(a:Object, b:Object, msg:String = null) {
            a > b ? success() : failure(msg, a+" is not greater than "+b);
        }
        
        /**
         * Assertion passes if the first value is less than the second value.
         * @param a The first value, e.g. a Number or a String. This should be less than the second value.
         * @param b The second value, e.g. a Number or a String. This should be greater than the first value.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function less(a:Object, b:Object, msg:String = null) {
            a < b ? success() : failure(msg, a+" is not less than "+b);
        }
        
        /**
         * Assertion passes if the first value is greater than or equal to the second value.
         * @param a The first value, e.g. a Number or a String. This should be greater than or equal to the second value.
         * @param b The second value, e.g. a Number or a String. This should be less than or equal to the first value.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function greaterOrEqual(a:Object, b:Object, msg:String = null) {
            a >= b ? success() : failure(msg, a+" is not greater than or equal to "+b);
        }
        
        /**
         * Assertion passes if the first value is less than or equal to the second value.
         * @param a The first value, e.g. a Number or a String. This should be less than or equal to the second value.
         * @param b The second value, e.g. a Number or a String. This should be greater than or equal to the first value.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
        static public function lessOrEqual(a:Object, b:Object, msg:String = null) {
            a <= b ? success() : failure(msg, a+" is not less than or equal to "+b);
        }
        
        /**
         * Assertion passes if the needle is contained within the haystack.
         * @param needle    The needle has to be a String if the haystack is a String. If the haystack is a Vector, the needle can be an Object.
         * @param haystack  If haystack is a String, the assertion passes if needle is a substring contained in haystack.
         *                  If haystack is a Vector, the assertion passes if needle is contained within the Vector.
         * @param msg   Optional custom message providing more information in the event of assertion failure.
         */
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
        
        /**
         * Internal function adding a successful assertion result.
         */
        static private function success() {
            asserts.push(RESULT_SUCCESS);
        }
        
        /**
         * Internal function addding a failed assertion result.
         * @param msg   Custom message providing more information in the event of assertion failure.
         * @param info  Auto-generated message with information about the failure.
         */
        static private function failure(msg:String, info:String) {
            var result = new AssertResult();
            result.callStack = getStack();
            result.message = msg;
            var func = (result.callStack[0] as CallStackInfo).method.getName();
            result.info = func+" "+info;
            asserts.push(result);
        }
        
        /**
         * Internal function providing a trimmed call stack.
         * @return  The trimmed call stack.
         */
        static private function getStack():Vector.<CallStackInfo> {
            var infos:Vector.<CallStackInfo> = Debug.getCallStack();
            Debug.assert(infos != null, "Unable to get call stack");
            infos.splice(0, CALL_STACK_SKIP);
            return infos;
        }
        
    }
    
}