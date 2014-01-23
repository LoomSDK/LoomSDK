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

package demo 
{
    import loom.Application;

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;

    import loom2d.textures.Texture;

    /**
     * Default Loom Demo when no working directory is specified
     */

    public class Demo extends Application
    {
        public var img:Image;

        override public function run():void
        {

            // Set up automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            img = new Image(Texture.fromAsset("assets/default.png"));
            img.center();
            img.x = stage.stageWidth / 2;
            img.y = stage.stageHeight / 2;

            stage.addChild(img);

            trace( "This is the default demo application found in the sdk/src/demo folder. To debug your application instead, make sure your working directory is set to your project directory." );
        }
    }
}