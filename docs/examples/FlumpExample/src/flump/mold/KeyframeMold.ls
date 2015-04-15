//
// Flump - Copyright 2013 Flump Authors
package flump.mold {
    
import flump.Flump;
import system.errors.Error;
import system.reflection.FieldInfo;

/** @private */
public class KeyframeMold
{
    public var index :int;

    /** The length of this keyframe in frames. */
    public var duration :int;

    /**
     * The symbol of the image or movie in this keyframe, or null if there is nothing in it.
     * For flipbook frames, this will be a name constructed out of the movie and frame index.
     */
    public var ref :String;

    /** The label on this keyframe, or null if there isn't one */
    public var label :String;

    /** Exploded values from matrix */
    public var x :Number = 0.0;
    public var y :Number = 0.0;
    public var scaleX :Number = 1.0;
    public var scaleY :Number = 1.0;
    public var skewX :Number = 0.0;
    public var skewY :Number = 0.0;

    /** Transformation point */
    public var pivotX :Number = 0.0;
    public var pivotY :Number = 0.0;

    public var alpha :Number = 1;

    public var visible :Boolean = true;

    /** Is this keyframe tweened? */
    public var tweened :Boolean = true;

    /** Tween easing. Only valid if tweened==true. */
    public var ease :Number = 0;

    public static function fromJSON (o :JSON) :KeyframeMold {
        const mold :KeyframeMold = new KeyframeMold();
        mold.index = Flump.requireNumber(o, "index");
        mold.duration = Flump.requireNumber(o, "duration");
        extractField(o, mold, "ref");
        extractNumbers(o, mold, "loc", "x", "y");
        extractNumbers(o, mold, "scale", "scaleX", "scaleY");
        extractNumbers(o, mold, "skew", "skewX", "skewY");
        extractNumbers(o, mold, "pivot", "pivotX", "pivotY");
        extractField(o, mold, "alpha");
        extractField(o, mold, "visible");
        extractField(o, mold, "ease");
        extractField(o, mold, "tweened");
        extractField(o, mold, "label");
        return mold;
    }

    /** True if this keyframe does not display anything. */
    public function get isEmpty () :Boolean { return this.ref == null; }

    public function get rotation () :Number { return skewX; }
    // public function set rotation (angle :Number) :void { skewX = skewY = angle; }

    public function rotate (delta :Number) :void {
        skewX += delta;
        skewY += delta;
    }

    public function toJSON (_:Object) :Object {
        var json:JSON = new JSON();
        json.setInteger("index", index);
        json.setInteger("duration", duration);
        if (ref != null) {
            json.setString("ref", ref);
            if (x != 0 || y != 0) json.setArray("loc", JSON.parse(JSON.stringify([round(x), round(y)])));
            if (scaleX != 1 || scaleY != 1) json.setArray("scale", JSON.parse(JSON.stringify([round(scaleX), round(scaleY)])));
            if (skewX != 0 || skewY != 0) json.setArray("skew", JSON.parse(JSON.stringify([round(skewX), round(skewY)])));
            if (pivotX != 0 || pivotY != 0) json.setArray("pivot", JSON.parse(JSON.stringify([round(pivotX), round(pivotY)])));
            if (alpha != 1) json.setFloat("alpha", round(alpha));
            if (!visible) json.setBoolean("visible", visible);
            if (!tweened) json.setBoolean("tweened", tweened);
            if (ease != 0) json.setFloat("ease", round(ease));
        }
        if (label != null) json.setString("label", label);
        return json;
    }
    
    /*
    public function toXML () :XML {
        var xml :XML = <kf duration={duration}/>;
        if (ref != null) {
            xml.@ref = ref;
            if (x != 0 || y != 0) xml.@loc = "" + round(x) + "," + round(y);
            if (scaleX != 1 || scaleY != 1) xml.@scale = "" + round(scaleX) + "," + round(scaleY);
            if (skewX != 0 || skewY != 0) xml.@skew = "" + round(skewX) + "," + round(skewY);
            if (pivotX != 0 || pivotY != 0) xml.@pivot = "" + round(pivotX) + "," + round(pivotY);
            if (alpha != 1) xml.@alpha = round(alpha);
            if (!visible) xml.@visible = visible;
            if (!tweened) xml.@tweened = tweened;
            if (ease != 0) xml.@ease = round(ease);
        }
        if (label != null) xml.@label = label;
        return xml;
    }
    */
    
    protected static function extractNumbers(o :JSON, destObj :Object, source :String,
        dest1 :String, dest2 :String) :void {
        const extracted :JSON = o.getArray(source);
        if (extracted == null) return;
        destObj.getType().getFieldInfoByName(dest1).setValue(destObj, extracted.getArrayNumber(0));
        destObj.getType().getFieldInfoByName(dest2).setValue(destObj, extracted.getArrayNumber(1));
    }

    protected static function extractField(o :JSON, destObj :Object, field :String) :void {
        o.applyField(destObj, field);
    }

    protected static function round (n :Number, places :int = 4) :Number {
        const shift :int = Math.pow(10, places);
        return Math.round(n * shift) / shift;
    }

}
}
