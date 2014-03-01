/****************************************************************************
Copyright (c) 2010-2011 cocos2d-x.org

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/
package org.cocos2dx.lib;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

import android.os.Process;

import android.opengl.GLSurfaceView;

public class Cocos2dxRenderer implements GLSurfaceView.Renderer 
{
	private int screenWidth;
	private int screenHeight;

    protected static native void nativeReshapeProjection(int width, int height);
	
    public void onSurfaceCreated(GL10 gl, EGLConfig config) 
    {
        // Setting thread priority aggressively here helps us max out our
        // performance. Specifically, we want to make sure that we process
        // frames as fast as possible with no interruptions. The OS seems
        // to do a good job of keeping us from breaking anything. Note
        // that Android makes us sleep to vsync (60hz) so we won't bake 
        // the CPU unless people actually max out frame time - in which case
        // they can call sleep explicitly to tune power usage.
        Thread.currentThread().setPriority(Thread.MAX_PRIORITY);
        Process.setThreadPriority(-20);
    	nativeInit(screenWidth, screenHeight);
    }
    
    public void setScreenWidthAndHeight(int w, int h)
    {
    	this.screenWidth = w;
    	this.screenHeight = h;
    }

    public void onSurfaceChanged(GL10 gl, int w, int h) 
    {
        nativeReshapeProjection(w,h);
    }
    
    public void onDrawFrame(GL10 gl) 
    {
    	nativeRender();   	
    }
    
    public void handleActionDown(int id, float x, float y)
    {
    	nativeTouchesBegin(id, x, y);
    }
    
    public void handleActionUp(int id, float x, float y)
    {
    	nativeTouchesEnd(id, x, y);
    }
    
    public void handleActionCancel(int[] id, float[] x, float[] y)
    {
    	nativeTouchesCancel(id, x, y);
    }
    
    public void handleActionMove(int[] id, float[] x, float[] y)
    {
    	nativeTouchesMove(id, x, y);
    }
    
    public void handleKeyDown(int keyCode)
    {
    	nativeKeyDown(keyCode);
    }
    
    public void handleOnPause(){
    	nativeOnPause();
    }
    
    public void handleOnResume(){
    	nativeOnResume();
    }

    public static void setAnimationInterval(double interval)
    {
        // NOP for now.
    }
    
    private static native void nativeTouchesBegin(int id, float x, float y);
    private static native void nativeTouchesEnd(int id, float x, float y);
    private static native void nativeTouchesMove(int[] id, float[] x, float[] y);
    private static native void nativeTouchesCancel(int[] id, float[] x, float[] y);
    private static native boolean nativeKeyDown(int keyCode);
    private static native void nativeRender();
    private static native void nativeInit(int w, int h);
    private static native void nativeOnPause();
    private static native void nativeOnResume();
    
    /////////////////////////////////////////////////////////////////////////////////
    // handle input method edit message
    /////////////////////////////////////////////////////////////////////////////////
    
    public void handleInsertText(final String text) {
    	nativeInsertText(text);
    }
    
    public void handleDeleteBackward() {
    	nativeDeleteBackward();
    }

	public String getContentText() {
		return nativeGetContentText();
	}
	
    private static native void nativeInsertText(String text);
    private static native void nativeDeleteBackward();
    private static native String nativeGetContentText();
}
