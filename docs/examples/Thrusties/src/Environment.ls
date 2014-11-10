package
{
	import loom2d.display.Stage;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import loom2d.math.Point;
	
	/**
	 * Manages all the Ships and defines the environment they reside in.
	 */
	public class Environment
	{
		private var stage:Stage;
		
		private var numShips = 3;
		private var dt:Number = 1/60;
		
		private var ships:Vector.<Ship> = new Vector.<Ship>();
		
		/** Used for storing touch event results */
		private var tempTouches = new Vector.<Touch>();
		
		/** Stores a touch-to-ship mapping to support multiple concurrent touches */
		private var touchMap = new Dictionary.<Ship>();
		
		public function Environment(stage:Stage)
		{
			this.stage = stage;
			
			var ship:Ship;
			
			var i:int;
			
			for (i = 0; i < numShips; i++) {
				ship = new Ship(stage);
				ships.push(ship);
			}
			
			
			// Randomly position ships on the lower half of the stage
			// and direct them to the meeting point initially, except the last one
			var target = getMeetingPoint();
			for (i = 0; i < numShips - 1; i++) {
				ship = ships[i];
				ship.setPosition(Math.random() * stage.stageWidth, (Math.random() * 0.5 + 0.5) * stage.stageHeight);
				ship.setTarget(target);
			}
			
			// Position the last ship on top, centered for demo purposes
			ship = getDemoShip();
			ship.setPosition(stage.stageWidth * 0.5, stage.stageHeight * 0.2);
			ship.setTarget(ship.getPosition());	
		}
		
		/**
		 * Returns the meeting point used at startup
		 */
		public function getMeetingPoint():Point
		{
			return new Point(stage.stageWidth / 2, stage.stageHeight * 0.7);
		}
		
		/**
		 * Returns the ship used for demonstratory purposes
		 */
		public function getDemoShip():Ship
		{
			return ships[ships.length - 1];
		}
		
		public function touched(e:TouchEvent)
		{
			var ship:Ship;
			
			// Clear the temporary touch Vector and add new touches to it
			tempTouches.clear();
			e.getTouches(stage, null, tempTouches);
			
			for each (var touch:Touch in tempTouches) {
				switch (touch.phase) {
					case TouchPhase.BEGAN:
						// When beginning to touch, find the nearest ship
						// and assign it to the touch id, then move the ship.
						ship = findNearestShip(touch.getLocation(stage));
						touchMap[touch.id] = ship;
						shipTouch(ship, touch);
						break;
					case TouchPhase.MOVED:
						// For a moving touch, move the ship associated with it.
						ship = touchMap[touch.id];
						shipTouch(ship, touch);
						break;
					case TouchPhase.ENDED:
						// When the touch ends, delete the association with the ship.
						touchMap.deleteKey(touch.id);
						break;
				}
			}
		}
		
		/**
		 * Move the specified ship based on the provided touch.
		 */
		private function shipTouch(ship:Ship, touch:Touch) 
		{
			if (ship != null) ship.setTarget(touch.getLocation(stage));
		}
		
		/**
		 * Find the ship nearest to the provided point.
		 */
		private function findNearestShip(target:Point):Ship
		{
			var minDist = Number.POSITIVE_INFINITY;
			var minShip:Ship = null;
			for each (var ship in ships) {
				var dist = Point.distanceSquared(target, ship.getPosition());
				if (dist < minDist) {
					minDist = dist;
					minShip = ship;
				}
			}
			return minShip;
		}
		
		public function tick()
		{
			for (var i in ships) {
				for (var j in ships) {
					if (i == j) continue;
					// Make all the ships avoid all other ships
					ships[i].avoid(ships[j]);
				}
			}
			for each (var ship in ships) {
				ship.tick(dt);
			}
		}
		
		public function render() {
			for each (var ship in ships) {
				ship.render();
			}
		}
		
	}
}