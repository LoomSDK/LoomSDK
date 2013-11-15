package feathers.text
{
    import loom.platform.LoomKeyboardType;
    import loom2d.math.Point;
    import feathers.core.ITextEditor;
    import feathers.core.FeathersControl;

    public class DummyTextEditor extends FeathersControl implements ITextEditor
    {
        function get text():String
        {
            return "";
        }
        function set text(value:String):void
        {

        }
        function get displayAsPassword():Boolean
        {
            return false;    
        }
        function set displayAsPassword(value:Boolean):void
        {

        }
        function get maxChars():int
        {
            return 100;
        }
        function set maxChars(value:int):void
        {

        }
        function get restrict():String
        {
            return "";
        }
        function set restrict(value:String):void
        {

        }
        function get isEditable():Boolean
        {
            return false;
        }
        function set isEditable(value:Boolean):void
        {

        }
        function get keyboardType():LoomKeyboardType
        {
            return 0;
        }
        function set keyboardType(value:LoomKeyboardType):void
        {

        }
        function get setTouchFocusOnEndedPhase():Boolean
        {
            return false;
        }
        function setFocus():void
        {

        }
        function clearFocus():void
        {

        }
        function selectRange(startIndex:int, endIndex:int):void
        {

        }
        function measureText():Point
        {
            return new Point();
        }        
    }
}