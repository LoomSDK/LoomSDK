package flump.display {

import loom2d.math.Point;

import loom2d.display.DisplayObject;
import loom2d.display.Image;
import loom2d.textures.Texture;

public class ImageCreator
    implements SymbolCreator
{
    public var texture :Texture;
    public var origin :Point;
    public var symbol :String;

    public function ImageCreator (texture :Texture, origin :Point, symbol :String) {
        this.texture = texture;
        this.origin = origin;
        this.symbol = symbol;
    }

    public function create (library :Library) :DisplayObject {
        const image :Image = new Image(texture);
        image.pivotX = origin.x;
        image.pivotY = origin.y;
        image.name = symbol;
        return image;
    }
}
}
