package
{
    import loom.animation.LoomTween;

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
    
    import com.loomengine.flooder.ColorTile;

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
        public static var colors:Vector.<int> = [0x602462, 0x396EAA, 0xDDC222, 0xFDF5E6, 0xFB2447, 0x6C8C16];
    
        /**
         * The score label.
         */
        public var scoreLabel:SimpleLabel;

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
         * Set when the game has ended.
         */
        public var gameOver:Boolean = false;

        /**
         * References to every tile on the board.
         */
        public var tiles:Vector.<ColorTile> = new Vector.<ColorTile>(gridSize * gridSize);
   
        /**
         *  References to the six orb buttons, indexed by their color ID.
         */
        public var orbs:Vector.<Image> = new Vector.<Image>(6);
        
        /**
         * Entry point for the game (see main.ls)
         */
        override public function run():void
        {
            
            // Initialize the labels, grid, and buttons.
            layout();

            // And start play.
            startGame();
        }
        
        /**
         * Initialize the score label, game grid, and the orbs.
         */
        protected function layout():void
        {
            // Set up automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Score Label
            scoreLabel = new SimpleLabel("assets/Curse-hd.fnt", 128, 40);
            scoreLabel.x = stage.stageWidth / 2 - 64;
            scoreLabel.y = 385;
            stage.addChild(scoreLabel);

            var tileSize:Number = Number(25*12) / Number(gridSize);        
            for(var h:int=0; h < gridSize; h++)
            {
                for(var w:int=0; w < gridSize; w++)
                {
                    var tile = new ColorTile(Math.floor(Math.random() * 6), w, h);
                    tile.x = w * tileSize + 10;
                    tile.y = h * tileSize + 20;
                    tile.width = tileSize;
                    tile.height = tileSize;

                    setTile(w, h, tile);
                    
                    stage.addChild(tile);
                }
            }

            for(var i:int=0; i < 6; i++)
            {
                var button:Image = new Image(Texture.fromAsset("assets/orb.png"));
                button.x = i * 50 + 35;
                button.y = 355;
                button.pivotX = button.width / 2;
                button.pivotY = button.height / 2;
                button.scaleX = button.scaleY = 0.5;
                button.color = colors[i];

                button.addEventListener(TouchEvent.TOUCH, orbClicked);

                orbs[i] = button;
                stage.addChild(button);
            }
        }
        
        /**
         * Handle an orb being clicked.
         * @param   e Event describing the touch.
         */
        protected function orbClicked(e:TouchEvent)
        {
            // Only respond on release.
            if(e.getTouch(e.target as DisplayObject, TouchPhase.ENDED) == null)
                return;

            // Retrieve the index of the orb.
            var i = orbs.indexOf(e.target);
            if (i == -1)
            {
                trace("Got click on non-orb.");
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
            for(var i=0; i<gridSize*gridSize; i++)
                tiles[i].reset(Math.floor(Math.random() * 6));
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
            
            // Seed the stack with the tile at 0,0
            toProcess.push(getTile(0,0));
            
            // Note the original color.
            var originalColor:int = getTile(0,0).colorIndex;
            
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
                curTile.colorIndex = color;
                curTile.visited = floodToken;

                // Check if we need to color any adjacent tiles.
                var rightTile = getTile(curTile.tileX + 1, curTile.tileY);
                if(rightTile && rightTile.colorIndex == originalColor)
                    toProcess.push(rightTile);
                
                var bottomTile = getTile(curTile.tileX, curTile.tileY + 1);
                if(bottomTile && bottomTile.colorIndex == originalColor)
                    toProcess.push(bottomTile);
                    
                var leftTile = getTile(curTile.tileX - 1, curTile.tileY);
                if(leftTile && leftTile.colorIndex == originalColor)
                    toProcess.push(leftTile);
                
                var topTile = getTile(curTile.tileX, curTile.tileY - 1);
                if(topTile && topTile.colorIndex == originalColor)
                    toProcess.push(topTile);
            }
            
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
            LoomTween.to(scoreLabel, 0.2, { "scaleX": 1, "scaleY": 1 } );
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