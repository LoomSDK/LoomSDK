package
{
    import loom2d.Loom2D;
    import loom.sound.SimpleAudioEngine;
    import loom.gameframework.LoomComponent;

    /**
     * This class is a base class for controlling paddles. Classes extending this class must
     * implement their own control methods and thus override that of this class.
     * 
     * This class is also responsible for checking paddle movement constraints or when a paddle
     * allowed a ball to pass by it or it returned a ball to the play area.
     */
    public class PongPaddleMover extends LoomComponent
    {
        static public var WIDTH:Number = 124;   ///< Width of the unscaled paddle.
        static public var HEIGHT:Number = 30;   ///< Height of the unscaled paddle.
        static public var DRAG:Number = 30;     ///< The maximum degrees a paddle can change the angle of the ball - depending on
                                                ///< the distance of the collision point from the center of the paddle.

        public var config_SPEED:Number = 200;   ///< A relative speed for paddles.

        var ctrl:Coroutine;                     ///< Coroutine for control.

        public var x:Number = 0;
        public var y:Number = 0;
        public var scale:Number = 1;

        public var speedX:Number = 0;           ///< The amount of units the paddle moves over the screen per frame.

        public var goalBelow = true;            ///< True signals that the paddle is below the play area and false that it is above.

        public var playing:Boolean = false;     ///< When true, deactivates the paddle.
                                                ///< This is a switch to take control and movement away from the object.

        /**
         * Plays a sound effect when a ball and this paddle collide.
         */
        private function paddleHitSfx():void
        {
            SimpleAudioEngine.sharedEngine().playEffect("assets/sound/paddlehit.mp3");
        }

        /**
         * By default the PongPaddleMover doesn't control any of the paddles in the game.
         * Instead, classes that extend PongPaddleMover must implement and override this method.
         *
         * @param   dt:Number  Delta time in milliseconds since the last frame.
         * @param   game:Pong   The game instance.
         */
        public function control(dt:Number, game:Pong):void
        {
        }

        /**
         * Checks if the paddle has collided with either wall on the sides.
         *
         * @param   dt:Number  Delta time in milliseconds since the last frame.
         * @param   game:Pong   The game instance.
         */
        public function checkMovementConstraints(dt:Number, game:Pong):void
        {
            // this is called by the control method of a derived class
            // it has generic movement constraint checks

            if (x < 0) {
                speedX = 0;
                x = 0;
            }
            if (x > Loom2D.stage.nativeStageWidth - (WIDTH * game.assetScale)) {
                speedX = 0;
                x = Loom2D.stage.nativeStageWidth - (WIDTH * game.assetScale);
            }
        }

        /**
         * Returns true when a goal was scored, false otherwise
         *
         * @param   dt:Number  Delta time in milliseconds since the last frame.
         * @param   game:Pong   The game instance.
         */
        public function checkHit(dt:Number, game:Pong):Boolean
        {
            if (!playing || game.ballObjs.length==0)
                return false;

            // this will only allow execution if the object is instantiated from a class that extends PongPaddleMover
            // using reflection to make sure this object was insnantiated from a derived class and not directly through PongPaddleMover
            if (this.getType().getName() == "PongPaddleMover")
                return false;

            // let the overriden "control" coroutine figure out the best values for the current speed of the paddle
            if (!ctrl || !ctrl.alive)
                ctrl = Coroutine.create(control);
            ctrl.resume(dt, game);

            // move the paddle
            x += speedX * (dt / 1000);

            // check for movement constraints
            checkMovementConstraints(dt, game);

            // see if there is at least one ball that is in the play zone
            // number of balls in play (in safe zone)
            var safeCount:int = 0;
            // whether the paddle was hit by at least one ball this frame
            var paddleHit:Boolean = false;

            for (var b=0;b<game.ballObjs.length;b++)
            {
                var ballMover:PongBallMover = game.getBallMover(b);

                var r:Number = ballMover.RADIUS * game.assetScale;
                var bx:Number = ballMover.x;
                var by:Number = ballMover.y;

                // set up constraints for the paddle also including the radius of the ball
                var xMin:int = x - 2*r;
                var xMax:int = x + (WIDTH * game.assetScale);
                var yMin:int = y - 2*r;
                var yMax:int = y + (HEIGHT * game.assetScale);

                // if the ball is on the playfield, bail early
                if ((by > yMax && goalBelow) || (by < yMin && !goalBelow)) {
                    safeCount++;
                    continue;
                }

                // if the ball center is in the paddle area, return the ball
                if (bx >= xMin && bx <= xMax && by >= yMin && by <= yMax) {

                    // make sure the ball doesn't trigger this once again the next frame (not quite ideal, but simple)
                    // by aligning it with the edge of the paddle
                    ballMover.y = goalBelow ? yMax - (by - yMax) : yMin + (yMin - by);
                    // bounce the ball off the paddle
                    ballMover.speedY *= -1;

                    // we should also change the angle of the ball based on where the paddle is hit ("drag")
                    // dist is the relative distance from the center of the paddle
                    var dist = Math.clamp((bx - x) / (WIDTH * game.assetScale / 2), -1, 1);
                    if (ballMover.speedY < 0) dist *= -1;
                    // calculate the final escape angle of the ball with drag
                    var degrees = 180 - ballMover.getCurrentAngle() + (dist * DRAG);

                    // decrease the ball's speed somewhat
                    ballMover.speed = Math.clamp(ballMover.speed - 10, ballMover.config_SPEED, ballMover.config_SPEED * 3);
                    // set the new angle of movement (+ the movement vector size)
                    ballMover.setAngle(degrees);

                    paddleHit = true;

                    safeCount++;

                    continue;
                }
            }

            if (paddleHit)
                paddleHitSfx();

            if (safeCount==0)
                return true;

            return false;
        }
    }
}
