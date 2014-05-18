package extensions {
	import feathers.controls.Label;
	import loom2d.animation.IAnimatable;
	import loom2d.display.DisplayObject;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.display.Quad;
	import loom2d.display.QuadBatch;
	import loom2d.events.Event;
	import loom2d.math.Matrix;
	import loom2d.math.Point;
	import loom2d.math.Rectangle;
	import loom2d.textures.Texture;
	import loom2d.textures.TextureSmoothing;
	import loom2d.ui.SimpleLabel;
	import loom2d.utils.VertexData;
	import system.errors.ArgumentError;
	/** Dispatched when emission of particles is finished. */
	[Event(name="complete", type="starling.events.Event")]
	
	public class ParticleSystem extends DisplayObjectContainer implements IAnimatable
	{
		public static const MAX_NUM_PARTICLES = 16383;
		
		private var mTexture:Texture;
		private var mParticles:Vector.<Particle>;
		private var mFrameTime:Number;
		
		private var batch:QuadBatch = new QuadBatch();
		private var mImages:Vector.<Image>;
		
		private var mNumParticles:int;
		private var mMaxCapacity:int;
		private var mEmissionRate:Number; // emitted particles per second
		private var mEmissionTime:Number;
		
		/** Helper objects. */
		private static var sHelperMatrix:Matrix = new Matrix();
		private static var sRenderAlpha:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];
		
		protected var mEmitterX:Number;
		protected var mEmitterY:Number;
		protected var mPremultipliedAlpha:Boolean;
		protected var mBlendFactorSource:String;     
		protected var mBlendFactorDestination:String;
		protected var mSmoothing:Number;
		
		//protected var debug:SimpleLabel;
		
        public function ParticleSystem(texture:Texture, emissionRate:Number, initialCapacity:int = 128, maxCapacity:int = MAX_NUM_PARTICLES, blendFactorSource:String=null, blendFactorDest:String=null)
        {
            if (texture == null) throw new ArgumentError("texture must not be null");
            
            mTexture = texture;
            mPremultipliedAlpha = texture.premultipliedAlpha;
            mParticles = new Vector.<Particle>(0);
            mImages = new Vector.<Image>(0);
			//mIndices = new <uint>[];
            mEmissionRate = emissionRate;
            mEmissionTime = 0.0;
            mFrameTime = 0.0;
            mEmitterX = mEmitterY = 0;
            mMaxCapacity = Math.min(MAX_NUM_PARTICLES, maxCapacity);
            mSmoothing = TextureSmoothing.BILINEAR;
			
            //debug = new SimpleLabel("assets/Curse-hd.fnt", 120*5, 1000);
            //debug.text = "Hello Quad!";
			//debug.y = 200;
			//debug.scale = 0.2;
            //addChild(debug);

            
            //mBlendFactorDestination = blendFactorDest || Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
            //mBlendFactorSource = blendFactorSource ||
                //(mPremultipliedAlpha ? Context3DBlendFactor.ONE : Context3DBlendFactor.SOURCE_ALPHA);
            
            //createProgram();
            raiseCapacity(initialCapacity);
            
            // handle a lost device context
            //Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE, 
                //onContextCreated, false, 0, true);
        }
		
        protected function createParticle():Particle
        {
            return new Particle();
        }
        
        protected function initParticle(particle:Particle):void
        {
            particle.x = mEmitterX;
            particle.y = mEmitterY;
            particle.currentTime = 0;
            particle.totalTime = 1;
            particle.color = Math.random() * 0xffffff;
        }
		
        protected function advanceParticle(particle:Particle, passedTime:Number):void
        {
            particle.y += passedTime * 250;
            particle.alpha = 1.0 - particle.currentTime / particle.totalTime;
            particle.scale = 1.0 - particle.alpha; 
            particle.currentTime += passedTime;
        }
		
		/** Starts the emitter for a certain time. @default infinite time */
		public function start(duration:Number=Number.MAX_VALUE):void
		{
			if (mEmissionRate != 0)                
				mEmissionTime = duration;
		}
		
		/** Stops emitting new particles. Depending on 'clearParticles', the existing particles
         *  will either keep animating until they die or will be removed right away. */
        public function stop(clearParticles:Boolean=false):void
        {
            mEmissionTime = 0.0;
            if (clearParticles) clear();
        }
		
        /** Removes all currently active particles. */
        public function clear():void
        {
            mNumParticles = 0;
        }
        
        /** Returns an empty rectangle at the particle system's position. Calculating the
         *  actual bounds would be too expensive. */
        public override function getBounds(targetSpace:DisplayObject, 
                                           resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            getTargetTransformationMatrix(targetSpace, sHelperMatrix);
            //MatrixUtil.transformCoords(sHelperMatrix, 0, 0, sHelperPoint);
			
            resultRect.x = sHelperPoint.x;
            resultRect.y = sHelperPoint.y;
            resultRect.width = resultRect.height = 0;
            
            return resultRect;
        }
        
        private function raiseCapacity(byAmount:int):void
        {
            var oldCapacity:int = capacity;
            var newCapacity:int = Math.min(mMaxCapacity, capacity + byAmount);
            
			mParticles.length = newCapacity;
			mImages.length = newCapacity;
			
            for (var i:int=oldCapacity; i<newCapacity; ++i)  
            {
				mParticles[i] = createParticle();
				var image = new Image();
				// TODO fix
				if (mTexture) image.texture = mTexture;
				image.center();
				addChild(image);
				mImages[i] = image;
            }
        }
        
		
        public function advanceTime(passedTime:Number):void
        {
			var particleIndex:int = 0;
            var particle:Particle;
            
            // advance existing particles
            
            while (particleIndex < mNumParticles)
            {
                particle = mParticles[particleIndex] as Particle;
                
                if (particle.currentTime < particle.totalTime)
                {
                    advanceParticle(particle, passedTime);
                    ++particleIndex;
                }
                else
                {
                    if (particleIndex != mNumParticles - 1)
                    {
                        var nextParticle:Particle = mParticles[int(mNumParticles-1)] as Particle;
                        mParticles[int(mNumParticles-1)] = particle;
                        mParticles[particleIndex] = nextParticle;
                    }
                    
                    --mNumParticles;
                    
                    if (mNumParticles == 0 && mEmissionTime == 0)
                        dispatchEvent(new Event(Event.COMPLETE));
                }
            }
            
            // create and advance new particles
            
            if (mEmissionTime > 0)
            {
                var timeBetweenParticles:Number = 1.0 / mEmissionRate;
                mFrameTime += passedTime;
                
                while (mFrameTime > 0)
                {
                    if (mNumParticles < mMaxCapacity)
                    {
                        if (mNumParticles == capacity)
                            raiseCapacity(capacity);
						
                        particle = mParticles[mNumParticles] as Particle;
                        initParticle(particle);
                        
                        // particle might be dead at birth
                        if (particle.totalTime > 0.0)
                        {
                            advanceParticle(particle, mFrameTime);
                            ++mNumParticles;
                        }
                    }
                    
                    mFrameTime -= timeBetweenParticles;
                }
                
                if (mEmissionTime != Number.MAX_VALUE)
                    mEmissionTime = Math.max(0.0, mEmissionTime - passedTime);
            }
            
            // update vertex data
            
            var vertexID:int = 0;
            var color:uint;
            var alpha:Number;
            var rotation:Number;
            var x:Number, y:Number;
            var xOffset:Number, yOffset:Number;
            var textureWidth:Number = mTexture.width;
            var textureHeight:Number = mTexture.height;
            
			var i:int;
			
			for (i=0; i<mImages.length; ++i) {
				mImages[i].visible = i < mNumParticles;
				//mImages[i].visible = true;
				//mImages[i].alpha = 0.2;
			}
			
			//var dbg = "";
			
            for (i=0; i<mNumParticles; ++i)
            {
                vertexID = i << 2;
                particle = mParticles[i] as Particle;
                color = particle.color;
                alpha = particle.alpha;
                rotation = particle.rotation;
                x = particle.x;
                y = particle.y;
                xOffset = textureWidth  * particle.scale >> 1;
                yOffset = textureHeight * particle.scale >> 1;
                
                //for (var j:int=0; j<4; ++j)
                    //mVertexData.setColor(vertexID+j, color);
                    //mVertexData.setAlpha(vertexID+j, alpha);
                
				var image:Image = mImages[i];
				image.scale = particle.scale;
				image.color = particle.color;
				image.alpha = Math.clamp(particle.alpha, 0, 1);
				image.rotation = rotation;
				image.x = x;
				image.y = y;
				
                //if (rotation)
                //{
                    //var cos:Number  = Math.cos(rotation);
                    //var sin:Number  = Math.sin(rotation);
                    //var cosX:Number = cos * xOffset;
                    //var cosY:Number = cos * yOffset;
                    //var sinX:Number = sin * xOffset;
                    //var sinY:Number = sin * yOffset;
                    
                    //mVertexData.setPosition(vertexID,   x - cosX + sinY, y - sinX - cosY);
                    //mVertexData.setPosition(vertexID+1, x + cosX + sinY, y + sinX - cosY);
                    //mVertexData.setPosition(vertexID+2, x - cosX - sinY, y - sinX + cosY);
                    //mVertexData.setPosition(vertexID+3, x + cosX - sinY, y + sinX + cosY);
                //}
                //else 
                //{
                    // optimization for rotation == 0
                    //mVertexData.setPosition(vertexID,   x - xOffset, y - yOffset);
                    //mVertexData.setPosition(vertexID+1, x + xOffset, y - yOffset);
                    //mVertexData.setPosition(vertexID+2, x - xOffset, y + yOffset);
                    //mVertexData.setPosition(vertexID+3, x + xOffset, y + yOffset);
                //}
            }
			
			//debug.text = dbg;
			
        }
		
		
        /** Initialize the <tt>ParticleSystem</tt> with particles distributed randomly throughout
         *  their lifespans. */
        public function populate(count:int):void
        {
            count = Math.min(count, mMaxCapacity - mNumParticles);
			
            if (mNumParticles + count > capacity)
                raiseCapacity(mNumParticles + count - capacity);
            
			//trace("populate", capacity, count, mNumParticles);
			
            var p:Particle;
            for (var i:int=0; i<count; i++)
            {
                p = mParticles[mNumParticles+i];
                initParticle(p);
                advanceParticle(p, Math.random() * p.totalTime);
            }
            
            mNumParticles += count;
        }
        
        public function get isEmitting():Boolean { return mEmissionTime > 0 && mEmissionRate > 0; }
        public function get capacity():int { return mImages.length; }
        public function get numParticles():int { return mNumParticles; }
        
        public function get maxCapacity():int { return mMaxCapacity; }
        public function set maxCapacity(value:int):void
        {
            mMaxCapacity = Math.min(MAX_NUM_PARTICLES, value);
        }
        
        public function get emissionRate():Number { return mEmissionRate; }
        public function set emissionRate(value:Number):void { mEmissionRate = value; }
        
        public function get emitterX():Number { return mEmitterX; }
        public function set emitterX(value:Number):void { mEmitterX = value; }
        
        public function get emitterY():Number { return mEmitterY; }
        public function set emitterY(value:Number):void { mEmitterY = value; }
        
        public function get blendFactorSource():String { return mBlendFactorSource; }
        public function set blendFactorSource(value:String):void { mBlendFactorSource = value; }
        
        public function get blendFactorDestination():String { return mBlendFactorDestination; }
        public function set blendFactorDestination(value:String):void { mBlendFactorDestination = value; }
        
        public function get texture():Texture { return mTexture; }
        public function set texture(value:Texture):void
        {
            mTexture = value;
			
            //createProgram();
            //for (var i:int = mVertexData.numVertices - 4; i >= 0; i -= 4)
            //{
                //mVertexData.setTexCoords(i + 0, 0.0, 0.0);
                //mVertexData.setTexCoords(i + 1, 1.0, 0.0);
                //mVertexData.setTexCoords(i + 2, 0.0, 1.0);
                //mVertexData.setTexCoords(i + 3, 1.0, 1.0);
                //mTexture.adjustVertexData(mVertexData, i, 4);
            //}
        }
        
        public function get smoothing():Number { return mSmoothing; }
        public function set smoothing(value:Number):void { mSmoothing = value; }
		
	}
	
}