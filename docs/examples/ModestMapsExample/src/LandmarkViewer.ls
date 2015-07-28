package
{
    import loom.modestmaps.extras.Distance;
    import loom.modestmaps.geo.Location;
    import loom.modestmaps.Map;
    import loom.modestmaps.mapproviders.MapboxProvider;
    import loom2d.display.Graphics;
    import loom2d.display.Shape;
    import loom2d.display.TextAlign;
    import loom2d.display.TextFormat;
    import loom2d.math.Point;
    import system.platform.File;
    import system.platform.Platform;
    
    class Volcano {
        public var number:String;
        public var name:String;
        public var country:String;
        public var region:String;
        public var latitude:Number;
        public var longitude:Number;
        public var elevation:Number;
        public var type:String;
        public var status:String;
        public var lastEruption:String;
    }
    
    public class LandmarkViewer
    {
        private static const DELAY_TIME = 5000;
        private static const INFO_SIZES:Vector.<int> = [
            50,
            80,
            60,
            50,
            30
        ];
        private static const ERUPTION:Dictionary.<String, String> = {
            "D1": "2000 or later",
            "D2": "1900-1999",
            "D3": "1800-1899",
            "D4": "1700-1799",
            "D5": "1500-1699",
            "D6": "A.D. 1-1499",
            "D7": "B.C. Holocene\n(11.7 thousand years ago to A.D.)",
            "U": "not dated, likely Holocene\n(11.7 thousand years ago to the present)",
            "?": "2000 or later",
            "Q": "quaternary period\n(2.588 million years ago to the present)"
        };
        
        private var sHelperPoint:Point;
        
        private var dt:Number = 1/60;
        
        private var map:Map;
        
        private var volcanoShowcase = false;
        private var volcanoes:Vector.<Volcano>;
        private var randomVolcano:Volcano;

        private var flying:Boolean = false;
        private var flyCallback:Function;
        private var flyTarget:Location;
        private var flyPoint:Point;
        private var flySpeed:Number;
        private var flyInfo:Vector.<String>;
        private var delaying:Boolean = false;
        private var delayStartTime:int;
        
        private var overlay:Shape;
        private var debugTextFormat:TextFormat;
        private var mainTextFormat:TextFormat;
        
        public function LandmarkViewer(map:Map)
        {
            this.map = map;
            
            
            TextFormat.load("sans", "assets/SourceSansPro-Regular.ttf");
            debugTextFormat = new TextFormat("sans", 30, 0xFFFFFF);
            
            mainTextFormat = new TextFormat("sans", 50, 0xFFFFFF);
            mainTextFormat.align = TextAlign.TOP | TextAlign.CENTER;
            
            overlay = new Shape();
            map.addChild(overlay);
        }
        
        public function loadVolcanoes(path:String)
        {
            var csv:String = File.loadTextFile(path);
            volcanoes = new Vector.<Volcano>();
            var lines = csv.split("\n");
            for (var i = 1; i < lines.length; i++) {
                var cols = lines[i].trim().split("\t");
                if (cols.length < 10) {
                    Debug.assert(false, "Invalid data " + cols);
                }
                var v:Volcano = new Volcano();
                v.number       = cols[0];
                v.name         = cols[1];
                v.country      = cols[2];
                v.region       = cols[3];
                v.latitude     = cols[4] == "" ? NaN : Number.fromString(cols[4]);
                v.longitude    = cols[5] == "" ? NaN : Number.fromString(cols[5]);
                v.elevation    = cols[6] == "" ? NaN : Number.fromString(cols[6]);
                v.type         = cols[7];
                v.status       = cols[8];
                v.lastEruption = cols[9];
                volcanoes.push(v);
            }
            runVolcanoShowcase();
        }
        
        public function runVolcanoShowcase()
        {
            map.setMapProvider(new MapboxProvider("mapbox.satellite", File.loadTextFile("assets/mapbox/token.txt")));
            map.setCenterZoom(new Location(80, 0), -5);
            
            volcanoShowcase = true;
            nextVolcano();
        }
        
        private function nextVolcano() {
            randomVolcano = volcanoes[Math.randomRangeInt(0, volcanoes.length-1)];
            
            var info = new Vector.<String>();
            info.push(randomVolcano.status+" "+randomVolcano.type);
            info.push(randomVolcano.name);
            info.push(randomVolcano.elevation+"m");
            info.push(randomVolcano.region+", "+randomVolcano.country);
            
            var lastEruption = ERUPTION.fetch(randomVolcano.lastEruption, "unknown");
            info.push("Last eruption "+(lastEruption == "unknown" ? "is" : "was")+" "+lastEruption);
            //info += "\n("+)";
            
            //trace(">"+randomVolcano.lastEruption.charCodeAt(randomVolcano.lastEruption.length-1)+"<");
            
            flyTo(new Location(randomVolcano.latitude, randomVolcano.longitude), info, onVolcanoFocus);
        }
        
        private function flyTo(location:Location, info:Vector.<String>, callback:Function) {
            flyTarget = location;
            flyInfo = info;
            flyCallback = callback;
            delaying = false;
            flying = true;
            flySpeed = 0;
        }
        
        private function onVolcanoFocus() {
        }
        
        public function onTick()
        {
            if (flying) fly();
        }
        
        private function fly() {
            var g:Graphics = overlay.graphics;
            
            g.clear();
            g.textFormat(debugTextFormat);
            
            var diag = "";
            
            var center = map.getCenterZoom();
            var currentLocation:Location = center[0] as Location;
            var currentZoom:Number = center[1] as Number;
            var dist = Distance.haversineDistance(currentLocation, flyTarget);
            
            //trace(currentLocation, flyTarget, dist);
            
            Debug.assert(!isNaN(currentLocation.lat), "cur loc "+currentLocation+" "+center);
            Debug.assert(!isNaN(currentLocation.lon));
            Debug.assert(!isNaN(flyTarget.lat));
            Debug.assert(!isNaN(flyTarget.lon));
            Debug.assert(!isNaN(currentZoom));
            Debug.assert(!isNaN(dist), "dist "+dist+" "+center+" "+flyTarget);
            
            var minZoom = 2;
            var maxZoom = 13.5;
            var zoomRange = maxZoom-minZoom;
            //var zoomDist = 15e6;
            var zoomDist = 2e6;
            
            var moveSpeedMax = 10e6;
            
            var targetZoom = minZoom+(maxZoom-minZoom)*(1-Math.sqrt(Math.min(1, dist/zoomDist)));
            
            var zoomDiff = targetZoom - currentZoom;
            //var zoomDiff = maxZoom - currentZoom;
            
            sHelperPoint.x = map.getWidth() / 2;
            sHelperPoint.y = map.getHeight() / 2;
            //map.panAndZoomBy(zoomDiff*0.01, interpLocation, sHelperPoint);
            //trace(currentZoom);
            var zoomSpeed = zoomDiff*0.3;
            //var moveSpeed = 1/(1+currentZoom)*Math.min(dist, 1000)/1000;
            //var moveSpeed = 2/Math.pow(2, currentZoom)*Math.min(dist, 100000)/100000;
            //var moveSpeed = Math.min(100000, dist)*20*(Math.exp(-currentZoom*0.3));
            
            var unitDistRange = 10e6;
            var unitDist = Math.min(dist/unitDistRange, unitDistRange);
            var bump = (1-Math.cos(unitDist*Math.TWOPI))*0.5;
            
            //var moveAccel = dist*10*(1-Math.exp(-10*(currentZoom-minZoom)/maxZoom));
            
            var unitZoom = (currentZoom-minZoom)/zoomRange;
            
            //var moveAccel = dist*2*Math.max(0.1, 1-unitZoom);
            //var zoomDampen = Math.pow(1-Math.abs(zoomDiff/zoomRange), 6);
            var zoomDampen = Math.pow(1-Math.abs(zoomDiff/zoomRange), 4);
            
            var moveAccel = Math.min((dist-flySpeed*0.9)*20, 50e6)*zoomDampen-flySpeed;
            
            //var moveAccel = bump*50e6*(1-(currentZoom-minZoom)/maxZoom);
            //var moveSpeed = bump*10e6+Math.min(1e3, dist);
            
            flySpeed += moveAccel*dt;
            flySpeed *= 0.98;
            //flySpeed *= Math.pow(1-unitZoom, 1);
            
            //diag += "\n" + Math.pow(zoomDiff/zoomRange, 2);
            
            flySpeed = Math.min(moveSpeedMax, flySpeed);
            
            diag += "\nzoom cur:  " + currentZoom;
            diag += "\nzoom tgt:  " + targetZoom;
            
            diag += "\nloc cur:  " + currentLocation;
            diag += "\nloc tgt:  " + flyTarget;
            
            diag += "\ndist: " + dist;
            diag += "\nfly speed: " + flySpeed;
            diag += "\nzoom diff: " + Math.abs(zoomDiff/zoomRange);
            diag += "\nzoom dampen: " + zoomDampen;
            
            flyPoint.x = flyTarget.lon-currentLocation.lon;
            flyPoint.y = flyTarget.lat-currentLocation.lat;
            flyPoint.normalize(1);
            
            flyPoint.x *= flySpeed/(111111*Math.cos(currentLocation.lat/180*Math.PI));
            flyPoint.y *= flySpeed/111111;
            
            diag += "\nvec: " + flyPoint;
            
            var away = Math.abs(zoomDiff)*5*0.5+dist/100*0.5;
            
            diag += "\naway: " + away;
            
            var nextLocation = new Location(currentLocation.lat+flyPoint.y*dt, currentLocation.lon+flyPoint.x*dt);
            
            map.panAndZoomBy(1+zoomSpeed*dt, nextLocation, sHelperPoint);
            
            Debug.assert(!isNaN(map.getCenter().lat), "Move error "+dt+" "+zoomSpeed+" "+nextLocation+" "+sHelperPoint);
            
            //g.drawTextBox(10, 10, NaN, diag);
            
            var infoAwayDist = 40;
            
            if (away < infoAwayDist) {
                g.beginFill(0x000000, 0.4);
                g.drawRect(0, -(away/infoAwayDist)*420, map.getWidth(), 420);
                g.endFill();
                var nfpos = 0;
                for (var nfi = 0; nfi < flyInfo.length; nfi++) {
                    var nfx = 0;
                    var nfy = 50-(away/infoAwayDist)*(400+(flyInfo.length-nfi)*20) + nfpos;
                    var nfw = map.getWidth();
                    var nft = flyInfo[nfi];
                    
                    mainTextFormat.size = INFO_SIZES[Math.clamp(nfi, 0, INFO_SIZES.length-1)];
                    
                    g.textFormat(mainTextFormat);
                    g.drawTextBox(nfx, nfy, map.getWidth(), nft);
                    
                    nfpos += g.textBoxBounds(mainTextFormat, nfx, nfy, nfw, nft).height + 10;
                }
            }
            
            if (delaying) {
                if (Platform.getTime()-delayStartTime > DELAY_TIME) {
                    delaying = false;
                    flying = false;
                    nextVolcano();
                }
            } else if (away < 1) {
                delaying = true;
                delayStartTime = Platform.getTime();
            }
            
            
            
        }
        
        
        //private function zoomTo(location:Location, callback:Function = null) {
            //zoomCallback = callback;
            //_map.setCenter(location);
            //zoom = true;
        //}
        //
        //public function onTick()
        //{
            //if (zoom) {
                //if (_map.getZoom() >= 19) {
                    //zoom = false;
                    //if (zoomCallback) zoomCallback();
                //} else {
                    //_map.zoomByAbout(0.1, new Point(_map.getWidth() / 2, _map.getHeight() / 2));
                //}
            //}
        //}
        
    }
    
}