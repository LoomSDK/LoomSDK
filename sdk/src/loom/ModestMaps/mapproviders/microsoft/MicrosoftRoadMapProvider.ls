package com.modestmaps.mapproviders.microsoft
{
	/**
	 * @author darren
	 * $Id$
	 */
	public class MicrosoftRoadMapProvider extends MicrosoftProvider
	{
	    public function MicrosoftRoadMapProvider(hillShading:Boolean, minZoom:int, maxZoom:int)
	    {
	        super(ROAD, hillShading, minZoom, maxZoom);
	    }
	}
}
