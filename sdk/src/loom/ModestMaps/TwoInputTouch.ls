package
{
	import loom2d.display.DisplayObject;
	import loom2d.display.Stage;
	import loom2d.math.Point;
	
	import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	
	public delegate DoubleTouchCallback(touch1Pos:Point, touch2Pos:Point):void;
	public delegate OnDoubleTouchEnd():void;

	public class TwoInputTouch extends DisplayObject
	{
		private var _stage:Stage;
		private var isTouchDown:Boolean = false;
		private var angleDelta:Number = 0;
		private var zoomDelta:Number = 0;
		private var touchCount:Number = 0;
		private var touch1:Touch;
		private var touch2:Touch;
		
		public var OnDoubleTouchEvent:DoubleTouchCallback;
		public var OnDoubleTouchEndEvent:OnDoubleTouchEnd;
		
		public var zoomSensitivity:Number = 0.005;
		public var rotationSensitivity:Number = 0.01;
		
		// Returns the change in angle between the current frame and the previous frame in degrees
		public function getAngleDelta():Number
		{
			if (!isTouchDown)
				return 0;
			else
				return Math.radToDeg(angleDelta);
		}
		
		// Returns the change in distance between the two touches between successive frames in pixels
		public function getZoomDelta():Number
		{
			if (!isTouchDown)
				return 0;
			else
				return zoomDelta;
		}
		
		public function getTouchCount():Number
		{
			if (!isTouchDown)
				return 0;
			else
				return touchCount;
		}
		
		public function getTouchMidPoint():Point
		{
			if (!isTouchDown)
			{
				trace("No touches detected on screen, returning a midpoint of zero from TwoTouchInput class");
				return Point.ZERO;
			}
			else
				return new Point((touch1.getLocation(_stage).x + touch2.getLocation(_stage).x) / 2 , (touch1.getLocation(_stage).y + touch2.getLocation(_stage).y) / 2);
		}
		
		public function getTouchMidPointDelta():Point
		{
			return new Point((touch1.getMovement(_stage).x + touch2.getMovement(_stage).x)/2, (touch1.getMovement(_stage).y + touch2.getMovement(_stage).y)/2);
		}
		
		function TwoInputTouch(mainStage:Stage)
		{
			_stage = mainStage;
			_stage.addEventListener(TouchEvent.TOUCH, OnTouch);
		}
		
		private function OnTouch(event:TouchEvent)
		{
			var touches = event.getTouches(_stage);
			touchCount = touches.length;
			
			// Determine whether we're starting or stopping a touch using the first touch because it's both the first and last touch to be registered
			if (touches[0].phase == TouchPhase.BEGAN)
				isTouchDown = true;
				
			if (touches[0].phase == TouchPhase.ENDED)
			{
				isTouchDown = false;
				OnDoubleTouchEndEvent();
			}
			
			// Make sure there are at least two touches before updating the angle or zoom delta
			if (touches.length > 1)
			{
				touch1 = touches[0];
				touch2 = touches[1];
				
				var prevAngle:Number = Math.atan2(touch2.getPreviousLocation(_stage).y - touch1.getPreviousLocation(_stage).y, touch2.getPreviousLocation(_stage).x - touch1.getPreviousLocation(_stage).x);
				var curAngle:Number = Math.atan2(touch2.getLocation(_stage).y - touch1.getLocation(_stage).y, touch2.getLocation(_stage).x - touch1.getLocation(_stage).x);
				angleDelta = curAngle - prevAngle;
								
				var prevDist = Math.sqrt(Math.pow((touch2.previousGlobalX - touch1.previousGlobalX), 2) + Math.pow((touch2.previousGlobalY - touch1.previousGlobalY), 2));
				var curDist = Math.sqrt(Math.pow((touch2.globalX - touch1.globalX), 2) + Math.pow((touch2.globalY - touch1.globalY), 2)); 
				zoomDelta = curDist - prevDist;
				
				// Tell anyone who's subscribed to our delegate that a change in the delta values has occured!
				OnDoubleTouchEvent(touch1.getLocation(_stage), touch2.getLocation(_stage));
			}	
		}
	}
}