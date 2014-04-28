
package loom2d.display
{
    import loom2d.math.Matrix;
    import loom2d.math.Rectangle;
    import loom2d.textures.Texture;

    [Native(managed)]
    public native class QuadBatch extends DisplayObject
    {

        public var texture:Texture;        

        /** The number of Quads currently contained within the batch */
        public native function get numQuads():float;

        /** Adds an image to the batch. This method internally calls 'addQuad' with the correct
         *  parameters for 'texture' and 'smoothing'. */ 
        public function addImage(image:Image, parentAlpha:Number=1.0, modelViewMatrix:Matrix=null,
                                 blendMode:String=null):void
        {
            addQuad(image, parentAlpha, image.texture, image.smoothing, modelViewMatrix, blendMode);
        }

        /** Adds a quad to the batch. The first quad determines the state of the batch,
         *  i.e. the values for texture, smoothing and blendmode. When you add additional quads,  
         *  make sure they share that state (e.g. with the 'isStageChange' method), or reset
         *  the batch. */ 
         //TODO: Neither 'smoothing' nor 'blendMode' do anything here!?!?!?! Shouldn't they???
         //gfxQuadRenderer seems to a) use whatever smoothing is set for the Texture and b) force SrcAlpha / InvSrcAlpha alpha blending
        public function addQuad(quad:Quad, parentAlpha:Number=1.0, texture:Texture=null, 
                                smoothing:Boolean=false, modelViewMatrix:Matrix=null, 
                                blendMode:String=null):void
        {
            if (modelViewMatrix == null)
                modelViewMatrix = quad.transformationMatrix;
            
            var alpha:Number = parentAlpha * quad.alpha;

            this.texture = texture;

            _addQuad(quad, modelViewMatrix);
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
    }

}

