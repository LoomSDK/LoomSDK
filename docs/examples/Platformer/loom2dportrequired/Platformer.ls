package
{
    import loom2d.display.Cocos2DGame;
    import loom2d.display.Cocos2D;
    import cocos2d.CCSprite;
    import loom2d.display.CCLayer;
    import cocos2d.ScaleMode;
    import cocos2d.CCSpriteFrameCache;
    import cocos2d.CCDirector;
    import cocos2d.CCTMXTiledMap;


    import system.platform.Gamepad;

    import loom.Application;
    import loom.platform.LoomKey;

    import UI.Label;

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
    public class Platformer extends Cocos2DGame
    {
        public static var trackVertically = true;

        private var useWiimote = false;
        private var gamepadConnected = false;
        public var level:PlatformerLevel = null;
 
        public static var jumpFlag = false;
        public static var moveDirX = 0.0;
        public static var moveDirY = 0.0;

        override public function run():void
        {
            super.run();

            // Load our sprite sheets
            CCSpriteFrameCache.sharedSpriteFrameCache().addSpriteFramesWithFile(
                "assets/sprites/PlatformerSprites.plist", 
                "assets/sprites/PlatformerSprites.png");

            // Create our game scene (TODO: Add a menu here, to choose which scene we're going to load)
            var startingLevel = "assets/tilemaps/action_map_1.tmx"
            //var startingLevel = "assets/tilemaps/test_angles.tmx"
            level = new PlatformerLevel(this, startingLevel);

            CCDirector.sharedDirector().replaceScene(level.getScene());

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
            level.setKeypadEnabled(true);
            level.onKeyDown += handleKeyDown;
            level.onKeyUp += handleKeyUp;

        }

        public var leftKeyFlag:Boolean = false;
        public var rightKeyFlag:Boolean = false;

        protected function handleKeyDown(keycode:int):void
        {
            if(keycode == LoomKey.A)
                leftKeyFlag = true;
            if(keycode == LoomKey.D)
                rightKeyFlag = true;
            if(keycode == LoomKey.W)
                jumpFlag = true;

            recalculateKeyInput();
        }

        protected function handleKeyUp(keycode:int):void
        {
            if(keycode == LoomKey.A)
                leftKeyFlag = false;
            if(keycode == LoomKey.D)
                rightKeyFlag = false;
            if(keycode == LoomKey.W)
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
            if(gamepadConnected)
            {
                Gamepad.update();
            }
        }

        public static var verticalTracking = true;

        override public function onFrame():void
        {
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

                        if (level.fgLayer.y > 0)
                            level.fgLayer.y = 0;
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
            obj.dest.originX = 32;
            obj.dest.originY = 500;
            obj.velocityX = 0;
            obj.velocityY = 0;

            verticalTracking = false;
        }
    }
}