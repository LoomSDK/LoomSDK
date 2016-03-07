package
{
    import unittest.TestRunner;
    import unittest.Assert;
    import loom.Application;
    import system.reflection.Assembly;
    
    import loom2d.display.TextFormat;
    import system.platform.Platform;
    
    import feathers.events.FeathersEventType;
    import feathers.motion.transitions.ScreenSlidingStackTransitionManager;
    import feathers.system.DeviceCapabilities;
    import feathers.themes.MetalWorksMobileTheme;
    import feathers.themes.MetalWorksMobileVectorTheme;
    import feathers.controls.*;

    import loom2d.Loom2D;
    import loom2d.events.Event;
    import unittest.TestComplete;
    
    import data.*;
    import screens.*;
    
    public class UnitTestGUIExample extends Application
    {
        override public function run():void
        {
            Loom2D.stage.addChild( new Main() );
        }
        
        [Test]
        private function stepChange(p:TestComplete):void {
            run();
            // FocusManager
        }
        
    }
    
    public class Main extends Drawers
    {
        private static const MAIN_MENU:String = "mainMenu";
        private static const NUMERIC_STEPPER:String = "numericStepper";
        private static const NUMERIC_STEPPER_SETTINGS:String = "numericStepperSettings";

        private static const MAIN_MENU_EVENTS:Dictionary.<String, String> =
        {
            "showNumericStepper": NUMERIC_STEPPER,
        };
        
        public function Main()
        {
            super();
            this.addEventListener(FeathersEventType.INITIALIZE, initializeHandler);
        }

        private var _navigator:ScreenNavigator;
        private var _menu:MainMenuScreen;
        private var _transitionManager:ScreenSlidingStackTransitionManager;
        
        private function initializeHandler(event:Event):void
        {
            DeviceCapabilities.dpi = Platform.getDPI();
            TextFormat.load("sans", "assets/SourceSansPro-Regular.ttf");
            new MetalWorksMobileVectorTheme();
            
            this._navigator = new ScreenNavigator();
            this.content = this._navigator;

            const numericStepperSettings:NumericStepperSettings = new NumericStepperSettings();
            this._navigator.addScreen(NUMERIC_STEPPER, new ScreenNavigatorItem(NumericStepperScreen,
            {
                complete: MAIN_MENU,
                showSettings: NUMERIC_STEPPER_SETTINGS
            },
            {
                settings: numericStepperSettings
            }));

            this._navigator.addScreen(NUMERIC_STEPPER_SETTINGS, new ScreenNavigatorItem(NumericStepperSettingsScreen,
            {
                complete: NUMERIC_STEPPER
            },
            {
                settings: numericStepperSettings
            }));

            
            this._transitionManager = new ScreenSlidingStackTransitionManager(this._navigator);
            this._transitionManager.duration = 0.4;

            if(DeviceCapabilities.isTablet())
            {
                this._navigator.clipContent = true;
                this._menu = new MainMenuScreen();
                for(var eventType:String in MAIN_MENU_EVENTS)
                {
                    this._menu.addEventListener(eventType, mainMenuEventHandler);
                }
                this._menu.height = 200;
                this.leftDrawer = this._menu;
                this.leftDrawerDockMode = Drawers.DOCK_MODE_BOTH;
            }
            else
            {
                this._navigator.addScreen(MAIN_MENU, new ScreenNavigatorItem(MainMenuScreen, MAIN_MENU_EVENTS));
                this._navigator.showScreen(MAIN_MENU);
            }
        }

        private function mainMenuEventHandler(event:Event):void
        {
            const screenName:String = MAIN_MENU_EVENTS[event.type];
            //because we're controlling the navigation externally, it doesn't
            //make sense to transition or keep a history
            this._transitionManager.clearStack();
            this._transitionManager.skipNextTransition = true;
            this._navigator.showScreen(screenName);
        }
    }
}