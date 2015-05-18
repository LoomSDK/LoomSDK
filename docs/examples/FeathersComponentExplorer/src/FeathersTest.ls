package {
    
    public class FeathersTest extends InstrumentationTestCase {
        
        private var device:UiDevice;
        
        override protected function setUp() {
            device = UiDevice.getInstance(getInstrumentation());
        }
        
        override protected function tearDown() {
            
        }
        
        [Test]
        public function testButton() {
            var toggle:UiObject = device.findObject(new UiSelector()
                .text("Toggle Button")
                .className("feathers.controls.Button")
            );
            trace("Toggle exists?", toggle.exists());
            trace("Toggle enabled?", toggle.enabled());
            
            
            var disabled:UiObject = device.findObject(new UiSelector()
                .text("Disabled Button")
                .className("feathers.controls.Button")
            );
            trace("Disabled exists?", disabled.exists());
            trace("Disabled enabled?", disabled.enabled());
            
            toggle.click();
            
            trace(device.findObject(new UiSelector()
                .className("feathers.controls.Button")
                .instance(2)
            ).getText());
            
        }
        
    }
    
}