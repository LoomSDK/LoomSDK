package
{

    import loom.Application;    
    import loom.platform.Timer;
    
    import loom2d.Loom2D;
    import loom2d.display.Image;        
    import loom2d.display.StageScaleMode;
    import loom2d.animation.Transitions;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;

    import loom2d.math.Point;

    public class WhackAMole extends Application
    {
        protected var timer:Timer;
        protected var moles:Vector.<Image>;
        protected var moleStates:Vector.<Boolean>;
        protected var scores:Vector.<SimpleLabel>;
        protected var misses:Vector.<SimpleLabel>;
        protected var waitTime:Number;
        protected var totalScore:SimpleLabel;
        protected var total:Number;
        protected var strikes:Number;
        protected var retryButton:Image;
        protected var timeLabel:SimpleLabel;
        protected var gameTimer:Timer;

        override public function run():void
        {

            stage.scaleMode = StageScaleMode.FILL;

            var screenWidth = stage.stageWidth;
            var screenHeight = stage.stageHeight;            
         
            waitTime = 0.5;
            strikes = 0;

            var ground = new Image(Texture.fromAsset("assets/background/bg_dirt.png"));
            ground.x = 0;
            ground.y = 0;
            ground.touchable = false;
            stage.addChild(ground);

            var top = new Image(Texture.fromAsset("assets/foreground/grass_upper.png"));
            top.x = 0;
            top.y = 0;
            top.height = 160;
            top.width = 480;
            top.touchable = false;
            stage.addChild(top);

            var mole1 = new Image(Texture.fromAsset("assets/sprites/mole_1.png"));
            mole1.x = 50;
            mole1.y = 180;
            mole1.scale = 0.5;
            stage.addChild(mole1);

            mole1.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                if (e.getTouch(mole1, TouchPhase.BEGAN)) {                    
                    whackMole(e, mole1); 
                } } );            

            var mole2 = new Image(Texture.fromAsset("assets/sprites/mole_1.png"));
            mole2.x = 195;
            mole2.y = 180;
            mole2.scale = 0.5;
            stage.addChild(mole2);

            mole2.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                if (e.getTouch(mole2, TouchPhase.BEGAN)) {                    
                    whackMole(e, mole2);
                } } );            

            var mole3 = new Image(Texture.fromAsset("assets/sprites/mole_1.png"));
            mole3.x = 340;
            mole3.y = 180;
            mole3.scale = 0.5;
            stage.addChild(mole3);

            mole3.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                if (e.getTouch(mole3, TouchPhase.BEGAN)) {                    
                    whackMole(e, mole3);
                } } );            

            moles = [mole1, mole2, mole3];
            moleStates = [false, false, false];

            var bottom = new Image(Texture.fromAsset("assets/foreground/grass_lower.png"));
            bottom.x = 0;
            bottom.y = 160;
            bottom.width = 480;    
            bottom.height = 160;   
            bottom.touchable = false; 
            stage.addChild(bottom);

            total = 0;
            totalScore = new SimpleLabel("assets/Curse-hd.fnt");
            totalScore.text = "Score: 0";
            totalScore.x = screenWidth/2 - totalScore.size.x*.5/2;
            totalScore.y = 16;
            totalScore.scale = .5;
            totalScore.touchable = false;
            stage.addChild(totalScore);

            retryButton = new Image(Texture.fromAsset("assets/retry.png"));
            retryButton.x = screenWidth/2 - retryButton.width*.5/2;
            retryButton.y = screenHeight - 24 - retryButton.height/2;
            retryButton.scale = 0.5;

            retryButton.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                if (e.getTouch(retryButton, TouchPhase.BEGAN))
                {
                    resetGame();
                    e.stopImmediatePropagation();
                }
            } );            

            timeLabel = new SimpleLabel("assets/Curse-hd.fnt");
            timeLabel.text = "30";
            timeLabel.x = 410;
            timeLabel.y = 16;
            timeLabel.scale = 0.5;
            timeLabel.touchable = false;
            stage.addChild(timeLabel);

            gameTimer = new Timer(30000);
            gameTimer.onComplete = endGame;
            gameTimer.start();

            timer = new Timer(1000);
            timer.onComplete = onTimerComplete;
            timer.start();

            stage.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 

                var touch = e.getTouch(stage, TouchPhase.BEGAN);

                if (!touch)
                    return;                

                onMiss(touch.globalX, touch.globalY);
                    
            } );            

            createScoreLabels();
        }

        override public function onTick()
        {
            timeLabel.text = (30-Math.round(gameTimer.elapsed/1000)).toString();
        }

        protected function createScoreLabels()
        {
            // create a pool a score labels to pull from
            scores = new Vector.<SimpleLabel>();
            misses = new Vector.<SimpleLabel>();
            for(var i = 0; i<4; i++)
            {
                var score = new SimpleLabel("assets/Curse-hd.fnt");
                score.text = "+100";
                score.scale = 0.5;
                score.y = 400;
                score.touchable = false;
                scores.push(score);
                stage.addChild(score);

                var miss = new SimpleLabel("assets/Red-hd.fnt");
                miss.text = "miss";
                miss.y = 400;
                miss.touchable = false;
                misses.push(miss);
                stage.addChild(miss);
            }
        }

        protected function getAvailableScoreLabel():SimpleLabel
        {
            for(var i = 0; i<scores.length; i++)
            {
                var score = scores[i];
                if(!Loom2D.juggler.containsTweens(score))
                    return score;
            }

            // default, return the first one
            Loom2D.juggler.removeTweens(scores[0]);
            return scores[0];
        }

        protected function getAvailableMissLabel():SimpleLabel
        {
            for(var i = 0; i<misses.length; i++)
            {
                var miss = misses[i];
                if(!Loom2D.juggler.containsTweens(miss))
                    return miss;
            }

            // default, return the first one
            Loom2D.juggler.removeTweens(misses[0]);
            return misses[0];
        }

        protected function onTimerComplete(timer:Timer)
        {
            for(var i = 0; i<moles.length; i++)
            {
                if(Math.floor(Math.random()*4) == 0)
                {
                    var mole = moles[i];

                    if(moleStates[i] == true) {
                        moleStates[i] = false;
                        mole.source = "assets/sprites/mole_1.png";
                    }

                    if(!Loom2D.juggler.containsTweens(mole))
                    {
                        Loom2D.juggler.tween(mole, 0.5, {"y": 85, "transition": Transitions.EASE_OUT});
                        Loom2D.juggler.tween(mole, 0.3, {"y": 180, "transition": Transitions.EASE_OUT, "delay": 0.5+waitTime});
                    }
                }
            }

            // play the timer again
            timer.start();
        }

        protected function whackMole(e:TouchEvent, mole:Image)
        {

            if(strikes == 3) 
                return;

            var index = moles.indexOf(mole);

            if(moleStates[index] == false && mole.y < 125) 
            {
                // increase the difficulty as we get more moles
                waitTime *= 0.9;
                timer.delay *= 0.9;

                // update our whacked state
                moleStates[index] = true;

                // animate a score
                var score = getAvailableScoreLabel();
                score.x = mole.x;
                score.y = mole.y;
                score.scale = 0;

                total += 100;
                totalScore.text = "Score: " + total.toString();
                // center
                totalScore.x = stage.stageWidth/2 - totalScore.size.x*.5/2;

                Loom2D.juggler.tween(score, 0.3, {"scaleX": 0.5, "transition": Transitions.EASE_OUT_BACK});
                Loom2D.juggler.tween(score, 0.3, {"scaleY": 0.5, "transition": Transitions.EASE_OUT_BACK});
                Loom2D.juggler.tween(score, 0.3, {"y": -100, "transition": Transitions.EASE_IN_BACK, "delay": 0.3});

                Loom2D.juggler.removeTweens(mole);
                mole.source = "assets/sprites/mole_thump4.png";
                Loom2D.juggler.tween(mole, 0.3, {"y": 180, "transition": Transitions.EASE_OUT, "delay": 0.1});

                // stop the event propogating to the miss handler
                e.stopImmediatePropagation();
            }
        }

        protected function onMiss(x:Number, y:Number)
        {
            if(strikes == 3) 
                return;

            strikes++;

            var miss = getAvailableMissLabel();
            miss.x = x - miss.width/2;
            miss.y = y - miss.height/2;
            miss.scale = 0;

            Loom2D.juggler.tween(miss, 0.3, {"scaleX": 0.5, "scaleY": 0.5, "transition": Transitions.EASE_OUT_BACK});
            Loom2D.juggler.tween(miss, 0.3, {"y": -100, "transition": Transitions.EASE_IN_BACK, "delay": 0.3});

            if(strikes == 3) {
                endGame();
            }
        }

        protected function endGame(t:Timer=null)
        {
            strikes = 3;
            stage.removeChild(timeLabel);
            timer.stop();
            gameTimer.stop();

            if(retryButton.parent == null)
                stage.addChild(retryButton);
        }

        protected function resetGame()
        {
            stage.addChild(timeLabel);
            strikes = 0;
            total = 0;
            totalScore.text = "Score: 0";
            totalScore.x = stage.stageWidth/2 - totalScore.size.x*.5/2;
            timer.start();
            gameTimer.start();
            stage.removeChild(retryButton);
            waitTime = 0.5;
            timer.delay = 1000;
        }
    }
}