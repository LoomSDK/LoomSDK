package
{

    import system.platform.Platform;
    import loom.Application;

    import loom.animation.LoomTween;
    import loom.gameframework.ITicked;
    import loom.gameframework.TimeManager;    

    import loom2d.math.Point;
    
    import loom2d.display.Sprite;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.textures.SubTexture;
    import loom2d.display.StageScaleMode;

    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;    


    import loom2d.ui.TextureAtlasManager;
    import loom2d.ui.TextureAtlasSprite;
    import loom2d.ui.SimpleLabel;

    public class IsometricAtlasSprite extends TextureAtlasSprite
    {
        public var waitCount:int = 15;
        public var velX:Number = 1;
        public var velY:Number = 1;
        public var posX:Number = 15 * 90;
        public var posY:Number = 15 * 90;
        public var texPrefix:String = null;

        public function setIsometricPosition(_x:int, _y:int):void
        {
            x = _x;
            y = _y;

            depth = (_y * 10000) - x;
        }

        public function set isoX(_value:int):void
        {
            setIsometricPosition(_value, y);
        }

        public function get isoX():Number
        {
            return x;
        }

        public function set isoY(_value:int):void
        {
            setIsometricPosition(x, _value);
        }

        public function get isoY():Number
        {
            return y;
        }
    }    

    public class IsoVille extends Application implements ITicked
    {
        public var sceneRootNode:Sprite;
        public var backgroundNode:Image;

        public var wanderers:Vector.<IsometricAtlasSprite> = new Vector.<IsometricAtlasSprite>();

        public var minViewX:int, maxViewX:int, minViewY:int, maxViewY:int;

        override public function run():void
        {

            stage.scaleMode = StageScaleMode.LETTERBOX;

            TextureAtlasManager.register("atlas", "assets/atlas.xml");

            backgroundNode = new Image(Texture.fromAsset("assets/background.png"));
            backgroundNode.x = -2048;
            backgroundNode.y = -2048;
            backgroundNode.scale = 4096;
            stage.addChild(backgroundNode);

            sceneRootNode = new Sprite();
            sceneRootNode.depthSort = true;
            stage.addChild(sceneRootNode);

            minViewX = 1000000;
            maxViewX = -1000000;
            minViewY = 1000000;
            maxViewY = -1000000;

            for(var i:int = 0; i<25; i++)
            {
                for(var j:int = 0; j<25; j++)
                {
                    var sprite = new IsometricAtlasSprite();
                    sprite.atlasName = "atlas";
                    sprite.textureName = "" + (Math.floor(Math.random() * 5) + 1) + ".png";

                    sceneRootNode.addChild(sprite);

                    sprite.pivotX = sprite.width/2;
                    sprite.pivotY = sprite.height/2;

                    sprite.pivotY += sprite.height/10;
                    
                    //setAnchorPoint(new CCPoint(0.5, 0.1));

                    sprite.scale = 2.0;

                    sprite.setIsometricPosition( (i+j) * 90, (i-j) * 90);

                    // Note the x/y position for clamping the view.
                    if(sprite.x < minViewX) minViewX = sprite.x;
                    if(sprite.x > maxViewX) maxViewX = sprite.x;
                    if(sprite.y < minViewY) minViewY = sprite.y;
                    if(sprite.y > maxViewY) maxViewY = sprite.y;
                }
            }

            for(var k:int = 0; k<25; k++)
            {
                var wander = new IsometricAtlasSprite();
                wander.atlasName = "atlas";
                wander.textureName = "grey_walk_west0018.png";

                wander.center();

                //wander.setAnchorPoint(new CCPoint(0.5, 0.5));
                //wander.pivotX = wander.width/2;
                //wander.pivotY = wander.height/2;                    

                wander.setIsometricPosition(500, 0);

                sceneRootNode.addChild(wander);
                wanderers.pushSingle(wander);
            }

            sceneRootNode.x = -2000;
            sceneRootNode.y = 0;

            stage.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 

                var point:Point;
                var touch = e.getTouch(stage, TouchPhase.BEGAN);

                if (touch)
                {
                    point = touch.getLocation(stage);
                    dragStart(touch.id, point.x, point.y);
                }

                touch = e.getTouch(stage, TouchPhase.MOVED);
                if (touch)
                {
                    point = touch.getLocation(stage);
                    dragMover(touch.id, point.x, point.y);
                }                

                touch = e.getTouch(stage, TouchPhase.ENDED);
                if (touch)
                {
                    point = touch.getLocation(stage);
                    dragEnd(touch.id, point.x, point.y);
                }                

            } );            

        }

        public var dragStartTouchX:Number, dragStartTouchY:Number;
        public var dragStartNodeX:Number, dragStartNodeY:Number;
        public var dragLastX:Number, dragLastY:Number;
        public var dragVerletX1:Number, dragVerletY1:Number, dragVerletTime:Number;
        public var dragVerletX2:Number, dragVerletY2:Number;
        public var pinchLastX:Number, pinchLastY:Number;
        public var pinchStartLength:Number, pinchOriginalScale:Number, pinchTouchId:int = -1;
        public var pinchOffsetX:Number, pinchOffsetY:Number;
        public var dragTouchId = -1;

        public function dragStart(touchId:int, x:Number, y:Number):void
        {
            if(dragTouchId == -1)
            {
                // Start dragging.
                dragTouchId = touchId;

                dragStartTouchX = x;
                dragStartTouchY = y; 

                dragStartNodeX = sceneRootNode.x;
                dragStartNodeY = sceneRootNode.y;
                
                dragLastX = x;
                dragLastY = y;

                dragVerletTime = Platform.getTime();

                dragVerletX1 = dragStartNodeX + x;
                dragVerletY1 = dragStartNodeY + y;
                dragVerletX2 = dragStartNodeX + x;
                dragVerletY2 = dragStartNodeY + y;
            }
            else if(pinchTouchId == -1)
            {
                // Start pinching.
                pinchTouchId = touchId;

                pinchOriginalScale = sceneRootNode.scale;
                pinchStartLength = Math.sqrt((x - dragStartTouchX) * (x - dragStartTouchX)+ (y - dragStartTouchY) * (y - dragStartTouchY));

                pinchLastX = x;
                pinchLastY = y;
            }
        }

        public function dragMover(touchId:int, x:Number, y:Number):void
        {
            // Update the state of the pinch or drag points.
            if(touchId == pinchTouchId)
            {
                pinchLastX = x;
                pinchLastY = y;
            } 
            else if(touchId == dragTouchId)
            {
                dragLastX = x;
                dragLastY = y;
            }

            if(pinchTouchId == -1)
            {
                // If we are dragging and not pinching...
                if(dragTouchId != -1)
                {
                    // Update our Verlet velocity for flicking.
                    if(true)
                    {
                        dragVerletX1 = dragVerletX2;
                        dragVerletY1 = dragVerletY2;

                        dragVerletX2 = dragStartNodeX + (x - dragStartTouchX);
                        dragVerletY2 = dragStartNodeY + (y - dragStartTouchY);

                        // Cap the verlet velocity in screen coordinates.
                        var absXCap = (stage.stageWidth) * 0.1;
                        var absYCap = (stage.stageHeight) * 0.1;
                        var maxLength = (absXCap + absYCap);

                        var driftX = dragVerletX2 - dragVerletX1;
                        var driftY = dragVerletY2 - dragVerletY1;

                        var actualLength = Math.sqrt(driftX * driftX + driftY * driftY + 1);
                        var normalizeFactor = actualLength / maxLength;
                        if(normalizeFactor > 1)
                        {
                            if(normalizeFactor < 10)
                            {
                                //Console.print("normalizing due to actualLength=" + actualLength + " nf=" + normalizeFactor + " max=" + maxLength);
                                driftX = driftX / normalizeFactor;
                                driftY = driftY / normalizeFactor;
                            }
                            else
                            {
                                //Console.print("cancelling due to actualLength=" + actualLength + " nf=" + normalizeFactor + " >10" + " max=" + maxLength);
                                driftX = dragVerletX2 - dragVerletX1;
                                driftY = dragVerletY2 - dragVerletY1;
                            }
                        }

                        dragVerletX2 = dragVerletX1 + driftX;
                        dragVerletY2 = dragVerletY1 + driftY;
                    }

                    // Just dragging, so update position.
                    sceneRootNode.x = dragStartNodeX + (x - dragStartTouchX);
                    sceneRootNode.y = dragStartNodeY + (y - dragStartTouchY);
                }
            }
            else
            {
                // Otherwise, we're pinching (scaling).
                var curLength = Math.sqrt(
                      (pinchLastX - dragLastX) * (pinchLastX - dragLastX)
                    + (pinchLastY - dragLastY) * (pinchLastY - dragLastY));

                var scaleFactor = (curLength / pinchStartLength);

                sceneRootNode.scale = scaleFactor * pinchOriginalScale;

                var halfWidth = stage.stageWidth * 0.5;
                var halfHeight = stage.stageHeight * 0.5;

                sceneRootNode.x = (dragStartNodeX - halfWidth) * scaleFactor + halfWidth;
                sceneRootNode.y = (dragStartNodeY - halfHeight) * scaleFactor + halfHeight;

            }
        }

        public function dragEnd(touchId:int, x:Number, y:Number):void
        {
            //Console.print("Touch end, inertia is: " + (dragVerletX2 - dragVerletX1) + ", " + (dragVerletY2 - dragVerletY1) + " pos=" + sceneRootNode.getPositionX() + ", " + sceneRootNode.getPositionY());

            dragTouchId = -1;
            pinchTouchId = -1;
        }

        public function onTick():void
        {
            // Apply drift if appropriate.
            if(dragTouchId == -1 && pinchTouchId == -1)
            {
                var driftX = dragVerletX2 - dragVerletX1;
                var driftY = dragVerletY2 - dragVerletY1;
                dragVerletX2 = dragVerletX1 + driftX * 0.9;
                dragVerletY2 = dragVerletY1 + driftY * 0.9;

                var newPosX = sceneRootNode.x + driftX;
                var newPosY = sceneRootNode.y + driftY;

                // Clamp to be in range of buildings so we don't fly off into
                // infinity.
                var widthOffset = (stage.stageWidth * 0.5);
                var heightOffset = (stage.stageHeight * 0.5);

                newPosX = Math.clamp(newPosX / sceneRootNode.scale, -(maxViewX - widthOffset), -(minViewX - widthOffset)) * sceneRootNode.scale;
                newPosY = Math.clamp(newPosY / sceneRootNode.scale, -(maxViewY - heightOffset), -(minViewY - heightOffset)) * sceneRootNode.scale;

                sceneRootNode.x = newPosX;
                sceneRootNode.y = newPosY;
            }


            // Move the wanderers around.
            for(var i:int=0; i<25; i++)
            {
                var wander = wanderers[i];
                wander.waitCount = wander.waitCount - 1;
                if(wander.waitCount > 0)
                {
                    // Set the frame.
                    if(wander.texPrefix != null)
                    {
                        var curFrame = wander.waitCount % 20;
                        if(curFrame < 10)
                            wander.textureName = wander.texPrefix + "000" + curFrame + ".png";
                        else
                            wander.textureName = wander.texPrefix + "00" + curFrame + ".png"; 
                    } 

                    wander.posX = wander.posX + wander.velX;
                    wander.posY = wander.posY + wander.velY;

                    // NOTE: Due to using cocos2d's Z-sorting, this is the slowest part
                    // of the demo. A more optimized iso sort would allow you to have
                    // many many more sprites on screen. Note that perf here is proportional
                    // to total sprites in the iso sort, not the number of wanderers.
                    wander.setIsometricPosition((wander.posX + wander.posY) - 25, (wander.posX - wander.posY) + 110);
                }
                else
                {
                    var speed = Math.floor((Math.random() * 2) + 1);
                    if(Math.random () > 0.5)
                    {
                        if(Math.random() > 0.5)
                        {
                            wander.texPrefix = "grey_walk_north";
                            wander.velX = speed;
                            wander.velY = 0;
                        }
                        else
                        {
                            wander.texPrefix = "grey_walk_east";
                            wander.velX = 0;
                            wander.velY = speed;
                        }
                    }
                    else
                    {
                        if(Math.random() > 0.5)
                        {
                            wander.texPrefix = "grey_walk_south";
                            wander.velX = -speed;
                            wander.velY = 0;
                        }
                        else
                        {
                            wander.texPrefix = "grey_walk_west";
                            wander.velX = 0;
                            wander.velY = -speed;
                        }           
                    }

                    wander.waitCount = 90 / speed;
                }
            }
        }
    }
}