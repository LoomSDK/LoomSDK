package loom
{
    public native class System
    {
        /**
         * Create a new LoomTextAsset representing the requested path.
         */
        public native function cmd(path:String):Void;

        public native var onData:NativeDelegate;
    }
}
