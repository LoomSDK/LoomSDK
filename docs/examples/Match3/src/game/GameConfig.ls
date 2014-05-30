package game {
	
	public class GameConfig {
		/** Game duration in seconds, -1 if unlimited */
		public var duration:int;
		public var freeform:Boolean;
		
		public var modeLabel:String;
		public var diffLabel:String;
		
		public function reset() {
			duration = 2;
			freeform = false;
			modeLabel = "mode";
			diffLabel = "diff";
		}
	}
	
}