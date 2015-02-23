
package com.modestmaps.mapproviders.microsoft
{
	/**
	 * @author darren
	 * $Id$
	 */
	public class MicrosoftAerialMapProvider extends MicrosoftProvider
	{
		public function MicrosoftAerialMapProvider(minZoom:int=MIN_ZOOM, maxZoom:int=MAX_ZOOM)
		{
			super(AERIAL, true, minZoom, maxZoom);
		}
	}
}