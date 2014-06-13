package ui.views.game {
    import feathers.controls.Button;
    import loom2d.display.Image;
    import loom2d.events.Event;
    import loom2d.textures.Texture;
    import ui.views.ConfigView;
    import ui.views.DialogView;
    import ui.views.ViewCallback;
    
    /**
     * Quit confirmation dialog view with yes/no options.
     */
    class ConfirmView extends DialogView
    {
        public var onYes:ViewCallback;
        public var onNo:ViewCallback;
        
        private var background:Image;
        
        [Bind] var quit:Button;
        [Bind] var yes:Button;
        [Bind] var no:Button;
        
        function get layoutFile():String { return "confirm.lml"; }
        
        public function created()
        {
            // Background as image for easy live reload
            background = new Image(Texture.fromAsset("assets/dialogColor.png"));
            addChildAt(background, 0);
            
            items.push(quit);
            items.push(yes);
            items.push(no);
            
            yes.addEventListener(Event.TRIGGERED, function(e:Event) {
                onYes();
            });
            no.addEventListener(Event.TRIGGERED, function(e:Event) {
                onNo();
            });
            
            // Easter egg when touching the quit header button
            var q = 0;
            var labels:Vector.<String> = [
                "Quit?",
                "no touching",
                "i am serious",
                "i am going",
                "to krush you",
                "with blokks",
                "stop",
                "it",
                "right",
                "now",
                ".",
                "..",
                "...",
                "...",
                "...",
                "Fine",
                "do it",
                "then",
                "if",
                "that",
                "is",
                "your",
                "fetish",
                "",
                "",
                "",
            ];
            quit.addEventListener(Event.TRIGGERED, function(e:Event) {
                quit.label = labels[(++q)%labels.length];
            });
            
        }
        
        public function resize(w:Number, h:Number)
        {
            super.resize(w, h);
            // Offset the background to counteract responsive positioning
            background.x = -x;
            background.width = w;
            background.height = h;
        }
        
    }
}