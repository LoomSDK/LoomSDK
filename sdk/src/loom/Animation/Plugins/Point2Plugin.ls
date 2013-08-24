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

package loom.animation.plugins
{
    import loom.animation.ITypePlugin;
    import loom.animation.TweenProperty;

    import loom2d.math.Point;

    public class Point2Plugin implements ITypePlugin
    {
        public function apply(prop:TweenProperty, phase:Number)
        {
            var start = prop.startValue as Point;
            var end = prop.endValue as Point;

            var result:Point;
            result.x = start.x + ((end.x - start.x) * phase);
            result.y = start.y + ((end.y - start.y) * phase);
            prop.setValue(result);
        }
    }

}