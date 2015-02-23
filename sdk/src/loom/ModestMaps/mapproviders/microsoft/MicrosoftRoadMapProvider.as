package com.modestmaps.mapproviders.microsoft
{
	/**
	 * @author darren
	 * $Id$
	 */
	public class MicrosoftRoadMapProvider extends MicrosoftProvider
	{
	    public function MicrosoftRoadMapProvider(hillShading:Boolean=true, minZoom:int=MIN_ZOOM, maxZoom:int=MAX_ZOOM)
	    {
	        super(ROAD, hillShading, minZoom, maxZoom);
	    }
	}
}
