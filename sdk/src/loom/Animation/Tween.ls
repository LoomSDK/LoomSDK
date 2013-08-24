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

package loom.animation
{
    import loom.Application;
    import system.platform.Platform;
    import loom.animation.plugins.NumberPlugin;
    import loom.animation.plugins.Point2Plugin;
    import loom.animation.LoomEaseType;

    public delegate TweenCallback(tween:LoomTween);

    /**
     *  LoomTween is a small and fast animation library in LoomScript.
     *  The LoomTween class allows tweening of any property on any arbitrary object, given that the property's type is supported.
     *  A type can be supported through implementing an ITypePlugin. This works very well for custom structs and type which 
     *  need to be tweened.
     */

    [Deprecated(msg="Please use loom2d.animation.Tween")]
    public class LoomTween
    {
        //____________________________________________
        //  Public static functions
        //____________________________________________

        /**
         *  Tweens an target object's properties to their specified values within the specified
         *  duration.
         */
        public static function to(target:Object, duration:Number, params:Dictionary.<String, Object>):LoomTween
        {
            ensureInitialized();

            var tween = new LoomTween();
            tween.easeType = LoomEaseType.LINEAR;
            tween.properties = new Vector.<TweenProperty>();
            tween.duration = duration;
            tween.addedTime = Platform.getTime();

            tween.targetObj = target;

            var targetType = target.getType();

            // ease is a special keyword, so we will check for it
            if(params["ease"])
            {
                tween.easeType = params["ease"] as LoomEaseType;
                params.deleteKey("ease");
            }

            if(params["delay"])
            {
                tween.delay = params["delay"] as Number;
                params.deleteKey("delay");
            }

            for(var key:String in params)
            {
                var prop:TweenProperty = new TweenProperty();
                prop.name = key;
                prop.target = target;
                prop.field = targetType.getFieldInfoByName(key);
                prop.property = targetType.getPropertyInfoByName(key);
                
                if(tween.delay == 0)
                    prop.startValue = prop.getValue();

                prop.endValue = params[key];

                if(prop.type)
                    tween.properties.push(prop);
            }

            tweens.push(tween);

            return tween;
        }

        /**
         *  Determines whether or not a particular object is actively tweening. If a tween is paused or hasn't started yet, it doesn't count as active.
         *  
         *  @param target Target object whose tweens you're checking
         *  @return Boolean value indicating whether or not any active tweens were found
         */
        public static function isTweening(target:Object):Boolean
        {
            for(var i = 0; i<tweens.length; i++)
            {
                var tween = tweens[i];
                if(tween.targetObj == target)
                    return true;
            }

            return false;
        }

        /**
         *  Kills all the tweens of a particular object
         *
         *  @param target Object whose tweens should be immediately killed
         */
        public static function killTweensOf(target:Object):void
        {
            for(var i = 0; i<tweens.length; i++)
            {
                var tween = tweens[i];
                if(tween.targetObj == target)
                    tweens.remove(tween);
            }
        }

        /**
         *  Tweens an target object's properties to their specified values within the specified
         *  duration.
         */
        public static function registerTypePlugin(typeName:String, plugin:ITypePlugin):void
        {
            ensureInitialized();

            plugins[typeName] = plugin;
        }

        //____________________________________________
        //  Protected static properties
        //____________________________________________
        protected static var initialized:Boolean = false;
        protected static var tweens:Vector.<LoomTween> = new Vector.<LoomTween>();
        protected static var lastTickTime:Number = -1;
        protected static var plugins:Dictionary.<String, ITypePlugin> = new Dictionary.<String, ITypePlugin>();
        
        //____________________________________________
        //  Protected static functions
        //____________________________________________
        protected static function tick():void
        {
            var currentTime = Platform.getTime();
            update(currentTime);
        }

        protected static function ensureInitialized():void
        {
            if(initialized)
                return;

            initialized = true;
            Application.ticks += tick;

            // register default type plugins
            registerTypePlugin("system.Number", new NumberPlugin());
            registerTypePlugin("loom2d.math.Point", new Point2Plugin());
        }

        protected static function update(currentTime:Number):void
        {
            var i = 0;
            while(i < tweens.length)
            {
                var tween = tweens[i];

                // Continue does not work on while loops, LOOM-464
                if(currentTime - tween.addedTime < tween.delay*1000)
                {
                    i++;
                    continue;
                }

                // delegate calls
                if(!tween.started)
                {
                    tween.started = true;
                    tween.startTime = Platform.getTime();
                    tween.onStart(tween);
                }
                else
                {
                    tween.onUpdate(tween);
                }

                tween.phase = (currentTime - tween.startTime)/(tween.duration * 1000);
                tween.phase = Math.clamp(tween.phase, 0, 1);

                var ease:EaseMethod = LoomTransitions.getTransition(tween.easeType);
                var easePhase = ease(tween.phase);

                // loop over properties and update them
                for each(var property:TweenProperty in tween.properties)
                {
                    // case for delayed tweens. defer startValue lookup
                    if(!property.startValue) 
                        property.startValue = property.getValue();

                    // lookup the plugin based on the type
                    var plugin = plugins[property.type.getFullName()];

                    Debug.assert(plugin, "Cannot tween type: " + property.type.getFullName() + ". Type is not currently supported in LoomTween. You can implement it by registering a plugin");

                    // apply via plugin
                    plugin.apply(property, easePhase);
                }

                // remove the tween if we have a 1 phase
                if(tween.phase >= 1.0)
                {
                    tweens.remove(tween);
                    tween.onComplete(tween);
                }
                else
                {
                    i++;
                }
            }
        }

        //____________________________________________
        //  Public Properties
        //____________________________________________
        public var properties:Vector.<TweenProperty>;
        public var easeType:LoomEaseType;
        public var started:Boolean = false;
        public var addedTime:Number;
        public var startTime:Number;
        public var phase:Number = 0;
        public var duration:Number;
        public var delay:Number = 0;
        public var targetObj:Object;

        // Delegates
        public var onStart:TweenCallback;
        public var onUpdate:TweenCallback;
        public var onComplete:TweenCallback;

    }

    public class TweenProperty
    {
        public var name:String;
        public var startValue:Object;
        public var endValue:Object;
        public var field:FieldInfo;
        public var property:PropertyInfo;
        public var target:Object;

        public function get type():Type
        {
            if(field)
            {
                return field.getTypeInfo();
            }
            else if(property)
            {
                return property.getTypeInfo();
            }

            return null;
        }

        // abstraction of field and property api
        public function setValue(value:Object):void
        {
            if(field)
            {
                field.setValue(target, value);
            }
            else if(property)
            {
                property.getSetMethod().invokeSingle(target, value);
            }
        }

        public function getValue():Object
        {
            if(field)
            {
                return field.getValue(target);
            }
            else if(property)
            {
                return property.getGetMethod().invoke(target);
            }

            return null;
        }
    }
}