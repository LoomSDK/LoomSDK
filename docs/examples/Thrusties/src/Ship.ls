package
{
    import loom.sound.Sound;
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.display.Stage;
    import loom2d.math.Matrix;
    import loom2d.math.Point;
    import loom2d.textures.Texture;
	
	/**
	 * Runs all the spaceship-related simulation and logic - the main part.
	 * The actual motion integration happens in Entity.
	 */
	public class Ship extends Entity
	{
		public var stage:Stage;
		
		private var thrusterEngineSound:Sound;
		
		private var display:Sprite;
		
		private var thrustForwardMax:Number = 50;
		private var thrustAngularMax:Number = 200;
		private var shipAvoidMaxDistance:Number = 250;
		private var shipAvoidOffset:Number = -4;
		private var shipAvoidForce:Number = 200;
		
		private var forwardSpeed:Number = 0.5;
		private var approachCompensation:Number = 2/forwardSpeed;
		private var antiSpin:Number = 0.2;
		private var angularCompensation:Number = 1.1;
		private var distanceThreshold:Number = 20;
		private var angularSpeed:Number = 100;
		private var offsetThrustSpread:Number = Math.PI*0.3;
		
		private var body:Image;
		private var thrusterMain:Image;
		private var thrusterSideTL:Image;
		private var thrusterSideTR:Image;
		private var thrusterSideBL:Image;
		private var thrusterSideBR:Image;
		
		private var debugA:Image;
		private var debugB:Image;
		
		private var tempMatrix:Matrix = new Matrix();
		
		private var offsetForce:Point = new Point();
		
		private var target:Point;
		private var bearing:Number = 0;
		private var angularVel:Number = 0;
		
		private var thrustForward:Number = 0;
		private var thrustAngular:Number = 0;
		private var engineActivity:Number = 0;
		
		public function Ship(stage:Stage)
		{
			this.stage = stage;
			
			thrusterEngineSound = Sound.load("assets/sprayLoop.ogg");
			thrusterEngineSound.setLooping(true);
			thrusterEngineSound.setPitch(0);
			thrusterEngineSound.play();
			
			display = new Sprite();
			display.scale = 0.5;
			
			var fireMain = Texture.fromAsset("assets/fireMain.png");
			var fireSide = Texture.fromAsset("assets/fireSide.png");
			
			thrusterMain = createThruster(-36, 0, 0.5, 1, -Math.PI*0.5, fireMain);
			thrusterSideTL = createThruster( 32, -6, 0.5, 0, Math.PI*(-0.5-0.2), fireSide);
			thrusterSideTR = createThruster( 32,  6, 0.5, 0, Math.PI*(-0.5+0.2), fireSide);
			thrusterSideBL = createThruster(-36, -12, 0.5, 0, Math.PI*(0.5+0.2), fireSide);
			thrusterSideBR = createThruster(-36,  12, 0.5, 0, Math.PI*(0.5-0.2), fireSide);
			
			body = new Image(Texture.fromAsset("assets/playerShip2_orange.png"));
			body.center();
			body.rotation = Math.PI*0.5;
			display.addChild(body);
			
			stage.addChild(display);
			
			debugA = new Image(Texture.fromAsset("assets/star_gold.png"));
			debugA.center();
			debugA.scale = 0.5;
			// Uncomment to see final / compensated target points
			//stage.addChild(debugA);
			
			debugB = new Image(Texture.fromAsset("assets/star_silver.png"));
			debugB.center();
			debugB.scale = 0.5;
			// Uncomment to see actual target points
			//stage.addChild(debugB);
		}
		
		/**
		 * Convenience method for creating an Image for a thruster
		 */
		private function createThruster(x:Number, y:Number, pivotX:Number, pivotY:Number, rot:Number, tex:Texture):Image
		{
			var thruster = new Image(tex);
			thruster.x = x;
			thruster.y = y;
			thruster.pivotX = pivotX*thruster.width;
			thruster.pivotY = pivotY*thruster.height;
			thruster.rotation = rot;
			display.addChild(thruster);
			return thruster;
		}
		
		public function setPosition(x:Number, y:Number)
		{
			p.x = x;
			p.y = y;
		}
		
		public function getPosition():Point
		{
			return p;
		}
		
		public function setTarget(t:Point)
		{
			target = t;
		}
		
		/**
		 * Return the difference between two arbitrary angles in the closest direction
		 */
		private function angleDifference(source:Number, target:Number):Number
		{
			var d:Number = target-source;
			d = ((d+Math.PI)%Math.TWOPI+Math.TWOPI)%Math.TWOPI-Math.PI;
			return d;
		}
		
		public function avoid(ship:Ship)
		{
			var dist = Point.distance(p, ship.p);
			var d = ship.p-p;
			// Change the amount of avoidance added to the offset force based on the distance
			d.normalize(shipAvoidOffset+shipAvoidForce*Math.max(0, (shipAvoidMaxDistance-dist)/shipAvoidMaxDistance));
			offsetForce -= d;
		}
		
		override public function tick(dt:Number)
		{
			// Reset the thrust amounts for the current tick
			thrustForward = thrustAngular = 0;
			
			// Use a rotation matrix to adjust the direction
			// of the velocity to prevent spinning in circles
			tempMatrix.identity();
			tempMatrix.rotate(angularVel*antiSpin);
			
			var rv = tempMatrix.transformCoord(v.x, v.y);
			
			// Adjust the target to compensate for the current velocity
			var comp = target;
			comp.x -= rv.x*approachCompensation;
			comp.y -= rv.y*approachCompensation;
			
			// Add offset (avoidance) forces as an offset to the
			// compensated target, this keeps the ships apart
			comp += offsetForce;
			
			// Reset the offset forces
			offsetForce.x = offsetForce.y = 0;
			
			// If enabled, show compensated and actual target
			debugA.x = comp.x;
			debugA.y = comp.y;
			debugB.x = target.x;
			debugB.y = target.y;
			
			// Target delta between comp. target and current position
			var targetVector = comp-p;
			
			// Absolute angle/distance of target delta
			var targetBearing = Math.atan2(targetVector.y, targetVector.x);
			var targetDistance = targetVector.length;
			
			// Relative angle between current heading and target heading
			var bearingDiff = angleDifference(bearing, targetBearing);
			
			// Add turning thrust force accounting for current angular velocity
			turn(angleDifference(angularVel*angularCompensation, bearingDiff)*angularSpeed);
			
			// Attenuate forward thrust if not pointed towards the target
			var offsetThrustAttenuation:Number = Math.max(0, (offsetThrustSpread-Math.abs(bearingDiff))/offsetThrustSpread);
			
			// Add forward thrust based on distance with some leeway
			thrust((targetDistance-distanceThreshold)*forwardSpeed*offsetThrustAttenuation);
			
			applyThrust(dt);
			
			super.tick(dt);
		}
		
		private function turn(delta:Number)
		{
			thrustAngular += delta;
		}
		
		private function thrust(delta:Number)
		{
			thrustForward += delta;
		}
		
		private function applyThrust(dt:Number)
		{
			// Constrain thrust to min/max values
			thrustForward = Math.clamp(thrustForward, 0, thrustForwardMax);
			thrustAngular = Math.clamp(thrustAngular, -thrustAngularMax, thrustAngularMax);
			
			// Calculate a fuzzy, eased imaginary engine activity value used for visual/audio purposes
			engineActivity += (thrustForward+(Math.random()-0.5)*10-engineActivity)*0.1;
			
			// Change engine sound pitch based on engine activity
			thrusterEngineSound.setPitch((engineActivity*0.02)*0.1);
			
			// Add forward thrust to acceleration
			a.x += thrustForward*Math.cos(bearing);
			a.y += thrustForward*Math.sin(bearing);
			
			// Add angular thrust to angular velocity
			angularVel += thrustAngular*dt*dt;
			
			// Apply angular velocity to current heading
			bearing += angularVel*dt;
		}
		
		private function exponentialRamp(x:Number, steepness:Number):Number
		{
			var sign = x < 0 ? -1 : 1;
			return (1-Math.exp(-x*sign*steepness))*sign;
		}
		
		override public function render()
		{
			// Scale engine exhausts by the engine activity and current thrust values
			
			var mainScale = exponentialRamp(engineActivity/thrustForwardMax, 10);
			thrusterMain.scaleY = mainScale;
			
			var sideScale = exponentialRamp(thrustAngular/thrustAngularMax, 20);
			thrusterSideTL.scaleY = Math.max(0,  sideScale);
			thrusterSideTR.scaleY = Math.max(0, -sideScale);
			thrusterSideBL.scaleY = Math.max(0, -sideScale);
			thrusterSideBR.scaleY = Math.max(0,  sideScale);
			
			// Apply the current position and heading to the graphic display
			display.x = p.x;
			display.y = p.y;
			display.rotation = bearing;
		}
		
	}
}