// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.textures
{
    import loom.graphics.Graphics;
    import loom.graphics.Texture2D;
    import loom2d.Loom2D;
    import loom2d.math.Matrix;
    import loom2d.math.Rectangle;
    
    import loom2d.display.BlendMode;
    import loom2d.display.DisplayObject;
    import loom2d.display.Image;
    
    /** A RenderTexture is a dynamic texture onto which you can draw any display object.
     * 
     *  <p>After creating a render texture, just call the <code>drawObject</code> method to render 
     *  an object directly onto the texture. The object will be drawn onto the texture at its current
     *  position, adhering its current rotation, scale and alpha properties.</p> 
     *  
     *  <p>Drawing is done very efficiently, as it is happening directly in graphics memory. After 
     *  you have drawn objects onto the texture, the performance will be just like that of a normal 
     *  texture - no matter how many objects you have drawn.</p>
     *  
     *  <p>If you draw lots of objects at once, it is recommended to bundle the drawing calls in 
     *  a block via the <code>drawBundled</code> method, like shown below. That will speed it up 
     *  immensely, allowing you to draw hundreds of objects very quickly.</p>
     *  
     * 	<pre>
     *  renderTexture.drawBundled(function():void
     *  {
     *     for (var i:int=0; i&lt;numDrawings; ++i)
     *     {
     *         image.rotation = (2 &#42; Math.PI / numDrawings) &#42; i;
     *         renderTexture.draw(image);
     *     }   
     *  });
     *  </pre>
     *  
     *  <p>To erase parts of a render texture, you can use any display object like a "rubber" by
     *  setting its blending mode to "BlendMode.ERASE".</p>
     * 
     *  <p>Beware that render textures can't be restored when the Starling's render context is lost.
     *  </p>
     *
     *  <strong>Persistence</strong>
     *
     *  <p>Persistent render textures (see the 'persistent' flag in the constructor) are more
     *  expensive, because they might have to use two render buffers internally. Disable this
     *  parameter if you don't need that.</p>
     *
     *  <p>On modern hardware, you can make use of the static 'optimizePersistentBuffers'
     *  property to overcome the need for double buffering. Use this feature with care, though!</p>
     *
     */
    public class RenderTexture extends SubTexture
    {
        private const PMA:Boolean = true;
        
        private var mActiveTexture:Texture;
        private var mBufferTexture:Texture;
        private var mHelperImage:Image;
        private var mDrawing:Boolean;
        private var mBufferReady:Boolean;
        private var mIsPersistent:Boolean;
        
        /** helper object */
        private static var sClipRect:Rectangle = new Rectangle();
        
        private var supportsRelaxedTargetClearRequirement:Boolean = true;
        
        /** Indicates if new persistent textures should use a single render buffer instead of
         *  the default double buffering approach. That's faster and requires less memory, but is
         *  not supported on all hardware.
         *
         *  // TODO: fix this if needed
         *  @default true
         */
        public static var optimizePersistentBuffers:Boolean = true;

        /** Creates a new RenderTexture with a certain size (in points). If the texture is
         *  persistent, the contents of the texture remains intact after each draw call, allowing
         *  you to use the texture just like a canvas. If it is not, it will be cleared before each
         *  draw call.
         *
         *  <p>Beware that persistence requires an additional texture buffer (i.e. the required
         *  memory is doubled). You can avoid that via 'optimizePersistentBuffers', though.</p>
         */
        public function RenderTexture(width:int, height:int, persistent:Boolean=true,
                                      scale:Number=-1, format:String="bgra", repeat:Boolean=false)
        {
            if (scale <= 0) scale = Loom2D.contentScaleFactor;
            
            var legalWidth:Number  = width;
            var legalHeight:Number = height;
            
            mActiveTexture = Texture.empty(legalWidth, legalHeight, PMA, false, true, scale, format, repeat);
            
            super(mActiveTexture, new Rectangle(0, 0, width, height), true);
            
            setTextureInfo(mActiveTexture.textureInfo);
            
            var rootWidth:Number  = mActiveTexture.root.width;
            var rootHeight:Number = mActiveTexture.root.height;
            
            mIsPersistent = persistent;
            
            if (persistent && !optimizePersistentBuffers) {
                mBufferTexture = Texture.empty(legalWidth, legalHeight, PMA, false, true, scale, format, repeat);
                mBufferTexture.smoothing = TextureSmoothing.NONE;
                mHelperImage = new Image(mBufferTexture);
            }
        }
        
        /** @inheritDoc */
        public override function dispose():void
        {
            mActiveTexture.dispose();
            
            if (isDoubleBuffered)
            {
                mBufferTexture.dispose();
                mHelperImage.dispose();
            }
            
            super.dispose();
        }
        
        /** Draws an object into the texture. Note that any filters on the object will currently
         *  be ignored.
         * 
         *  @param object       The object to draw.
         *  @param matrix       If 'matrix' is null, the object will be drawn adhering its 
         *                      properties for position, scale, and rotation. If it is not null,
         *                      the object will be drawn in the orientation depicted by the matrix.
         *  @param alpha        The object's alpha value will be multiplied with this value.
         */
        public function draw(object:DisplayObject, matrix:Matrix=null, alpha:Number=1.0):void
        {
            if (object == null) return;
            
            if (mDrawing)
                render(object, matrix, alpha);
            else
                renderBundled(render, object, matrix, alpha);
        }
        
        /** Bundles several calls to <code>draw</code> together in a block. This avoids buffer 
         *  switches and allows you to draw multiple objects into a non-persistent texture.
         *  
         *  @param drawingBlock  a callback with the form: <pre>function():void;</pre> */
        public function drawBundled(drawingBlock:Function):void
        {
            renderBundled(drawingBlock, null, null, 1.0);
        }
        
        /** For finer control over bundled drawing. Locks the texture so that any future draw
         *  calls will render to the texture. Call <code>drawBundledUnlock</code> when you are
         *  done drawing to switch back to regular rendering.
         *  <code>drawBundled</code> uses this function internally.
         */
        public function drawBundledLock():void
        {
            Texture2D.setRenderTarget(mActiveTexture.nativeID);
            
            if (isDoubleBuffered || !isPersistent || !mBufferReady)
                Texture2D.clear(mActiveTexture.nativeID);
                
            // draw buffer
            if (isDoubleBuffered && mBufferReady)
                Graphics.render(mHelperImage);
            else
                mBufferReady = true;
                
            mDrawing = true;
        }
        
        /** For finer control over bundled drawing. Unlocks the texture and allows for regular
         *  rendering to resume. Call <code>drawBundledLock</code> before calling this function
         *  to first lock the texture.
         *  <code>drawBundled</code> uses this function internally.
         */
        public function drawBundledUnlock():void
        {
            mDrawing = false;
            
            Texture2D.setRenderTarget(-1);
        }
        
        private function render(object:DisplayObject, matrix:Matrix=null, alpha:Number=1.0):void
        {
            Graphics.render(object, matrix, alpha);
        }
        
        private function renderBundled(renderBlock:Function, object:DisplayObject=null,
                                       matrix:Matrix=null, alpha:Number=1.0):void
        {
            // switch buffers
            if (isDoubleBuffered)
            {
                var tmpTexture:Texture = mActiveTexture;
                mActiveTexture = mBufferTexture;
                mBufferTexture = tmpTexture;
                mHelperImage.texture = mBufferTexture;
            }
            
            drawBundledLock();
            
            Loom2D.execute(renderBlock, object, matrix, alpha);
            
            drawBundledUnlock();
        }
        
        /** Clears the render texture with a certain color and alpha value. Call without any
         *  arguments to restore full transparency. */
        public function clear(rgb:uint=0, alpha:Number=0.0):void
        {
            Texture2D.clear(mActiveTexture.nativeID, rgb, alpha);
            mBufferReady = true;
        }
        
        private function get supportsNonPotDimensions():Boolean
        {
            return true;
        }

        // properties

        /** Indicates if the render texture is using double buffering. This might be necessary for
         *  persistent textures, depending on the runtime version and the value of
         *  'forceDoubleBuffering'. */
        private function get isDoubleBuffered():Boolean { return mBufferTexture != null; }

        /** Indicates if the texture is persistent over multiple draw calls. */
        public function get isPersistent():Boolean { return mIsPersistent; }
        
        /** @inheritDoc */
        public override function get root():ConcreteTexture { return mActiveTexture.root; }
    }
}