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
    import loom2d.textures.ConcreteTexture;
    import loom2d.ui.SimpleLabel;
    import loom2d.ui.SimpleButton;
    import loom.HTTPRequest;


    public class TexBox
    {
        private const NUM_IMAGES:int        = 10;

        //texture state constants
        private const NOT_LOADED:String     = "Touch Me!";
        private const LOADING_DISK:String   = "Loading from Disk...";
        private const LOADING_HTTP:String   = "Loading from HTTP...";
        private const LOADED:String         = "Load Completed";
        private const USING_CACHED:String   = "Cached Texture (Touch to Start)";
        private const ERROR:String          = "ERROR Loading Texture (Touch to Retry)";
        private const HTTP_FAIL             = "FAILED HTTP LOAD (Touch to Retry)";

        private var _sprite:Image;
        private var _label:SimpleLabel;
        private var _name:SimpleLabel;
        private var _texBase:String;

        private var _curImage:int = 0;
        private var _origTex:Texture;
        private var _startTime:int;
        private var _go:Boolean = false;
        private var _httpTextureURLs:Vector.<String> = null;

        private static var _textureCache:Dictionary.<Texture, int> = new Dictionary.<Texture, int>();


        public function TexBox(texPath:String, stage:Stage, x:int, y:int)
        {
            _texBase = texPath;
        
            //image
            _sprite = new Image(AsyncImageExample.DefaultTex);
            _origTex = _sprite.texture;
            _sprite.center();
            _sprite.x = x + _sprite.width / 2;
            _sprite.y = y + _sprite.height / 2;
            _sprite.touchable = true;
            stage.addChild(_sprite);

            //label
            _label = new SimpleLabel("assets/fonts/Curse-hd.fnt", stage.stageWidth, 64);            
            _label.x = _sprite.x - (stage.stageWidth / 8);
            _label.y = _sprite.y + (_sprite.height / 2 + 10);
            _label.scale = 0.25;
            _label.text = NOT_LOADED;
            _label.touchable = false;
            stage.addChild(_label);

            //name
            _name = new SimpleLabel("assets/fonts/Curse-hd.fnt", stage.stageWidth, 256);            
            _name.x = _sprite.x - (stage.stageWidth / 8);
            _name.y = _sprite.y - (_sprite.height / 2 + 80);
            _name.scale = 0.25;            
            _name.text = _origTex.textureInfo.path;
            _name.touchable = false;
            stage.addChild(_name);

            //listen to touch events
            _sprite.addEventListener(TouchEvent.TOUCH, onTouch);

            //request Flickr image URLS
            AsyncImageExample.requestFlickrImageURLs(NUM_IMAGES, flickrImagesStore);
        }


        //called when there is a new list of Flickr image URLs to use
        private function flickrImagesStore(imageURLs:Vector.<String>):void
        {
            if(imageURLs != null)
            {
                _httpTextureURLs = imageURLs;
            }
        }


        //sets the new texture for our image
        private function setTexture(tex:Texture, text:String):void
        {
            //add new texture to the cache
            if(_textureCache[tex] == null)
            {
                _textureCache[tex] = 0;
            }
            _textureCache[tex]++;

            //dispose old tex?
            if((_sprite.texture != null) && (_sprite.texture != AsyncImageExample.DefaultTex))
            {
                _textureCache[_sprite.texture]--;
                if(_textureCache[_sprite.texture] == 0)
                {
                    _textureCache.deleteKey(_sprite.texture);
                    _sprite.texture.dispose();
                }
            }

            //scale to base image size 
            _sprite.scaleX = _sprite.width / tex.width;
            _sprite.scaleY = _sprite.height / tex.height;

            //set texture
            _sprite.texture = tex;
            _sprite.center();

            //update labels
            _label.text = text;
            _name.text = (tex as ConcreteTexture).assetPath;
        }


        //requests a new async texture load
        private function requestAsyncTex():void
        {
            var texToLoad:String = null;         
            var newTex:Texture = null;   

            _startTime = Platform.getTime();
            if(AsyncImageExample.LoadFromHTTP && (_httpTextureURLs != null))
            {
                //load from HTTP
                texToLoad = _httpTextureURLs[_curImage];
                newTex = Texture.fromHTTP(texToLoad, asyncLoadCompleteCB, httpLoadFailureCB, false);
            }
            else
            {
                //load from disk
                texToLoad = _texBase + _curImage + ".png";
                newTex = Texture.fromAssetAsync(texToLoad, asyncLoadCompleteCB);                
            }

            //wrap image
            if(++_curImage == NUM_IMAGES)
            {
                _curImage = 0;

                //repopulate the image list
                AsyncImageExample.requestFlickrImageURLs(NUM_IMAGES, flickrImagesStore);
            }  

            if(newTex == null)
            {
                _label.text = ERROR;
                _go = false;
            }
            else
            {
                if(newTex.isTextureValid())
                {
                    setTexture(newTex, USING_CACHED);
                    _go = false;
                }
                else
                {
                    //note that we've started async loading...
                    _label.text = (AsyncImageExample.LoadFromHTTP) ? LOADING_HTTP : LOADING_DISK;
                }
            }
        }


        //called when a texture completes async loading
        private function asyncLoadCompleteCB(texture:Texture):void
        {
            setTexture(texture, LOADED + ": " + (Platform.getTime() - _startTime) + "ms");

            //again!
            if(_go)
            {
                requestAsyncTex();
            }
        }


        //called on HTTP texture load failure
        private function httpLoadFailureCB():void
        {
            trace("Failed to load texture via HTTP...");
            _label.text = HTTP_FAIL;
        }        


        //touch input to start/stop image loading
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

        private var _polySprite:Image;
        private var _polySpeed:Point = new Point(200, 200);

        private var _loadTypeButton:SimpleButton;
        private var _loadTypeLabel:SimpleLabel;

        public static var LoadFromHTTP:Boolean = false;
        public static var DefaultTex:Texture = null;
        static private var _httpRequestCache:Vector.<HTTPRequest> = [];


        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            //load permanent default texture
            DefaultTex = Texture.fromAsset("assets/default.png");

            //bouncing poly so we can feel the performance
            _polySprite = new Image(Texture.fromAsset("assets/logo.png"));
            _polySprite.center();
            _polySprite.x = stage.stageWidth / 2;
            _polySprite.y = stage.stageHeight / 2;
            _polySprite.touchable = false;
            stage.addChild(_polySprite);    

            //button & label to toggle the load type with
            _loadTypeButton = new SimpleButton();
            _loadTypeButton.scaleX = 0.8;
            _loadTypeButton.scaleY = 0.4;
            _loadTypeButton.center();
            _loadTypeButton.x = (stage.stageWidth - _loadTypeButton.width) / 2;
            _loadTypeButton.y = stage.stageHeight - _loadTypeButton.height - 64;
            _loadTypeButton.upImage = "assets/up.png";
            _loadTypeButton.downImage = "assets/down.png";
            _loadTypeButton.onClick +=  function() { LoadFromHTTP = !LoadFromHTTP; _loadTypeLabel.text = (LoadFromHTTP) ? "HTTP Load" : "Asset Load";};
            stage.addChild(_loadTypeButton);

            _loadTypeLabel = new SimpleLabel("assets/fonts/Curse-hd.fnt", 256, 64);            
            _loadTypeLabel.x = _loadTypeButton.x - 16;
            _loadTypeLabel.y = _loadTypeButton.y;
            _loadTypeLabel.scale = 0.5;
            _loadTypeLabel.touchable = false;
            _loadTypeLabel.text = (LoadFromHTTP) ? "HTTP Load" : "Asset Load";
            stage.addChild(_loadTypeLabel);

            //add FPS output to the app
            _fps = new SimpleLabel("assets/fonts/Curse-hd.fnt", 256, 64);            
            _fps.x = stage.stageWidth - 80;
            _fps.y = 10;
            _fps.scale = 0.25;
            _fps.touchable = false;
            stage.addChild(_fps);

            //create the texture load boxes
            var top:int = 128;
            var left:int = 32;
            var gap:int = 16;
            _textureA = new TexBox("assets/stream1/img_", stage, left, top);
            _textureC = new TexBox("assets/stream2/img_", stage, 300+left+gap, top);
            _textureB = new TexBox("assets/stream3/img_", stage, 600+left+(gap*2), top);
        }


        //called once per tick to update all the things
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

            //update our bouncing poly
            updatePoly();

            //tick super
            super.onTick();
        }


        //udpates the bounding Poly around the screen so we can see framerate hitches
        private function updatePoly():void
        {
            ///update the app DT
            var timeManager:TimeManager = LoomGroup.rootGroup.getManager(TimeManager) as TimeManager;
            var dt:Number = timeManager.deltaTime;

            //bounce poly around the screen
            _polySprite.x += _polySpeed.x * dt;
            _polySprite.y += _polySpeed.y * dt;

            //check for collision with bounds
            //X
            if(_polySprite.x >= stage.stageWidth)
            {
                _polySprite.x = (2 * stage.stageWidth) - _polySprite.x;
                _polySpeed.x *= -1.0;
            }
            else if(_polySprite.x <= 0)
            {
                _polySprite.x *= -1;
                _polySpeed.x *= -1.0;
            }

            //Y
            if(_polySprite.y >= stage.stageHeight)
            {
                _polySprite.y = (2 * stage.stageHeight) - _polySprite.y;
                _polySpeed.y *= -1.0;
            }
            else if(_polySprite.y <= 0)
            {
                _polySprite.y *= -1;
                _polySpeed.y *= -1.0;
            }
        }


        //reqeusts a lists of Flickr image URLs to use as HTTP texture sources
        static public function requestFlickrImageURLs(count:int, func:Function)
        {
            var perPage = count + "";
            var request:HTTPRequest = new HTTPRequest("https://api.flickr.com/services/rest/?method=flickr.photos.getRecent&api_key=b24b3f28e764fe0b41d38b7ed4cc64d1&per_page=" + perPage + "&page=1&format=json&nojsoncallback=1");
            request.method = "GET";
            request.onSuccess += function(str:String)
                                 {
                                    _httpRequestCache.remove(request);
                                    var imageUrls:Vector.<String> = [];
                                    var json = new JSON();
                                    json.loadString(str);

                                    var photos:JSON = json.getObject("photos").getArray("photo");
                                    for (var i = 0; i < photos.getArrayCount(); i++)
                                    {
                                        var photo:JSON = photos.getArrayObject(i);
                                        var farmId = photo.getInteger("farm");
                                        var serverId = photo.getString("server");
                                        var id = photo.getString("id");
                                        var secret = photo.getString("secret");
                                        var url = "https://farm" + farmId + ".staticflickr.com/" + serverId + "/" + id + "_" + secret + ".jpg";
                                        imageUrls.pushSingle(url);
                                    }
                                    func(imageUrls);
                                 };
            request.onFailure += function(str:String) { trace("Flickr ERROR: " + str); _httpRequestCache.remove(request); func(null); };
            request.send();
            _httpRequestCache.pushSingle(request);
        }
    }
}