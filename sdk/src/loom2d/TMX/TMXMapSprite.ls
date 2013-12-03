package loom2d.tmx
{
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.textures.Texture;
    import loom2d.textures.TextureAtlas;
    import system.xml.XMLDocument;

    public class TMXMapSprite extends Sprite
    {
        private var _tileWidth:Number;
        private var _tileHeight:Number;
        private var _orthogonal:Boolean;
        private var _isometric:Boolean;
        private var _tileAtlases:Vector.<TextureAtlas> = [];
        private var _layers:Dictionary.<String, Sprite> = {};
        private var _imageLayers:Dictionary.<String, Image> = {};

        public function TMXMapSprite(tmx:TMXDocument)
        {
            tmx.onTilesetParsed += onTilesetParsed;
            tmx.onLayerParsed += onLayerParsed;
            tmx.onImageLayerParsed += onImageLayerParsed;
            tmx.onTMXUpdated += onTMXUpdated;
        }

        public function getLayer(name:String):Sprite
        {
            return _layers[name];
        }

        public function getImageLayer(name:String):Image
        {
            return _imageLayers[name];
        }

        private function onTMXUpdated(file:String, tmx:TMXDocument):void
        {
            _tileAtlases.clear();
            _layers.clear();
            _imageLayers.clear();
            removeChildren();

            _tileWidth = tmx.tileWidth;
            _tileHeight = tmx.tileHeight;
            _orthogonal = tmx.orientation == "orthogonal";
            _isometric = tmx.orientation == "isometric";

        }

        private function onTilesetParsed(file:String, tileset:TMXTileset):void
        {
            // Atlas creation code borrowed from Loom's TMXTileSheet
            var texture = Texture.fromAsset(tileset.image.source);
            
            var numRows:int = Math.floor((texture.height - tileset.margin) / (tileset.tilewidth + tileset.spacing));
            var numCols:int = Math.floor((texture.width - tileset.margin) / (tileset.tileheight + tileset.spacing));
 
            var id:int = tileset.firstgid;

            var xml:XMLDocument = new XMLDocument;

            var atlas = xml.newElement("TextureAtlas");
            xml.insertEndChild(atlas);

            atlas.setAttribute("imagePath", tileset.image.source);
 
            for (var i:int = 0; i < numRows; i++)
            {
                for (var j:int = 0; j < numCols; j++)
                {
                    var subTexture = xml.newElement("SubTexture");

                    subTexture.setAttribute("name", String(id));
                    subTexture.setAttribute("x", String(tileset.margin + 0.5 + (j * tileset.tilewidth) + (j * tileset.spacing)));
                    subTexture.setAttribute("y", String(tileset.margin + 0.5 + (i * tileset.tileheight) + (i * tileset.spacing)));
                    subTexture.setAttribute("width", String(tileset.tilewidth - 0.5));
                    subTexture.setAttribute("height", String(tileset.tileheight - 0.5));

                    atlas.insertEndChild(subTexture);

                    id++;
                }
            }

            _tileAtlases.pushSingle(new TextureAtlas(texture, atlas));
        }

        private function onLayerParsed(file:String, layer:TMXLayer):void
        {
            var layerSprite:Sprite = new Sprite();

            const FLIPPED_HORIZONTALLY_FLAG:uint = 0x80000000;
            const FLIPPED_VERTICALLY_FLAG:uint = 0x40000000;
            const FLIPPED_DIAGONALLY_FLAG:uint = 0x20000000;
            var flipped_horizontally:Boolean = false;
            var flipped_vertically:Boolean = false;
            var flipped_diagonally:Boolean = false;

            var x:int = 0;
            var y:int = 0;
            var gid:uint = 0;
            for (y = 0; y < layer.height; ++y)
            {
                for (x = 0; x < layer.width; ++x)
                {
                    gid = layer.tiles[(y * layer.width) + x];

                    flipped_horizontally = (gid & FLIPPED_HORIZONTALLY_FLAG) != 0;
                    flipped_vertically = (gid & FLIPPED_VERTICALLY_FLAG) != 0;
                    flipped_diagonally = (gid & FLIPPED_DIAGONALLY_FLAG) != 0;
                    
                    gid &= ~(FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG | FLIPPED_DIAGONALLY_FLAG);
                    
                    var tileImage = imageFromGid(gid);
                    if (!tileImage)
                    {
                        continue;
                    }

                    if(_isometric)
                    {
                        tileImage.x = x * _tileWidth/2 - y * _tileWidth/2;
                        tileImage.y = x * _tileHeight/2 + y * _tileHeight/2;
                        
                        if(flipped_vertically && flipped_horizontally && flipped_diagonally)
                        {
                            //TODO
                        }
                        else if(flipped_vertically && flipped_horizontally)
                        {
                            //TODO   
                        }
                        else if(flipped_vertically && flipped_diagonally)
                        {
                            //TODO
                        }
                        else if(flipped_horizontally && flipped_diagonally)
                        {
                            //TODO
                        }
                        else if (flipped_horizontally)
                        {
                            //TODO
                        }
                        else if (flipped_vertically)
                        {
                            //TODO
                        }
                        else if (flipped_diagonally)
                        {
                            //TODO
                        }
                    }
                    else
                    {
                        tileImage.x = x * _tileWidth;
                        tileImage.y = y * _tileHeight;

                        //These flipped values only work for orthogonal maps
                        if(flipped_vertically && flipped_horizontally && flipped_diagonally)
                        {
                            tileImage.rotation = 90 * Math.PI / 180;
                            tileImage.x = x * _tileWidth + _tileWidth;
                        }
                        else if(flipped_vertically && flipped_horizontally)
                        {
                            tileImage.scaleX = tileImage.scaleY = -1;
                            tileImage.x = x * _tileWidth + _tileWidth;
                            tileImage.y = y * _tileHeight + _tileHeight;    
                        }
                        else if(flipped_vertically && flipped_diagonally)
                        {
                            tileImage.rotation = -90 * Math.PI / 180;
                            tileImage.y = y * _tileHeight + _tileHeight;
                        }
                        else if(flipped_horizontally && flipped_diagonally)
                        {
                            tileImage.rotation = 90 * Math.PI / 180;
                            tileImage.x = x * _tileWidth + _tileWidth;
                        }
                        else if (flipped_horizontally)
                        {
                            tileImage.scaleX = -1;
                            tileImage.x = x * _tileWidth + _tileWidth;
                        }
                        else if (flipped_vertically)
                        {
                            tileImage.scaleY = -1;
                            tileImage.y = y * _tileHeight + _tileHeight;
                        }
                        else if (flipped_diagonally)
                        {
                            
                        }
                    }

                    layerSprite.addChild(tileImage);
                }
            }

            layerSprite.alpha = layer.opacity;
            layerSprite.visible = layer.visible;

            _layers[layer.name] = layerSprite;
            addChild(layerSprite);
        }

        private function onImageLayerParsed(file:String, imageLayer:TMXImageLayer):void
        {
            var layerImage = new Image(Texture.fromAsset(imageLayer.image.source));

            layerImage.alpha = imageLayer.opacity;
            layerImage.visible = imageLayer.visible;

            _imageLayers[imageLayer.name] = layerImage;
            addChild(layerImage);
        }

        private function imageFromGid(gid:int):Image
        {
            // Borrowed and modified from Loom's TMXTileMap
            var foundTexture:Texture = null;
            var testTexture:Texture = null;
            for (var i:int = 0; i < _tileAtlases.length; i++)
            {
                if (!_tileAtlases[i])
                {
                    trace("TMXMapSprite - Missing texture atlas");
                    continue;
                }

                testTexture = _tileAtlases[i].getTexture(String(gid));
                if (testTexture)
                {
                    foundTexture = testTexture;
                }
            }

            if (!foundTexture)
            {
                return null;
            }

            var result:Image = new Image(foundTexture);
            result.width = foundTexture.width + 1;
            result.height = foundTexture.height + 1;
            
            return result;
        }
    }
}