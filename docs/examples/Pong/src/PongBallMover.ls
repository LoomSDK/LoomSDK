package
{    
    import loom2d.Loom2D;
    import loom.sound.SimpleAudioEngine;
    import loom.gameframework.LoomComponent;

    public class PongBallMover extends LoomComponent
    {
        static public var RADIUS:Number = 12;   ///< The radius of the ball.
        public var config_SPEED:Number = 300;   ///< The speed of the ball - not comparable with paddle speeds.

        public var speed:Number = 300;          ///< The ball's actual speed.
                                                ///< This is increased for every wall hit and decreased for every paddle hit.

        public var x:Number = Math.round(Loom2D.stage.stageWidth / 2);
        public var y:Number = Math.round(Loom2D.stage.stageHeight / 2);
        public var scale:Number = 0;
        public var rotation:Number = 0;

        public var speedX:Number = 0;           ///< Movement of the ball on the x axis during the actual frame.
        public var speedY:Number = 0;           ///< Movement of the ball on the y axis during the actual frame.

        public var playing:Boolean = false;     ///< Facility to halt the ball.

        var angleDegrees:Number = 0;            ///< The angle of the ball's movement vector (where 0 is up, 90 is right).

        /**
         * Returns the current angle of the ball movement vector.
         *
         * @return  Number  Angle of the ball's movement vector in degrees.
         */
        public function getCurrentAngle():Number
        {
            return angleDegrees;
        }

        /**
         * Assigns a new angle to be the ball's new movement vector changing its direction.
         *
         * @param   angleDeg:Number The new angle to use for the ball's movement vector.
         */
        public function setAngle(angleDeg:Number):void
        {
            // set the current angle in degrees
            angleDegrees = angleDeg;
            var vSpeed:Number = speed;
            // angle will store the same value in radians
            var angle:Number = angleDegrees * (Math.PI / 180);
            // set the correct movement speed for each axis
            speedX = vSpeed * Math.sin(angle);
            speedY = vSpeed * Math.cos(angle);
        }

        /**
         * Plays a sound effect when the ball hits the wall.
         */
        private function wallHitSfx():void
        {
            SimpleAudioEngine.sharedEngine().playEffect("assets/sound/wallhit.mp3");
        }

        /**
         * Moves the ball depending on its set speed and checks if any walls are hit.
         *
         * @param   dt:Number  Delta time in milliseconds since the last frame.
         * @param   game:Pong   The game instance.
         */
        public function move(dt:Number, game:Pong):void
        {
            if (!playing)
                return;

            var playScale = game.config_PLAY_SCALE;

            // move the ball
            x += speedX * (dt / 1000);
            y += speedY * (dt / 1000);

            // set the constraints for the area where the ball may move freely
            var xMin:int = RADIUS * scale * playScale;
            var yMin:int = RADIUS * scale * playScale;
            var xMax:int = Loom2D.stage.stageWidth - (RADIUS * scale * playScale);
            var yMax:int = Loom2D.stage.stageHeight - (RADIUS * scale * playScale);

            // check if the ball is outside of the previously set bounds
            // if yes, it means that we hit a wall:
            //   - bounce the ball back from the wall
            //   - register the new movement vector angle
            //   - play a wall hit sound effect
            var wallHit = false;
            if (x < xMin) {
                speedX = Math.abs(speedX);
                angleDegrees = -angleDegrees;
                wallHit = true;
            } else if (x > xMax) {
                speedX = -Math.abs(speedX);
                angleDegrees = -angleDegrees;
                wallHit = true;
            } else if (y < yMin) {
                speedY = Math.abs(speedY);
                angleDegrees = 180 - angleDegrees;
                wallHit = true;
            } else if (y > yMax) {
                speedY = -Math.abs(speedY);
                angleDegrees = 180 - angleDegrees;
                wallHit = true;
            }

            if (wallHit) {
                // increase the speed of the ball slightly
                speed = Math.clamp(speed + 20, config_SPEED, config_SPEED * 3);
                // setAngle also changes the size of the movement vector
                setAngle(angleDegrees);
                wallHitSfx();
            }
        }
    }
}