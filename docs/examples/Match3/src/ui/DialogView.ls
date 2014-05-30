package ui {
	import feathers.controls.Button;
	import feathers.controls.Label;
	import loom2d.animation.Transitions;
	import loom2d.display.DisplayObject;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.Loom2D;
	
	public class DialogView extends ConfigView {
		
		[Bind] protected var header:Label;
		protected var items = new Vector.<DisplayObject>();
		
		protected static const dialogWidth = 120;
		
		public function init() {
			super.init();
			header.nameList.add("header");
			header.setSize(dialogWidth, 20);
			header.validate();
		}
		
		public function resize(w:Number, h:Number) {
			super.resize(w, h);
			x = (w-dialogWidth)/2;
		}
		
		public function enter(owner:DisplayObjectContainer):void {
			super.enter(owner);
			for (var i = 0; i < items.length; i++) {
				var item = items[i];
				Loom2D.juggler.tween(item, 0.8, {
					y: item.y,
					delay: (1-(i+1)/items.length)*0.3,
					transition: Transitions.EASE_OUT_BOUNCE
				});
				item.y = -30;
			}
			Loom2D.juggler.tween(header, 0.8, {
				y: header.y,
				delay: 0.3,
				transition: Transitions.EASE_OUT_BOUNCE
			});
			header.y = -header.height;
		}
		
	}
	
}