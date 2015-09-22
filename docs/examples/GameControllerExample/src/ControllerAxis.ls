package 
{
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.display.Sprite;
	import loom2d.textures.Texture;
	
	/**
	 * An extension to the ControllerButton class for representing the analog stick on the game controller.
	 * It supports two dimensional offset.
	 */
	public class ControllerStick extends ControllerButton
	{
		public static const BUTTON_STICK:String = "stickButton";
		
		private var stick:Image;
		
		private var maxOffset:Number = 40;
		private var myValue:Number = 0;
		private var mxValue:Number = 0;
		
		public function ControllerStick(type:String, id:int, x:Number = 0, y:Number = 0, rotation:Number = 0) 
		{
			super(type, id, x, y, rotation);
		}
		
		override protected function init()
		{
			normal = new Image(Texture.fromAsset("assets/controller/stick.png"));
			pressed = new Image(Texture.fromAsset("assets/controller/stick-pressed.png"));
			super.init();
		}
		
		override public function onTick()
		{
			var xStick = mxValue;
			var yStick = myValue;
			
			normal.x = pressed.x = maxOffset * xStick;
			normal.y = pressed.y = maxOffset * yStick;
			
			super.onTick();
		}
		
		public function get yValue():Number { return myValue; }
		public function get xValue():Number	{ return myValue; }
		public function set yValue(value:Number):void
		{
			myValue = value;
		}
		public function set xValue(value:Number):void
		{ 
			mxValue = value;
		}
	}
	
}