//SOCIALTODO: LFL: Likely change to new Teak version of their API
//SOCIALTODO: LFL: Neaten up / expand, and add to LoomSDK once moved over to Teak
package Loom
{
    public native class Carrot
    {
        public static native function postAchievement(achievementId:String):Boolean;
        public static native function postHighScore(score:Number):Boolean;
        public static native function postAction(actionId:String, objectInstanceId:String):Boolean;

        public static native function getStatus():String;
        public static native var onAuthStatus:NativeDelegate;
    }
}
