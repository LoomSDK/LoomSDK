package loom.modestmaps.mapproviders.microsoft
{
    /**
     * @author darren
     * $Id$
     */
    public class MicrosoftHybridMapProvider extends MicrosoftProvider
    {
        public function MicrosoftHybridMapProvider(minZoom:int, maxZoom:int)
        {
            super(HYBRID, true, minZoom, maxZoom);
        }
    }
}