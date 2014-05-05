
package loom2d.display
{
    import loom2d.math.Matrix;
    import loom2d.math.Rectangle;
    import loom2d.textures.Texture;

    [Native(managed)]
    public native class QuadBatch extends DisplayObject
    {
        /** The number of Quads currently contained within the batch */
        public native function get numQuads():float;

        /** Adds an image to the batch. This method internally calls 'addQuad' with the correct
         *  parameters for 'texture' and 'smoothing'. */ 
        public function addImage(image:Image, parentAlpha:Number=1.0, modelViewMatrix:Matrix=null,
                                 blendMode:String=null):void
        {
            // don't pass through the Image texture, or smoothing as QuadBatch doesn't use it currently
            addQuad(image, parentAlpha, null, false, modelViewMatrix, blendMode);
        }

        /** Adds a quad to the batch. The first quad determines the state of the batch,
         *  i.e. the values for texture, smoothing and blendmode. When you add additional quads,  
         *  make sure they share that state (e.g. with the 'isStageChange' method), or reset
         *  the batch. */ 
        public function addQuad(quad:Quad, parentAlpha:Number=1.0, texture:Texture=null, 
                                smoothing:Boolean=false, modelViewMatrix:Matrix=null, 
                                blendMode:String=null):void
        {
            if (modelViewMatrix == null)
                modelViewMatrix = quad.transformationMatrix;
            
            _addQuad(quad, modelViewMatrix);

            // LOOM-1868: Support the below functionality so that we can remove these asserts!
            // add some messages for now that tell users when they are trying to something unsupported currently
            Debug.assert(parentAlpha == 1.0, "QuadBatch 'addQuad' doesn't support per-Quad alpha modifications at the moment. You must set the alpha on the Quad via 'setVertexAlpha()' prior to adding it to the batch.");
            Debug.assert(texture == null, "QuadBatch 'addQuad' doesn't support per-Quad texture modifications at the moment. You must derive your own Quad-based class, create an object of that type, and set its 'nativeTextureID prior to adding it to the batch.");
            Debug.assert(smoothing == false, "QuadBatch 'addQuad' doesn't support per-Quad texture smoothing at the moment. You must set the 'smoothing' value on the Texture assigned to the Quad prior to adding it to the batch.");
            Debug.assert(blendMode == null, "QuadBatch 'addQuad' doesn't support per-Quad blend mode values at the moment.  Currently, Loom Quads always force blending to be SrcAlpha / OneMinusSrcAlpha.");
        }   

        /** Updates the 'index'th Quad in the QuadBatch to take use whatever new vertex & texture data the Quad has been set with.  
         *  If 'index' is larger than the number of Quads in the batch, it will fail. */ 
        public function updateQuad(index:int, quad:Quad, modelViewMatrix:Matrix=null):void
        {
            if (modelViewMatrix == null)
                modelViewMatrix = quad.transformationMatrix;
            
            _updateQuad(index, quad, modelViewMatrix);
        }   

        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();

            _getBounds(targetSpace, resultRect);
                        
            return resultRect;
        }

        public native function reset();

        protected native function get nativeTextureID():int;
        protected native function set nativeTextureID(value:int);

        private native function _getBounds(targetSpace:DisplayObject, resultRect:Rectangle);
        private native function _addQuad(quad:Quad, modelViewMatrix:Matrix);     
        private native function _updateQuad(index:int, quad:Quad, modelViewMatrix:Matrix);     
    }

}

