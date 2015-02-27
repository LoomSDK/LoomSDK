//
// Flump - Copyright 2013 Flump Authors

package flump.executor {

/**
 * A Future that provides interfaces to succeed or fail directly, or based
 * on the result of Function call.
 */
public class FutureTask extends Future
{
    public function FutureTask (onCompletion :Function=null) {
        super(onCompletion);
    }

    /** Succeed immediately */
    public function succeed (...result) :void {
        // Sigh, where's your explode operator, ActionScript?
        if (result.length == 0) super.onSuccess(null);
        else super.onSuccess([result[0]]);
    }

    /** Fail immediately */
    public function fail (error :Object) :void { super.onFailure(error); }

    /**
     * Calls a function. Succeed if the function exits normally; fail with any
     * error thrown by the Function.
     */
    public function succeedAfter(thisObj:Object, f :Function, ...args) :void {
        trace("succeedAfter", f, args);
        applyMonitored(thisObj, f, args);
        if (!isComplete) succeed();
    }

    /**
     * Call a function. Fail with any error thrown by the function, otherwise
     * no state change.
     */
    public function monitor (thisObj:Object, f :Function, ...args) :void { 
            trace("monitor", f, args); applyMonitored(thisObj, f, args); }

    /** Returns a callback Function that behaves like #monitor */
    public function monitoredCallback (thisObj:Object, callback :Function, activeCallback :Boolean=true) :Function {
        return function (...args) :void {
            if (activeCallback && isComplete) return;
            trace("monitoredCallback", callback, args);
            applyMonitored(thisObj, callback, args);
        };
    }

    protected function applyMonitored(thisObj:Object, monitored :Function, args :Vector.<Object>) :void {
        //try {
        trace("applyMonitored", monitored, args);
        monitored.apply(thisObj, args);
        //} catch (e :Error) {
            //if (this.isComplete) {
                 //can't fail if we're already completed
                //throw e;
            //} else {
                //fail(e);
            //}
        //}
    }
}
}
