package
{
    import system.platform.Gamepad;
    
    import loom2d.ui.TextureAtlasManager;
    
    import loom2d.events.KeyboardEvent;

    import loom.Application;
    import loom.platform.LoomKey;
    import loom2d.display.StageScaleMode;
    
    import loom2d.math.Point;
    
    import loom2d.events.*;

    // Wiimote Buttons (held sideways, dpad on left)
    // UP: 1
    // DOWN: 0
    // RIGHT: 3
    // LEFT: 2
    // BTN_1: 9
    // BTN_2: 10
    // TRIGGER: 5
    // PLUS: 6
    // MINUS: 7
    // HOME: 8
    enum WiiMote {
        BTN_DOWN = 0,
        BTN_UP,
        BTN_LEFT,
        BTN_RIGHT,
        BTN_A,
        BTN_B,
        BTN_PLUS,
        BTN_MINUS,
        BTN_HOME,
        BTN_1,
        BTN_2
    }

    /**
     * Platformer demo game.
     */
    public class Platformer extends Application
    {
        public static var trackVertically = true;

        private var useWiimote = false;
        private var gamepadConnected = false;
        public var level:PlatformerLevel = null;
 
        public static var jumpFlag = false;
        public static var moveDirX = 0.0;
        public static var moveDirY = 0.0;
        
        private var jumpTouchId:int = -1;
        private var rightTouchId:int = -1;
        private var leftTouchId:int = -1;

        override public function run():void
        {
            GC.setBackOffTime( 30000 );
            
            stage.scaleMode = StageScaleMode.FILL;
            stage.stageWidth = 720;
            stage.stageHeight = 480;
        
            TextureAtlasManager.register("PlatformerSprites", "assets/sprites/PlatformerSprites.xml");

            // Create our game scene (TODO: Add a menu here, to choose which scene we're going to load)
            var startingLevel = "assets/tilemaps/action_map_1.tmx";
            //var startingLevel = "assets/tilemaps/test_angles.tmx"
            level = new PlatformerLevel(this, startingLevel);

            //CCDirector.sharedDirector().replaceScene(level.getScene());
            stage.addChild(level.getScene());

            // Set up gamepad support.
            Gamepad.initialize();

            var pads:Vector.<Gamepad> = Gamepad.gamepads;

            for(var i=0; i<pads.length; i++)
            {
                var pad = pads[i];
                pad.buttonEvent += handleButton;
                //pad.axisEvent += handleMove;
                pad.hatEvent += handleHat;

                trace("Game pad name is '" + Gamepad.getGamePadName(i) + "'");
                if (Gamepad.getGamePadName(i).substr(0, 7) == "Wiimote")
                {
                    useWiimote = true;
                }
            }

            trace("Registered " + pads.length + " gamepads");

            if(pads.length > 0) gamepadConnected = true;

            // Also listen to the keyboard.
            //level.setKeypadEnabled(true);
            //level.onKeyDown += handleKeyDown;
            //level.onKeyUp += handleKeyUp;
            
            stage.addEventListener( KeyboardEvent.KEY_DOWN, handleKeyDown );
            stage.addEventListener( KeyboardEvent.KEY_UP, handleKeyUp );
            stage.addEventListener( TouchEvent.TOUCH, onTouch );
            

        }
        
        private function onTouch( e:TouchEvent ):void
        {
            var touch = e.getTouch(stage, TouchPhase.BEGAN);
            if (touch) onTouchBegan(touch.id, touch.getLocation(stage));
            touch = e.getTouch(stage, TouchPhase.ENDED);
            if (touch) onTouchEnded(touch.id, touch.getLocation(stage));
        }
        
        private function onTouchBegan( id:int, position:Point ):void
        {
            if ( position.y > stage.stageHeight * 0.8 && jumpTouchId == -1 )
            {
                jumpTouchId = id;
                jumpFlag = true;
            }
            else if ( position.x > stage.stageWidth * 0.5 && rightTouchId == -1 )
            {
                rightTouchId = id;
                rightKeyFlag = true;
            }
            else if ( position.x < stage.stageWidth * 0.5 && leftTouchId == -1 )
            {
                leftTouchId = id;
                leftKeyFlag = true;
            }
            
            recalculateKeyInput();
        }
        
        private function onTouchEnded( id:int, position:Point ):void
        {
            if ( jumpTouchId == id )
            {
                jumpTouchId = -1;
                jumpFlag = false;
            }
            else if ( rightTouchId == id )
            {
                rightTouchId = -1;
                rightKeyFlag = false;
            }
            else if ( leftTouchId == id )
            {
                leftTouchId = -1;
                leftKeyFlag = false;
            }

            recalculateKeyInput();
        }
        

        public var leftKeyFlag:Boolean = false;
        public var rightKeyFlag:Boolean = false;

        protected function handleKeyDown(e:KeyboardEvent):void
        {
            if(e.keyCode == LoomKey.A)
                leftKeyFlag = true;
            if(e.keyCode == LoomKey.D)
                rightKeyFlag = true;
            if(e.keyCode == LoomKey.W)
                jumpFlag = true;

            recalculateKeyInput();
        }

        protected function handleKeyUp(e:KeyboardEvent):void
        {
            if(e.keyCode == LoomKey.A)
                leftKeyFlag = false;
            if(e.keyCode == LoomKey.D)
                rightKeyFlag = false;
            if(e.keyCode == LoomKey.W)
                jumpFlag = false;

            recalculateKeyInput();
        }

        protected function recalculateKeyInput():void
        {
            if((leftKeyFlag && rightKeyFlag)
               || (!leftKeyFlag && !rightKeyFlag))
                moveDirX = 0;
            else if(leftKeyFlag)
                moveDirX = -1;
            else if(rightKeyFlag)
                moveDirX = 1;
            else
                moveDirX = 0;
        }

        function handleHat(hat:int, state:int):void
        {
            //trace("Hat " + hat + ": " + state);
            //trace("OuyaHat.BTN_LEFT: ",OuyaHat.BTN_LEFT);
            switch (state)
            {
                case Gamepad.HAT_LEFTUP:
                case Gamepad.HAT_LEFTDOWN:
                case Gamepad.HAT_LEFT:
                    //trace("left on");
                    moveDirX = -1;
                    break;
                case Gamepad.HAT_RIGHTUP:
                case Gamepad.HAT_RIGHTDOWN:
                case Gamepad.HAT_RIGHT:
                    //trace("right on");
                    moveDirX = 1;
                    break;
                case Gamepad.HAT_CENTERED:
                    moveDirX = 0;
                    //trace("hat off");
                    break;
            }
        }
        
        public function handleButton(button:int, state:Boolean):void
        {
            //trace("Button " + button + ": " + state);

            if (useWiimote) // If we're on Wiimote
            {
                switch (button)
                {
                    case WiiMote.BTN_DOWN:
                        moveDirY = state ? -1 : 0;
                        break;
                    case WiiMote.BTN_UP:
                        moveDirY = state ?  1 : 0;
                        break;
                    case WiiMote.BTN_LEFT:
                        moveDirX = state ? -1 : 0;
                        break;
                    case WiiMote.BTN_RIGHT:
                        moveDirX = state ?  1 : 0;
                        break;
                    case WiiMote.BTN_1:
                    case WiiMote.BTN_2:
                        jumpFlag = state;
                        break;
                    case WiiMote.BTN_B:
                        Application.reloadMainAssembly();
                        break;
                }
            }
            else // Android / Ouya
            {
                if (button == 0 || button == 1)
                {
                    jumpFlag = state;
                }

                if(button == 5) Application.reloadMainAssembly();

            }
        }

        public function handleMove(axis:int, state:float):void
        {
            //trace("Axis " + axis + ": " + state);

            if(axis != 0) // Only register for the X axis
                return;

            moveDirX = state;
        }

        override public function onTick():void
        {
            super.onTick();
            
            if(gamepadConnected)
            {
                Gamepad.update();
            }
        }

        public static var verticalTracking = true;

        override public function onFrame():void
        {
            super.onFrame();
            
            if (level != null)
            {
                if (level.trackObject != null)
                {
                    level.fgLayer.x = -(level.trackObject.x - 8 * 32); //  * level.getScaleX());
                    if (level.fgLayer.x > 0)
                        level.fgLayer.x = 0;

                    if (verticalTracking)
                    {
                        level.fgLayer.y = -(level.trackObject.y - 5 * 32); //  * level.getScaleX());

                        var minLevelY = -level.tmxDocument.height * level.tmxDocument.tileHeight + stage.stageHeight;
                        if (level.fgLayer.y < minLevelY )
                            level.fgLayer.y = minLevelY;
                    }
                    else
                    {
                        level.fgLayer.y = -25; // Total hack so that the camera doesn't snap after the hero lands on the ground after respawning.
                    }

                    // Do parallax
                    level.bgLayer.x = level.fgLayer.x * 0.25;
                }

            }
        }

        public static function onFellOffMap(obj:PlatformerMover):void
        {
            obj.dest.x = 32;
            obj.dest.y = 500;
            obj.velocityX = 0;
            obj.velocityY = 0;

            //verticalTracking = false;
        }
    }
}