package tests {
    
    import unittest.Assert;
    import unittest.TestComplete;
    import loom.platform.Timer;
    import system.platform.Platform;

    public class TimerTest {
        
        protected var infiniteRuns:int = 5;

        protected var delay:int;
        protected var runs:int;
        protected var allowedTimingError:Number;

        protected var time:int;
        protected var onStartCalls:int;
        protected var onCompleteCalls:int;
        protected var onPauseCalls:int;
        protected var onStopCalls:int;
        protected var testComplete:TestComplete;

        protected var pausee:Timer;
        protected var elapsedBeforePause:int;
        protected var timeOfResume:int;

        public function TimerTest() {}
        
        function onStart(timer:Timer) {
            Assert.compare(0, onCompleteCalls, "onComplete should not be called before onStart");
            Assert.compare(0, onPauseCalls, "onPause should not be called before onStart");
            Assert.compare(0, onStopCalls, "onStop should not be called before onStart");
            Assert.compare(0, timer.currentCount);
            Assert.compare(true, timer.running, "timer should be running in onStart");

            onStartCalls++;
        }

        function onComplete(timer:Timer) {
            Assert.compare(1, onStartCalls, "onStart should be called exactly once");
            Assert.compare(0, onStopCalls, "onStop should not be called before onComplete");
            Assert.compare(onCompleteCalls+1, timer.currentCount, "onComplete call number should equal current count");
            Assert.compare(true, timer.running, "timer should be running in onComplete");
            Assert.compareNumber(delay, timer.elapsed, "elapsed should match actual time taken", allowedTimingError);

            onCompleteCalls++;
        }

        function onPause(timer:Timer) {
            Assert.compare(1, onStartCalls, "onStart should be called exactly once");
            Assert.compare(false, timer.running, "timer should not be running in onPause");
                        
            onPauseCalls++;
        }

        function onStop(timer:Timer) {
            time = Platform.getTime() - time;

            Assert.compare(1, onStartCalls, "onStart should be called exactly once");
            Assert.compare(0, onStopCalls, "onStop should be called exactly once");
            if (timer.repeatCount > 0) {
                Assert.compare(timer.repeatCount, onCompleteCalls, "number of onComplete calls should equal the timer repeat count");
                Assert.compare(timer.repeatCount, timer.currentCount, "current count should equal repeat count");
                Assert.compareNumber(delay*runs, time, "timer too fast or too slow", allowedTimingError);
                Assert.compareNumber(delay, timer.elapsed, "elapsed should match actual time taken", allowedTimingError);
            } else {
                Assert.compare(infiniteRuns, timer.currentCount, "infinite timer should repeat the right amount of times before it gets stopped");
            }
            Assert.compare(false, timer.running, "timer should not be running in onStop");
            

            onStopCalls++;

            testComplete.done();
        }

        function testTimer(p:TestComplete, delay:int, runs:int, allowedTimingError:Number = 0.1):Timer {
            
            this.delay = delay;
            this.runs = runs;
            this.allowedTimingError = allowedTimingError;

            this.time = Platform.getTime();
            this.onStartCalls = 0;
            this.onCompleteCalls = 0;
            this.onPauseCalls = 0;
            this.onStopCalls = 0;
            this.testComplete = p;

            var timer = runs == 1 ? new Timer(delay) : new Timer(delay, runs);
            
            Assert.compare(delay, timer.delay, "set delay should apply");
            Assert.compare(runs, timer.repeatCount, "repeat count should equal the number of set runs");

            timer.onStart += onStart;
            timer.onComplete += onComplete;
            timer.onPause += onPause;
            timer.onStop += onStop;

            Assert.compare(false, timer.running, "timer should not be running before start");
            timer.start();
            Assert.compare(true, timer.running, "timer should be running after start");

            return timer;
        }
        
        [Test]
        function onceFast(p:TestComplete) {
            testTimer(p, 20, 1, 0.8);
        }

        [Test]
        function onceSlow(p:TestComplete) {
            testTimer(p, 500, 1);
        }

        [Test]
        function twice(p:TestComplete) {
            testTimer(p, 300, 2);
        }

        [Test]
        function infinite(p:TestComplete) {
            var timer = testTimer(p, 16*6, 0, 0.2);
            var stopper = new Timer(timer.delay*infiniteRuns + 40);
            stopper.onComplete += function() {
                timer.stop();
            };
            stopper.start();
        }
        
        [Test]
        function rapid(p:TestComplete) {
            testTimer(p, 15, 10, 1.5); // very generous error allowed
        }

        function onPauserComplete(pauser:Timer) {
            var timer = pausee;
            switch (pauser.currentCount) {
                case 1:
                    Assert.compare(0, onPauseCalls, "onPause should not have been called yet");
                    Assert.compare(true, timer.running, "timer should be running at first");
                    timer.pause();
                    elapsedBeforePause = timer.elapsed;
                    Assert.compare(1, onPauseCalls, "onPause should have been called exactly once");
                    break;

                case 2:
                    Assert.compare(elapsedBeforePause, timer.elapsed, "elapsed time should not change after pause");
                    Assert.compare(false, timer.running, "timer should still be stopped");
                    timer.play();
                    timeOfResume = Platform.getTime();
                    Assert.compare(true, timer.running, "timer should be running after play");
                    break;

                case 3:
                    Assert.compare(true, timer.running, "timer should still be running");
                    Assert.greater(timer.elapsed, elapsedBeforePause, "elapsed time should increase after resuming");
                    Assert.compareNumber(pauser.delay*2, timer.elapsed, "elapsed time should resume properly", 0.2);
                    break;
            }
        }

        [Test]
        function pause(p:TestComplete) {
            pausee = testTimer(p, 400, 1, 1.5);
            var pauser = new Timer(100, 3);
            pauser.onComplete += onPauserComplete;
            pauser.start();
        }
        
    }
    
}