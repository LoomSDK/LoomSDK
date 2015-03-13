//
// Flump - Copyright 2013 Flump Authors

package flump.mold {

import flump.display.Movie;
import flump.Flump;
import system.reflection.Type;

/** @private */
public class MovieMold
{
    public var id :String;
    public var layers :Vector.<LayerMold> = new <LayerMold>[];
    public var labels :Vector.<Vector.<String>>;

    public static function fromJSON (o :JSON) :MovieMold {
        const mold :MovieMold = new MovieMold();
        mold.id = Flump.requireString(o, "id");
        var ol:Vector.<JSON> = Flump.requireVector(o, "layers");
        for each (var layer :JSON in ol) mold.layers.push(LayerMold.fromJSON(layer));
        return mold;
    }

    public function get frames():int {
        var frameNum:int = 0;
        for each (var layer :LayerMold in layers) frameNum = Math.max(frameNum, layer.frames);
        return frameNum;
    }

    public function get flipbook () :Boolean { return (layers.length > 0 && layers[0].flipbook); }

    public function fillLabels () :void {
        labels = new Vector.<Vector.<String>>(frames);
        if (labels.length == 0) {
            return;
        }
        labels[0] = new <String>[];
        labels[0].push(Movie.FIRST_FRAME);
        if (labels.length > 1) {
            // If we only have 1 frame, don't overwrite labels[0]
            labels[frames - 1] = new <String>[];
        }
        labels[frames - 1].push(Movie.LAST_FRAME);
        for each (var layer :LayerMold in layers) {
            for each (var kf :KeyframeMold in layer.keyframes) {
                if (kf.label == null) continue;
                if (labels[kf.index] == null) labels[kf.index] = new <String>[];
                labels[kf.index].push(kf.label);
            }

        }
    }

    public function scale(s:Number):MovieMold {
        const clone :MovieMold = MovieMold(fromJSON(JSON.parse(JSON.stringify(this))));
        for each (var layer :LayerMold in clone.layers) {
            for each (var kf :KeyframeMold in layer.keyframes) {
                kf.x *= s;
                kf.y *= s;
                kf.pivotX *= s;
                kf.pivotY *= s;
            }
        }
        return clone;
    }

    public function toJSON (_:Object) :JSON {
        var json = new JSON();
        json.setString("id", id);
        json.setArray("layers", JSON.parse(JSON.stringify(layers)));
        return json;
    }

    /*
    public function toXML () :XML {
        var xml :XML = <movie name={id}/>;
        for each (var layer :LayerMold in layers) xml.appendChild(layer.toXML());
        return xml;
    }
    */

}
}
