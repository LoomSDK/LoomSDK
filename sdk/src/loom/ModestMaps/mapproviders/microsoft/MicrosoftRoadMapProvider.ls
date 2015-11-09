package loom.modestmaps.mapproviders.microsoft
{
    /**
     * @author darren
     * $Id$
     */
    public class MicrosoftRoadMapProvider extends MicrosoftProvider
    {
        public function MicrosoftRoadMapProvider(hillShading:Boolean, minZoom:int = MIN_ZOOM, maxZoom:int = MAX_ZOOM)
        {
            super(ROAD, hillShading, minZoom, maxZoom);
        }
    }
}
