package  
{
	import loom2d.animation.Transitions;
	import loom2d.display.Image;
	import loom2d.display.Sprite;
	import loom2d.Loom2D;
	import loom2d.math.Point;
	import loom2d.textures.Texture;
	import loom2d.ui.SimpleButton;
	
	/**
	 * Provides an overlay with instructions and credits.
	 */
	public class Help extends Sprite
	{
		private var hand:Image;
		private var instructions:Image;
		private var environment:Environment;
		
		private var credits:Image;
		private var creditsShown:Boolean = false;
		private var creditsBtn:SimpleButton;
		
		public function Help(environment:Environment) 
		{
			this.environment = environment;
			
			// Sets up the hand symbol shown at startup
			hand = new Image(Texture.fromAsset("assets/hand.png"));
			hand.pivotX = 105;
			hand.pivotY = 33;
			hand.rotation = -Math.PI*0.3;
			hand.visible = false;
			hand.scale = 0.6;
			hand.touchable = false;
			addChild(hand);
			
			// Overlay with instructions
			instructions = new Image(Texture.fromAsset("assets/instructions.png"));
			instructions.center();
			instructions.touchable = false;
			addChild(instructions);
			
			// Credits text overlay
			credits = new Image(Texture.fromAsset("assets/credits.png"));
			credits.center();
			credits.touchable = false;
			credits.alpha = 0;
			addChild(credits);
			
			// Credits button
			creditsBtn = new SimpleButton();
			creditsBtn.upImage = "assets/info.png";
			creditsBtn.onClick = toggleCredits;
			addChild(creditsBtn);
		}
		
		/**
		 * Shows and hides the credits
		 */
		private function toggleCredits():void 
		{
			Loom2D.juggler.tween(credits, 0.5, {
				alpha: creditsShown ? 0 : 1
			});
			creditsShown = !creditsShown;
		}
		
		/**
		 * Runs a demonstration with instructions
		 */
		public function run()
		{
			// Positioning and other initialization
			
			instructions.x = stage.stageWidth * 0.5;
			instructions.y = stage.stageHeight * 0.5;
			
			credits.x = stage.stageWidth * 0.5;
			credits.y = stage.stageHeight * 0.5;
			
			instructions.visible = true;
			instructions.alpha = 0;
			Loom2D.juggler.tween(instructions, 0.5, {
				delay: 1,
				alpha: 1
			});
			
			hand.visible = true;
			hand.alpha = 0;
			
			var ship = environment.getDemoShip();
			var meet = environment.getMeetingPoint();
			var p = ship.getPosition();
			
			hand.x = p.x;
			hand.y = p.y;
			
			
			// Animation with tweens
			
			Loom2D.juggler.tween(hand, 0.5, {
				delay: 1.5,
				alpha: 1,
				transition: Transitions.EASE_IN_OUT
			});
			
			Loom2D.juggler.tween(hand, 2, {
				delay: 2.1,
				x: meet.x,
				y: meet.y,
				transition: Transitions.EASE_IN_OUT,
				onUpdate: function() {
					ship.setTarget(new Point(hand.x, hand.y));
				}
			});
			
			Loom2D.juggler.tween(hand, 0.5, {
				delay: 4.2,
				alpha: 0,
				transition: Transitions.EASE_IN_OUT,
				onComplete: function() {
					hand.visible = false;
				}
			});
			
			Loom2D.juggler.tween(instructions, 0.5, {
				delay: 5,
				alpha: 0,
				onComplete: function() {
					instructions.visible = false;
				}
			});
			
		}
		
	}
	
}