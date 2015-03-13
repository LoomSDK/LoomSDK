
package com.modestmaps.mapproviders.microsoft
{
    /**
     * @author darren
     * $Id$
     */
    public class MicrosoftAerialMapProvider extends MicrosoftProvider
    {
        public function MicrosoftAerialMapProvider(minZoom:int, maxZoom:int)
        {
            super(AERIAL, true, minZoom, maxZoom);
        }
    }
}