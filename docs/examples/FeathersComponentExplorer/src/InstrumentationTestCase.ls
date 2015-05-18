package {
    
    public class InstrumentationTestCase extends TestCase {
        
        protected var instr:Instrumentation;
        
        public function InstrumentationTestCase() {
            
        }
        
        public function getInstrumentation():Instrumentation {
            return instr;
        }
        
        public function injectInstrumentation(instrumentation:Instrumentation) {
            this.instr = instr;
        }
        
    }
    
}