package
{
    import feathers.display.OffsetTiledImage;
    import game.ColorTile;
    import game.TileType;
    import loom.Application;
    import loom.gameframework.TimeManager;
    import loom2d.animation.Transitions;
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.display.StageScaleMode;
    import loom2d.events.Event;
    import loom2d.events.KeyboardEvent;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.Loom2D;
    import loom2d.math.Point;
    import loom2d.textures.Texture;
    import loom2d.textures.TextureSmoothing;
    import loom2d.ui.SimpleLabel;

    /**
     * Fun color matching game! Use the buttons in the bottom of the screen to
     * change the colors of the region in the bottom left to make the whole 
     * board one color.
     */
    public class FloodIt extends Application
    {
        /**
         * The RGB values for the six tile colors.
         */
        public var types:Vector.<TileType> = [];
        
        public var content:Sprite = new Sprite();
        
        /**
         * Instruction text image.
         */
        public var instructions:Image;
        
        /**
         * The score label.
         */
        public var scoreLabel:SimpleLabel;
        
        /**
         * The result label.
         */
        public var resultLabel:SimpleLabel;
        
        /**
         * The width of the content.
         */
        public var contentWidth = 320;
        
        /**
         * The height of the content.
         */
        public var contentHeight = 480;
        
        /**
         * Spacing around the edges next to tiles.
         */
        private var tilePadding = 10;
        
        /**
         * The width of a button on the bottom strip of buttons.
         */
        private var buttonWidth = 50;
        
        /**
         * Size of the game grid. Try changing this via live reload!
         */
        public var gridSize:int = 14;

        /**
         * How many moves do we allow the player before they lose?
         */
        public var maxMoves:int = 25;

        /**
         * Identifier used to tell if we have visited a tile before during the 
         * current flood fill.
         */
        public var floodToken:int = 0;
        
        /**
         * Controls the speed of the flooding.
         */
        //public var floodDelay = 0.01;
        public var floodDelay = 0.03;
        
        /**
         * Block interaction until this time (same timebase as Loom2D.juggler.elapsedTime).
         */
        public var waitUntil = -1;
        
        /**
         * Set when the game has ended.
         */
        public var gameOver:Boolean = false;
        
        
        /**
         * References to every tile on the board.
         */
        public var tiles = new Vector.<ColorTile>(gridSize * gridSize);
        
        
        /**
         * Container for the buttons.
         */
        public var buttonStrip = new Sprite();
        
        /**
         * References to the six buttons, indexed by their color ID.
         */
        public var buttons = new Vector.<ColorTile>(6);
        
        /**
         * The currently active ("down state") button.
         */
        public var activeButton:ColorTile = null;
        
        
        /**
         * Scrolling tiled background.
         */
        public var background:OffsetTiledImage;
        
        /**
         * Background scrolling toggle.
         */
        public var backgroundScroll = false;
        
        /**
         * Background scrolling position.
         */
        public var scroll:Number = 0;
        
        /**
         * Background scrolling speed.
         */
        public var scrollSpeed:Number = 0;
        
        public var scorePos = 334+40/2;
        public var scorePosOffset = 40;
        
        /**
         * Temporary helper for passing Point to functions.
         */
        private var tempPoint:Point;
        
        /**
         * Temporary helper to avoid allocation of new Vectors.
         */
        private var tempTileVector = new Vector.<ColorTile>();
        
        // Gets injected automatically before run() is called, used in the splash loader.
        [Inject] private var timeManager:TimeManager;
        
        /**
         * Entry point for the game (see main.ls)
         */
        override public function run():void
        {
            // Set up automatic scaling.
            stage.scaleMode = StageScaleMode.NONE;
            SplashLoader.init(stage, timeManager, load);
        }
        
        /**
         * Called with a delay to allow the splash display to show.
         */
        protected function load():void {
            // Listen to system events
            stage.addEventListener(KeyboardEvent.BACK_PRESSED, back);
            stage.addEventListener(Event.RESIZE, resize);
            
            // Initialize the labels, grid, and buttons.
            layout();
            
            // And start play.
            startGame();
            
            resize();
        }
        
        /**
         * Scale the content to fit width.
         */
        private function resize(e:Event = null):void 
        {
            if (stage.stageWidth/stage.stageHeight < contentWidth/contentHeight) {
                content.scale = stage.stageWidth/contentWidth;
            } else {
                content.scale = stage.stageHeight/contentHeight;
            }
            content.x = (stage.stageWidth-contentWidth*content.scale)/2;
            content.y = (stage.stageHeight - contentHeight * content.scale) / 2;
            background.setSize(stage.stageWidth, stage.stageHeight);
        }
        
        /**
         * Exit app on back button press.
         */
        private function back(e:KeyboardEvent):void 
        {
            Process.exit(0);
        }
        
        /**
         * Scroll the background on every tick.
         */
        override public function onTick()
        {
            scrollSpeed *= 0.99;
            scroll += scrollSpeed;
        }
        
        /**
         * Update the background scroll every frame.
         */
        override public function onFrame()
        {
            if (backgroundScroll) background.setScroll(-scroll, -scroll);
        }
        
        /**
         * Initialize the score label, game grid, and the buttons.
         */
        protected function layout():void
        {   
            // Scrolling tiled background, scaled with no smoothing to preserve hard edges.
            var tex = Texture.fromAsset("assets/background.png");
            tex.smoothing = TextureSmoothing.NONE;
            background = new OffsetTiledImage(tex, 4);
            stage.addChild(background);
            
            stage.addChild(content);
            
            // Instructions that are hidden after a short delay
            instructions = new Image(Texture.fromAsset("assets/instructions.png"));
            instructions.scale = contentWidth / instructions.width;
            instructions.y = 70-40;
            instructions.touchable = false;
            instructions.alpha = 0;
            Loom2D.juggler.tween(instructions, 0.3, { delay: 0.8, alpha: 1, y: 70, transition: Transitions.EASE_OUT } );
            Loom2D.juggler.tween(instructions, 2, { delay: 2+3, alpha: 0 } );
            
            var fontFile = "assets/Curse-hd.fnt";
            
            // Score Label
            scoreLabel = new SimpleLabel(fontFile, contentWidth-40, 40);
            scoreLabel.x = 20;
            scoreLabel.y = scorePos+scorePosOffset;
            scoreLabel.alpha = 0;
            Loom2D.juggler.tween(scoreLabel, 0.3, { delay: 2.2, alpha: 1, y: scorePos, transition: Transitions.EASE_OUT } );
            content.addChild(scoreLabel);
            
            // Result (win/loss) text
            resultLabel = new SimpleLabel(fontFile, contentWidth-40, 26);
            resultLabel.x = 20;
            resultLabel.y = 334+40/2+60;
            resultLabel.text = "";
            resultLabel.visible = false;
            content.addChild(resultLabel);
            
            // Define all the different tile types
            var tileDir = "assets/tiles/";
            types = [
                new TileType(0, 0x602462, Texture.fromAsset(tileDir+"tile0.png")),
                new TileType(1, 0x396EAA, Texture.fromAsset(tileDir+"tile1.png")),
                new TileType(2, 0xDDC222, Texture.fromAsset(tileDir+"tile2.png")),
                new TileType(3, 0xFDF5E6, Texture.fromAsset(tileDir+"tile3.png")),
                new TileType(4, 0xFB2447, Texture.fromAsset(tileDir+"tile4.png")),
                new TileType(5, 0x6C8C16, Texture.fromAsset(tileDir+"tile5.png"))
            ];
            
            // Create and place tiles
            var tileSize:Number = (contentWidth-tilePadding*2)/gridSize;        
            for(var h:int = 0; h < gridSize; h++)
            {
                for(var w:int = 0; w < gridSize; w++)
                {
                    var tile = new ColorTile(w, h);
                    tile.x = tilePadding + w*tileSize;
                    tile.y = tilePadding + h*tileSize;
                    tile.width = tileSize;
                    tile.height = tileSize;
                    
                    setTile(w, h, tile);
                    
                    content.addChild(tile);
                }
            }
            
            // Place the button container
            buttonStrip.x = 35;
            buttonStrip.y = 445;
            content.addChild(buttonStrip);
            
            // Create and place the buttons
            for(var i:int=0; i < types.length; i++)
            {
                var button = new ColorTile(i, 0);
                
                // Position the button
                button.x = i * buttonWidth;
                
                // Hide it at first
                button.alpha = 0;
                
                // Set the button type (with additional delayed animation)
                button.paint(types[i]);
                button.paint(types[i], 1.65+i*0.05);
                
                // Center and scale to fit predefined width
                button.center();
                button.scale = buttonWidth/button.image.width;
                
                // Add to Vector and container
                buttons[i] = button;
                buttonStrip.addChild(button);
            }
            
            // Listen to the stage for custom touch logic
            stage.addEventListener(TouchEvent.TOUCH, onTouch);
            
            // Add the instructions on top of everything else
            content.addChild(instructions);
        }
        
        /**
         * Activate a button, making it the currently active button in the "down" state.
         * @param button The button to activate.
         * @return `false` if the button was already active, `true` otherwise.
         */
        protected function buttonActivate(button:ColorTile):Boolean
        {
            if (activeButton) {
                if (activeButton == button) return false;
                buttonDeactivate();
            }
            activeButton = button;
            var buttonScale = buttonWidth/activeButton.image.width;
            Loom2D.juggler.tween(activeButton, 0.1, { scale: 0.6*buttonScale, transition: Transitions.EASE_OUT } );
            return true;
        }
        
        /**
         * Deactivate the currently active button (if any).
         * @return `false` if there was no currently active button, `true` otherwise.
         */
        private function buttonDeactivate():Boolean
        {
            if (!activeButton) {
                return false;
            }
            var buttonScale = buttonWidth/activeButton.image.width;
            Loom2D.juggler.tween(activeButton, 0.3, { scale: 1*buttonScale, transition: Transitions.EASE_OUT_BACK } );
            activeButton = null;
            return true;
        }
        
        /**
         * Custom button handling logic for better usability.
         * @param e TouchEvent describing the touch.
         */
        protected function onTouch(e:TouchEvent)
        {
            // Don't respond if waiting is to be had!
            if (Loom2D.juggler.elapsedTime < waitUntil) return;
            
            // If game is over, restart.
            if (gameOver)
            {
                startGame();
                return;
            }
            
            var touch:Touch = e.getTouch(stage);
            
            // Find the closest button to the touch
            var button:ColorTile = null;
            var minDist:Number = Number.POSITIVE_INFINITY;
            for each (var b:ColorTile in buttons) {
                tempPoint.x = b.x;
                tempPoint.y = b.y;
                var dist = Point.distance(touch.getLocation(buttonStrip), tempPoint);
                if (dist < minDist) {
                    minDist = dist;
                    button = b;
                }
            }
            
            // Handle touches too far away from the nearest button
            if (minDist > 100) {
                buttonDeactivate();
                return;
            }
            
            // Retrieve the index of the button.
            var i = buttons.indexOf(button);
            
            // Handle begin/move separately from ending.
            switch (touch.phase) {
                case TouchPhase.BEGAN:
                case TouchPhase.MOVED:
                    buttonActivate(button);
                    return;
                case TouchPhase.ENDED:
                    buttonDeactivate();
                    break;
            }
            // Otherwise, flood fill the new color.
            flood(i);
        }
        
        /**
         * Begin gameplay.
         */
        protected function startGame():void
        {
            trace("Starting game");
            floodToken = 0;
            gameOver = false;
            
            Loom2D.juggler.delayCall(setScore, 1.5, 0);
            Loom2D.juggler.delayCall(showButtons, 1);
            Loom2D.juggler.tween(resultLabel, 0.3, { delay: 2, alpha: 0, onComplete: function() {
                resultLabel.visible = false;
            }});
            
            var maxDelay = 0;
            
            // Set the grid to random colors.
            for(var i=0; i<gridSize*gridSize; i++) {
                var tile = tiles[i];
                tile.reset();
                // Paint the tiles with a delayed animation
                var delay = getTileDelay(tile);
                if (delay > maxDelay) maxDelay = delay;
                tile.paint(types[int(Math.random() * 6)], delay);
            }
            
            // Block interaction until all the tiles are finished transitioning
            waitUntil = Loom2D.juggler.elapsedTime+maxDelay+0.7;
        }
        
        /**
         * Stop the game resulting in either a win or a loss.
         */
        private function stopGame(winner:Boolean) 
        {
            gameOver = true;
            hideButtons();
            if (winner) {
                resultLabel.text = "You won!";
            } else {
                resultLabel.text = "You lost!";
            }
            resultLabel.alpha = 0;
            resultLabel.visible = true;
            Loom2D.juggler.tween(resultLabel, 0.3, { alpha: 1 } );
        }
        
        
        /**
         * Return the animation delay for the specified tile.
         * Based on the distance from the top left corner.
         * @param tile The tile to return the delay for.
         * @return The animation delay in seconds.
         */
        protected function getTileDelay(tile:ColorTile):Number
        {
            var dx = tile.tileX;
            var dy = tile.tileY;
            var distance = Math.sqrt(dx*dx+dy*dy);
            return floodDelay * distance;
        }
        
        /**
         * Do a flood fill from (0,0) on the grid - the bottom left.
         *
         * Change the first tile to the passed color, and then walk all
         * adjacent tiles in order to change their color, too, if they
         * matched the original tile color.
         *
         * Play the game, you'll see what it does! :)
         */
        protected function flood(color:int):void
        {
            // We'll use this to store a stack of tiles we need to process.
            //
            // We could implement this behavior recursively, but it's a lot
            // simpler and more reliable to do it with an explicit stack and
            // loop.
            tempTileVector.clear();
            var toProcess = tempTileVector;
            
            // The seed tile at origin
            var origin = getTile(0, 0);
            
            // Seed the stack with the tile at 0,0
            toProcess.push(origin);
            
            // Note the original color.
            var originalColor:int = origin.colorIndex;
            
            if (color == originalColor) return;
            
            scrollSpeed += 1;
            
            // Change the token. We could use a flag, but then we'd have to
            // reset the flag after every fill, which I hate. So instead we
            // have this counter and check for equality.
            floodToken++;
            
            setScore(floodToken);
            
            // The maximum animation delay of all the processed tiles,
            // used to block interactivity for that period of time.
            var maxDelay = 0;
            
            // Now walk everything that is a match to the current color,
            // always adding bottom or right tiles.
            while(toProcess.length)
            {
                // A tile is only added if it matches so set color.
                var curTile = toProcess.pop() as ColorTile;
                
                // Skip stuff we've already seen.
                if (curTile.visited == floodToken) continue;
                
                var delay = getTileDelay(curTile);
                if (delay > maxDelay) maxDelay = delay;
                
                // Color and note that we visited them.
                curTile.paint(types[color], delay);
                curTile.visited = floodToken;
                
                // Check if we need to color any adjacent tiles.
                var rightTile = getTile(curTile.tileX + 1, curTile.tileY);
                if (rightTile && rightTile.colorIndex == originalColor) {
                    toProcess.push(rightTile);
                }
                
                var bottomTile = getTile(curTile.tileX, curTile.tileY + 1);
                if (bottomTile && bottomTile.colorIndex == originalColor) {
                    toProcess.push(bottomTile);
                }
                    
                var leftTile = getTile(curTile.tileX - 1, curTile.tileY);
                if (leftTile && leftTile.colorIndex == originalColor) {
                    toProcess.push(leftTile);
                }
                
                var topTile = getTile(curTile.tileX, curTile.tileY - 1);
                if (topTile && topTile.colorIndex == originalColor) {
                    toProcess.push(topTile);
                }
            }
            
            // Block interaction until all the tiles are finished transitioning
            waitUntil = Loom2D.juggler.elapsedTime+maxDelay+0.5;
            
            // Check to see if we won. Note that because the array is linear,
            // we don't have to do a 2d traversal - we can just walk it directly.
            var didWeWin = true;
            for(var i=0; i<gridSize*gridSize; i++)
                if(tiles[i].colorIndex != color)
                    didWeWin = false;
            
            // Handle victory.
            if (didWeWin == true) {
                stopGame(true);
            } else if (floodToken >= maxMoves) {
                // If they exceeded move max, they lost.
                stopGame(false);
            }
        }
        
        /**
         * Show and enable the buttons for tile types with a neat animation.
         */
        private function showButtons()
        {
            for (var i = 0; i < buttons.length; i++) {
                var button = buttons[i];
                button.y = -120;
                button.alpha = 0;
                Loom2D.juggler.tween(button, 0.6, { delay: i*0.05, y: 0, alpha: 1, transition: Transitions.EASE_OUT_BOUNCE } );
            }
            Loom2D.juggler.delayCall(function() {
                buttonStrip.touchable = true;
            }, 1+buttons.length*0.05);
        }
        
        /**
         * Hide and disable the buttons for tile types with a neat animation.
         */
        private function hideButtons()
        {
            buttonStrip.touchable = false;
            for (var i = 0; i < buttons.length; i++) {
                var button = buttons[i];
                button.y = 0;
                button.alpha = 1;
                Loom2D.juggler.tween(button, 0.6, { delay: i*0.05, y: -120, alpha: 0, transition: Transitions.EASE_IN_BACK } );
            }
        }
        
        /**
         * Helper to set a tile from our grid given X and Y coordinates.
         */
        protected function setTile(x:int, y:int, tile:ColorTile):void
        {
            var i:int = x * gridSize + y;
            tiles[i] = tile;
        }
       
        /**
         * Helper to get a tile from our grid given X and Y coordinates.
         */ 
        protected function getTile(x:int, y:int):ColorTile
        {
            if(x < 0 || x >= gridSize)
                return null;
            if(y < 0 || y >= gridSize)
                return null;
            
            return tiles[x * gridSize + y];
        }
        
        /**
         * Helper to update the score display.
         */
        protected function setScore(value:int):void
        {
            var left = (maxMoves-value);
            scoreLabel.text = left == 0 ? "No moves left" : left == 1 ? "One move left" : left+" moves left";
            scoreLabel.center();
            scoreLabel.x = contentWidth/2;
            scoreLabel.y = scorePos;
        }
        
        /**
         * Debug to show grid state in log.
         */
        protected function dumpTileContents():void
        {
            trace(tiles.join());
        }
    }
}