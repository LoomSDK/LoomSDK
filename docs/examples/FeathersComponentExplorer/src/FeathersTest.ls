package {
    import feathers.controls.Button;
    import loom2d.display.D;
    import loom2d.display.Stage;
    import loom2d.Loom2D;
    import unittest.Assert;
    import unittest.AssertResult;
    public class FeathersTest extends InstrumentationTestCase {
        
        private var device:UiDevice;
        
        override protected function setUp() {
            device = UiDevice.getInstance(getInstrumentation());
        }
        
        override protected function tearDown() {
            
        }
        
        [Test]
        public function testButtons() {
            var toggle:UiObject;
            
            toggle = device.findObject(new UiSelector()
                .text("Toggle Button")
                .className("feathers.controls.Button")
            );
            Assert.isTrue(toggle.exists());
            Assert.isTrue(toggle.enabled());
            toggle.click();
            
            toggle = device.findObject(new UiSelector()
                .className("screens.ButtonScreen")
                .childSelector(new UiSelector()
                    .checkable(true)
                    .checked(true)
                )
            );
            Assert.compare("Toggle Button", toggle.getText());
            
            Assert.compare("Button", device.findObject(new UiSelector()
                .classType(Button)
            ).getText());
            
            var disabled:UiObject = device.findObject(new UiSelector()
                .text("Disabled Button")
                .className("feathers.controls.Button")
            );
            Assert.isTrue(disabled.exists());
            Assert.isFalse(disabled.enabled());
            
            D.enabled = true;
            
            Assert.compare("Callout", device.findObject(new UiSelector()
                .className("feathers.controls.Button")
                .instance(2)
            ).getText());
            
            Assert.compare("Icon Button", device.findObject(new UiSelector()
                .className("screens.ButtonScreen")
                .childSelector(new UiSelector()
                    .className("feathers.controls.Button")
                    .instance(2)
                )
            ).getText());
            
            Assert.compare("Normal Button", device.findObject(new UiSelector()
                .classNameMatches("Button")
                .instance(3)
            ).getText());
            
            Assert.isFalse(device.findObject(new UiSelector()
                .clickable(false)
            ).exists());
            
            Assert.compare("Disabled Button", device.findObject(new UiSelector()
                .enabled(false)
            ).getText());
            
            Assert.compare("Normal Button", device.findObject(new UiSelector()
                .text("Danger Button")
                .fromParent(new UiSelector()
                    .classNameMatches("Button")
                )
            ).getText());
            
            Assert.compare("Toggle Button", device.findObject(new UiSelector()
                .classNameMatches("Button")
                .index(3)
            ).getText());
            
            Assert.compare("Quiet Button", device.findObject(new UiSelector()
                .textContains("Quiet")
            ).getText());
            
            Assert.compare("Call to Action Button", device.findObject(new UiSelector()
                .textMatches("Call.*n B")
            ).getText());
            
            Assert.compare("Danger Button", device.findObject(new UiSelector()
                .textStartsWith("Dan")
            ).getText());
            
            var results = Assert.popResults();
            for each (var result:AssertResult in results) {
                trace(result);
            }
        }
        
        public function testToggles() {
            var toggle:UiObject = device.findObject(new UiSelector()
                .text("Toggle Button")
                .className("feathers.controls.Button")
            );
            trace("Toggle exists?", toggle.exists());
            trace("Toggle enabled?", toggle.enabled());
            
        }
        
    }
    
}