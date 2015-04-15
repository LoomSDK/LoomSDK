//
// flump-runtime

package flump.mold {
	import flump.Flump;

public class TextureGroupMold
{
    public var scaleFactor :int;
    public var atlases :Vector.<AtlasMold> = new <AtlasMold>[];

    public static function fromJSON (o :JSON) :TextureGroupMold {
        const mold :TextureGroupMold = new TextureGroupMold();
        mold.scaleFactor = Flump.requireNumber(o, "scaleFactor");
        var atlases:Vector.<JSON> = Flump.requireVector(o, "atlases");
        for each (var atlas :JSON in atlases) {
            mold.atlases.push(AtlasMold.fromJSON(atlas));
        }
        return mold;
    }

    public function toJSON (_:Object) :Object {
        return {
            scaleFactor: scaleFactor,
            atlases: atlases
        };
    }

    /*
    public function toXML () :XML {
        var xml :XML = <textureGroup scaleFactor={scaleFactor}/>;
        for each (var atlas :AtlasMold in atlases) {
            xml.appendChild(atlas.toXML());
        }
        return xml;
    }
    */
    
}
}
