// =================================================================================================
//
//  Starling Framework - Particle System Extension
//  Copyright 2012 Gamua OG. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package extensions
{
    import loom.LoomTextAsset;
    import loom2d.math.Color;
    import loom2d.textures.Texture;
    import loom2d.textures.TextureSmoothing;
    import system.platform.File;
    import system.platform.Path;
    import system.xml.XMLDocument;
    import system.xml.XMLElement;
    import system.xml.XMLNode;
    
    /**
     * Provides a particle system compatible with Particle Designer with live reload capability.
     */
    public class PDParticleSystem extends ParticleSystem
    {
        private const EMITTER_TYPE_GRAVITY:int = 0;
        private const EMITTER_TYPE_RADIAL:int  = 1;
        
        // emitter configuration                                // .pex element name
        private var mEmitterType:int                       = 0; // emitterType
        private var mEmitterXVariance:Number               = 0; // sourcePositionVariance x
        private var mEmitterYVariance:Number               = 0; // sourcePositionVariance y
        
        // particle configuration
        private var mMaxNumParticles:int                   = 0; // maxParticles
        private var mLifespan:Number                       = 0; // particleLifeSpan
        private var mLifespanVariance:Number               = 0; // particleLifeSpanVariance
        private var mStartSize:Number                      = 0; // startParticleSize
        private var mStartSizeVariance:Number              = 0; // startParticleSizeVariance
        private var mEndSize:Number                        = 0; // finishParticleSize
        private var mEndSizeVariance:Number                = 0; // finishParticleSizeVariance
        private var mEmitAngle:Number                      = 0; // angle
        private var mEmitAngleVariance:Number              = 0; // angleVariance
        private var mStartRotation:Number                  = 0; // rotationStart
        private var mStartRotationVariance:Number          = 0; // rotationStartVariance
        private var mEndRotation:Number                    = 0; // rotationEnd
        private var mEndRotationVariance:Number            = 0; // rotationEndVariance
        
        // gravity configuration
        private var mSpeed:Number                          = 0; // speed
        private var mSpeedVariance:Number                  = 0; // speedVariance
        private var mGravityX:Number                       = 0; // gravity x
        private var mGravityY:Number                       = 0; // gravity y
        private var mRadialAcceleration:Number             = 0; // radialAcceleration
        private var mRadialAccelerationVariance:Number     = 0; // radialAccelerationVariance
        private var mTangentialAcceleration:Number         = 0; // tangentialAcceleration
        private var mTangentialAccelerationVariance:Number = 0; // tangentialAccelerationVariance
        
        // radial configuration 
        private var mMaxRadius:Number                      = 0; // maxRadius
        private var mMaxRadiusVariance:Number              = 0; // maxRadiusVariance
        private var mMinRadius:Number                      = 0; // minRadius
        private var mMinRadiusVariance:Number              = 0; // minRadiusVariance
        private var mRotatePerSecond:Number                = 0; // rotatePerSecond
        private var mRotatePerSecondVariance:Number        = 0; // rotatePerSecondVariance
        
        // color configuration
        private var mStartColor:Color                      = new Color(); // startColor
        private var mStartColorVariance:Color              = new Color(); // startColorVariance
        private var mEndColor:Color                        = new Color(); // finishColor
        private var mEndColorVariance:Color                = new Color(); // finishColorVariance
        
        /**
         * Construct a live reloading particle system.
         * @param   path    Path to the .pex particle system configuration file.
         * @param   texture Custom texture for the particle (optional). If not provided, it's read from the configuration file.
         */
        public static function loadLiveSystem(path:String, texture:Texture = null):PDParticleSystem {
            var config = new XMLDocument();
            config.loadFile(path);
            var basePath = Path.folderFromPath(path);
            var ps = new PDParticleSystem(config, texture, basePath);
            var xml = LoomTextAsset.create(path);
            xml.updateDelegate += function(path:String, contents:String):void {
                config.parse(contents);
                ps.parseConfig(config, texture, basePath);
            };
            xml.load();
            return ps;
        }
        
        /**
         * @param   config   XML structure defining the Particle Designer compatible configuration variables.
         * @param   texture  Custom texture for the particle (optional). If not provided, it's read from the configuration file.
         * @param   basePath Relative path of the texture file specified in configuration file. Ignored if a custom `texture` is set.
         */
        public function PDParticleSystem(config:XMLNode, texture:Texture = null, basePath:String = "")
        {
            parseConfig(config, texture, basePath);
            
            super(this.texture, emissionRate, mMaxNumParticles, mMaxNumParticles);
        }
        
        protected override function createParticle():Particle
        {
            return new PDParticle();
        }
        
        protected override function initParticle(aParticle:Particle):void
        {
            var particle:PDParticle = aParticle as PDParticle; 
         
            // for performance reasons, the random variances are calculated inline instead
            // of calling a function
            
            var lifespan:Number = mLifespan + mLifespanVariance * (Math.random() * 2.0 - 1.0);
            
            particle.currentTime = 0.0;
            particle.totalTime = lifespan > 0.0 ? lifespan : 0.0;
            
            if (lifespan <= 0.0) return;
            
            particle.x = mEmitterX + mEmitterXVariance * (Math.random() * 2.0 - 1.0);
            particle.y = mEmitterY + mEmitterYVariance * (Math.random() * 2.0 - 1.0);
            particle.startX = mEmitterX;
            particle.startY = mEmitterY;
            
            var angle:Number = mEmitAngle + mEmitAngleVariance * (Math.random() * 2.0 - 1.0);
            var speed:Number = mSpeed + mSpeedVariance * (Math.random() * 2.0 - 1.0);
            particle.velocityX = speed * Math.cos(angle);
            particle.velocityY = speed * Math.sin(angle);
            
            var startRadius:Number = mMaxRadius + mMaxRadiusVariance * (Math.random() * 2.0 - 1.0);
            var endRadius:Number   = mMinRadius + mMinRadiusVariance * (Math.random() * 2.0 - 1.0);
            particle.emitRadius = startRadius;
            particle.emitRadiusDelta = (endRadius - startRadius) / lifespan;
            particle.emitRotation = mEmitAngle + mEmitAngleVariance * (Math.random() * 2.0 - 1.0); 
            particle.emitRotationDelta = mRotatePerSecond + mRotatePerSecondVariance * (Math.random() * 2.0 - 1.0); 
            particle.radialAcceleration = mRadialAcceleration + mRadialAccelerationVariance * (Math.random() * 2.0 - 1.0);
            particle.tangentialAcceleration = mTangentialAcceleration + mTangentialAccelerationVariance * (Math.random() * 2.0 - 1.0);
            
            var startSize:Number = mStartSize + mStartSizeVariance * (Math.random() * 2.0 - 1.0); 
            var endSize:Number = mEndSize + mEndSizeVariance * (Math.random() * 2.0 - 1.0);
            if (startSize < 0.1) startSize = 0.1;
            if (endSize < 0.1)   endSize = 0.1;
            if (texture) {
                particle.scale = startSize / texture.width;
                particle.scaleDelta = ((endSize - startSize) / lifespan) / texture.width;
            }
            
            // colors
            
            var startColor:Color = particle.colorArgb;
            var colorDelta:Color = particle.colorArgbDelta;
            
            startColor.red   = mStartColor.red;
            startColor.green = mStartColor.green;
            startColor.blue  = mStartColor.blue;
            startColor.alpha = mStartColor.alpha;
            
            if (mStartColorVariance.red != 0)   startColor.red   += mStartColorVariance.red   * (Math.random() * 2.0 - 1.0);
            if (mStartColorVariance.green != 0) startColor.green += mStartColorVariance.green * (Math.random() * 2.0 - 1.0);
            if (mStartColorVariance.blue != 0)  startColor.blue  += mStartColorVariance.blue  * (Math.random() * 2.0 - 1.0);
            if (mStartColorVariance.alpha != 0) startColor.alpha += mStartColorVariance.alpha * (Math.random() * 2.0 - 1.0);
            
            startColor.red = Math.clamp(startColor.red, 0, 0xFF);
            startColor.green = Math.clamp(startColor.green, 0, 0xFF);
            startColor.blue = Math.clamp(startColor.blue, 0, 0xFF);
            startColor.alpha = Math.clamp(startColor.alpha, 0, 0xFF);
            
            var endColorRed:Number   = mEndColor.red;
            var endColorGreen:Number = mEndColor.green;
            var endColorBlue:Number  = mEndColor.blue;
            var endColorAlpha:Number = mEndColor.alpha;

            if (mEndColorVariance.red != 0)   endColorRed   += mEndColorVariance.red   * (Math.random() * 2.0 - 1.0);
            if (mEndColorVariance.green != 0) endColorGreen += mEndColorVariance.green * (Math.random() * 2.0 - 1.0);
            if (mEndColorVariance.blue != 0)  endColorBlue  += mEndColorVariance.blue  * (Math.random() * 2.0 - 1.0);
            if (mEndColorVariance.alpha != 0) endColorAlpha += mEndColorVariance.alpha * (Math.random() * 2.0 - 1.0);
            
            endColorRed = Math.clamp(endColorRed, 0, 0xFF);
            endColorGreen = Math.clamp(endColorGreen, 0, 0xFF);
            endColorBlue = Math.clamp(endColorBlue, 0, 0xFF);
            endColorAlpha = Math.clamp(endColorAlpha, 0, 0xFF);
            
            colorDelta.red   = (endColorRed   - startColor.red)   / lifespan;
            colorDelta.green = (endColorGreen - startColor.green) / lifespan;
            colorDelta.blue  = (endColorBlue  - startColor.blue)  / lifespan;
            colorDelta.alpha = (endColorAlpha - startColor.alpha) / lifespan;
            
            // rotation
            
            var startRotation:Number = mStartRotation + mStartRotationVariance * (Math.random() * 2.0 - 1.0); 
            var endRotation:Number   = mEndRotation   + mEndRotationVariance   * (Math.random() * 2.0 - 1.0);
            
            particle.rotation = startRotation;
            particle.rotationDelta = (endRotation - startRotation) / lifespan;
        }
        
        protected override function advanceParticle(aParticle:Particle, passedTime:Number):void
        {
            
            var particle:PDParticle = aParticle as PDParticle;
            
            var restTime:Number = particle.totalTime - particle.currentTime;
            passedTime = restTime > passedTime ? passedTime : restTime;
            particle.currentTime += passedTime;
            
            if (mEmitterType == EMITTER_TYPE_RADIAL)
            {
                particle.emitRotation += particle.emitRotationDelta * passedTime;
                particle.emitRadius   += particle.emitRadiusDelta   * passedTime;
                particle.x = mEmitterX - Math.cos(particle.emitRotation) * particle.emitRadius;
                particle.y = mEmitterY - Math.sin(particle.emitRotation) * particle.emitRadius;
            }
            else
            {
                var distanceX:Number = particle.x - particle.startX;
                var distanceY:Number = particle.y - particle.startY;
                var distanceScalar:Number = Math.sqrt(distanceX*distanceX + distanceY*distanceY);
                if (distanceScalar < 0.01) distanceScalar = 0.01;
                
                var radialX:Number = distanceX / distanceScalar;
                var radialY:Number = distanceY / distanceScalar;
                var tangentialX:Number = radialX;
                var tangentialY:Number = radialY;
                
                radialX *= particle.radialAcceleration;
                radialY *= particle.radialAcceleration;
                
                var newY:Number = tangentialX;
                tangentialX = -tangentialY * particle.tangentialAcceleration;
                tangentialY = newY * particle.tangentialAcceleration;
                
                particle.velocityX += passedTime * (mGravityX + radialX + tangentialX);
                particle.velocityY += passedTime * (mGravityY + radialY + tangentialY);
                particle.x += particle.velocityX * passedTime;
                particle.y += particle.velocityY * passedTime;
            }
            
            particle.scale += particle.scaleDelta * passedTime;
            particle.rotation += particle.rotationDelta * passedTime;
            
            particle.colorArgb.red   += particle.colorArgbDelta.red   * passedTime;
            particle.colorArgb.green += particle.colorArgbDelta.green * passedTime;
            particle.colorArgb.blue  += particle.colorArgbDelta.blue  * passedTime;
            particle.colorArgb.alpha += particle.colorArgbDelta.alpha * passedTime;
            
            particle.color = particle.colorArgb.toInt();
            particle.alpha = particle.colorArgb.alpha;
        }
        
        private function updateEmissionRate():void
        {
            // -1 fixes unintentional behavior of skipping a particle in original implementation
            emissionRate = (mMaxNumParticles-1) / mLifespan;
        }
        
        private function parseFloat(config:XMLNode, name:String, attr:String):Number {
            var element = config.firstChildElement(name);
            if (!element) return NaN;
            return Number.fromString(element.getAttribute(attr));
        }
        private function parseFloatValue(config:XMLNode, name:String):Number {
            return parseFloat(config, name, "value");
        }
        private function parseAngle(config:XMLNode, name:String):Number {
            return Math.degToRad(parseFloatValue(config, name));
        }
        
        private function parseInt(config:XMLNode, name:String, attr:String):int {
            var element = config.firstChildElement(name);
            if (!element) return 0;
            return int.fromString(element.getAttribute(attr));
        }
        private function parseIntValue(config:XMLNode, name:String):int {
            return parseInt(config, name, "value");
        }
        
        private function parseColor(config:XMLNode, name:String):Color {
            return new Color(
                parseFloat(config, name, "red")*0xFF,
                parseFloat(config, name, "green")*0xFF,
                parseFloat(config, name, "blue")*0xFF,
                parseFloat(config, name, "alpha")
            );
        }
        
        private function parseTexture(config:XMLNode, name:String, basePath:String = ""):Texture {
            var element = config.firstChildElement(name);
            if (!element) return null;
            var relPath = element.getAttribute("name");
            if (basePath.length > 0) basePath += Path.getFolderDelimiter();
            var path = basePath+relPath;
            Debug.assert(File.fileExists(path), "Texture file in particle config not found");
            var tex = Texture.fromAsset(path);
            var smoothing = element.getAttribute("smoothing");
            switch (smoothing) {
                case "bilinear": tex.smoothing = TextureSmoothing.BILINEAR; break;
                case "max":      tex.smoothing = TextureSmoothing.MAX;      break;
                case "none":     tex.smoothing = TextureSmoothing.NONE;     break;
            }
            return tex;
        }
        
        /**
         * Parses a Particle Designer compatible configuration file.
         * @param   config   XML structure defining the Particle Designer compatible configuration variables.
         * @param   texture  Custom texture for the particle (optional). If not provided, it's read from the configuration file.
         * @param   basePath Relative path of the texture file specified in configuration file. Ignored if a custom `texture` is set.
         */
        public function parseConfig(config:XMLNode, texture:Texture = null, basePath:String = ""):void
        {
            config = config.firstChild();
            
            if (!texture) texture = parseTexture(config, "texture", basePath);
            this.texture = texture;
            
            mEmitterXVariance = parseFloat(config, "sourcePositionVariance", "x");
            mEmitterYVariance = parseFloat(config, "sourcePositionVariance", "y");
            mGravityX = parseFloat(config, "gravity", "x");
            mGravityY = parseFloat(config, "gravity", "y");
            mEmitterType = parseIntValue(config, "emitterType");
            maxNumParticles = parseIntValue(config, "maxParticles");
            mLifespan = Math.max(0.01, parseFloatValue(config, "particleLifeSpan"));
            mLifespanVariance = parseFloatValue(config, "particleLifespanVariance");
            mStartSize = parseFloatValue(config, "startParticleSize");
            mStartSizeVariance = parseFloatValue(config, "startParticleSizeVariance");
            mEndSize = parseFloatValue(config, "finishParticleSize");
            mEndSizeVariance = parseFloatValue(config, "FinishParticleSizeVariance");
            mEmitAngle = parseAngle(config, "angle");
            mEmitAngleVariance = parseAngle(config, "angleVariance");
            mStartRotation = parseAngle(config, "rotationStart");
            mStartRotationVariance = parseAngle(config, "rotationStartVariance");
            mEndRotation = parseAngle(config, "rotationEnd");
            mEndRotationVariance = parseAngle(config, "rotationEndVariance");
            mSpeed = parseFloatValue(config, "speed");
            mSpeedVariance = parseFloatValue(config, "speedVariance");
            mRadialAcceleration = parseFloatValue(config, "radialAcceleration");
            mRadialAccelerationVariance = parseFloatValue(config, "radialAccelVariance");
            mTangentialAcceleration = parseFloatValue(config, "tangentialAcceleration");
            mTangentialAccelerationVariance = parseFloatValue(config, "tangentialAccelVariance");
            mMaxRadius = parseFloatValue(config, "maxRadius");
            mMaxRadiusVariance = parseFloatValue(config, "maxRadiusVariance");
            mMinRadius = parseFloatValue(config, "minRadius");
            mMinRadiusVariance = parseFloatValue(config, "minRadiusVariance");
            mRotatePerSecond = parseFloatValue(config, "rotatePerSecond");
            mRotatePerSecondVariance = parseFloatValue(config, "rotatePerSecondVariance");
            mStartColor = parseColor(config, "startColor");
            mStartColorVariance = parseColor(config, "startColorVariance");
            mEndColor = parseColor(config, "finishColor");
            mEndColorVariance = parseColor(config, "finishColorVariance");
            
            // compatibility with future Particle Designer versions
            // (might fix some of the uppercase/lowercase typos)
            
            if (isNaN(mEndSizeVariance))
                mEndSizeVariance = parseFloatValue(config, "finishParticleSizeVariance");
            if (isNaN(mLifespan))
                mLifespan = Math.max(0.01, parseFloatValue(config, "particleLifespan"));
            if (isNaN(mLifespanVariance))
                mLifespanVariance = parseFloatValue(config, "particleLifeSpanVariance");    
        }
        
        public function get emitterType():int { return mEmitterType; }
        public function set emitterType(value:int):void { mEmitterType = value; }

        public function get emitterXVariance():Number { return mEmitterXVariance; }
        public function set emitterXVariance(value:Number):void { mEmitterXVariance = value; }

        public function get emitterYVariance():Number { return mEmitterYVariance; }
        public function set emitterYVariance(value:Number):void { mEmitterYVariance = value; }

        public function get maxNumParticles():int { return mMaxNumParticles; }
        public function set maxNumParticles(value:int):void 
        { 
            maxCapacity = value;
            mMaxNumParticles = maxCapacity; 
            updateEmissionRate(); 
        }

        public function get lifespan():Number { return mLifespan; }
        public function set lifespan(value:Number):void 
        { 
            mLifespan = Math.max(0.01, value);
            updateEmissionRate();
        }

        public function get lifespanVariance():Number { return mLifespanVariance; }
        public function set lifespanVariance(value:Number):void { mLifespanVariance = value; }

        public function get startSize():Number { return mStartSize; }
        public function set startSize(value:Number):void { mStartSize = value; }

        public function get startSizeVariance():Number { return mStartSizeVariance; }
        public function set startSizeVariance(value:Number):void { mStartSizeVariance = value; }

        public function get endSize():Number { return mEndSize; }
        public function set endSize(value:Number):void { mEndSize = value; }

        public function get endSizeVariance():Number { return mEndSizeVariance; }
        public function set endSizeVariance(value:Number):void { mEndSizeVariance = value; }

        public function get emitAngle():Number { return mEmitAngle; }
        public function set emitAngle(value:Number):void { mEmitAngle = value; }

        public function get emitAngleVariance():Number { return mEmitAngleVariance; }
        public function set emitAngleVariance(value:Number):void { mEmitAngleVariance = value; }

        public function get startRotation():Number { return mStartRotation; } 
        public function set startRotation(value:Number):void { mStartRotation = value; }
        
        public function get startRotationVariance():Number { return mStartRotationVariance; } 
        public function set startRotationVariance(value:Number):void { mStartRotationVariance = value; }
        
        public function get endRotation():Number { return mEndRotation; } 
        public function set endRotation(value:Number):void { mEndRotation = value; }
        
        public function get endRotationVariance():Number { return mEndRotationVariance; } 
        public function set endRotationVariance(value:Number):void { mEndRotationVariance = value; }
        
        public function get speed():Number { return mSpeed; }
        public function set speed(value:Number):void { mSpeed = value; }

        public function get speedVariance():Number { return mSpeedVariance; }
        public function set speedVariance(value:Number):void { mSpeedVariance = value; }

        public function get gravityX():Number { return mGravityX; }
        public function set gravityX(value:Number):void { mGravityX = value; }

        public function get gravityY():Number { return mGravityY; }
        public function set gravityY(value:Number):void { mGravityY = value; }

        public function get radialAcceleration():Number { return mRadialAcceleration; }
        public function set radialAcceleration(value:Number):void { mRadialAcceleration = value; }

        public function get radialAccelerationVariance():Number { return mRadialAccelerationVariance; }
        public function set radialAccelerationVariance(value:Number):void { mRadialAccelerationVariance = value; }

        public function get tangentialAcceleration():Number { return mTangentialAcceleration; }
        public function set tangentialAcceleration(value:Number):void { mTangentialAcceleration = value; }

        public function get tangentialAccelerationVariance():Number { return mTangentialAccelerationVariance; }
        public function set tangentialAccelerationVariance(value:Number):void { mTangentialAccelerationVariance = value; }

        public function get maxRadius():Number { return mMaxRadius; }
        public function set maxRadius(value:Number):void { mMaxRadius = value; }

        public function get maxRadiusVariance():Number { return mMaxRadiusVariance; }
        public function set maxRadiusVariance(value:Number):void { mMaxRadiusVariance = value; }

        public function get minRadius():Number { return mMinRadius; }
        public function set minRadius(value:Number):void { mMinRadius = value; }

        public function get minRadiusVariance():Number { return mMinRadiusVariance; }
        public function set minRadiusVariance(value:Number):void { mMinRadiusVariance = value; }

        public function get rotatePerSecond():Number { return mRotatePerSecond; }
        public function set rotatePerSecond(value:Number):void { mRotatePerSecond = value; }

        public function get rotatePerSecondVariance():Number { return mRotatePerSecondVariance; }
        public function set rotatePerSecondVariance(value:Number):void { mRotatePerSecondVariance = value; }

        public function get startColor():Color { return mStartColor; }
        public function set startColor(value:Color):void { mStartColor = value; }

        public function get startColorVariance():Color { return mStartColorVariance; }
        public function set startColorVariance(value:Color):void { mStartColorVariance = value; }

        public function get endColor():Color { return mEndColor; }
        public function set endColor(value:Color):void { mEndColor = value; }

        public function get endColorVariance():Color { return mEndColorVariance; }
        public function set endColorVariance(value:Color):void { mEndColorVariance = value; }
        
    }
    
}