package
{
	import loom2d.tmx.TMXMapSprite;
	import loom2d.tmx.TMXDocument;
	import loom2d.display.DisplayObject;
	import loom2d.display.Image;
    import loom2d.tmx.TMXMapSprite;
    import loom2d.tmx.TMXDocument;
    import loom2d.tmx.TMXLayer;
    import loom2d.tmx.TMXRectangle;
    import loom2d.tmx.TMXObject;
    import loom2d.tmx.TMXObjectGroup;
	import loom2d.display.Sprite;
	import loom2d.textures.Texture;
	
    import loom.Application;
    
    import loom.gameframework.AnimatedComponent;
    import loom.gameframework.LoomComponent;
    import loom.gameframework.LoomGroup;
    import loom.gameframework.LoomGameObject;

    /** 
     * Manage state related to the current level, tilemap, etc.
     */
    public class PlatformerLevel extends Sprite
    {

        public var tmxFile:String;
        public var map:TMXMapSprite;
        public var tmxDocument:TMXDocument;

        public var game:Application;
        public var group:LoomGroup;

        protected var scene:Sprite;

        // Everything that scrolls gets added to the foreground
        public var fgLayer:Sprite;
        public var bgLayer:Sprite;

        public var trackObject:DisplayObject;

        public var moverManager:PlatformerMoverManager = new PlatformerMoverManager();

        public function getScene():Sprite
        {
            return scene;
        }

        // Constructor
        public function PlatformerLevel( gameInstance:Application, tmxFileName:String )
        {
            tmxFile = tmxFileName;
            game = gameInstance;
            group = game.group;

            scene = new Sprite();
            scene.addChild(this);

            // Parallaxed stuff gets added to the background
            bgLayer = new Sprite();
            addChild(bgLayer);

            // Everything that scrolls gets added to the foreground
            fgLayer = new Sprite();
            addChild(fgLayer);

            // Initialize everything that goes into the view
            
            tmxDocument = new TMXDocument(tmxFile);
            tmxDocument.onTMXUpdated = onMapReload;
            map = new TMXMapSprite(tmxDocument);
            
            tmxDocument.load();

            // Turn on collision for foreground and background layers.
            setLayerCollisionActive("bg", true);
            
            var collisionLayer = map.getLayer("collision");
            if(collisionLayer)
            {
                collisionLayer.visible = false;
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
            var mapProps:Dictionary.<String, String> = tmxDocument.properties;

            var bgFile:String = mapProps["bg_far"];
            if (bgFile != null)
            {
                var bgSprite:Image = new Image(Texture.fromAsset(bgFile));
                bgSprite.center();
                bgSprite.x = 848 * 0.5;
                bgSprite.y = 480 * 0.5;
                bgLayer.addChild(bgSprite);
            }

            // Now that the background is loaded, add the map to ourselves 
            //  (keeping all of these sprites as a child of this scene, which is a CCNode)
            fgLayer.addChild(map);

            // Spawn all objects listed in the TMX
            var objGroups:Vector.<TMXObjectGroup> = tmxDocument.objectGroups;
            for (var groupCnt = 0; groupCnt < objGroups.length; groupCnt++)
            {
                var objGroup:TMXObjectGroup = objGroups[groupCnt];
                var objs:Vector.<TMXObject> = objGroup.objects;
                for (var objCnt = 0; objCnt < objs.length; objCnt++)
                {
                    var obj:TMXRectangle = objs[objCnt] as TMXRectangle;
                    if (!obj) continue;

                    var objType:String = obj.type;
                    var objName:String = obj.name;
                    var objX:int = obj.x;
                    var objY:int = obj.y;
                    var objW:int = obj.width;
                    var objH:int = obj.height;

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
            var layer = tmxDocument.getLayerByName(layerName);

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

        protected function onMapReload(file:String, tmx:TMXDocument):void
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

            var rend = new PlatformerRenderer("PlatformerSprites", spriteName, fgLayer);
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