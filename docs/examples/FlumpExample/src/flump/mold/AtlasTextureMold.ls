//
// Flump - Copyright 2013 Flump Authors

package flump.mold {

import flump.Flump;
import loom2d.math.Point;
import loom2d.math.Rectangle;

/** @private */
public class AtlasTextureMold
{
    public var symbol :String;
    public var bounds :Rectangle;
    public var origin :Point;

    public static function fromJSON (o :JSON) :AtlasTextureMold {
        const mold :AtlasTextureMold = new AtlasTextureMold();
        mold.symbol = Flump.requireString(o, "symbol");
        const rect :JSON = o.getArray("rect");
        mold.bounds = new Rectangle(rect.getArrayNumber(0), rect.getArrayNumber(1), rect.getArrayNumber(2), rect.getArrayNumber(3));
        const orig :JSON = o.getArray("origin");
        mold.origin = new Point(orig.getArrayNumber(0), orig.getArrayNumber(1));
        return mold;
    }

    public function toJSON (_:JSON) :Object {
        return JSON.fromDictionary({
            symbol: symbol,
            rect: [bounds.x, bounds.y, bounds.width, bounds.height],
            origin: [origin.x, origin.y]
        });
    }

    /*
    public function toXML () :XML {
        const json :Object = toJSON(null);
        return <texture name={symbol} rect={json.rect} origin={json.origin}/>;
    }
    */

}
}
