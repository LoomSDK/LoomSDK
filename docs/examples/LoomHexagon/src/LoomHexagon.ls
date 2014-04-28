/*****************************************************************************

The MIT License (MIT)

Copyright (c) 2013 Raymond Cook

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*****************************************************************************/

package
{
    import loom2d.ui.SimpleLabel;
    import loom.Application;
    
    import loom.platform.LoomKey;
    
    import loom2d.Loom2D;
    
    import loom2d.events.Event;
    import loom2d.events.KeyboardEvent;
    import loom2d.events.TouchEvent;
    import loom2d.events.Touch;
    import loom2d.events.TouchPhase;
    
    import loom2d.animation.Tween;
    import loom2d.animation.Transitions;
    
    import loom2d.display.Quad;
    import loom2d.display.Sprite;
    
    /**
     * Loom Hexagon is a small demo game based off of Terry Cavanagh's Hexagon,
     * which can be found at http://jayisgames.com/games/hexagon/. The purpose
     * of this demo is to showcase Loom's ability to create fun and addicting
     * mobile games.
     */
    
    public class LoomHexagon extends Application
    {
        // Player revolution speed in radians per second
        private static const PLAYER_SPEED:Number = Math.PI * 3;
        
        // Player width/height in game screen dimensions
        private static const PLAYER_SIZE:Number = 0.02;
        
        // Player distance from the center of the screen
        private static const PLAYER_DISTANCE:Number = 0.08;
        
        // Speed of incoming colliders in game units per second
        private static const INITIAL_COLLIDER_SPEED:Number = 0.2;
        
        // Distance between collider spawns in game units
        private static const INITIAL_COLLIDER_GAP:Number = 0.4;
        
        // How much collider speed is incremented per second, in game units per second
        private static const COLLIDER_SPEED_INCREASE:Number = 0.0025;
        
        // How much collider spawn distance is decreased in game units per second
        private static const COLLIDER_GAP_DECREASE:Number = 0.0025;
        
        private static const PI_2:Number = Math.PI * 2;
        
        private var _rootSprite:Sprite;
        private var _fxContainer:Sprite;
        private var _backgroundLayer:Sprite;
        private var _colliderLayer:Sprite;
        private var _playerLayer:Sprite;
        private var _uiLayer:Sprite;
        
        private var _colliderSpeed:Number;
        private var _colliderGap:Number;
        private var _lastUpdate:int;
        
        private var _player:Quad;
        private var _leftPressed:Boolean;
        private var _rightPressed:Boolean;
        private var _distanceTravelled:Number;
        private var _running:Boolean;
        
        private var _scoresText:SimpleLabel;
        
        private var _startTime:int;
        private var _bestTime:int;
        private var _time:int;
        
        private var _colliderPool:Vector.<HexagonSector> = [];
        private var _activeColliders:Vector.<HexagonSector> = [];
        
        /**
         * Our application entry point. Game initialization occurs here.
         */
        
        override public function run():void
        {
            // Our root sprite, representing a square gameplay window. It uses a coordinate system of
            // -0.5 to 0.5 on both axes, and is scaled to the height or width of the screen, whichever
            // is greater.
            
            _rootSprite = new Sprite();
            stage.addChild( _rootSprite );
            
            // A special effects container that houses the player, colliders and
            // background. This is used to scaling and rotation effects
            // without affecting gameplay positioning.
            
            _fxContainer = new Sprite();
            _rootSprite.addChild( _fxContainer );
            
            // We create our background by creating 6 alternating color hexagon sectors
            // and adding them to a background layer.
            
            _backgroundLayer = new Sprite();
            
            for ( var i:int = 0; i < 6; i++ )
            {
                var bgHexPiece:HexagonSector = new HexagonSector();
                bgHexPiece.distance = 1;
                bgHexPiece.thickness = 1;
                bgHexPiece.color = 0x111111 + 0x111111 * ( i & 1 );
                bgHexPiece.sector = i;
                _backgroundLayer.addChild( bgHexPiece );
            }
            
            _fxContainer.addChild( _backgroundLayer );
            
            // The collider layer. All game colliders will be added to this layer.
            
            _colliderLayer = new Sprite();
            _fxContainer.addChild( _colliderLayer );
            
            // The player layer. Houses the player triangle and the central hexagon decoration.
            
            _playerLayer = new Sprite();
            _playerLayer.addChild( createHexagon( PLAYER_DISTANCE * 0.65, 0xffffff ) );
            _playerLayer.addChild( createHexagon( PLAYER_DISTANCE * 0.55, 0x888888 ) );
            _playerLayer.addChild( createHexagon( PLAYER_DISTANCE * 0.45, 0x000000 ) );
            _fxContainer.addChild( _playerLayer );
            
            // The player triangle, created by modifying the vertices of a quad to create
            // a triangle shape.
            
            _player = new Quad( 1, 1, 0xffffff );
            _player.setVertexPosition( 0, 0, -PLAYER_SIZE * 0.5 );
            _player.setVertexPosition( 1, 0, -PLAYER_SIZE * 0.5 );
            _player.setVertexPosition( 2, -PLAYER_SIZE * 0.5, PLAYER_SIZE * 0.5 );
            _player.setVertexPosition( 3, PLAYER_SIZE * 0.5, PLAYER_SIZE * 0.5 );
            _player.pivotY = PLAYER_DISTANCE - PLAYER_SIZE * 0.5;
            _playerLayer.addChild( _player );
            
            // Our UI layer sits on top of the game layers. It contains the game title and player scores
            
            _uiLayer = new Sprite();
            _rootSprite.addChild( _uiLayer );
            
            var title:SimpleLabel = new SimpleLabel( "assets/Curse-hd.fnt" );
            title.text = "LOOM HEXAGON";
            title.center();
            title.scale = 0.5 / title.width;
            title.y = -0.1;
            _uiLayer.addChild( title );

            _scoresText = new SimpleLabel( "assets/Curse-hd.fnt" );
            _scoresText.scale = title.scale * 0.45;
            _uiLayer.addChild( _scoresText );
            
            // Set initial player score text
            updateStatText();
            
            var tapToStart:SimpleLabel = new SimpleLabel( "assets/Curse-hd.fnt" );
            tapToStart.text = "TAP TO START";
            tapToStart.center();
            tapToStart.scale = title.scale * 0.75;
            tapToStart.y = 0.1;
            _uiLayer.addChild( tapToStart );
            
            stage.addEventListener( TouchEvent.TOUCH, onTouch );
            stage.addEventListener( KeyboardEvent.KEY_DOWN, onKeyDown );
            stage.addEventListener( KeyboardEvent.KEY_UP, onKeyUp );
            stage.addEventListener( Event.RESIZE, onResize );
            
            onResize();
            showOpeningScreen();
        }
        
        /**
         * Our main game simulation loop. Moves the player based on player input, spawns new colliders, 
         * moves all active colliders inward, and handles collision detection.
         */
         
        override public function onFrame():void
        {
            // Exit the simulation if we're not running
            if ( !_running ) return;
            
            // Grab our delta time since last frame for simulation calculations
            var currentTime:int = Platform.getTime();
            var deltaTime:Number = ( currentTime - _lastUpdate ) * 0.001;
            _lastUpdate = currentTime;
            
            // Move player based on key or touch input
            if ( _leftPressed ) _player.rotation -= PLAYER_SPEED * deltaTime;
            if ( _rightPressed ) _player.rotation += PLAYER_SPEED * deltaTime;
            
            // Sanity check player rotation and cap it for hexagonal sector calculation
            if ( Math.abs( _player.rotation ) >= PI_2 ) _player.rotation = _player.rotation % PI_2;
            if ( _player.rotation < 0 ) _player.rotation += PI_2;
            
            // Get the sector we're in for collision detection
            var playerSector:int = Math.round( ( _player.rotation / PI_2 ) * 6 );
            if ( playerSector > 5 ) playerSector -= 6;
            
            // Increase difficulty by increasing collider speed and decreasing gap between spawns
            _colliderSpeed += COLLIDER_SPEED_INCREASE * deltaTime;
            _colliderGap -= COLLIDER_GAP_DECREASE * deltaTime;
            
            // Update our distance travelled since last collider spawn
            _distanceTravelled += _colliderSpeed * deltaTime;
            
            // If we've travelled the spawn gap distance, reset the distance travelled, then spawn
            if ( _distanceTravelled >= _colliderGap )
            {
                _distanceTravelled = 0;
                spawnColliders();
            }
            
            // Loop through the onscreen colliders and update the position of each inward.
            // If the collider is in the same sector as a player, perform a hit check. If
            // the hit check returns true, end the game.
            
            var colliderCount:int = _activeColliders.length;
            
            var playerHit:Boolean = false;
            
            for ( var i:int = 0; i < colliderCount; i++ )
            {
                var collider:HexagonSector = _activeColliders[ i ]; 
                collider.distance -= _colliderSpeed * deltaTime;
                
                if ( playerSector == collider.sector && collider.hitCheck( PLAYER_DISTANCE ) ) playerHit = true;
                
                if ( collider.distance <= 0 )
                {
                    _colliderLayer.removeChild( collider );
                    returnColliderToPool( collider );
                    colliderCount--;
                    i--;
                }
            }
            
            if ( playerHit )
            {
                trace( "PLAYER HIT IN SECTOR ", playerSector );
                showOpeningScreen();
            }
        }
        
        /**
         * Updates the scores label with current score and best score
         */
        
        private function updateStatText():void
        {
            _scoresText.text = "TIME: " + createTimeString( _time ) + "                   BEST: " + createTimeString( _bestTime );
            _scoresText.x = -_scoresText.width * 0.5;
        }
        
        /**
         * Generates a formatted time string from the passed in int
         */
        
        private function createTimeString( time:int ):String
        {
            var jiffies:Number = time / 1000;
            var seconds:int = Math.floor( jiffies );
            jiffies = Math.floor( ( jiffies - seconds ) * 60 );
            
            var secondsPrefix:String = seconds < 10 ? "0" : ""; 
            var jiffiesPrefix:String = jiffies < 10 ? "0" : ""; 
            
            return secondsPrefix + seconds + ":" + jiffiesPrefix + jiffies;
        }
        
        /**
         * Hides UI screen and begins game simulation. Clears all animations and colliders,
         * resets game timers and collider speeds, and scales view to gameplay size before
         * enabling game loop.
         */
         
        private function start():void
        {
            Loom2D.juggler.purge();
            clearColliders();
            
            _startTime = Platform.getTime();
            _lastUpdate = _startTime;
            
            _playerLayer.scale = 1;
            _distanceTravelled = 0;
            _colliderSpeed = INITIAL_COLLIDER_SPEED;
            _colliderGap = INITIAL_COLLIDER_GAP;
            _running = true;
            
            Loom2D.juggler.tween( _uiLayer, 0.25, { "alpha" : 0 } );
            Loom2D.juggler.tween( _fxContainer, 0.25, { "scale" : 1, "rotation" : 0, "onComplete" : startEffectTweens } );
        }
        
        /**
         * Ends game simulation and shows the UI layer, zooming out to opening screen
         */
        
        private function showOpeningScreen():void
        {
            var delay:Number = 0;
            if ( _running )
            {
                // Update our best time stat
                _time = Platform.getTime() - _startTime;
                if ( _time > _bestTime ) _bestTime = _time;
                updateStatText();
                delay = 0.3;
            }
            
            Loom2D.juggler.purge();
            _playerLayer.scale = 1;
            _running = false;
            
            _uiLayer.alpha = 0;
            
            Loom2D.juggler.tween( _fxContainer, 0.25, { "delay" : delay, "scale" : 1 / ( PLAYER_DISTANCE * 1.25 ), "transition" : Transitions.EASE_IN } );
            Loom2D.juggler.tween( _fxContainer, 4, { "delay" : delay, "rotation" : _fxContainer.rotation + PI_2, "repeatCount" : 0 } );
            Loom2D.juggler.tween( _uiLayer, 0.25, { "delay" : delay, "alpha" : 1 } );
        }
        
        /**
         * A basic collider random pattern generator / spawner. Possibly places a collider into each
         * hexagonal sector, randomly doubling the collider thickness. Creates some interesting
         * patterns. Colliders are spawned offscreen.
         */
        
        private function spawnColliders():void
        {
            var count:int = 0;
            for ( var i:int = 0; i < 6; i++ )
            {
                if ( count < 5 && Math.random() * 6 <= 3 )
                {
                    addCollider( i, 1 );
                    if ( Math.random() * 6 <= 2 ) addCollider( i, 1 + HexagonSector.DEFAULT_THICKNESS );
                    count++;
                }
            }
        }
        
        /**
         * Retrieves a collider from the collider pool and adds it to the game window
         * at the specified sector and distance.
         */
        
        private function addCollider( sector:int, distance:Number ):void
        {
            var newCollider:HexagonSector = getColliderFromPool();
            newCollider.distance = distance;
            newCollider.sector = sector;
            _activeColliders.push( newCollider );
            _colliderLayer.addChild( newCollider );
        }
        
        /**
         * Removes all colliders from the game window and returns them to the collider pool.
         */
        
        private function clearColliders():void
        {
            while ( _activeColliders.length > 0 )
            {
                var collider:HexagonSector = _activeColliders[ 0 ];
                _colliderLayer.removeChild( collider );
                returnColliderToPool( collider );
            }
        }
        
        /**
         * Called when the game screen resizes. Centers the gameplay viewport and scales it
         * to the width or height of the screen, whichever is greater.
         */
        
        private function onResize( e:Event = null ):void
        {
            _rootSprite.x = stage.stageWidth * 0.5;
            _rootSprite.y = stage.stageHeight * 0.5;
            _rootSprite.scale = stage.stageWidth > stage.stageHeight ? stage.stageWidth : stage.stageHeight;
        }
        
        /**
         * Checks if touches exist on the left or right sides of the screen, and sets _leftPressed
         * and _rightPressed accordingly.
         */
        
        private function onTouch( e:TouchEvent ):void
        {
            _leftPressed = false;
            _rightPressed = false;
            
            var touches:Vector.<Touch> = e.getTouches( stage );
            
            for each ( var touch:Touch in touches )
            {
                if ( touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED || touch.phase == TouchPhase.STATIONARY )
                {
                    if ( touch.globalX < stage.stageWidth * 0.5 ) _leftPressed = true;
                    else _rightPressed = true;
                }
            }
            
            if ( !_running && touches.length == 1 && touches[ 0 ].phase == TouchPhase.BEGAN ) start();
        }
        
        /**
         * Checks if left key or right key is pressed, and sets _leftPressed or _rightPressed to true.
         */
        
        private function onKeyDown( e:KeyboardEvent ):void
        {
            if ( e.keyCode == LoomKey.LEFT_ARROW ) _leftPressed = true; 
            if ( e.keyCode == LoomKey.RIGHT_ARROW ) _rightPressed = true;
            if ( !_running ) start();
        }
        
        /**
         * Checks if left key or right key is released, and sets _leftPressed or _rightPressed to false.
         */
         
        private function onKeyUp( e:KeyboardEvent ):void
        {
            if ( e.keyCode == LoomKey.LEFT_ARROW ) _leftPressed = false; 
            if ( e.keyCode == LoomKey.RIGHT_ARROW ) _rightPressed = false; 
        }
        
        /**
         * Creates a series of repeating gameplay animations, beginning the rotation and pulsing effects.
         */
        
        private function startEffectTweens():void
        {
            _fxContainer.rotation = 0;
            _fxContainer.scale = 1;
            _playerLayer.scale = 1;
            
            Loom2D.juggler.tween( _playerLayer, 0.2, { "scale" : 1.2, "transition" : Transitions.EASE_IN_OUT_BOUNCE, "reverse" : true, "repeatCount" : 0 } );
            Loom2D.juggler.tween( _fxContainer, 0.3, { "scale" : 1.04, "transition" : Transitions.EASE_OUT_BOUNCE, "reverse" : true, "repeatCount" : 0 } );
            Loom2D.juggler.tween( _fxContainer, 4, { "rotation" : -PI_2, "reverse" : true, "repeatCount" : 0 } );
        }
        
        /**
         * Checks the collider pool for an available collider, and returns it if found. Otherwise
         * returns a new collider.
         */
        
        private function getColliderFromPool():HexagonSector
        {
            return _colliderPool.length > 0 ? _colliderPool.pop() : new HexagonSector();
        }
        
        /**
         * Removes the passed in collider from the active colliders in play and
         * returns it to the collider pool.
         */
        
        private function returnColliderToPool( collider:HexagonSector ):void
        {
            var colliderIndex:int = _activeColliders.indexOf( collider );
            _activeColliders.splice( colliderIndex, 1 );
            _colliderPool.push( collider );
        }
        
        /**
         * Returns a decorative hexagon Sprite of the width (from center) and color provided.
         */
        
        private function createHexagon( width:Number, color:uint ):Sprite
        {
            var result:Sprite = new Sprite();
            var horizontalPosition:Number = Math.cos( Math.PI / 3 );
            var verticalPosition:Number = Math.sin( Math.PI / 3 );
            
            for ( var i:Number = 0; i < 2; i++ )
            {
                var quad:Quad = new Quad( 1, 1, 0xffffff );
                quad.setVertexPosition( 0, horizontalPosition * -width, verticalPosition * width );
                quad.setVertexPosition( 1, horizontalPosition * width, verticalPosition * width );
                quad.setVertexPosition( 2, -width, 0 );
                quad.setVertexPosition( 3, width, 0 );
                quad.color = color;
                quad.rotation = Math.PI * i;
                result.addChild( quad );
            }
            
            return result;
        }
    }
    
    /**
     * A HexagonSector is a column in the shape of 1/6th of a Hexagon. It becomes narrower as its distance
     * to the center decreases. It is positioned by a sector id, representing one of the 6 hexagonal
     * sections in the game window, and by distance from center. Thickness can also adjusted.
     * A narrow HexagonSector is used as a game collider.
     */
    
    public class HexagonSector extends Quad
    {
        // The thickness of a collider, our default thickness
        public static const DEFAULT_THICKNESS:Number = 0.04;
        
        // Cache values used to help calculate vertex positions
        private static const HORIZONTAL_MULTIPLIER:Number = Math.cos( Math.PI / 3 );
        private static const VERTICAL_MULTIPLIER:Number = -Math.sin( Math.PI / 3 );
        
        private var _sector:int;
        private var _distance:Number;
        private var _thickness:Number = DEFAULT_THICKNESS;
        
        public function HexagonSector()
        {
            super( 1, 1, 0xffffff, true );
        }
        
        /**
         * The sector id this HexagonSector sits in. Valid values are integers in the range of 0-5.
         */
        
        public function get sector():int { return _sector; }
        
        public function set sector( value:int ):void
        {
            _sector = value;
            rotation = Math.PI / 3 * value;
        }
        
        /**
         * The distance from the center to the inner edge of the shape, in game units.
         */
        
        public function get distance():Number { return _distance; }
        
        public function set distance( value:Number ):void
        {
            _distance = value >= 0 ? value : 0;
            updateVertexData();
        }
        
        /**
         * The thickness of the shape from the inner edge to the outer edge, in game units.
         */
        
        public function get thickness():Number { return _thickness; }
        
        public function set thickness( value:Number ):void
        {
            _thickness = value;
            updateVertexData();
        }
        
        /**
         * Checks the vertical position (distance from center) passed in against the
         * distances of the inner and outer edges. If it falls between the two, returns true.
         * Otherwise returns false.
         */
        
        public function hitCheck( verticalPosition:Number ):Boolean
        {
            return ( verticalPosition >= ( _distance - _thickness ) ) && ( verticalPosition <= _distance ); 
        }
        
        /**
         * Updates the vertex positions of our Quad to the current distance and thickness.
         */
        
        private function updateVertexData():void
        {
            var bottomMultiplier:Number = _distance - _thickness;
            if ( bottomMultiplier < 0 ) bottomMultiplier = 0;
            setVertexPosition( 0, HORIZONTAL_MULTIPLIER * -_distance, VERTICAL_MULTIPLIER * _distance );
            setVertexPosition( 1, HORIZONTAL_MULTIPLIER * _distance, VERTICAL_MULTIPLIER * _distance );
            setVertexPosition( 2, HORIZONTAL_MULTIPLIER * -bottomMultiplier, VERTICAL_MULTIPLIER * bottomMultiplier );
            setVertexPosition( 3, HORIZONTAL_MULTIPLIER * bottomMultiplier, VERTICAL_MULTIPLIER * bottomMultiplier );
        }
        
    }
}