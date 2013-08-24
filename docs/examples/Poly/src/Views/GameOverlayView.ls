package poly.views
{
    import poly.ui.View;
    import poly.ui.ViewCallback;
    import loom2d.ui.SimpleButton;

    import loom.lml.LML;
    import loom.lml.LMLDocument;

    /**
     * View shown overlaying gameplay; hidden when in pause menu.
     */
    class GameOverlayView extends View
    {
        [Bind]
        public var pauseButton:SimpleButton;

        public var onPause:ViewCallback;

        public function GameOverlayView()
        {
            super();

            var doc = LML.bind("assets/gameOverlay.lml", this);
            doc.onLMLCreated = onLMLCreated;
            doc.apply();
        }

        protected function onClick()
        {
            trace("Pausing");
            onPause();
        }

        protected function onLMLCreated()
        {
            pauseButton.onClick = onClick;
        }
    }
}