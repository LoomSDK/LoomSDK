package {
    
    public class UiDevice {
        
        private var instr:Instrumentation;
        
        public function UiDevice() {
            
        }
    
        static public function getInstance(instrumentation:Instrumentation):UiDevice {
            var device = new UiDevice();
            device.instr = instrumentation;
            return device;
        }
        
        public function findObject(selector:UiSelector):UiObject {
            return new UiObject(selector);
        }
        
    }
    
}