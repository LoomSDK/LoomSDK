package ui.views.game
{
    import extensions.PDParticleSystem;
    import feathers.controls.Button;
    import feathers.controls.Label;
    import feathers.display.OffsetTiledImage;
    import game.Board;
    import game.GameConfig;
    import game.Match;
    import game.Shaker;
    import game.Swap;
    import game.Tile;
    import loom.platform.Mobile;
    import loom.platform.UserDefault;
    import loom.sound.Listener;
    import loom.sound.Sound;
    import loom2d.animation.Juggler;
    import loom2d.animation.Transitions;
    import loom2d.display.DisplayObject;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.events.Event;
    import loom2d.math.Color;
    import loom2d.textures.Texture;
    import ui.views.ConfigView;
    import ui.views.ViewCallback;
    
    /**
     * View responsible for general game logic shown while the timer is running.
     * Handles everything except the actual match-3 board logic.
     */
    class GameView extends ConfigView
    {
        public var onQuit:ViewCallback;
        public var onTimeout:ViewCallback;
        
        // Quick and simple state machine for easier overal game state control
        private static const STATE_GAME   = 0;
        private static const STATE_QUIT   = 1;
        private static const STATE_ENDING = 2;
        private static const STATE_DEMO   = 3;
        private var state = STATE_GAME;
        
        private var origConfig:GameConfig;
        private var demoConfig:GameConfig = new GameConfig();
        private var minDemoDelay = 0.220;
        private var maxDemoDelay = 4.000;
        private var demoPeriod = 30;
        private var demoHand:Image;
        private var demoStartTime:Number;
        private var demoInstructions:Label;
        
        /** Delta time, how long each game tick lasts */
        private var dt:Number = 1/60;
        private var t:Number;
        
        /** Custom juggler used for most animations, enables easy pausing */
        private var juggler:Juggler = new Juggler();
        
        private var screenshaker:Shaker;
        private var screenshake:Number;
        
        /** Contained view, so it can be displayed on top of game */
        private var confirmView:ConfirmView;
        
        public var score:int;
        
        // User interface from LML
        [Bind] public var esc:Button;
        [Bind] public var mute:Button;
        [Bind] public var timeDisplay:Label;
        [Bind] public var lastDisplay:Label;
        [Bind] public var multiDisplay:Label;
        [Bind] public var scoreDisplay:Label;
        
        private static const MUTE_NONE  = 0;
        private static const MUTE_MUSIC = 1;
        private static const MUTE_ALL   = 2;
        private var muteMode = MUTE_NONE;
        
        private var textScale:Number = 1;
        
        /** Last added score */
        private var last:Number;
        /** Score multiplier */
        private var multiplier:Number;
        /** Represents the apparent momentum of the game as swapping speed increases */
        private var momentum:Number;
        
        /** Contains relatively positioned game stuff */
        private var field:Sprite = new Sprite();
        
        /** Contains all actual board logic and interaction */
        private var board:Board;
        
        /** Tiled scrolling background */
        private var background:OffsetTiledImage;
        private var bgColor = new Color(0, 0.3*0xFF, 0.3*0xFF);
        private var bgScroll:Number;
        
        /** Particle system for explosions */
        private var particles:PDParticleSystem;
        
        // Sounds
        private var explosion:Sound;
        private var soundtrack:Sound;
        
        protected function get layoutFile():String { return "game.lml"; }
        
        public function init()
        {
            background = new OffsetTiledImage(Texture.fromAsset("assets/background.png"), 2);
            addChild(background);
            
            super.init();
            
            origConfig = config;
            demoConfig.duration = -1;
            demoConfig.freeform = false;
            demoHand = new Image(Texture.fromAsset("assets/hand.png"));
            demoHand.scale = 0.2;
            demoHand.pivotX = 105;
            demoHand.pivotY = 33;
            demoHand.rotation = -Math.PI*0.3;
            demoHand.alpha = 0.5;
            demoHand.touchable = false;
            demoHand.visible = false;
            demoInstructions = new Label();
            demoInstructions.text = "";
            demoInstructions.nameList.add("header");
            demoInstructions.visible = false;
            
            esc.addEventListener(Event.TRIGGERED, confirmQuit);
            onBack += function() { 
                switch (state) {
                    case STATE_QUIT: confirmNo(); break;
                    default: confirmQuit();
                }
            };
            
            mute.addEventListener(Event.TRIGGERED, switchMuteMode);
            
            // Get saved mute mode (or default if none exists)
            muteMode = UserDefault.sharedUserDefault().getIntegerForKey("muteMode", muteMode);
            
            confirmView = new ConfirmView();
            confirmView.onYes += confirmYes;
            confirmView.onNo += confirmNo;
            confirmView.init();
            
            board = new Board(juggler);
            board.onTileCleared += tileCleared;
            board.onTilesMatched += tilesMatched;
            board.onEnded += boardEnded;
            board.init();
            field.addChild(board);
            
            initDisplay(timeDisplay);
            initDisplay(lastDisplay);
            initDisplay(multiDisplay);
            initDisplay(scoreDisplay);
            
            field.addChild(demoHand);
            field.addChild(demoInstructions);
            
            screenshaker = new Shaker(board);
            screenshaker.start(juggler);
            
            particles = PDParticleSystem.loadLiveSystem("assets/particles/explosion.pex");
            particles.emitterX = 60;
            particles.emitterY = 60;
            field.addChild(particles);
            
            resetJuggler();
            
            addChild(field);
            
            soundtrack = Sound.load("assets/sounds/contemplation 2.ogg");
            soundtrack.setLooping(true);
            
            explosion = Sound.load("assets/sounds/tileExplosion.ogg");
        }
        
        /**
         * Exists for symmetry against activate()
         */
        public function deactivate() {}
        
        /**
         * Update mute mode on activation,
         * keeps sound from getting unmuted unintentionally
         */
        public function activate() {
            updateMuteMode();
        }
        
        /**
         * Switch over to the next mute mode
         */
        private function switchMuteMode(e:Event) 
        {
            switch (muteMode) {
                case MUTE_NONE:  muteMode = MUTE_MUSIC; break;
                case MUTE_MUSIC: muteMode = MUTE_ALL; break;
                case MUTE_ALL:   muteMode = MUTE_NONE; break;
            }
            // Save mute mode to persistent storage
            UserDefault.sharedUserDefault().setIntegerForKey("muteMode", muteMode);
            updateMuteMode();
        }
        
        /**
         * Update the sounds and state based on the current mute mode
         */
        private function updateMuteMode() 
        {
            if (muteMode == MUTE_MUSIC || muteMode == MUTE_ALL) {
                soundtrack.pause();
            } else {
                soundtrack.play();
            }
            if (muteMode == MUTE_ALL) {
                Listener.setGain(0);
            } else {
                Listener.setGain(1);
            }
            switch (muteMode) {
                case MUTE_NONE: mute.label = "MUTE"; break;
                case MUTE_MUSIC: mute.label = "SFX"; break;
                case MUTE_ALL: mute.label = "MUTED"; break;
            }
        }
        
        
        /** Some additional label setup */
        private function initDisplay(display:Label)
        {
            display.nameList.add("light");
            field.addChild(display);
        }
        
        
        // Quit confirmation screen
        private function confirmQuit(e:Event = null)
        {
            showConfirm();
            if (state != STATE_DEMO) state = STATE_QUIT;
        }
        private function showConfirm()
        {
            confirmView.enter(this);
        }
        private function hideConfirm()
        {
            confirmView.exit();
        }
        private function confirmYes()
        {
            onQuit();
        }
        private function confirmNo()
        {
            hideConfirm();
            state = STATE_GAME;
        }
        
        
        public function resize(w:Number, h:Number)
        {
            confirmView.resize(w, h);
            esc.width = 30;
            mute.width = 30;
            esc.x = w-esc.width;
            background.setSize(w, h);
            field.x = (w-board.contentWidth)/2;
            field.y = h-board.contentHeight-10;
            demoInstructions.setSize(board.contentWidth, 20);
            updateDisplay();
        }
        
        private function tileCleared(x:Number, y:Number, color:Color)
        {
            explode(x, y, color);
            momentum++;
        }
        
        private function tilesMatched(m:Match)
        {
            if (state == STATE_ENDING) return;
            
            // Score based on the length of the match sequence squared
            var matchLength = m.end-m.begin+1;
            addScore(matchLength*matchLength);
            
            // For a special match, add a big score and large shake
            if (m.type == null) {
                addScore(100);
                momentum += 30;
                screenshake += 20;
                explosion.setPitch(0.5);
                explosion.play();
            }
            
            updateScore();
        }
        
        private function addScore(delta:int)
        {
            var d = Math.ceil(multiplier*delta);
            score += d;
            last = d;
            updateLast();
        }
        
        
        
        // Label text update and positioning
        
        /** Helper function for label positioning */
        private function positionRight(d:DisplayObject, offset:Number)
        {
            d.x = 5+board.contentWidth-d.width-offset;
            d.y = -10;
        }
        
        private function updateDisplay()
        {
            updateScore();
            updateMulti();
            updateLast();
            updateTime();
        }
        
        private function updateScore()
        {
            var newText = ""+score;
            if (newText != scoreDisplay.text) {
                scoreDisplay.text = ""+score;
                // Explicit call to validate, so the text size is correct before positioning
                scoreDisplay.validate();
            }
            positionRight(scoreDisplay, 5);
            scoreDisplay.scale = textScale*2;
            juggler.tween(scoreDisplay, 0.5, {
                scale: textScale,
                transition: Transitions.EASE_OUT_ELASTIC
            });
        }
        
        private function updateMulti()
        {
            var newText = "x "+multiplier.toFixed(2);
            if (newText != multiDisplay.text) {
                multiDisplay.text = newText;
                multiDisplay.validate();
            }
            positionRight(multiDisplay, 35);
        }
        
        private function updateLast()
        {
            var newText = "+"+last;
            if (newText != lastDisplay.text) {
                lastDisplay.text = newText;
                lastDisplay.validate();
            }
            juggler.removeTweens(lastDisplay);
            lastDisplay.alpha = 1;
            juggler.tween(lastDisplay, 3, {
                alpha: 0,
                transition: Transitions.EASE_IN
            });
            lastDisplay.x = multiDisplay.x-lastDisplay.width-2;
            lastDisplay.y = multiDisplay.y;
        }
        
        private function updateTime()
        {
            var newText = Math.abs(Math.ceil(config.duration - t)).toFixed(0);
            if (newText != timeDisplay.text) {
                timeDisplay.text = newText;
                timeDisplay.validate();
            }
            positionRight(timeDisplay, 85);
        }
        
        
        
        /**
         * Curve for translating an unbounded value to a pitch
         */
        private function getPitch(x:Number):Number
        {
            return 0.8+0.2*(Math.exp(x*0.08)-1);
        }
        
        /**
         * Run explosion effect at the given position with the given color
         */
        private function explode(x:Number, y:Number, color:Color)
        {
            particles.emitterX = x;
            particles.emitterY = y;
            particles.startColor = color;
            particles.populate(6, 0);
            if (state == STATE_ENDING) {
                explosion.setPitch(1+Math.randomRange(-0.1, 0.1));
            } else {
                explosion.setPitch(getPitch(momentum)+Math.randomRange(-0.1, 0.1));
            }
            explosion.play();
            screenshake += 0.25;
        }
        
        /**
         * Begin game
         */
        public function enter(owner:DisplayObjectContainer)
        {
            super.enter(owner);
            state = STATE_GAME;
            hideConfirm();
            
            Mobile.allowScreenSleep(false);
            
            // Set config options
            board.freeformMode = config.freeform;
            board.reset();
            
            // Reset state
            t = 0;
            score = 0;
            momentum = 0;
            screenshake = 0;
            bgScroll = 0;
            multiplier = 1;
            updateDisplay();
            
            soundtrack.play();
            
            updateMuteMode();
        }
        
        /**
         * Enable demo mode with automated swapping and instructional messages
         */
        public function demo()
        {
            config = demoConfig;
            state = STATE_DEMO;
            board.touchable = false;
            Tile.swapTime = Tile.SWAP_TIME_DEMO;
            demoStartTime = juggler.elapsedTime;
            juggler.delayCall(nextRandomSwap, maxDemoDelay);
            demoHand.visible = true;
            demoHand.alpha = 0;
            demoInstructions.visible = true;
            demoInstructions.alpha = 0;
            
            showInstruction("DRAG TILES TO SWAP THEM", 0, 3.8);
            showInstruction("MATCH 3 OR MORE", 6, 2.5);
            showInstruction("OF THE SAME TYPE", 8.5, 2.5);
            
            showInstruction("QUICKER SWAPPING", 14, 3);
            showInstruction("MEANS A HIGHER MULTIPLIER", 17, 3);
            showInstruction("FOR MORE POINTS", 20, 3);
            
            showInstruction("TAP ESC TO EXIT DEMO", 40, 3);
            
            showInstruction("THERE ARE no", 60, 3);
            showInstruction("HIDDEN MESSAGES OR FEATURES", 63, 3);
            showInstruction("for sure", 66, 3);
            
            showInstruction("i lied\n\n\n", 120, 1.3);
            showInstruction("    i lied\n\n", 121, 0.3);
            showInstruction("i lied    \n", 121.1, 0.3);
            showInstruction("     i lied", 121.2, 0.3);
            showInstruction("\ni lied    ", 121.3, 0.3);
            showInstruction("\n\n    i lied", 121.4, 0.3);
            showInstruction("\n\n\ni lied", 121.5, 1.3);
        }   
        
        /**
         * Show instructional text with a specified delay and for a specified duration
         */
        private function showInstruction(text:String, delay:Number, duration:Number) 
        {
            juggler.delayCall(function() {
                demoInstructions.text = text;
                demoInstructions.validate();
                demoInstructions.y = 20 + demoInstructions.height/2;
            }, delay);
            juggler.tween(demoInstructions, 0.1, { delay: delay, alpha: 1 } );
            juggler.tween(demoInstructions, 0.1, { delay: delay+duration-0.2, alpha: 0 } );
        }
        
        /**
         * Display a hand performing the tile swap
         */
        private function showSwap(swap:Swap) 
        {
            demoHand.x = swap.a.getDisplayX(swap.a.transitionalTileX);
            demoHand.y = swap.a.getDisplayY(swap.a.transitionalTileY);
            juggler.removeTweens(demoHand);
            juggler.tween(demoHand, 0.2, { alpha: 0.4 } );
            juggler.tween(demoHand, Tile.swapTime, {
                x: swap.a.getDisplayX(swap.b.transitionalTileX),
                y: swap.b.getDisplayY(swap.b.transitionalTileY),
                transition: Transitions.EASE_IN_OUT
            });
            juggler.tween(demoHand, 0.2, { delay: Tile.swapTime, alpha: 0 } );
        }
        
        /**
         * Attempt a tile swap from a timer
         */
        private function nextRandomSwap() 
        {
            var demoTime = juggler.elapsedTime-demoStartTime;
            // Have the swapping speed start off slowly at minDemoDelay
            // and ramp up to maxDemoDelay over demoPeriod milliseconds
            // and then reverse and repeat
            var time = minDemoDelay+(maxDemoDelay-minDemoDelay)*(Math.cos(demoTime/demoPeriod*Math.PI)+1)/2;
            // Modify the swapping time for demo purposes
            Tile.swapTime = Math.clamp(time, Tile.SWAP_TIME_NORMAL, Tile.SWAP_TIME_DEMO);
            var swap = board.randomSwap();
            // If the tiles are null, the swap failed
            if (swap.a != null && swap.b != null) showSwap(swap);
            // Attempt the next swap with a short delay
            juggler.delayCall(nextRandomSwap, time+0.1);
        }
        
        public function demoMode():Boolean
        {
            return state == STATE_DEMO;
        }
        
        public function exit()
        {
            super.exit();
            if (state == STATE_DEMO) {
                config = origConfig;
                board.touchable = true;
                Tile.swapTime = Tile.SWAP_TIME_NORMAL;
                demoHand.visible = false;
                demoInstructions.visible = false;
            }
            resetJuggler();
            particles.clear();
            soundtrack.stop();
            Mobile.allowScreenSleep(true);
        }
        
        private function resetJuggler() 
        {
            juggler.purge();
            juggler.add(particles);
        }
        
        public function tick()
        {
            // Do not process ticks after quitting
            if (state == STATE_QUIT) return;
            
            t += dt;
            juggler.advanceTime(dt);
            
            screenshaker.strength = screenshake;
            
            // Decays
            screenshake -= screenshake*6*dt;
            if (Math.abs(screenshake) < 0.1) screenshake = 0;
            momentum -= momentum*0.2*dt;
            
            // Scroll based on momentum
            bgScroll -= momentum*1.5*dt;
            
            // Do not process multiplier or time while in end animation
            if (state == STATE_ENDING) return;
            
            multiplier = Math.round(Math.pow(1+0.1*momentum, 2)/0.5)*0.5;
            updateMulti();
            updateTime();
            if (config.duration > 0 && t >= config.duration) {
                end();
            }
        }
        
        private function end()
        {
            state = STATE_ENDING;
            // Animate board ending
            board.end();
        }
        
        private function boardEnded()
        {
            onTimeout();
        }
        
        public function render()
        {
            // Tint the background based on current momentum
            bgColor.red += ((1-Math.exp(-momentum*0.2))*0xFF-bgColor.red)*0.1;
            background.color = bgColor.toInt();
            // Render scroll
            background.scrollY = bgScroll;
        }
        
    }
}