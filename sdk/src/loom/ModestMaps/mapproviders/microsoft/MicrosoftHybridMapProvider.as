package com.modestmaps.mapproviders.microsoft
{
	/**
	 * @author darren
	 * $Id$
	 */
	public class MicrosoftHybridMapProvider extends MicrosoftProvider
	{
		public function MicrosoftHybridMapProvider(minZoom:int=MIN_ZOOM, maxZoom:int=MAX_ZOOM)
		{
			super(HYBRID, true, minZoom, maxZoom);
		}
	}
}