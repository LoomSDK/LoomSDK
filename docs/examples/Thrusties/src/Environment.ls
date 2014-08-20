package
{
	import loom.utils.Injector;
	import loom2d.display.Stage;
	import loom2d.math.Point;
	
	/**
	 * Manages all the Ships and defines the environment they reside in.
	 */
	public class Environment
	{
		private var stage:Stage;
		
		private var numShips = 5;
		private var dt:Number = 1/60;
		
		private var ships:Vector.<Ship> = new Vector.<Ship>();
		
		public function Environment(stage:Stage)
		{
			this.stage = stage;
			
			for (var i = 0; i < numShips; i++) {
				var ship = new Ship(stage);
				// Randomly position ships on the stage initially
				ship.setPosition(Math.random()*stage.stageWidth, Math.random()*stage.stageHeight);
				ships.push(ship);
			}
			
			// Set the initial target to the center of the stage
			touched(new Point(stage.stageWidth/2, stage.stageHeight/2));
		}
		
		public function touched(location:Point)
		{
			for each (var ship in ships) {
				ship.setTarget(location);
			}
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