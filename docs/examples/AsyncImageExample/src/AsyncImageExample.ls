package
{

    import loom.Application;    
    import loom.platform.Timer;    
    import loom.gameframework.LoomGroup;    
    import loom.gameframework.TimeManager;    
    import loom2d.display.Stage;
    import loom2d.math.Point;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;    
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.display.AsyncImage;   
    import loom2d.display.MovieClip;    
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

        private var _sprite:AsyncImage;
        private var _label:SimpleLabel;
        private var _name:SimpleLabel;
        private var _priorityLabel:SimpleLabel;
        private var _texBase:String;

        private var _curImage:int = 0;
        private var _lastTexture:Texture;
        private var _newTex:Texture;
        private var _startTime:int;
        private var _go:Boolean = false;
        private var _priority:Boolean = false;
        private var _requestTimer:Timer = null;
        private var _httpTextureURLs:Vector.<String> = null;

        private static var _textureCache:Dictionary.<Texture, int> = new Dictionary.<Texture, int>();


        public function TexBox(texPath:String, stage:Stage, x:int, y:int)
        {
            _texBase = texPath;
        
            //image
            _sprite = new AsyncImage(AsyncImageExample.LoadingAnim, null, 256, 256);
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
            _name.y = _sprite.y - ((_sprite.height / 2) + 56);
            _name.scale = 0.25;            
            _name.text = "...";
            _name.touchable = false;
            stage.addChild(_name);

            //priority button & label
            var priorityButton:SimpleButton = new SimpleButton();
            priorityButton.scaleX = 0.4;
            priorityButton.scaleY = 0.2;
            priorityButton.center();
            priorityButton.x = _sprite.x - (priorityButton.width / 2);
            priorityButton.y = _sprite.y - ((_sprite.height + priorityButton.width) / 2) - 48;
            priorityButton.upImage = "assets/up.png";
            priorityButton.downImage = "assets/down.png";
            priorityButton.onClick +=  function() { _priority = !_priority; _priorityLabel.text = (_priority) ? "High Priority" : "Low Priority";};
            stage.addChild(priorityButton);

            _priorityLabel = new SimpleLabel("assets/fonts/Curse-hd.fnt", 256, 64);            
            _priorityLabel.x = priorityButton.x - 8;
            _priorityLabel.y = priorityButton.y;
            _priorityLabel.scale = 0.25;
            _priorityLabel.touchable = false;
            _priorityLabel.text = (_priority) ? "High Priority" : "Low Priority";
            stage.addChild(_priorityLabel);

            //listen to touch events
            _sprite.addEventListener(TouchEvent.TOUCH, onTouch);

            //request Flickr image URLS
            AsyncImageExample.requestFlickrImageURLs(NUM_IMAGES, flickrImagesStore);

            //start up the cache
            _lastTexture = _sprite.texture;          
            if(_textureCache[_lastTexture] == null)
            {
                //start at 1 because we never want this texture to be destroyed...
                _textureCache[_lastTexture] = 1;
            }
            _textureCache[_lastTexture]++;  

            //timer to delay the auto-loads 
            _requestTimer = new Timer(500);
            _requestTimer.onComplete += requestAsyncTex;            
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
        private function updateTexture(tex:Texture, text:String):void
        {
            //add new texture to the cache
            if(tex != _lastTexture)
            {
                if(_textureCache[tex] == null)
                {
                    _textureCache[tex] = 0;
                }
                _textureCache[tex]++;

                //dispose old tex?
                if(_lastTexture != null)
                {
                    _textureCache[_lastTexture]--;
                    if(_textureCache[_lastTexture] == 0)
                    {
                        _textureCache.deleteKey(_lastTexture);
                        _lastTexture.dispose();
                    }
                }
                _lastTexture = tex;
            }

            //update labels
            _label.text = text;
            _name.text = (tex as ConcreteTexture).assetPath;
        }


        //requests a new async texture load
        private function requestAsyncTex(timer:Timer=null):void
        {
            var texToLoad:String = null;         

            _startTime = Platform.getTime();
            if(AsyncImageExample.LoadFromHTTP && (_httpTextureURLs != null))
            {
                //load from HTTP
                texToLoad = _httpTextureURLs[_curImage];
                _newTex = _sprite.loadTextureFromHTTP(texToLoad, asyncLoadCompleteCB, httpLoadFailureCB, false, _priority);
            }
            else
            {
                //load from disk
                texToLoad = _texBase + _curImage + ".png";
                _newTex = _sprite.loadTextureFromAsset(texToLoad, asyncLoadCompleteCB, _priority);                
            }

            //wrap image
            if(++_curImage == NUM_IMAGES)
            {
                _curImage = 0;

                //repopulate the Flickr image list
                AsyncImageExample.requestFlickrImageURLs(NUM_IMAGES, flickrImagesStore);
            }  

            if(_newTex == null)
            {
                _label.text = ERROR;
                _go = false;
            }
            else
            {
                if(_newTex.isTextureValid())
                {
                    updateTexture(_newTex, USING_CACHED);
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
            updateTexture(texture, LOADED + ": " + (Platform.getTime() - _startTime) + "ms");

            //again!
            if(_go)
            {
                _requestTimer.start();
            }
        }


        //called on HTTP texture load failure
        private function httpLoadFailureCB(texture:Texture):void
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
                else
                {
                    _sprite.cancelHTTPLoad();
                    _label.text = NOT_LOADED;
                    _requestTimer.stop();
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

        private var _loadTypeLabel:SimpleLabel;

        public static var LoadFromHTTP:Boolean = false;
        public static var LoadingAnim:MovieClip = null;
        static private var _httpRequestCache:Vector.<HTTPRequest> = [];


        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            //create permanent loading movieclip to use
            LoadingAnim = MovieClip.fromSpritesheet("assets/loadanim.png", 60, 60, 30, 5, 12);

            //bouncing poly so we can feel the performance
            _polySprite = new Image(Texture.fromAsset("assets/logo.png"));
            _polySprite.center();
            _polySprite.x = stage.stageWidth / 2;
            _polySprite.y = stage.stageHeight / 2;
            _polySprite.touchable = false;
            stage.addChild(_polySprite);    

            //button & label to toggle the load type with
            var typeButton:SimpleButton = new SimpleButton();
            typeButton.scaleX = 0.8;
            typeButton.scaleY = 0.4;
            typeButton.center();
            typeButton.x = (stage.stageWidth - typeButton.width) / 2;
            typeButton.y = stage.stageHeight - typeButton.height - 64;
            typeButton.upImage = "assets/up.png";
            typeButton.downImage = "assets/down.png";
            typeButton.onClick +=  function() { LoadFromHTTP = !LoadFromHTTP; _loadTypeLabel.text = (LoadFromHTTP) ? "HTTP Load" : "Asset Load";};
            stage.addChild(typeButton);

            _loadTypeLabel = new SimpleLabel("assets/fonts/Curse-hd.fnt", 256, 64);            
            _loadTypeLabel.x = typeButton.x - 16;
            _loadTypeLabel.y = typeButton.y;
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
            var apiKey = "cd563a32f84911cc06cab523db607bae";
            var request:HTTPRequest = new HTTPRequest("https://api.flickr.com/services/rest/?method=flickr.photos.getRecent&api_key=" + apiKey + "&per_page=" + perPage + "&page=1&format=json&nojsoncallback=1");
            request.method = "GET";
            request.onSuccess += function(str:String)
                                 {
                                    _httpRequestCache.remove(request);
                                    var imageUrls:Vector.<String> = null;
                                    var json = new JSON();
                                    json.loadString(str);

                                    var photosObj:JSON = json.getObject("photos");
                                    if(photosObj != null)
                                    {                                    
                                        var photos:JSON = photosObj.getArray("photo");
                                        if(photos)
                                        {
                                            imageUrls = new Vector.<String>();
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
                                        }
                                    }
                                    else
                                    {
                                        var errorCode:int = json.getInteger("code");
                                        var errorMessage:String = json.getString("message");
                                        trace("ERROR! Flickr API call failed with code: " + errorCode + " and message: " + errorMessage);
                                    }
                                    func(imageUrls);
                                 };
            request.onFailure += function(str:String) { trace("Flickr ERROR: " + str); _httpRequestCache.remove(request); func(null); };
            request.send();
            _httpRequestCache.pushSingle(request);
        }
    }
}