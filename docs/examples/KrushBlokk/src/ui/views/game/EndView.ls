package ui.views.game {
	import feathers.controls.Label;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import loom2d.Loom2D;
	import ui.views.DialogView;
	import ui.views.ViewCallback;
	
	/**
	 * Game over score screen view that displays the game results.
	 */
	class EndView extends DialogView
	{
		public var onContinue:ViewCallback;
		
		[Bind] public var score:Label;
		[Bind] public var info:Label;
		
		// These get set from the main class
		public var quitManually:Boolean;
		public var gameScore:int;
		
		function get layoutFile():String { return "end.lml"; }
		
		public function created()
		{
			items.push(score);
			items.push(info);
			
			// Styles for text, see Theme for more
			score.nameList.add("title");
			info.nameList.add("light");
		}
		
		public function resize(w:Number, h:Number)
		{
			super.resize(w, h);
			score.setSize(dialogWidth, h);
		}
		
		/**
		 * Set all the labels to their appropriate values based on the vars set.
		 */
		public function enter(owner:DisplayObjectContainer)
		{
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
			
			// Delayed call to prevent unintended touches skipping too soon
			Loom2D.juggler.delayCall(enableTouch, 1);
		}
		
		public function exit()
		{
			disableTouch();
			super.exit();
		}
		
		private function enableTouch()
		{
			stage.addEventListener(TouchEvent.TOUCH, touch);
		}
		private function touch(e:TouchEvent)
		{
			if (e.touches[0].phase == TouchPhase.BEGAN) onContinue();
		}
		private function disableTouch()
		{
			stage.removeEventListener(TouchEvent.TOUCH, touch);
		}
		
		
	}
}