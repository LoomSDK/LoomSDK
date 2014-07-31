package
{
    import game.TileType;
    import loom.gameframework.TimeManager;
    import loom2d.display.Sprite;
    import loom2d.events.KeyboardEvent;
    import loom2d.Loom2D;
    import loom2d.math.Point;

    import loom.Application;

    import loom2d.display.DisplayObject;
    import loom2d.display.Image;    
    import loom2d.display.StageScaleMode;
    
    import loom2d.events.Event;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.textures.Texture;

    import loom2d.ui.SimpleLabel;
    
    import game.ColorTile;

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
        
        public var instructions:Image;
        
        /**
         * The score label.
         */
        public var scoreLabel:SimpleLabel;
        
        /**
         * The width of the content.
         */
        public var contentWidth = 320;
        
        /**
         * The height of the content.
         */
        public var contentHeight = 480;

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
        public var floodDelay = 0.01;
        //public var floodDelay = 0.1;
        
        /**
         * Block interaction until this time.
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
         *  References to the six buttons, indexed by their color ID.
         */
        public var buttons = new Vector.<Sprite>(6);
        
        // Gets injected automatically before run() is called
        [Inject] private var timeManager:TimeManager;
        
        /**
         * Entry point for the game (see main.ls)
         */
        override public function run():void
        {
            // Set up automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;
            SplashLoader.init(stage, timeManager, load);
        }
        
        /**
         * Called with a delay to allow the splash display to show.
         */
        protected function load():void {
            stage.addEventListener(KeyboardEvent.BACK_PRESSED, back);
            
            // Initialize the labels, grid, and buttons.
            layout();
            
            // And start play.
            startGame();
        }
        
        /**
         * Exit app on back button press
         */
        private function back(e:KeyboardEvent):void 
        {
            Process.exit(0);
        }
        
        /**
         * Initialize the score label, game grid, and the buttons.
         */
        protected function layout():void
        {
            // Score Label
            scoreLabel = new SimpleLabel("assets/Curse-hd.fnt", 128, 40);
            scoreLabel.x = contentWidth / 2 - 64;
            scoreLabel.y = 385;
            stage.addChild(scoreLabel);
            
            // Instructions that are hidden after a short delay
            instructions = new Image(Texture.fromAsset("assets/instructions.png"));
            instructions.scale = contentWidth / instructions.width;
            instructions.y = 70;
            instructions.touchable = false;
            Loom2D.juggler.tween(instructions, 2, { alpha: 0, delay: 3 } );
            
            var tileSize:Number = Number(25*12) / Number(gridSize);        
            for(var h:int=0; h < gridSize; h++)
            {
                for(var w:int=0; w < gridSize; w++)
                {
                    var tile = new ColorTile(w, h);
                    tile.x = 10 + w*tileSize;
                    tile.y = 10 + h*tileSize;
                    tile.width = tileSize;
                    trace(tile.width, tileSize);
                    tile.height = tileSize;

                    setTile(w, h, tile);
                    
                    stage.addChild(tile);
                }
            }
            
            types = [
                new TileType(0, 0x602462, Texture.fromAsset("assets/tiles/tile0.png")),
                new TileType(1, 0x396EAA, Texture.fromAsset("assets/tiles/tile1.png")),
                new TileType(2, 0xDDC222, Texture.fromAsset("assets/tiles/tile2.png")),
                new TileType(3, 0xFDF5E6, Texture.fromAsset("assets/tiles/tile3.png")),
                new TileType(4, 0xFB2447, Texture.fromAsset("assets/tiles/tile4.png")),
                new TileType(5, 0x6C8C16, Texture.fromAsset("assets/tiles/tile5.png"))
            ];

            for(var i:int=0; i < 6; i++)
            {
                //var button:Image = new Image(Texture.fromAsset("assets/orb.png"));
                var button = new ColorTile(i, 0);
                button.paint(types[i]);
                button.x = i * 50 + 35;
                button.y = 355;
                button.center();
                button.scale = 50/button.width;
                //button.pivotX = button.width / 2;
                //button.pivotY = button.height / 2;
                //button.scaleX = button.scaleY = 0.5;

                button.addEventListener(TouchEvent.TOUCH, buttonClicked);

                buttons[i] = button;
                stage.addChild(button);
            }
            
            stage.addChild(instructions);
        }
        
        /**
         * Handle a button being clicked.
         * @param   e Event describing the touch.
         */
        protected function buttonClicked(e:TouchEvent)
        {
            // Don't respond if waiting is to be had!
            if (Loom2D.juggler.elapsedTime < waitUntil) return;
            
            // Only respond on release.
            if(e.getTouch(e.currentTarget as DisplayObject, TouchPhase.ENDED) == null)
                return;

            // Retrieve the index of the button.
            var i = buttons.indexOf(e.currentTarget);
            if (i == -1)
            {
                trace("Got click on a non-button.");
                return;
            }
            
            // If game is over, restart.
            if (gameOver)
            {
                startGame();
                return;
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
            setScore(0);
            gameOver = false;
            
            // Set the grid to random colors.
            for(var i=0; i<gridSize*gridSize; i++) {
                var tile = tiles[i];
                tile.reset();
                tile.paint(types[int(Math.random() * 6)], floodDelay * i);
                //tile.paint(types[int(Math.random() * 6)], 0);
            }
            
            // Block interaction until all the tiles are finished transitioning
            waitUntil = Loom2D.juggler.elapsedTime + floodDelay*gridSize*gridSize;
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
            // Change the token. We could use a flag, but then we'd have to
            // reset the flag after every fill, which I hate. So instead we
            // have this counter and check for equality.
            floodToken++;
            
            // Check if we've exceeded the move count. floodToken is convenient
            // for this because it never resets and it increments every turn, but
            // if that changed you'd want to use a seperate counter.
            if(floodToken > maxMoves)
            {
                // If they exceeded move max, they lost.
                scoreLabel.text = "You lost!";
                gameOver = true;
                return;
            }
            else
            {
                // Otherwise update score.
                setScore(floodToken);
                trace("Moves left: " + (maxMoves - floodToken));
            }
        
            // We'll use this to store a stack of tiles we need to process.
            //
            // We could implement this behavior recursively, but it's a lot
            // simpler and more reliable to do it with an explicit stack and
            // loop.
            var toProcess:Vector.<ColorTile> = new Vector.<ColorTile>();
            
            var origin = getTile(0, 0);
            
            // Seed the stack with the tile at 0,0
            toProcess.push(origin);
            
            // Note the original color.
            var originalColor:int = origin.colorIndex;
            
            origin.counter = 0;
            
            var count = 0;
            
            //for each (var tile:ColorTile in tiles) {
                //tile.counter = 0;
            //}
            
            // Now walk everything that is a match to the current color,
            // always adding bottom or right tiles.
            while(toProcess.length)
            {
                // A tile is only added if it matches so set color.
                var curTile = toProcess.pop() as ColorTile;
                
                // Skip stuff we've already seen.
                if(curTile.visited == floodToken)
                  continue;
                
                // Color and note that we visited them.
                curTile.paint(types[color], floodDelay*count);
                //curTile.paint(types[color], floodDelay*curTile.counter);
                curTile.visited = floodToken;
                
                count++;
                
                // Check if we need to color any adjacent tiles.
                var rightTile = getTile(curTile.tileX + 1, curTile.tileY);
                if (rightTile && rightTile.colorIndex == originalColor) {
                    rightTile.counter = curTile.counter+1;
                    toProcess.push(rightTile);
                }
                
                var bottomTile = getTile(curTile.tileX, curTile.tileY + 1);
                if (bottomTile && bottomTile.colorIndex == originalColor) {
                    bottomTile.counter = curTile.counter+1;
                    toProcess.push(bottomTile);
                }
                    
                var leftTile = getTile(curTile.tileX - 1, curTile.tileY);
                if (leftTile && leftTile.colorIndex == originalColor) {
                    leftTile.counter = curTile.counter+1;
                    toProcess.push(leftTile);
                }
                
                var topTile = getTile(curTile.tileX, curTile.tileY - 1);
                if (topTile && topTile.colorIndex == originalColor) {
                    topTile.counter = curTile.counter+1;
                    toProcess.push(topTile);
                }
            }
            
            // Block interaction until all the tiles are finished transitioning
            waitUntil = Loom2D.juggler.elapsedTime + floodDelay*count;
            
            // Check to see if we won. Note that because the array is linear,
            // we don't have to do a 2d traversal - we can just walk it directly.
            var didWeWin = true;
            for(var i=0; i<gridSize*gridSize; i++)
                if(tiles[i].colorIndex != color)
                    didWeWin = false;
            
            // Handle victory.
            if(didWeWin == true)
            {
                gameOver = true;
                scoreLabel.text = "You Won!";
                trace("You Won!");
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
            scoreLabel.text = value + "/" + maxMoves;
            scoreLabel.scaleX = 1.1;
            scoreLabel.scaleY = 1.1;
            Loom2D.juggler.tween(scoreLabel, 0.2, { "scaleX": 1, "scaleY": 1 } );
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