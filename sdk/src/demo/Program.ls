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
    import system.platform.Platform;

    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.textures.Texture;    

    // for ticks
    import loom.Application;

    //import loom.graphics.Texture;

    /**
     * Fun color matching game! Use the buttons in the bottom of the screen to
     * change the colors of the region in the bottom left to make the whole 
     * board one color.
     */
    public class DemoGame extends Application
    {

        /**
         * Entry point for the game (see main.ls)
         */

        var sprite:Sprite;
        var img:Image;
        var img2:Image;

        function onFrame()
        {
            sprite.rotation += .01;         

            sprite.scale = Math.sin(Platform.getTime()/1000.0);  
        }

        override public function run():void
        {

            // Set up automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            sprite = new Sprite;
            stage.addChild(sprite); 

            sprite.x = 256;
            sprite.y = 256;

            img = new Image(Texture.fromAsset("assets/boss1.png")); 
            img.x = -128;
            img.y = -128;

            sprite.addChild(img);      

            img2 = new Image(Texture.fromAsset("assets/boss1.png")); 
            img2.x = 128;
            img2.y = 128;
 
            sprite.addChild(img2);       

        }


    }


}