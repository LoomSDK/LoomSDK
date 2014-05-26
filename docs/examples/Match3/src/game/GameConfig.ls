package game {
	
	public class GameConfig {
		/** Game duration in seconds, -1 if unlimited */
		public var duration:int;
		public var freeform:Boolean;
		public function reset() {
			duration = 0;
			freeform = false;
		}
	}
	
}