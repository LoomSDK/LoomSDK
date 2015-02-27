//
// Flump - Copyright 2013 Flump Authors

package flump.mold {
    import flump.Flump;

/** @private */
public class AtlasMold
{
    public var file :String;
    public var textures :Vector.<AtlasTextureMold> = new <AtlasTextureMold>[];

    public static function scaleFactorSuffix (scaleFactor :int) :String {
        return (scaleFactor == 1 ? "" : "@" + scaleFactor + "x");
    }

    public static function extractScaleFactor (filename :String) :int {
        var f:String = Files.stripPathAndDotSuffix(filename);
        var digitIndex:int = f.indexOf("@")+1;
        var digits:String = "";
        if (digitIndex > 0) {
            while (digitIndex < f.length) {
                var c = f.charCodeAt(digitIndex);
                if (c < 48 || c > 57) break;
                digits += String.fromCharCode(c);
            }
        }
        return digits.length == 0 ? 1 : digits.toNumber();
    }

    public static function fromJSON (o :JSON) :AtlasMold {
        const mold :AtlasMold = new AtlasMold();
        mold.file = Flump.requireString(o, "file");
        for each (var tex :JSON in Flump.requireVector(o, "textures")) {
            mold.textures.push(AtlasTextureMold.fromJSON(tex));
        }
        return mold;
    }

    public function toJSON (_:Object) :Object {
        return {
            file: file,
            textures: textures
        };
    }

    /*
    public function toXML () :XML {
        var xml :XML = <atlas file={file} />;
        for each (var tex :AtlasTextureMold in textures) xml.appendChild(tex.toXML());
        return xml;
    }
    */

    public function get scaleFactor () :int {
        return extractScaleFactor(file);
    }
    
}
}
