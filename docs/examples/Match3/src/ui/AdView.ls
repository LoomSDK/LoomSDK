package ui {
	import feathers.controls.Label;
	import loom.admob.InterstitialAd;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import loom2d.Loom2D;
	import system.platform.Platform;
	
	public class AdView extends ConfigView {
		
		public var onContinue:ViewCallback;
		
		public var adBreakTime = 3*60*1000;
		
		private var lastTime = -adBreakTime;
		private var ad:InterstitialAd;
		
		private var adLabel:Label;
		
		override public function init() {
			super.init();
			adLabel = new Label();
			adLabel.nameList.add("header");
			adLabel.text = "This is an ad!";
			adLabel.validate();
			adLabel.visible = false;
			addChild(adLabel);
		}
		
		override public function resize(w:Number, h:Number) {
			super.resize(w, h);
			adLabel.setSize(w, 20);
			adLabel.y = (h-adLabel.height)/2;
		}
		
		override public function enter(owner:DisplayObjectContainer):void {
			super.enter(owner);
			var time = Platform.getTime();
			if (time-lastTime >= adBreakTime) {
				lastTime = time;
				showAd();
			} else {
				onContinue();
			}
		}
		
		private function showAd() {
			adLabel.visible = true;
			stage.addEventListener(TouchEvent.TOUCH, touch);
		}
		
		private function touch(e:TouchEvent):void {
			if (!e.getTouch(stage, TouchPhase.BEGAN)) return;
			hideAd();
		}
		
		private function hideAd() {
			adLabel.visible = false;
			stage.removeEventListener(TouchEvent.TOUCH, touch);
			onContinue();
		}
		
		override public function exit():void {
			super.exit();
		}
		
	}
	
}