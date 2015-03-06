package flump {
     
    public class Flump {
        
        static public function requireString(o:JSON, field:String):String {
            return o.getString(field);
        }
        
        static public function requireVector(o:JSON, field:String):Vector.<JSON> {
            var a:JSON = o.getArray(field);
            var n = a.getArrayCount();
            var v = new Vector.<JSON>();
            for (var i = 0; i < n; i++) {
                v.push(a.getArrayObject(i));
            }
            return v;
        }
        
        static public function requireNumber(o:JSON, field:String):Number {
            return o.getNumber(field);
        }
        
    }
    
}