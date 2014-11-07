package game
{
    import loom2d.textures.Texture;
    
    /**
     * Defines properties of a tile type
     */
    public class TileType
    {
        public var index:int;
        public var color:uint;
        public var texture:Texture;
        public function TileType(index:int, color:uint, texture:Texture)
        {
            this.index = index;
            this.color = color;
            this.texture = texture;
        }
        
    }
}