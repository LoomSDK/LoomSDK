package
{

    import loom.Application;    
    import loom.gameframework.LoomGroup;    
    import loom.gameframework.TimeManager;    
    import loom2d.display.Stage;
    import loom2d.math.Point;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;    
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;


    public class TexBox
    {
        private const NUM_IMAGES:int        = 20;

        //texture state constants
        private const NOT_LOADED:String     = "Not Loaded";
        private const LOADING:String        = "Loading...";
        private const LOADED:String         = "Load Completed";
        private const USING_CACHED:String   = "Using Cached Texture";

        private var _sprite:Image;
        private var _label:SimpleLabel;
        private var _name:SimpleLabel;
        private var _texBase:String;

        private var _curImage:int = 0;
        private var _origTex:Texture;
        private var _startTime:int;
        private var _go:Boolean = false;



        public function TexBox(texPath:String, stage:Stage, y:int)
        {
            _texBase = texPath;

            //image
            _sprite = new Image();
            _origTex = _sprite.texture;
            _sprite.pivotX = _sprite.width / _sprite.scaleX / 2;
            _sprite.pivotY = 0;
            _sprite.x = stage.stageWidth / 2;
            _sprite.y = y;
            _sprite.touchable = true;
            stage.addChild(_sprite);

            //label
            _label = new SimpleLabel("assets/fonts/Curse-hd.fnt", stage.stageWidth, 64);            
            _label.x = _sprite.x - (stage.stageWidth / 8);
            _label.y = _sprite.y + _sprite.height + 10;
            _label.scale = 0.25;
            _label.text = NOT_LOADED;
            _label.touchable = false;
            stage.addChild(_label);

            //name
            _name = new SimpleLabel("assets/fonts/Curse-hd.fnt", stage.stageWidth, 64);            
            _name.x = _sprite.x - (stage.stageWidth / 10);
            _name.y = _sprite.y - 24;
            _name.scale = 0.2;            
            _name.text = _origTex.textureInfo.path;
            _name.touchable = false;
            stage.addChild(_name);

            //listen to touch events
            _sprite.addEventListener(TouchEvent.TOUCH, onTouch);            
        }


        private function setTexture(tex:Texture, text:String):void
        {
            //dispose old tex?
            if(_sprite.texture != null)
            {
                _sprite.texture.dispose();
            }

            _sprite.texture = tex;
            _sprite.pivotX = _sprite.width / _sprite.scaleX / 2;
            _label.y = _sprite.y + _sprite.height;
            _label.text = text;
            _name.text = tex.textureInfo.path;
        }


        private function requestAsyncTex():void
        {
            //attempt async load!
            _startTime = Platform.getTime();
            var texToLoad:String = _texBase + _curImage + ".png";
            trace("AsyncImageExample::requestAsyncTex: " + texToLoad);       
            var newTex:Texture = Texture.fromAssetAsync(texToLoad, asyncLoadCompleteCB);
            if(newTex.isTextureValid())
            {
                setTexture(newTex, USING_CACHED);
            }
            else
            {
                //note that we've started async loading...
                _label.text = LOADING;
            }

            //wrap image
            if(++_curImage == NUM_IMAGES)
            {
                _curImage = 0;
            }  
        }


        private function asyncLoadCompleteCB(texture:Texture):void
        {
            setTexture(texture, LOADED + ": " + (Platform.getTime() - _startTime) + "ms");

            //again!
            if(_go)
            {
                requestAsyncTex();
            }
        }


        private function onTouch(e:TouchEvent) 
        { 
            var touch = e.getTouch(_sprite, TouchPhase.BEGAN);
            if (touch)
            {
                _go = !_go;
                if(_go)
                {
                    requestAsyncTex();
                }
            }
        }            
    }


    /**
     *  Example showcasing how to use the AsyncImage class in Loom
     */
    public class AsyncImageExample extends Application
    {
        private var _fps:SimpleLabel;
        private var _lastUpdate:int = 0;
        private var _numTicks:int;

        private var _textureA:TexBox;
        private var _textureB:TexBox;
        private var _textureC:TexBox;



        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            //add FPS output to the app
            _fps = new SimpleLabel("assets/fonts/Curse-hd.fnt", 256, 64);            
            _fps.x = stage.stageWidth - 80;
            _fps.y = 10;
            _fps.scale = 0.25;
            _fps.touchable = false;
            stage.addChild(_fps);

            //create the texture load boxes
            var top:int = 32;
            var gap:int = 16;
            _textureA = new TexBox("assets/stream1/img_", stage, top);
            _textureC = new TexBox("assets/stream2/img_", stage, 300+top+gap);
            _textureB = new TexBox("assets/stream3/img_", stage, 600+top+(gap*2));
        }


        override public function onTick():void
        {
            //handle FPS updating
            _numTicks++;
            var currentTime:int = Platform.getTime();
            if((currentTime - _lastUpdate) >= 1000)
            {
                var dt:Number = 1.0 / (((currentTime - _lastUpdate) / 1000) / _numTicks);
                dt = int(dt * 100) / 100;
                _lastUpdate = currentTime;
                _numTicks = 0;

                _fps.text = "fps: " + dt.toString();
            }

            //tick super
            super.onTick();
        }
    }
}