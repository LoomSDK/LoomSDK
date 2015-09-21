package 
{
	import loom2d.display.Image;
	import loom2d.display.Sprite;
	import loom2d.textures.Texture;
	
	/**
	 * This is a simple gauge to visually display a value ranging from 0 to 1.
	 * In this example it is used to represent triggers of the game controller.
	 */
	public class ControllerTrigger extends Sprite
	{
		private var gauge:Image;
		private var indicator:Image;
		
		private var indicatorBottom:Number = 120;
		private var indicatorTop:Number = 5;
		private var mValue:Number = 0;
		
		public function ControllerTrigger() 
		{
			init();
		}
		
		private function init() {
			gauge = new Image(Texture.fromAsset("assets/controller/gauge.png"));
			indicator = new Image(Texture.fromAsset("assets/controller/indicator.png"));
			
			this.addChild(gauge);
			this.addChild(indicator);
		}
		
		public function onTick() {
			indicator.y = (indicatorBottom - indicatorTop) - (mValue * (indicatorBottom - indicatorTop)) + 5;
		}
		
		public function get value():Number { return mValue; }
		public function set value(val:Number):void { mValue = val; }
	}
	
}