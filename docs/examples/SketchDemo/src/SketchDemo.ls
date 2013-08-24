package demo 
{

import loom.Application;    
import loom2d.display.StageScaleMode;

import loom2d.display.Image;
import loom2d.math.Point;
import loom2d.textures.Texture;

import loom2d.math.Point;

import loom2d.events.Touch;
import loom2d.events.TouchEvent;
import loom2d.events.TouchPhase;    

class SketchGame extends Application
{

    public function onTouchMoved(id:int, x:Number, y:Number):void
    {
        var sprite = new Image(Texture.fromAsset("assets/boss1.png"));
        sprite.scale = .2;
        sprite.x = x;
        sprite.y = y;
        stage.addChild(sprite);      

        while( stage.numChildren > 1024)
            stage.removeChildAt(0, true);
            
    }

    public function run() 
    {
        stage.scaleMode = StageScaleMode.LETTERBOX;
        
        stage.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 

            var point:Point;
            var touch = e.getTouch(stage, TouchPhase.MOVED);
            if (touch)
            {
                point = touch.getLocation(stage);
                onTouchMoved(touch.id, point.x, point.y);
            }                

        } );            

   
    }

}


}