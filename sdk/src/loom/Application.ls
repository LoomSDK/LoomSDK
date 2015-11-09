/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

package loom 
{
    import loom2d.display.Graphics;
    import loom2d.display.Shape;
    import system.platform.Platform;
    import system.reflection.Assembly;
    import system.application.BaseApplication;
    
    import loom.gameframework.LoomGroup;
    import loom.gameframework.TimeManager;
    import loom.gameframework.PropertyManager;
    import loom.gameframework.ConsoleCommandManager;

    import loom.gameframework.ITicked;
    import loom.gameframework.IAnimated;

    import loom.platform.Accelerometer;
   
    import loom2d.math.Rectangle;

    import loom2d.Loom2D;
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.display.Stage;
    import loom2d.display.Quad;
    import loom2d.textures.Texture;
    import loom2d.textures.SubTexture;
    import loom2d.animation.Tween;
    import loom2d.animation.Transitions;
    import loom2d.core.TouchProcessor;
    import loom2d.native.Loom2DNative;

    /**
     * Simple delegate called by Application on the start of the first frame.
     *
     * Useful for startup logic that requires fully configured graphics or other
     * resources that aren't available in the app constructor.
     */
    delegate OnStart():void;

    /**
     * The global static class that drives execution of our game.
     *
     * Corresponds to lmApplication.cpp; makes most basic stuff in Loom happen!
     */
    public class Application extends BaseApplication implements ITicked, IAnimated
    {
        private var splashContainer:Sprite;
        private var frameLastPlatformTime:Number = 0;
        
        private var assetDebugOverlay:Shape;
        private var assetDebugEnabled = false;

        /**
         * Starting point for your game's code.
         *
         * Some subsystems take a frame to start up; therefore we have run()
         * which is called after everything is ready.
         *
         * Make sure to call super.run() in your override so that the default
         * groups and managers get initialized.
         */
        protected function _run():void
        {
            Debug.assert(!theApplication, "Application already exists, executing _run more than once?");
            theApplication = this;

            // register onReload with DebuggerClient
            DebuggerClient.reloaded += onReload;
            
            frameLastPlatformTime = Platform.getTime();

            // set up the default layer for the cocos2d game
            /*layer.autorelease();
            layer.setKeypadEnabled(true);
            layer.setScrollWheelEnabled(true);
            layer.setAccelerometerEnabled(true);
            layer.onAccelerate += accelerated;

            Cocos2D.addLayer(layer); */
            //group.registerManager(layer);
            
            // TODO: LOOM-1521 Resurrent feedback layer with Loom2D
            // create our feedback layer for asset agent transfers

            // Listen for asset stream activity and give visual feedback.
            LoomAssetManager.pendingCountChange += onAssetStreamCountChange;
            
            //var displayStats = Cocos2D.getDisplayStats();
            //Cocos2D.onDisplayStatsChanged += onDisplayStatsChanged;

            // Only show the feedback layer when the fps stats are shown.
            //feedbackLayer.setVisible(displayStats);

            // initialize the native subsystem
            Loom2DNative.initialize();
            
            var config = new JSON();
            config.loadString(loomConfigJSON);
            
            var display = config.getObject("display");
            var configWidth = display.getInteger("width");
            var configHeight = display.getInteger("height");
            var configColor = Number.fromString("0x"+display.getString("color"));
            
            // create the stage using the initial display size as specified by loom.config
            //theStage = new Stage(/*layer,*/ Cocos2D.getConfigDisplayWidth(), Cocos2D.getConfigDisplayHeight(), 0x000000);
            theStage = new Stage(configWidth, configHeight, configColor);
            Loom2D.stage = theStage;
            
            if (display.getNumber("stats") == 1) theStage.reportFps = true;

            Stage.onRenderStage += onInternalFrame;
            
            if (assetDebugEnabled) {
                assetDebugOverlay = new Shape();
                stage.addChild(assetDebugOverlay);
            }
            
            theStage.onAccelerate += accelerated;

            // This enables touch/mouse input.
            touchProcessor = new TouchProcessor(stage);
            
            // Seed the Random Number Generator
            Random.setSeed(Platform.getEpochTime());

            // Used to adjust delay for starting the splash screen animation.
            var startDelay = 1.0;

            // LOOM-1752: Disabling splash screen until this issue is resolved
            if (false)
            {

                // Start the splash after first frame is renderered. This is in a 
                // big block here because otherwise it is in a single function in 
                // the loomlib that is easily rewritten/modified. It's not a lot 
                // of DRM but it's a little bit. ;)
                Loom2D.juggler.delayCall(function():void {

                    // Show the splash screen using the embedded texture.
                    var splashTexture = Texture.fromAsset("$splashAssets.png");
                    var splashUpperTexture = Texture.fromTexture(splashTexture, new Rectangle(0, 0, 264, 125));
                    var splashLowerTexture = Texture.fromTexture(splashTexture, new Rectangle(0, 125, 264, 52));

                    // Position everything on the  stage in its own container.
                    var realStageHeight = configHeight;
                    var realStageWidth = configWidth;

                    splashContainer = new Sprite();

                    var splashQuad = new Quad(realStageWidth, realStageHeight, 0x00000);
                    splashContainer.addChild(splashQuad);
                    
                    var splashUpper = new Image(splashUpperTexture);
                    splashUpper.x = (realStageWidth - splashUpper.width) / 2;
                    splashUpper.y = (realStageHeight - splashTexture.height) / 2;
                    splashContainer.addChild(splashUpper);
                    
                    var splashLower = new Image(splashLowerTexture);
                    splashLower.x = (realStageWidth - splashLower.width) / 2;
                    splashLower.y = ((realStageHeight - splashTexture.height) / 2) + splashUpperTexture.height;
                    splashContainer.addChild(splashLower);

                    stage.addChild(splashContainer);

                    // Initialize the tweens.
                    var upperTween = Tween.fromPool(splashUpper, 0.7, Transitions.EASE_IN);
                    upperTween.delay = startDelay + 0.3;
                    upperTween.animate("y", -2*splashUpperTexture.height);
                    Loom2D.juggler.add(upperTween);

                    var lowerTween = Tween.fromPool(splashLower, 0.7, Transitions.EASE_IN);
                    lowerTween.delay = startDelay + 0.3;
                    lowerTween.animate("y", realStageHeight + splashLowerTexture.height + 5);
                    Loom2D.juggler.add(lowerTween);

                    // And call user's run code once splash is done.
                    Loom2D.juggler.delayCall(function():void 
                    {
                        // Clean up the splash!
                        stage.removeChild(splashContainer, true);

                        // Initialize managers.
                        installManagers();

                        // Name the default group after the game's type.
                        group.initialize(this.getType().getFullName() + "Group");

                        // Apply root group injection to the game for convenience.
                        group.injectInto(this);

                        // Fire off user code!
                        run();
                    }, startDelay + 1.0);

                }, 0.0);
            }
            else
            {
                // Initialize managers.
                installManagers();

                // Name the default group after the game's type.
                group.initialize(this.getType().getFullName() + "Group");

                // Apply root group injection to the game for convenience.
                group.injectInto(this);

                // Fire off user code!
                run();
                
            }
    
        }

        protected function onTerminate():void
        {
            Console.print("Terminating process...");
            Process.exit(0);
        }

        protected function onProfilerEnable():void 
        {
            Console.print("Enabling profiler...");
            Profiler.enable();
        }

        protected function onProfilerDump():void
        {
            Console.print("Dumping profiler...");
            Profiler.dump();
        }
        
        protected function onTelemetryEnable():void
        {
            Telemetry.enable();
        }
        
        protected function onTelemetryDisable():void
        {
            Telemetry.disable();
        }

        protected function onDumpManagedNatives():void
        {
            VM.getExecutingVM().dumpManagedNatives();
        }

        protected function onReload():void
        {
            Application.reloadMainAssembly();
        }

        /**
         * Called every tick (ie, 60Hz) by the TimeManager.
         */
        public function onTick()
        {
            // override this in the subclass
        }

        /**
         * Called every frame by the TimeManager.
         */
        public function onFrame()
        {
            // override this in the subclass
        }

        /**
         * Get the active instance of the stage.
         */
        protected function get stage():Stage
        {
            return theStage;
        }

        /**
         * Get the active instance of the application.
         */
        protected function get application():Application
        {
            return theApplication;
        }

        
        /**
         * Called when the application is initialized; override this with your own startup logic.
         */
        protected function run()
        {

        }

        /**
         * Called to install any gameframework managers (happens before run is 
         * called), override for your own managers. By default provides a TimeManager,
         * PropertyManager, and ConsoleCommandManager.
         */
        protected function installManagers()
        {
            // Time Manager
            var timeManager = new TimeManager();
            timeManager.addTickedObject(this);
            timeManager.addAnimatedObject(this);
            group.registerManager(timeManager);

            // Property Manager
            group.registerManager(new PropertyManager());
            
            // Command Manager
            var commandManager = new ConsoleCommandManager();
            commandManager.registerCommand("reload", onReload);
            commandManager.registerCommand("terminate", onTerminate);
            commandManager.registerCommand("profilerEnable", onProfilerEnable);
            commandManager.registerCommand("profilerDump", onProfilerDump);
            commandManager.registerCommand("telemetryEnable", onTelemetryEnable);
            commandManager.registerCommand("telemetryDisable", onTelemetryDisable);
            commandManager.registerCommand("dumpManagedNatives", onDumpManagedNatives);
            group.registerManager(commandManager);
        }

        /**
         * Internal function to let the Stage update whenever we render.
         */
        private function onInternalFrame():void
        {
            var time = Platform.getTime();
            var delta = (time-frameLastPlatformTime)/1000;
            //trace(delta);
            theStage.firePendingResizeEvent();
            touchProcessor.advanceTime(delta);
            Loom2D.juggler.advanceTime(delta);
            theStage.advanceTime(delta);
            theStage.render();
            frameLastPlatformTime = time;
        }

        protected function onAssetStreamCountChange(quantity:int):void
        {
            // Stick a quad with (red/yellow) color tinting.
            if(LoomAssetManager.isConnected())
            {
                redrawAssetDebug(true, quantity);
                //feedbackLayer.setColor(new ccColor3B(0, 255, 0));

                if(lastSeenQuantity == 0 && quantity > 0)
                {
                    //feedbackLayer.setColor(new ccColor3B(255, 255, 0));
                }
                else if(lastSeenQuantity > 0 && quantity == 0)
                {
                    //feedbackLayer.setColor(new ccColor3B(0, 255, 0));
                }
            }
            else
            {
                redrawAssetDebug(false, 0);
                // set it to gray if we are not connected
                //feedbackLayer.setColor(new ccColor3B(128, 128, 128));
            }

            lastSeenQuantity = quantity;
        }
        
        private function redrawAssetDebug(connected:Boolean, quantity:int) {
            if (!assetDebugEnabled) return;
            var g:Graphics = assetDebugOverlay.graphics;
            g.clear();
            g.beginFill(connected ? 0x3CBD04 : 0xFB5133);
            if (!connected) quantity = 1;
            for (var i:int = 0; i < quantity; i++) {
                g.drawRect(5+i*8, 5, 10, 10);
            }
        }

        protected function onDisplayStatsChanged(enabled:Boolean):void
        {
            //feedbackLayer.setVisible(enabled);
        }

        private function initialize()
        {
            // we're using Cocos2D for some low level platform stuff, so initialize it
            //Cocos2D.initializeFromConfig();
            
            // we would like to get ticks please
            ticks+=tick;
            onStart += _run;
        }
    
        protected static function tick() 
        {
            if (initialTick) 
            {
                onStart();
                initialTick = false;

                // the initial tick is a good spot to enable debugger VM reload
                DebuggerClient.enableReload(true);
            }
        }

        /**
         * Root LoomGroup; add all your LoomObjects here.
         */
        public var group:LoomGroup = LoomGroup.rootGroup;

        /**
         * Delegate called at start of the first rendered frame.
         */
        public static var onStart:OnStart;

        //private var layer:CCLayer = new CCLayer();

        protected var lastSeenQuantity:Number = 0;

        private var theStage:Stage;
        private static var theApplication:Application;

        private var touchProcessor:TouchProcessor;
        private static var initialTick:Boolean = true;    

        /**
         * Access to the internal layer
         * (Warning: This is an internal method and WILL BE deprecated in the future).
         */
        /*public static function get internalLayer():CCLayer
        {
            Debug.assert(theApplication, "Application must exist before getting the internalLayer");
            return theApplication.layer;
        }*/

        /*
         * Internal delegate callback for native accelerometer event, forwards to the 
         * Accelerometer class, which is the public interface.  This could be cleaner, 
         * however it requires a considerable amount of native refactoring to achieve that.
         */
        private function accelerated(x:Number, y:Number, z:Number)
        {
            Accelerometer.accelerated(x, y, z);
        }         

        /**
         * True if the LoomScript compiler is included in this build.
         */
        public static native function compilerEnabled():Boolean;
        
        /**
         * Call to trigger a restart of the VM and reload of the main assembly
         * at the next convenient point.
         */
        public static native function reloadMainAssembly();

        /**
         * Call to fire a generic system event; events may be received by script
         * or by native code. See ApplicationEventType and Application.event for
         * further information.
         */
        public static native function fireGenericEvent(type:String, payload:String = ""):void;

        /**
         * Fired when generic system events come in. First parameter is string 
         * containing type, second is string containing payload if any. Events
         * be fired from either native or script code; this is a shared event bus.
         */
        public static native var event:NativeDelegate;

        /**
         * Delegate for frames; add your callbacks to this to get called at
         * the start of every frame!
         *
         * No parameters.
         */
        public static native var ticks:NativeDelegate;

        /**
         * Fired by the asset protocol when debug console commands come in.
         *
         * One parameter, the entire command passed in as a String.
         */
        public static native var assetCommandDelegate:NativeDelegate;

        /**
         * Called when the application comes into the foreground.
         *
         * No parameters.
         */
        public static native var applicationActivated:NativeDelegate;

        /**
         * Called when the application goes into the background.
         *
         * No parameters.
         */
        public static native var applicationDeactivated:NativeDelegate;

        /**
         * The path to the assembly we'll load; by default "Main.loom".
         */
        public static native function getBootAssembly():String;
        
        /**
         * Access to the copy of loom.config embedded in the application.
         */
        public static native var loomConfigJSON:String;
        
        /**
         * The version of Loom we're running against.
         */
        public static native var version:String;
    }
}