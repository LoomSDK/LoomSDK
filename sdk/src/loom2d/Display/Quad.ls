// =================================================================================================
//
//  Starling Framework
//  Copyright 2011 Gamua OG. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.display
{    
    import loom2d.math.Matrix;
    import loom2d.math.Point;
    import loom2d.math.Rectangle;
    
    import loom2d.utils.VertexData;
    import loom2d.textures.Texture;
    
    /** A Quad represents a rectangle with a uniform color or a color gradient.
     *  
     *  You can set one color per vertex. The colors will smoothly fade into each other over the area
     *  of the quad. To display a simple linear color gradient, assign one color to vertices 0 and 1 and 
     *  another color to vertices 2 and 3.  
     *
     *  The indices of the vertices are arranged like this:
     *  
     *  ~~~text
     *  0 - 1
     *  | / |
     *  2 - 3
     *  ~~~
     * 
     *  @see Image
     */

    [Native(managed)]
    public native class Quad extends DisplayObject
    {
        private var mTinted:Boolean;
        
        /** The raw vertex data of the quad. */
        protected var mVertexData:VertexData;
        
        /** Helper objects. */
        private static var sHelperPoint:Point = new Point();

        protected native function get nativeVertexDataInvalid():Boolean;
        protected native function set nativeVertexDataInvalid(value:Boolean):void;

        protected native function get nativeTextureID():int;
        protected native function set nativeTextureID(value:int);

        /** Creates a quad with a certain size and color. The 'premultipliedAlpha' parameter 
         *  controls if the alpha value should be premultiplied into the color values on 
         *  rendering, which can influence blending output. You can use the default value in 
         *  most cases.  The last parameter is whether or not to initialize the vertices of
         *  the Quad with the data provided, or to leave empty for custom manipulation.  */
        public function Quad(width:Number, height:Number, color:uint=0xffffff,
                             premultipliedAlpha:Boolean=true, initVertexData:Boolean=true)
        {            

            // Quads internally use a white texture with vertex colors applied
            nativeTextureID = Texture.fromAsset("assets/tile.png").nativeID;
            
            nativeVertexDataInvalid = true;

            mVertexData = new VertexData(4, premultipliedAlpha);
            
            // Useful for debugging.
            //trace("Size is " + width + ", " + height + " c=" + color + " r=" + (color & 0xFF) + " g= " + ((color >> 8) & 0xFF) + " b=" + ((color >> 16) & 0xFF));           
            if(initVertexData)
            {
                // ignore alpha incase somebody passes in full ARGB value unknowningly...
                mTinted = (color & 0x00ffffff) != 0x00ffffff;
            
                mVertexData.setPosition(0, 0.0,   0.0);
                mVertexData.setPosition(1, width, 0.0);
                mVertexData.setPosition(2, 0.0,   height);
                mVertexData.setPosition(3, width, height);            
                mVertexData.setUniformColor(color);

                mVertexData.setTexCoords(0, 0.0, 0.0);
                mVertexData.setTexCoords(1, 1.0, 0.0);
                mVertexData.setTexCoords(2, 0.0, 1.0);
                mVertexData.setTexCoords(3, 1.0, 1.0);
            }
            
            onVertexDataChanged();
        }

        /** Call this method after manually changing the contents of 'mVertexData'. */
        protected function onVertexDataChanged():void
        {
            // override in subclasses, if necessary
            nativeVertexDataInvalid = true;
        }
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            if (targetSpace == this) // optimization
            {
                sHelperPoint = mVertexData.getPosition(3);
                resultRect.setTo(0.0, 0.0, sHelperPoint.x, sHelperPoint.y);
            }
            else if (targetSpace == parent && rotation == 0.0) // optimization
            {
                var scaleX:Number = this.scaleX;
                var scaleY:Number = this.scaleY;
                sHelperPoint = mVertexData.getPosition(3);
                resultRect.setTo(x - pivotX * scaleX,      y - pivotY * scaleY,
                                 sHelperPoint.x * scaleX,  sHelperPoint.y * scaleY);
                if (scaleX < 0) { resultRect.width  *= -1; resultRect.x -= resultRect.width;  }
                if (scaleY < 0) { resultRect.height *= -1; resultRect.y -= resultRect.height; }
            }
            else
            {
                getTargetTransformationMatrix(targetSpace, sHelperMatrix);
                mVertexData.getBounds(sHelperMatrix, 0, 4, resultRect);
            }
            
            return resultRect;
        }

        /** Fills in all of the vertex data for the quad with an arbitrary set of 4 position, UV, color (RGB), 
         *  and alpha values. Make sure that data in the Vectors is ordered to correspond to the vertex index 
         *  order of a Quad (see above). */
        public function setVertexData(pos:Vector.<Point>, uv:Vector.<Point>, color:Vector.<int>, alpha:Vector.<float>)
        {
            for(var i=0;i<4;i++)
            {
                mVertexData.setPosition(i, pos[i].x, pos[i].y);
                mVertexData.setTexCoords(i, uv[i].x, uv[i].y);
                var rgb:int = color[i] & 0x00ffffff;
                mVertexData.setColor(i, rgb);
                mVertexData.setAlpha(i, alpha[i]);
                if((alpha[i] != 1.0) || (rgb != 0x00ffffff))
                {
                    mTinted = true;
                }
            }
            
            onVertexDataChanged();
        }        
        

        /** Returns the color of a vertex at a certain index. */
        public function getVertexColor(vertexID:int):uint
        {
            return mVertexData.getColor(vertexID);
        }
        
        /** Sets the color of a vertex at a certain index. */
        public function setVertexColor(vertexID:int, color:uint):void
        {
            mVertexData.setColor(vertexID, color);
            onVertexDataChanged();
            
            if (color != 0xffffff) mTinted = true;
            else mTinted = mVertexData.tinted;
        }
        
        /** Returns the alpha value of a vertex at a certain index. */
        public function getVertexAlpha(vertexID:int):Number
        {
            return mVertexData.getAlpha(vertexID);
        }
        
        /** Sets the alpha value of a vertex at a certain index. */
        public function setVertexAlpha(vertexID:int, alpha:Number):void
        {
            mVertexData.setAlpha(vertexID, alpha);
            onVertexDataChanged();
            
            if (alpha != 1.0) mTinted = true;
            else mTinted = mVertexData.tinted;
        }

        /** Sets the position of a vertex at a certain index. */
        public function setVertexPosition(vertexID:int, posX:Number, posY:Number):void
        {
            mVertexData.setPosition(vertexID, posX, posY);
            onVertexDataChanged();
        }

        /** Gets the position of a vertex at a certain index. */
        public function getVertexPosition(vertexID:int):Point
        {
            return mVertexData.getPosition(vertexID);
        }
        
        /** Returns the color of the quad, or of vertex 0 if vertices have different colors. */
        public function get color():uint 
        { 
            return mVertexData.getColor(0); 
        }
        
        /** Sets the colors of all vertices to a certain value. */
        public function set color(value:uint):void 
        {
            for (var i:int=0; i<4; ++i)
                setVertexColor(i, value);
            
            if (value != 0xffffff || alpha != 1.0) mTinted = true;
            else mTinted = mVertexData.tinted;
        }
        
        /** Set red color (0-255); convenience method for tweening. */
        public function set r(value:int):void 
        {
            color = (value << 16) | (g << 8) | (b << 0);
        }
        
        /** Set green color (0-255); convenience method for tweening. */
        public function set g(value:int):void 
        { 
            color = (r << 16) | (value << 8) | (b << 0);
        }
        
        /** Set blue color (0-255); convenience method for tweening. */
        public function set b(value:int):void 
        { 
            color = (r << 16) | (g << 8) | (value << 0);
        }

        public function get r():int { return (color >> 16) & 0xFF; };
        public function get g():int { return (color >> 8) & 0xFF; };
        public function get b():int { return (color >> 0) & 0xFF; };
        
        /** @inheritDoc **/

        /*
        public override function set alpha(value:Number):void
        {
            super.setAlpha(value);
            
            if (value < 1.0) mTinted = true;
            else mTinted = mVertexData.tinted;
        }
        */
        
        /** Copies the raw vertex data to a VertexData instance. */
        public function copyVertexDataTo(targetData:VertexData, targetVertexID:int=0):void
        {
            mVertexData.copyTo(targetData, targetVertexID);
        }
        
/*        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            support.batchQuad(this, parentAlpha);
        }*/
        
        
        /** Returns true if the quad (or any of its vertices) is non-white or non-opaque. */
        public function get tinted():Boolean { return mTinted; }
        
        /** Indicates if the rgb values are stored premultiplied with the alpha value; this can
         *  affect the rendering. (Most developers don't have to care, though.) */
        public function get premultipliedAlpha():Boolean { return mVertexData.premultipliedAlpha; }
    }
}