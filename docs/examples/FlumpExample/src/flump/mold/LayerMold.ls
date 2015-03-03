//
// Flump - Copyright 2013 Flump Authors

package flump.mold {
    
import flump.Flump;

/** @private */
public class LayerMold
{
    public var name :String;
    public var keyframes :Vector.<KeyframeMold> = new <KeyframeMold>[];
    public var flipbook :Boolean;

    public static function fromJSON (o :JSON) :LayerMold {
        const mold :LayerMold = new LayerMold();
        mold.name = Flump.requireString(o, "name");
        mold.flipbook = o.getBoolean("flipbook");
        for each (var kf :JSON in Flump.requireVector(o, "keyframes")) {
            mold.keyframes.push(KeyframeMold.fromJSON(kf));
        }
        return mold;
    }

    public function keyframeForFrame (frame :int) :KeyframeMold {
        var ii :int = 1;
        for (; ii < keyframes.length && keyframes[ii].index <= frame; ii++) {}
        return keyframes[ii - 1];
    }

    public function get frames () :int {
        if (keyframes.length == 0) return 0;
        const lastKf :KeyframeMold = keyframes[keyframes.length - 1];
        return lastKf.index + lastKf.duration;
    }

    public function toJSON (_:Object) :JSON {
        /*
        var json :Object = {
            name: name,
            keyframes: keyframes
        };
        */
        var json = new JSON();
        json.setString("name", name);
        json.setArray("keyframes", JSON.parse(JSON.stringify(keyframes)));
        if (flipbook) json.setBoolean("flipbook", flipbook);
        return json;
    }

    /*
    public function toXML () :XML {
        var xml :XML = <layer name={name}/>;
        if (flipbook) xml.@flipbook = flipbook;
        for each (var kf :KeyframeMold in keyframes) xml.appendChild(kf.toXML());
        return xml;
    }
    */
    
}
}
