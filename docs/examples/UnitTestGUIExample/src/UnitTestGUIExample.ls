package
{
    import data.*;
    import feathers.controls.*;
    import feathers.events.FeathersEventType;
    import feathers.motion.transitions.ScreenSlidingStackTransitionManager;
    import feathers.system.DeviceCapabilities;
    import feathers.text.VectorTextRenderer;
    import feathers.themes.MetalWorksMobileVectorTheme;
    import loom.Application;
    import loom2d.animation.Transitions;
    import loom2d.display.DisplayObject;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.Graphics;
    import loom2d.display.Shape;
    import loom2d.display.TextFormat;
    import loom2d.events.Event;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.Loom2D;
    import loom2d.math.Point;
    import screens.*;
    import unittest.Assert;
    import unittest.TestComplete;

    /**
     * Example GUI test based on the FeathersComponentExplorer example.
     */
    public class UnitTestGUIExample extends Application
    {
        private var main:Main;
        private var indicator:Shape;
        
        override public function run():void
        {
            if (!main) {			
                main = new Main();
                Loom2D.stage.addChild(main);
                indicator = new Shape();
                Loom2D.stage.addChild(indicator);
            }
        }
        
        /**
         * Emulates a click (begin and end touch events) on the provided DisplayObject
         * @param	target	The target to click.
         * @param	clicks	The number of times to click on the target in rapid succession.
         */
        private function clickObject(target:DisplayObject, clicks:int = 1)
        {
            var globalCenter = target.localToGlobal(new Point(target.width / 2, target.height / 2));
            
            // Animate a toucn indicator
            var g:Graphics = indicator.graphics;
            g.clear();
            g.beginFill(0xCCFC27);
            g.drawCircle(0, 0, target.width/4);
            indicator.x = globalCenter.x;
            indicator.y = globalCenter.y;
            indicator.scale = 1;
            indicator.alpha = 1;
            indicator.touchable = false;
            Loom2D.juggler.tween(indicator, 0.4, { scale: 3, alpha: 0, transition: Transitions.EASE_OUT } );
            
            // Dispatch touch events
            while (clicks > 0) {
                target.dispatchEvent(new TouchEvent(TouchEvent.TOUCH, [
                    new Touch(0, globalCenter.x, globalCenter.y, TouchPhase.BEGAN, target)
                ], false, false, false));
                
                target.dispatchEvent(new TouchEvent(TouchEvent.TOUCH, [
                    new Touch(0, globalCenter.x, globalCenter.y, TouchPhase.ENDED, target)
                ], false, false, false));
                
                clicks--;
            }
        }
        
        /**
         * Find a Feathers Button recursively in the provided display tree.
         * @param	target	The tree to search.
         * @param	label	The button label to search for.
         * @return	The first Button found with the provided label, otherwise null.
         */
        private function findButton(target:DisplayObject, label:String):Button
        {
            if (target is Button) if ((target as Button).label == label) return (target as Button);
            var doc = target as DisplayObjectContainer;
            if (doc) {
                for (var i = 0; i < doc.numChildren; i++) {
                    var ch = doc.getChildAt(i);
                    var b = findButton(ch, label);
                    if (b) return b;
                }	
            }
            return null;
        }
        
        /**
         * Traces out the provided object hierarchy-
         * @param	target	The object hierarchical tree to trace out.
         */
        private function debugObject(target:DisplayObject, index:int = 0, level:int = 0)
        {
            var prefix = ""; for (var l = 0; l < level; l++) prefix += "  ";
            var extra = "";
            if (target is Button) extra += " " + (target as Button).label;
            if (target is VectorTextRenderer) extra += " " + (target as VectorTextRenderer).text;
            trace(prefix + index, "(" + target.getTypeName() + ")", target.name, extra);
            var doc = target as DisplayObjectContainer;
            if (doc) {
                for (var i = 0; i < doc.numChildren; i++) {
                    var ch = doc.getChildAt(i);
                    debugObject(ch, i, level+1);
                }	
            }
        }
        
        /**
         * Asynchronous test that changes the step count through the settings and
         * then tests whether incrementing by one step increases by the specified amount.
         */
        [Test]
        private function stepChange(p:TestComplete):void {
            run();
            
            // Slow testing for nice effect
            var delay = 1;
            var stepCount = 5;
            // Default step is one
            var stepIncrease = stepCount-1;
            
            var nav = ScreenNavigator(main.content);
            
            var value = NumericStepperScreen(nav.activeScreen).getStepper().value;
            
            // Functions to call one after another with a delay in between them
            var queue = [
                function() {
                    clickObject(NumericStepperScreen(nav.activeScreen).getSettingsButton());
                },
                function() {
                    clickObject(findButton(NumericStepperSettingsScreen(nav.activeScreen), "+"), stepIncrease);
                },
                function() {
                    clickObject(NumericStepperSettingsScreen(nav.activeScreen).getBackButton());
                },
                function() {
                    Assert.instanceOf(nav.activeScreen, NumericStepperScreen);
                    clickObject(findButton(NumericStepperScreen(nav.activeScreen), "+"));
                    Assert.compare(value + stepCount, NumericStepperScreen(nav.activeScreen).getStepper().value, "Stepper step doesn't match the one set");
                },
                function() { p.done(); }
            ];
                
            // Setup the delayed function calls
            for (var i:int = 0; i < queue.length; i++) 
            {
                Loom2D.juggler.delayCall(Function(queue[i]), delay * (i + 1));
            }
        }
        
    }

    /**
     * Stripped down FeathersComponentExample code only containing the 
     */
    public class Main extends Drawers
    {
        public static const MAIN_MENU:String = "mainMenu";
        public static const NUMERIC_STEPPER:String = "numericStepper";
        public static const NUMERIC_STEPPER_SETTINGS:String = "numericStepperSettings";

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