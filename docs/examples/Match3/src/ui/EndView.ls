package ui {
	import feathers.controls.Button;
	import feathers.controls.Label;
	import game.GameConfig;
	import loom2d.animation.Transitions;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.events.Event;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import loom2d.Loom2D;
	import loom2d.textures.Texture;
	import loom2d.ui.SimpleButton;
	class EndView extends DialogView {
		
		public var onContinue:ViewCallback;
		
		[Bind] public var score:Label;
		[Bind] public var info:Label;
		
		public var quitManually:Boolean;
		public var gameScore:int;
		
		function get layoutFile():String { return "assets/end.lml"; }
		
		public function created() {
			items.push(score);
			items.push(info);
			
			score.nameList.add("title");
			info.nameList.add("light");
			//initButton(modeBeast, "assets/ui/iconBeast.png", pick(function() {
				//config.duration = 30;
			//}));
		}
		
		public function resize(w:Number, h:Number) {
			super.resize(w, h);
			score.setSize(dialogWidth, h);
		}
		
		public function enter(owner:DisplayObjectContainer):void {
			header.text = quitManually ? "TraitoR" : "TimE OUt";
			
			score.text = ""+gameScore;
			score.validate();
			
			var s = "";
			s += "Battle plan        "+config.modeLabel+"\n\n";
			if (config.duration != -1) s += "Destiny                  "+config.diffLabel+"\n\n";
			s += "FrEefoRm MODE   "+(config.freeform ? "Yes" : "No");
			info.text = s;
			info.validate();
			
			super.enter(owner);
			Loom2D.juggler.delayCall(enableTouch, 2);
		}
		
		public function exit():void {
			disableTouch();
			super.exit();
		}
		
		private function enableTouch() {
			stage.addEventListener(TouchEvent.TOUCH, touch);
		}
		private function disableTouch() {
			stage.removeEventListener(TouchEvent.TOUCH, touch);
		}
		
		private function touch(e:TouchEvent):void {
			if (e.touches[0].phase == TouchPhase.BEGAN) onContinue();
		}
		
	}
}