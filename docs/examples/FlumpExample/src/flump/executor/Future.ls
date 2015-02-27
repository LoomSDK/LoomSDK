//
// Flump - Copyright 2013 Flump Authors

package flump.executor {

public delegate FutureResult(result:Object);

/**
 * The result of a pending or completed asynchronous task.
 */
public class Future
{
    public static var NO_RESULT = new Object();
    
    /** @private */
    public function Future (onCompleted :Function=null) {
        _onCompleted = onCompleted;
    }

    /** Dispatches the result if the future completes successfully. */
    public var succeeded:FutureResult;

    /** Dispatches the result if the future fails. */
    public var failed:FutureResult;

    /** Dispatches if the future is cancelled. */
    public var cancelled:FutureResult;

    /** Dispatches the Future when it succeeds, fails, or is cancelled. */
    public var completed:FutureResult;

    /** Returns true if the Future completed successfully. */
    public function get isSuccessful () :Boolean { return _state == STATE_SUCCEEDED; }
    /** Returns true if the Future failed. */
    public function get isFailure () :Boolean { return _state == STATE_FAILED; }
    /** Returns true if the future was cancelled. */
    public function get isCancelled () :Boolean { return _state == STATE_CANCELLED; }
    /** Returns true if the future has succeeded or failed or was cancelled. */
    public function get isComplete () :Boolean { return _state != STATE_DEFAULT; }

    /**
     * Returns the result of the success or failure. If the success didn't call through with an
     * object or the future was cancelled, returns NO_RESULT.
     */
    public function get result ():Object { return _result; }

    function onSuccess (...result) :void {
        if (_result != null) {
            Debug.assert("already completed");
        }
        if (result.length > 0) _result = result[0];
        _state = STATE_SUCCEEDED;
        succeeded(_result);
        dispatchCompletion();
    }

    function onFailure (error :Object) :void {
        if (_result != null) {
            Debug.assert("already completed");
        }
        _result = error;
        _state = STATE_FAILED;
        failed(error);
        dispatchCompletion();
    }

    public function onCancel () :void {
        _state = STATE_CANCELLED;
        if (_onCancel != null) _onCancel();
        _onCompleted = null;// Don't tell the Executor we completed as we're not running
        dispatchCompletion();
    }

    protected function dispatchCompletion () :void {
        if (_onCompletion) _onCompletion(this);
        if (_onCompleted != null) _onCompleted(this);
        _onCompleted = null;// Allow Executor to be GC'd if the Future is hanging around
    }

    protected var _state :int = 0;
    protected var _result :Object = NO_RESULT;
    
    protected var _onCancel :Function;
    protected var _onCompletion :Function;
    protected var _onCompleted :Function;

    protected static const STATE_DEFAULT :int = 0;
    protected static const STATE_FAILED :int = 1;
    protected static const STATE_SUCCEEDED :int = 2;
    protected static const STATE_CANCELLED :int = 3;
}
}
