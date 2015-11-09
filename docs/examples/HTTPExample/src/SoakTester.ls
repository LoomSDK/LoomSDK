package
{
    import loom.HTTPRequest;
    import system.platform.Platform;

    public class SoakRequest
    {
        private var tester:SoakTester;
        public var req:HTTPRequest;
        
        public var recvSuccess:Boolean;
        public var lenSuccess:Boolean;
        
        public var sendTime:Number;
        public var reqTime:Number;
        
        public function SoakRequest(tester:SoakTester, url:String) {
            this.tester = tester;
            req = new HTTPRequest(url);
            req.onSuccess += onSuccess;
            req.onFailure += onFailure;
        }
        public function send():Boolean {
            sendTime = Platform.getTime();
            return req.send();
        }
        public function onSuccess(bytes:ByteArray):void {
            reqTime = Platform.getTime()-sendTime;
            recvSuccess = true;
            lenSuccess = (bytes.length == SoakTester.BYTES);
            tester.requestFinished(this);
        }
        
        public function onFailure(bytes:ByteArray):void {
            reqTime = Platform.getTime()-sendTime;
            recvSuccess = false;
            lenSuccess = false;
            tester.requestFinished(this);
        }
        
        public function finish() {
            tester = null;
            req.onSuccess = null;
            req.onFailure = null;
            req = null;
        }
    }
    
    public class SoakTester
    {
        // The URL to access, a random parameter gets appended at the end, and the expected byte length of the content for verification
        public static const URL = "http://192.168.1.108/np-nouser.json"; public static const BYTES = 68;
        
        // The maximum number of simultaneous requests
        //private static const MAX_REQUESTS = 1;
        private static const MAX_REQUESTS = 127;
        
        // Time limit for the test, set to Number.POSITIVE_INFINITY for unlimited
        //private static const TIME = 60;
        private static const TIME = Number.POSITIVE_INFINITY;
        
        // Print the current state every X frames
        private const UPDATE_FRAMES = 30;
        
        var running = false;
        var overtime:Boolean;
        var requests:Vector.<SoakRequest>;
        var startTime:Number;
        var frame:int;
        
        var count:int;
        var sendSuccess:int;
        var sendFailure:int;
        var recvSuccess:int;
        var recvFailure:int;
        var lenSuccess:int;
        var lenFailure:int;
        
        var reqTime:Number;
        
        public function run()
        {
            running = true;
            overtime = false;
            requests = new Vector.<HTTPRequest>();
            startTime = Platform.getTime();
            frame = 0;
            
            count = 0;
            sendSuccess = 0;
            sendFailure = 0;
            recvSuccess = 0;
            recvFailure = 0;
            lenSuccess = 0;
            lenFailure = 0;
            
            reqTime = 0;
            
            Profiler.enable();
        }
        
        public function onTick()
        {
            if (!running) return;
            
            overtime = (Platform.getTime() - startTime) > TIME*1000;
            
            nextRequests();
            
            if (frame%UPDATE_FRAMES == 0) printUpdate();
            
            if (overtime && requests.length == 0) {
                running = false;
                trace("Stopped");
                printUpdate();
                Profiler.dump();
            }
            
            frame++;
        }
        
        public function nextRequests()
        {
            while (!overtime && requests.length < MAX_REQUESTS) {
                var req = new SoakRequest(this, URL+"?random="+Math.random());
                count++;
                var success = req.send();
                if (success) {
                    sendSuccess++;
                    requests.push(req);
                } else {
                    sendFailure++;
                    req.finish();
                    break;
                }
            }
        }
        
        public function requestFinished(req:SoakRequest) {
            if (req.recvSuccess) recvSuccess++; else recvFailure++;
            if (req.lenSuccess) lenSuccess++; else lenFailure++;
            reqTime += req.reqTime;
            requests.splice(requests.indexOf(req), 1);
            req.finish();
            nextRequests();
        }
        
        private function printUpdate() {
            var info = "";
            info += "\nIn-flight: "+requests.length+" ";
            info += "\nSent: "+sendSuccess+", "+sendFailure+" failed";
            info += "\nRecv: "+recvSuccess+", "+recvFailure+" failed";
            info += "\nLeng: "+lenSuccess+", "+lenFailure+" failed";
            info += "\nAvg time: "+Math.round(reqTime/(recvSuccess+recvFailure)*100)/100+"ms";
            Debug.print(info);
        }
        
        
        
    }
}