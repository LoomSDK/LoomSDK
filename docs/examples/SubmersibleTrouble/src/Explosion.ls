package
{
	import loom2d.display.MovieClip;
	import loom2d.math.Rectangle;
	import loom2d.textures.Texture;
	import loom2d.textures.TextureSmoothing;
	
	/**
	 * Helper class for explosion sprite MovieClips
	 */
	public class Explosion extends MovieClip
	{
		/**
		 * @param	path	Path to sprite image, should be horizontal strip with square sprites.
		 */
		public function Explosion(path:String)
		{
			var tex = Texture.fromAsset(path);
			tex.smoothing = TextureSmoothing.NONE;
			var spriteCount:Number = Math.round(tex.width/tex.height);
			var textures = new Vector.<Texture>();
			for (var i = 0; i < spriteCount; i++) {
				textures.push(Texture.fromTexture(tex, new Rectangle(i*tex.height, 0, tex.height, tex.height)));
			}
			super(textures, 30);
			loop = false;
			visible = false;
			center();
			alpha = 0.6;
		}
	}
}