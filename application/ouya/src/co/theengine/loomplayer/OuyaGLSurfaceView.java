package co.theengine.loomplayer;

import org.cocos2dx.lib.Cocos2dxGLSurfaceView;

import android.content.Context;
import android.view.KeyEvent;
import android.view.MotionEvent;

import co.theengine.loomplayer.OuyaControllerBinder;
import tv.ouya.console.api.OuyaController;

/**
 * 
 * A GLSurfaceView which forwards events to the ouya controller
 *
 */
public class OuyaGLSurfaceView extends Cocos2dxGLSurfaceView {

    public OuyaGLSurfaceView(Context context) {
        super(context);
    }

    @Override
    public boolean onGenericMotionEvent(MotionEvent event) 
    {
        boolean handled = OuyaController.onGenericMotionEvent(event);
        return handled || super.onGenericMotionEvent(event);        
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) 
    {
        boolean handled = OuyaController.onKeyDown(keyCode, event);
        return handled || super.onKeyDown(keyCode, event);        
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) 
    {
        boolean handled = OuyaController.onKeyUp(keyCode, event);
        return handled || super.onKeyUp(keyCode, event);        
    }

}
