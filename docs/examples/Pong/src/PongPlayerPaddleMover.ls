package
{
    import loom2d.Loom2D;
    import loom.platform.GameController;

    /**
     * This class implements player control for paddles by overriding the PongPaddleMover.control method.
     */
    public class PongPlayerPaddleMover extends PongPaddleMover 
    {
        /**
         * Control method override implementing player controls.
         * This is a coroutine
         *
         * @param   dt:Number  Delta time in milliseconds since the last frame.
         * @param   game:Pong   The game instance.
         */
        override public function control(dt:Number, game:Pong):void
        {
            // if there is no active touch, bail early
            if (!game.touching && !GameController.numControllers)
            {
                speedX = 0;
                return;
            }

            speedX = 0;

            var move_x:Number;

            if (game.touching)
            {
                // player control is just tapping the left or right side of the screen
                // around your own paddle
                // filter the y range for this paddle
                var y1 = y - Loom2D.stage.stageHeight / 3;
                var y2 = y + Loom2D.stage.stageHeight / 3;
                if (y2 < y1)
                {
                    var yt = y1;
                    y1 = y2;
                    y2 = yt;
                }
                if (game.lastTouchY < y1 || game.lastTouchY > y2)
                    return;

                // now move the paddle to where the touch occured
                move_x = game.lastTouchX - Loom2D.stage.stageWidth / 2;
                if (Math.abs(speedX) < config_SPEED)
                    speedX = config_SPEED;
                speedX = move_x < 0 ? -Math.abs(speedX) : Math.abs(speedX);
            }
            else if (GameController.numControllers)
            {
                var gamepad = GameController.getGameController(0);
                move_x = gamepad.getNormalizedAxis(0);

                speedX = Math.abs(move_x);
                if (speedX < .25)
                    return; // dead zone
                speedX -= .1;
                if (speedX < config_SPEED)
                    speedX = config_SPEED;

                speedX = move_x < 0 ? -speedX : speedX;
            }
        }
    }
}