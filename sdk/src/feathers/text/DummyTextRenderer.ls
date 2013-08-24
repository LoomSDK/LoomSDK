package feathers.text
{
	import loom2d.math.Point;
	import feathers.core.ITextRenderer;
	import feathers.core.FeathersControl;

	public class DummyTextRenderer extends FeathersControl implements ITextRenderer
	{
		function get text():String
		{
			return "";
		}

		function set text(value:String):void
		{

		}

		function get baseline():Number
		{
			return 0;
		}

		function measureText():Point
		{
			return new Point();
		}
	}
}