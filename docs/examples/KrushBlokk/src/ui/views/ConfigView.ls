package ui.views
{
    import game.GameConfig;
    import loom.lml.LML;
    import loom.lml.LMLDocument;
    
    /**
     * Base convenience view providing easy access to game config
     * and applying an LML file if applicable.
     */
    class ConfigView extends View
    {
        
        public var config:GameConfig;
        public var onPick:ViewCallback;
        
        function get layoutFile():String { return null; }
        
        public function init()
        {
            if (layoutFile != null) {
                var doc:LMLDocument = LML.bind("assets/layout/" + layoutFile, this);
                doc.onLMLCreated += created;
                doc.apply();
            }
        }
        
        protected function created() {}
        
        protected function pick(setup:Function):Function {
            return function() {
                setup();
                onPick();
            };
        }
    }
}