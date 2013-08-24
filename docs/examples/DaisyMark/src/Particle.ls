package
{

   import loom2d.display.Image;
   import loom2d.textures.Texture;

    public class Particle extends Image 
    {

        public var vx:Number;
        public var vy:Number;

        public function Particle(texture:Texture)
        {
            super(texture);        
        }

        public function get width():Number 
        {
            return 10;
        }

        public function get height():Number 
        {
            return 10;
        }

    }
 }