package
{
	import feathers.display.TiledImage;
	import loom.sound.Sound;
	import loom.utils.Injector;
	import loom2d.display.Image;
	import loom2d.display.Sprite;
	import loom2d.display.Stage;
	import loom2d.events.Event;
	import loom2d.events.Touch;
	import loom2d.events.TouchPhase;
	import loom2d.math.Point;
	import loom2d.textures.Texture;
	import loom2d.textures.TextureSmoothing;
	import loom2d.ui.SimpleLabel;
	
	/**
	 */
	public class Environment
	{
		public static const GAMEOVER:String = "gameover";
		
		private var stage:Stage;
		
		private var dt:Number = 1/60;
		private var t:Number = 0;
		
		private var displayScale = 4;
		
		private var maxDepth:Number = 800;
		
		private var initOffset:Number = 280;
		private var introOffset:Number = 100;
		private var launchedOffset:Number = 0;
		
		private var display:Sprite = new Sprite();
		private var displayOffset:Number = initOffset;
		private var targetOffset:Number;
		private var cameraPos:Number = 0;
		
		private var launched:Boolean;
		
		private var w:Number;
		private var h:Number;
		
		private var sky:Image;
		private var sea:Image;
		private var seaTiled:TiledImage;
		private var player:Player;
		private var mines:Vector.<Mine> = new Vector.<Mine>();
		private var mineDisplay:Sprite = new Sprite();
		private var title:SimpleLabel;
		private var scoreTime:SimpleLabel;
		private var scoreMines:SimpleLabel;
		
		private var lastTouch:Touch;
		private var gameover:Boolean = false;
		
		private var ambience:Sound;
		
		public function Environment(stage:Stage)
		{
			this.stage = stage;
			
			display.scale = displayScale;
			stage.addChild(display);
			
			w = stage.stageWidth/display.scale;
			h = stage.stageHeight/display.scale;
			
			var tex:Texture;
			
			sky = new Image(Texture.fromAsset("assets/sky.png"));
			sky.width = w;
			sky.y = -sky.height;
			display.addChild(sky);
			
			display.addChild(mineDisplay);
			
			player = new Player(display, maxDepth);
			
			tex = Texture.fromAsset("assets/sea.png");
			tex.smoothing = TextureSmoothing.NONE;
			sea = new Image(tex);
			sea.width = w;
			sea.alpha = 0.5;
			display.addChild(sea);
			
			tex = Texture.fromAsset("assets/seaTiled.png");
			tex.smoothing = TextureSmoothing.NONE;
			seaTiled = new TiledImage(tex, 1);
			seaTiled.width = w;
			seaTiled.height = maxDepth;
			display.addChild(seaTiled);
			
			title = getLabel("Submersible Trouble", true, w/2, -85, 0.2);
			scoreTime  = getLabel("", false, 10, -50, 0.1);
			scoreMines = getLabel("", false, 10, -35, 0.1);
			
			ambience = Sound.load("assets/ObservingTheStar.ogg");
			ambience.setLooping(true);
			ambience.play();
			
			reset();
		}
		
		private function getLabel(txt:String, center:Boolean, x:Number, y:Number, scale:Number):SimpleLabel {
			var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = txt;
            if (center) label.center();
            label.x = x;
            label.y = y;
			label.scale = scale;
            display.addChild(label);
			return label;
		}
		
		public function reset() {
			t = 0;
			lastTouch = null;
			clearMines();
			placeMines();
			resetPlayer();
			render();
		}
		
		public function resetPlayer() {
			player.reset();
			player.setPosition(w/2, 0);
			player.setTarget(new Point(w/2, h/2));
			targetOffset = introOffset;
			launched = false;
		}
		
		private function clearMines() {
			while (mines.length > 0) {
				var mine:Mine = mines.pop();
				mine.dispose();
			}
		}
		
		private function placeMines() {
			for (var i = 0; i < 50; i++) {
				addMine(Math.randomRangeInt(0, w), 100+i*20);
			}
		}
		
		public function launch() {
			reset();
			targetOffset = launchedOffset;
			player.setVelocity(0, 120);
			launched = true;
		}
		
		public function touched(touch:Touch)
		{
			lastTouch = touch;
			if (touch.phase == TouchPhase.ENDED) lastTouch = null;
		}
		
		private function addMine(x:Number, y:Number) {
			var mine = new Mine(mineDisplay, maxDepth, player);
			mine.setPosition(x, y);
			mines.push(mine);
		}
		
		public function tick()
		{
			displayOffset += (targetOffset-displayOffset)*0.05;
			
			var targetCamera:Number;
			
			if (launched) {
				if (lastTouch) {
					var loc:Point = lastTouch.getLocation(display);
					player.setTarget(loc);
				}
				
				var mine:Mine;
				for each (mine in mines) {
					mine.tick(t, dt);
				}
				player.tick(t, dt);
				
				for (var i = 0; i < mines.length; i++) {
					mine = mines[i];
					mine.checkCollisionPlayer(player);
					for (var j = i+1; j < mines.length; j++) {
						mine.checkCollisionMine(mines[j]);
					}
				}
				
				if (player.state == Player.STATE_EXPLODED) {
					gameover = true;
					setScores();
					resetPlayer();
				}
				
				targetCamera = player.getDepth()-h/2+player.getDepthSpeed()*1;
			} else {
				targetCamera = 0;
			}
			
			var maxCameraSpeed = 5;
			cameraPos += Math.clamp((targetCamera-cameraPos)*0.02, -maxCameraSpeed, maxCameraSpeed);
			if (gameover && Math.abs(targetCamera-cameraPos) < 50) {
				gameover = false;
				stage.dispatchEvent(new Event(GAMEOVER));
			}
			
			t += dt;
		}
		
		private function setScores() {
			var explodedMines = 0;
			for each (var mine:Mine in mines) {
				if (mine.state == Mine.STATE_EXPLODED || mine.state == Mine.STATE_EXPLODING) explodedMines++;
			}
			
			scoreTime.text = "Time                                  " + getFormattedTime(t);
			scoreMines.text = "Mines exploded      " + explodedMines;
		}
		
		private function getFormattedTime(t:Number):String {
			var ms = t*1000;
			var sec = t;
			var min = t/60;
			return pad(Math.floor(min))+":"+pad(Math.floor(sec)%60)+"."+pad(Math.floor(ms)%1000, 3);
		}
		
		private function pad(x:Number, n:Number = 2):String {
			var s:String = ""+x;
			while (s.length < n) {
				s = "0"+s;
			}
			return s;
		}
		
		public function render() {
			for each (var mine:Mine in mines) {
				mine.render(t);
			}
			player.render(t);
			display.y = (displayOffset-cameraPos)*displayScale;
		}
		
	}
}