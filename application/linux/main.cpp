#include "main.h"
#include "../common/AppDelegate.h"
#include "CCEGLView.h"
#include "loom/engine/cocos2dx/loom/CCLoomCocos2D.h"

USING_NS_CC;


extern "C" {
void loom_appSetup();
void loom_appShutdown();
}

int main(int argc, char **argv)
{
    
    loom_appSetup();
    
    // create the application instance
    CCEGLView& eglView = CCEGLView::sharedOpenGLView();
    eglView.setViewName(CCLoomCocos2d::getDisplayCaption().c_str());
    eglView.setFrameSize(
       (float)CCLoomCocos2d::getDisplayWidth(), 
       (float)CCLoomCocos2d::getDisplayHeight());
        
    int r = CCApplication::sharedApplication().run();

    loom_appShutdown();
    
    return r;
}
