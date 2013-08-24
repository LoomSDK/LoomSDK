package
{
    import loom2d.Loom2D;
    
    /**
     * A class that implements a simple AI controller for paddles.
     */
    public class PongAIPaddleMover extends PongPaddleMover
    {
        public var config_REFLEX:Number = 10;   ///< Reflex emulation to add control lag.
                                                ///< (Primarily to AI, but would also be interesting to use with human controlled paddles as a temp hex.)

        static public var BLUR:Number = 1;      ///< A multiplier to blur the vision of the ai - a higher value adds more noise.

        var distance:Number = 0;                ///< The distance of the ball from this paddle.
        var noise:Number = 0;                   ///< The amount of noise the paddle control receives.

        /**
         * Control method override implementing AI / automatic controls.
         * This is a coroutine
         *
         * @param   dt:Number  Delta time in milliseconds since the last frame.
         * @param   game:Pong   The game instance.
         */
        override public function control(dt:Number, game:Pong):void
        {
            // bail for the first config_REFLEX times since the AI is not allowed to think every frame
            for (var i=0;i<config_REFLEX; i++)
                yield();

            // find the one ball that is closest and approaching this paddle
            var closestApproaching:Number = -1;
            for (var b=0;b<game.ballObjs.length;b++)
            {
                var ballMover:PongBallMover = game.getBallMover(b);
                // approaching?
                if (ballMover.speedY < 0 && goalBelow || ballMover.speedY > 0 && !goalBelow)
                    // closer?
                    if ((closestApproaching == -1) || (Math.abs(ballMover.y - y) < Math.abs(game.getBallMover(closestApproaching).y - y)))
                        closestApproaching = b;
            }

            // if all balls are going away from this paddle, jog
            if (closestApproaching == -1)
            {
                speedX = (Loom2D.stage.stageHeight / 2 - x) < 0 ? -config_SPEED : config_SPEED;
                return;
            }

            // the closer the ball is the better the AI should see its exact position
            // via generating more noise over a larger distance
            // we should only check / change this every n frames
            var mover:PongBallMover = game.getBallMover(closestApproaching);
            distance = Math.abs(mover.y - y);
            noise = Math.clamp(distance / Loom2D.stage.stageHeight, 0, 1) * BLUR;
            // move_x is how much and in which direction the paddle should move
            var move_x = (mover.x - x) + noise * ((Math.random() * Loom2D.stage.stageWidth) - (Loom2D.stage.stageWidth / 2));
            // paddles only move on the x axis
            if (Math.abs(speedX) < config_SPEED)
                speedX = config_SPEED;
            speedX = move_x < 0 ? -Math.abs(speedX) : Math.abs(speedX);
        }
    }
}