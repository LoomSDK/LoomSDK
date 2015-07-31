package tests {
    
    import system.platform.Platform;
    import unittest.Assert;
    
    public class AllocationPerformanceTest {
        
        public function AllocationPerformanceTest() {
            
        }
        
        [Test]
        public function allocPoints() {
            var n = 10000;
            var durationThreshold = 10;
            var time = Platform.getTime();
            for (var i:int = 0; i < n; i++) {
                var p = new Point();
            }
            var delta = Platform.getTime()-time;
            Assert.less(delta, durationThreshold, "Point allocation should not take more than "+durationThreshold/n*1000+"us: "+delta/n*1000+"us");
        }
        
    }
    
}