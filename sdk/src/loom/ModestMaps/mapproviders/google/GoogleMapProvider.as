package com.modestmaps.mapproviders.google
{
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.core.painter.GoogleTilePainter;
	import com.modestmaps.core.painter.ITilePainter;
	import com.modestmaps.core.painter.ITilePainterOverride;
	import com.modestmaps.mapproviders.AbstractMapProvider;
	import com.modestmaps.mapproviders.IMapProvider;

	public class GoogleMapProvider extends AbstractMapProvider implements IMapProvider, ITilePainterOverride
	{
		protected var tilePainter:GoogleTilePainter;
		
		public function GoogleMapProvider(tilePainter:GoogleTilePainter)
		{
			this.tilePainter = tilePainter
		}

		public function getTilePainter():ITilePainter
		{
			return tilePainter;
		}
		
		public function toString():String
		{
			return tilePainter.toString();
		}
		
		public function getTileUrls(coord:Coordinate):Array
		{
			return [];
		}
	}
}