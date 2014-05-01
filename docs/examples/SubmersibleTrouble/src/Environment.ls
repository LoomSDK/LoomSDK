package
{
	import feathers.display.TiledImage;
	import loom.sound.Listener;
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
		
		public static const STATE_INIT = 0;
		public static const STATE_LAUNCHED = 1;
		public static const STATE_RETURNING = 2;
		public static const STATE_RETURN = 3;
		public static const STATE_WINNER = 4;
		public var state:Number;
		
		private var over:Boolean = false;
		
		private var w:Number;
		private var h:Number;
		
		private var sky:Image;
		private var sea:Image;
		private var seaTiled:TiledImage;
		private var player:Player;
		private var mines:Vector.<Mine> = new Vector.<Mine>();
		private var mineDisplay:Sprite = new Sprite();
		private var arrowUp:Image;
		private var title:SimpleLabel;
		private var scoreTime:SimpleLabel;
		private var scoreMines:SimpleLabel;
		private var winnerTitle:SimpleLabel;
		private var returnStartTime:Number;
		
		private var lastTouch:Touch;
		
		private var ambience:Sound;
		private var winnerSound:Sound;
		private var warning:Sound;
		
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
			
			tex = Texture.fromAsset("assets/arrowUp.png");
			tex.smoothing = TextureSmoothing.NONE;
			arrowUp = new Image(tex);
			arrowUp.center();
			arrowUp.x = w/2;
			display.addChild(arrowUp);
			
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
			seaTiled.height = maxDepth+h*2;
			display.addChild(seaTiled);
			
			title = getLabel("Submersible Trouble", true, w/2, -85, 0.2);
			scoreTime  = getLabel("", false, 10, -47, 0.1);
			scoreMines = getLabel("", false, 10, -35, 0.1);
			winnerTitle = getLabel("WINNER!", true, w/2, -62, 0.15);
			winnerTitle.visible = false;
			
			ambience = Sound.load("assets/ObservingTheStar.ogg");
			ambience.setLooping(true);
			ambience.setListenerRelative(false);
			ambience.play();
			
			winnerSound = Sound.load("assets/winner.ogg");
			winnerSound.setListenerRelative(false);
			
			warning = Sound.load("assets/warning.ogg");
			warning.setListenerRelative(false);
			
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
			arrowUp.visible = false;
			targetOffset = introOffset;
			resetPlayer();
			state = STATE_INIT;
			render();
		}
		
		public function resetPlayer() {
			if (state == STATE_WINNER) {
				player.reset(false);
			} else {
				player.reset();
				player.setPosition(w/2, 0);
			}
			player.setTarget(new Point(w/2, h/2));
		}
		
		private function clearMines() {
			while (mines.length > 0) {
				var mine:Mine = mines.pop();
				mine.dispose();
			}
		}
		
		private function placeMines() {
			var offset = 100;
			var mineNum = 45;
			for (var i = 0; i < mineNum; i++) {
				addMine(Math.randomRangeInt(0, w), offset+(maxDepth-offset-h)*mineDistribution(i/(mineNum-1)));
			}
		}
		
		private function mineDistribution(x:Number):Number {
			var sharpness:Number = 5;
			return Math.log(1+x*sharpness)/Math.log(1+sharpness);
		}
		
		public function launch() {
			reset();
			targetOffset = launchedOffset;
			player.setVelocity(0, 120);
			player.launch();
			state = STATE_LAUNCHED;
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
			
			if (state != STATE_INIT) {
				if (state != STATE_WINNER && state != STATE_RETURNING && lastTouch) {
					var loc:Point = lastTouch.getLocation(display);
					player.setTarget(loc);
				}
				entityTick();
				checkCollisions();
				if (player.state == Player.STATE_EXPLODED) {
					gameover();
				}
			}
			
			switch (state) {
				case STATE_INIT:
					targetCamera = 0;
					break;
				case STATE_LAUNCHED:
					if (player.getDepth() > maxDepth) {
						state = STATE_RETURNING;
						returnStartTime = t;
						arrowUp.y = player.getDepth()+50;
						arrowUp.visible = true;
						warning.play();
					}
					targetCamera = player.getDepth()-h/2+player.getDepthSpeed()*1;
					break;
				case STATE_RETURNING:
					arrowUp.alpha = 0.25+0.75*0.5*(Math.sin(t*Math.PI*5)+1);
					if (t-returnStartTime > 2) {
						state = STATE_RETURN;
						player.state = Player.STATE_RETURN;
						arrowUp.visible = false;
					}
					targetCamera = player.getDepth()-h/2+player.getDepthSpeed()*1;
					break;
				case STATE_RETURN:
					if (player.getDepth() < h) {
						gameover(true);
					}
					targetCamera = player.getDepth()-h/2+player.getDepthSpeed()*1.2;
					break;
				case STATE_WINNER:
					targetCamera = 0;
					break;
			}
			
			var maxCameraSpeed = 5;
			cameraPos += Math.clamp((targetCamera-cameraPos)*0.02, -maxCameraSpeed, maxCameraSpeed);
			if (over && Math.abs(targetCamera-cameraPos) < 50) {
				over = false;
				stage.dispatchEvent(new Event(GAMEOVER));
			}
			
			t += dt;
		}
		
		private function entityTick() {
			var mine:Mine;
			for each (mine in mines) {
				mine.tick(t, dt);
			}
			player.tick(t, dt);
		}
		
		private function checkCollisions() {
			var mine:Mine;
			for (var i = 0; i < mines.length; i++) {
				mine = mines[i];
				mine.checkCollisionPlayer(player);
				for (var j = i+1; j < mines.length; j++) {
					mine.checkCollisionMine(mines[j]);
				}
			}
		}
		
		private function gameover(winner:Boolean = false) {
			over = true;
			setScores();
			targetOffset = introOffset;
			winnerTitle.visible = winner;
			if (winner) {
				state = STATE_WINNER;
				player.state = Player.STATE_WINNER;
				player.setTarget(new Point(w/2, 0));
				winnerSound.play();
			} else {
				state = STATE_INIT;
				resetPlayer();
			}
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