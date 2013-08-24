package
{
    import loom2d.display.Cocos2DGame;
    import loom2d.display.Cocos2D;
    import loom2d.display.CCLayer;
    import cocos2d.CCSprite;
    import cocos2d.CCScene;
    import cocos2d.CCScaledLayer;
    import cocos2d.ScaleMode;
    import cocos2d.CCTMXTiledMap;
    import cocos2d.CCTMXObjectGroup;
    import cocos2d.CCSpriteFrameCache;
    import cocos2d.CCDictionary;
    import cocos2d.CCArray;

    import loom.gameframework.AnimatedComponent;
    import loom.gameframework.LoomComponent;
    import loom.gameframework.LoomGroup;
    import loom.gameframework.LoomGameObject;

    import UI.Label;

    /** 
     * Manage state related to the current level, tilemap, etc.
     */
    public class PlatformerLevel extends CCScaledLayer
    {

        public var tmxFile:String;
        public var map:CCTMXTiledMap;

        public var game:Cocos2DGame;
        public var group:LoomGroup;

        protected var scene:CCScene;

        // Everything that scrolls gets added to the foreground
        public var fgLayer:CCLayer;
        public var bgLayer:CCLayer;

        public var trackObject:CCSprite;

        public var moverManager:PlatformerMoverManager = new PlatformerMoverManager();

        public function getScene():CCScene
        {
            return scene;
        }

        // Constructor
        public function PlatformerLevel( gameInstance:Cocos2DGame, tmxFileName:String )
        {
            scaleMode = ScaleMode.FILL;
            designWidth = 720;
            designHeight = 480;

            tmxFile = tmxFileName;
            game = gameInstance;
            group = game.group;

            scene = CCScene.create();
            scene.addChild(this);

            // Parallaxed stuff gets added to the background
            bgLayer = CCLayer.create();
            addChild(bgLayer);

            // Everything that scrolls gets added to the foreground
            fgLayer = CCLayer.create();
            addChild(fgLayer);

            // Initialize everything that goes into the view
            map = CCTMXTiledMap.tiledMapWithTMXFile(tmxFile);
            map.reload = onMapReload;

            // Turn on collision for foreground and background layers.
            setLayerCollisionActive("bg", true);
            var collisionLayer = map.layerNamed("collision");
            if(collisionLayer)
            {
                collisionLayer.setVisible(false);
            }
            setLayerCollisionActive("fg", true);

            // Configure tile collision types. See PlatformerMoverManager
            // for the specific types. One character per tile in the map.
            setTileCollisions(
                "X^......hH" +
                "^X......vV" +
                "........12" +
                "........34" +
                "XXXX......" +
                "XXXX......" +
                "....XX.X.." +
                "....XX...." +
                "XXXXXXX^^^" +
                "XXXXXXX^.." +
                ".........." +
                ".........." +
                ".........." +
                "......^..." +
                "XXXXX....." +
                "XXXXX....."
                );

            // Load map properties (namely: background images)
            var mapProps:CCDictionary = map.getProperties();

            var bgFile:String = mapProps.valueForKey("bg_far");
            if (bgFile != null)
            {
                var bgSprite:CCSprite = CCSprite.createFromFile(bgFile);
                bgSprite.x = 848 * 0.5;
                bgSprite.y = 480 * 0.5;

                bgLayer.addChild(bgSprite);
            }

            // Now that the background is loaded, add the map to ourselves 
            //  (keeping all of these sprites as a child of this scene, which is a CCNode)
            fgLayer.addChild(map);

            // Spawn all objects listed in the TMX
            var objGroups:CCArray = map.getObjectGroups();
            for (var groupCnt = 0; groupCnt < objGroups.count(); groupCnt++)
            {
                var objGroup:CCTMXObjectGroup = objGroups.objectAtIndex(groupCnt) as CCTMXObjectGroup;
                var objs:CCArray = objGroup.getObjects();
                for (var objCnt = 0; objCnt < objs.count(); objCnt++)
                {
                    var obj:CCDictionary = objs.objectAtIndex(objCnt) as CCDictionary;

                    var objType:String = obj.valueForKey("type");
                    var objName:String = obj.valueForKey("name");
                    var objX:int = obj.valueForKey("x").toNumber();
                    var objY:int = obj.valueForKey("y").toNumber();
                    var objW:int = obj.valueForKey("width").toNumber();
                    var objH:int = obj.valueForKey("height").toNumber();

                    objX += objW / 2;
                    objY += objH / 2;

                    Console.print(objType + " on map at (" + objX + ", " + objY + "), size (" + objW + ", " + objH + ")");
                    
                    var po = addPlatformerObject(objX, objY, objW, objH);
                    var rend = po.lookupComponentByName("renderer") as PlatformerRenderer;
                    var mover = po.lookupComponentByName("mover") as PlatformerMover;

                    if (objType == "player")
                    {
                        var controller = new PlatformerController(mover);
                        rend.addBinding("texture", "@controller.spriteFrame");
                        rend.addBinding("scaleX", "@controller.scaleX");
                        rend.addBinding("scaleY", "@controller.scaleY");
                        po.addComponent(controller, "controller");
                        mover.objectMask = 0x01;
                        mover.collidesWithObjectMask = 0xff;
                    }
                    else if (objType == "crate_sm")
                    {
                        var crateControllerSm = new PlatformerCrateController(mover);
                        rend.texture = "crate_sm.png";
                        mover.objectMask = 0x02;
                        mover.collidesWithObjectMask = 0xff;
                        po.addComponent(crateControllerSm, "controller");
                    }
                    else if (objType == "crate_lg")
                    {
                        var crateControllerLg = new PlatformerCrateController(mover);
                        rend.texture = "crate_lg.png";
                        mover.objectMask = 0x02;
                        mover.collidesWithObjectMask = 0xff;
                        po.addComponent(crateControllerLg, "controller");
                    }
                }
            }

        }

        public function setTileCollisions( formatString:String ):void
        {
            moverManager.setTileCollisions(formatString);
        }

        public function setLayerCollisionActive( layerName:String, layerActive:Boolean )
        {
            var layer = map.layerNamed(layerName);

            if (layer == null)
            {
                trace ("ERROR: Could not find layer '" + layerName + "' to set collision active");
                return;
            }

            if (layerActive)
            {
                if (!moverManager.collisionLayers.contains(layer))
                {
                    moverManager.collisionLayers.push(layer);
                }
            }
            else
            {
                if (moverManager.collisionLayers.contains(layer))
                {
                    moverManager.collisionLayers.remove(layer);
                }
            }
        }

        protected function onMapReload():void
        {
            // Anything that needs to happen on a map live reload can go here
            moverManager.collisionLayers.clear();
            setLayerCollisionActive("bg", true);
        }

        public function addPlatformerObject(x:int, y:int, w:int, h:int):LoomGameObject
        {
            var po = new LoomGameObject();
            var spriteName:String = "block32.png";

            var solidSizeX:int = w;
            var solidSizeY:int = h;

            var rend = new PlatformerRenderer(spriteName, fgLayer);
            var mover = new PlatformerMover(x, y, this.moverManager);

            mover.solidSizeX = solidSizeX;
            mover.solidSizeY = solidSizeY;

            rend.addBinding("x", "@mover.positionX");
            rend.addBinding("y", "@mover.positionY");

            po.addComponent(rend, "renderer");
            po.addComponent(mover, "mover");

            po.initialize();

            if (trackObject == null)
                trackObject = rend.sprite;

            return po;
        }
    }
}