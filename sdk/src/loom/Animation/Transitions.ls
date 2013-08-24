/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

package loom.animation {

    public delegate EaseMethod(phase:Number):Number;
    
    public enum LoomEaseType { LINEAR, EASE_IN, EASE_OUT, EASE_IN_OUT, EASE_OUT_IN, EASE_IN_BACK,
                           EASE_OUT_BACK, EASE_IN_OUT_BACK, EASE_OUT_IN_BACK, EASE_IN_ELASTIC,
                           EASE_OUT_ELASTIC, EASE_IN_OUT_ELASTIC, EASE_OUT_IN_ELASTIC,
                           EASE_IN_BOUNCE, EASE_OUT_BOUNCE, EASE_IN_OUT_BOUNCE, EASE_OUT_IN_BOUNCE };

    
    [Deprecated(msg="Please use loom2d.animation.Transitions")]                           
    public class LoomTransitions {        

        private static var sTransitions:Dictionary.<LoomEaseType, EaseMethod>;

        public static function getTransition(name:LoomEaseType):EaseMethod
        {
            if (sTransitions == null) registerDefaults();
            return sTransitions[name];
        }

        public static function register(name:LoomEaseType, func:EaseMethod):void
        {
            if (sTransitions == null) registerDefaults();
            sTransitions[name] = func;
        }

        private static function registerDefaults():void
        {
            sTransitions = new Dictionary.<LoomEaseType, EaseMethod>;
            
            var f:EaseMethod;
            
            f = new EaseMethod(); f = linear; register(LoomEaseType.LINEAR, f);
            f = new EaseMethod(); f = easeIn; register(LoomEaseType.EASE_IN, f);
            f = new EaseMethod(); f = easeOut; register(LoomEaseType.EASE_OUT, f);
            f = new EaseMethod(); f = easeInOut; register(LoomEaseType.EASE_IN_OUT, f);
            f = new EaseMethod(); f = easeOutIn; register(LoomEaseType.EASE_OUT_IN, f);
            f = new EaseMethod(); f = easeInBack; register(LoomEaseType.EASE_IN_BACK, f);
            f = new EaseMethod(); f = easeOutBack; register(LoomEaseType.EASE_OUT_BACK, f);
            
            f = new EaseMethod(); f = easeInOutBack; register(LoomEaseType.EASE_IN_OUT_BACK, f);
            f = new EaseMethod(); f = easeOutInBack; register(LoomEaseType.EASE_OUT_IN_BACK, f);
            
            f = new EaseMethod(); f = easeInElastic; register(LoomEaseType.EASE_IN_ELASTIC, f);
            f = new EaseMethod(); f = easeOutElastic; register(LoomEaseType.EASE_OUT_ELASTIC, f);
            f = new EaseMethod(); f = easeInOutElastic; register(LoomEaseType.EASE_IN_OUT_ELASTIC, f);
            f = new EaseMethod(); f = easeOutInElastic; register(LoomEaseType.EASE_OUT_IN_ELASTIC, f);
            
            
            f = new EaseMethod(); f = easeInBounce; register(LoomEaseType.EASE_IN_BOUNCE, f);
            f = new EaseMethod(); f = easeOutBounce; register(LoomEaseType.EASE_OUT_BOUNCE, f);
            f = new EaseMethod(); f = easeInOutBounce; register(LoomEaseType.EASE_IN_OUT_BOUNCE, f);
            f = new EaseMethod(); f = easeOutInBounce; register(LoomEaseType.EASE_OUT_IN_BOUNCE, f);

        }         

        // transition functions
        
        private static function linear(ratio:Number):Number
        {
            return ratio;
        }
        
        private static function easeIn(ratio:Number):Number
        {
            return ratio * ratio * ratio;
        }    
        
        private static function easeOut(ratio:Number):Number
        {
            var invRatio:Number = ratio - 1.0;
            return invRatio * invRatio * invRatio + 1;
        }        
        
        private static function easeInOut(ratio:Number):Number
        {
            return easeCombined(sTransitions[LoomEaseType.EASE_IN], sTransitions[LoomEaseType.EASE_OUT], ratio);
        }   
        
        private static function easeOutIn(ratio:Number):Number
        {
            return easeCombined(sTransitions[LoomEaseType.EASE_OUT], sTransitions[LoomEaseType.EASE_IN], ratio);
        }
        
        private static function easeInBack(ratio:Number):Number
        {
            var s:Number = 1.70158;
            return Math.pow(ratio, 2) * ((s + 1.0)*ratio - s);
        }
        
        private static function easeOutBack(ratio:Number):Number
        {
            var invRatio:Number = ratio - 1.0;            
            var s:Number = 1.70158;
            return Math.pow(invRatio, 2) * ((s + 1.0)*invRatio + s) + 1.0;
        }
        
        private static function easeInOutBack(ratio:Number):Number
        {
            return easeCombined(sTransitions[LoomEaseType.EASE_IN_BACK], sTransitions[LoomEaseType.EASE_OUT_BACK], ratio);
        }   
        
        private static function easeOutInBack(ratio:Number):Number
        {
            return easeCombined(sTransitions[LoomEaseType.EASE_OUT_BACK], sTransitions[LoomEaseType.EASE_IN_BACK], ratio);
        }        
        
        private static function easeInElastic(ratio:Number):Number
        {
            if (ratio == 0 || ratio == 1) return ratio;
            else
            {
                var p:Number = 0.3;
                var s:Number = p/4.0;
                var invRatio:Number = ratio - 1;
                return -1.0 * Math.pow(2.0, 10.0*invRatio) * Math.sin((invRatio-s)*(2.0*Math.PI)/p);                
            }            
        }
        
        private static function easeOutElastic(ratio:Number):Number
        {
            if (ratio == 0 || ratio == 1) return ratio;
            else
            {
                var p:Number = 0.3;
                var s:Number = p/4.0;                
                return Math.pow(2.0, -10.0*ratio) * Math.sin((ratio-s)*(2.0*Math.PI)/p) + 1;                
            }            
        }
        
        private static function easeInOutElastic(ratio:Number):Number
        {
            return easeCombined(sTransitions[LoomEaseType.EASE_IN_ELASTIC], sTransitions[LoomEaseType.EASE_OUT_ELASTIC], ratio);
        }   
        
        private static function easeOutInElastic(ratio:Number):Number
        {
            return easeCombined(sTransitions[LoomEaseType.EASE_OUT_ELASTIC], sTransitions[LoomEaseType.EASE_IN_ELASTIC], ratio);
        }
        
        private static function easeInBounce(ratio:Number):Number
        {
            return 1.0 - easeOutBounce(1.0 - ratio);
        }
        
        private static function easeOutBounce(ratio:Number):Number
        {
            var s:Number = 7.5625;
            var p:Number = 2.75;
            var l:Number;
            if (ratio < (1.0/p))
            {
                l = s * Math.pow(ratio, 2);
            }
            else
            {
                if (ratio < (2.0/p))
                {
                    ratio -= 1.5/p;
                    l = s * Math.pow(ratio, 2) + 0.75;
                }
                else
                {
                    if (ratio < 2.5/p)
                    {
                        ratio -= 2.25/p;
                        l = s * Math.pow(ratio, 2) + 0.9375;
                    }
                    else
                    {
                        ratio -= 2.625/p;
                        l =  s * Math.pow(ratio, 2) + 0.984375;
                    }
                }
            }
            return l;
        }
        
        private static function easeInOutBounce(ratio:Number):Number
        {
            return easeCombined(sTransitions[LoomEaseType.EASE_IN_BOUNCE], sTransitions[LoomEaseType.EASE_OUT_BOUNCE], ratio);
        }   
        
        private static function easeOutInBounce(ratio:Number):Number
        {
            return easeCombined(sTransitions[LoomEaseType.EASE_OUT_BOUNCE], sTransitions[LoomEaseType.EASE_IN_BOUNCE], ratio);
        }
        
        private static function easeCombined(startFunc:EaseMethod, endFunc:EaseMethod, ratio:Number):Number
        {
            var n:Number;
            if (ratio < 0.5) {
                n = startFunc(ratio*2.0);
                return 0.5 * n;
            }
            else  {           
                n = endFunc((ratio-0.5)*2.0);
                return 0.5 * n + 0.5;
            }
        }   

    }

}