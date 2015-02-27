package
{

    import loom.Application;    
    import loom2d.math.Point;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;    
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;

    /**
     *  Example showcasing how to use the AsyncImage class in Loom
     */
    public class AsyncImageExample extends Application
    {
        var checkerboard:Texture;
        var poly:Texture = null;
        var sprite:Image;
        var label:SimpleLabel;
        var startTime:int;

        const _disposePoly:Boolean = true;


        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            //create label to show status
            label = new SimpleLabel("assets/fonts/Curse-hd.fnt", 320, 128);            
            label.x = stage.stageWidth/2 - 80;
            label.y = stage.stageHeight - 80;
            label.scale = 0.5;
            label.text = "Not Loaded";
            stage.addChild(label);

            //create the empty sprite image to start
            checkerboard = Texture.fromAsset("assets/checkerboard.jpg");
            sprite = new Image(checkerboard);
            sprite.center();
            sprite.x = 160;
            sprite.y = 160;
            stage.addChild(sprite);

            //listen to touch events
            stage.addEventListener( TouchEvent.TOUCH, onTouch);
        }


        private function asyncLoadCompleteCB(texture:Texture):void
        {
            label.text = "Async Load Completed:  " + (Platform.getTime() - startTime) + "ms";
            sprite.texture = texture;
            sprite.center();
        }


        private function onTouch(e:TouchEvent) 
        { 
            var touch = e.getTouch(stage, TouchPhase.BEGAN);
            if (touch)
            {
                if(poly == null)
                {
                    //attempt async load!
                    startTime = Platform.getTime();
                    poly = Texture.fromAssetAsync("assets/logo.png", asyncLoadCompleteCB);
                    if(poly.isTextureValid())
                    {
                        label.text = "Cached Texture Used";
                        sprite.texture = poly;
                        sprite.center();
                    }
                    else
                    {
                        //note that we've started async loading...
                        label.text = "Loading Async...";
                    }               
                }
                else
                {
                    //clear the sprite texture to start again
                    label.text = "Not Loaded";
                    sprite.texture = checkerboard;
                    sprite.center();

                    //dispose of our async texture or just clear it?
                    if(_disposePoly)
                    {
                        poly.dispose();
                    }
                    poly = null;
                }
            }
        }         
    }
}