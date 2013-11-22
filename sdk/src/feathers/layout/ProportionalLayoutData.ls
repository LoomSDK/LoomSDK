package feathers.layout
{
    import loom2d.events.EventDispatcher;

    /**
     * Layout data for ProportionalLayout - attach this to a FeathersControl's layoutData
     * member in order to set layout goals.
     *
     * You can specify a pixel size ("100px") or a percent size ("50%") to control layout.
     * Values on the primary axis (ie, vertical if isVertical is true) are combined to
     * allocate space, while values on the secondary axis are either explicit (ie "100px")
     * or relative to the available space along that axis (ie, all controls with "50%" on
     * the secondary axis will have the same size).
     */
    public class ProportionalLayoutData extends EventDispatcher implements ILayoutData
    {
        /// Pass width and height for this control.
        public function ProportionalLayoutData(w:String, h:String)
        {
            super();

            width = w;
            height = h;
        }

        public var width:String, height:String;
    }
}