package ui
{
	import loom2d.display.DisplayObjectContainer;
	import loom2d.textures.Texture;
	import loom2d.textures.TextureSmoothing;

	public delegate ViewCallback():void;

	/**
	* Base view class; convenience callbacks to trigger Transitions and 
	* sequence adding/removing from parent.
	*/
	class View extends DisplayObjectContainer
	{
		public var onEnter:ViewCallback;
		public var onExit:ViewCallback;
		
		//protected function getTexture(path:String):Texture {
			//var tex = Texture.fromAsset(path);
			//tex.smoothing = TextureSmoothing.NONE;
			//return tex;
		//}
		
		public function init()
		{
		}
		
		public function enter(owner:DisplayObjectContainer):void
		{
			owner.addChild(this);
			onEnter();
		}
		
		public function resize() {
			//if (parent && parent.stage) parent.stage.sta
		}

		public function exit():void
		{
			if (parent) parent.removeChild(this);
			onExit();
		}
		
		public function tick() {
			
		}
		
		public function render() {
			
		}

	}
}