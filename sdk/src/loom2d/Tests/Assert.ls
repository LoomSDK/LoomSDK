package loom2d.tests 
{
    
    /**
     * Some very basic helper asserts for the Starling tests we have ported.
     */
    public class Assert 
    {
        static public function assertNull(value:Object):void
        {
            Debug.assert(value == null, "assertNull failed.");
        }
        
        static public function assertTrue(value:Boolean):void
        {
            Debug.assert(value, "assertTrue failed.");
        }
    
        static public function assertFalse(value:Boolean):void
        {
            Debug.assert(!value, "assertFalse failed.");
        }
        
        static public function assertEquals(v1:Object, v2:Object):void
        {
             Debug.assert(v1 == v2, "assertEquals failed.");
        }
    }
    
}