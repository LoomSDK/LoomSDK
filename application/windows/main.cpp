#include "main.h"
#include "../common/AppDelegate.h"
#include "CCEGLView.h"
#include "loom/engine/cocos2dx/loom/CCLoomCocos2D.h"

USING_NS_CC;


extern "C" {
void loom_appSetup();
void loom_appShutdown();
}

//int main(int argc, char **argv)
int CALLBACK WinMain( HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow )
{
    int    argc;
    char** argv;

    char*  arg;
    int    index;

    // count the arguments

    char* command_line = (char*) malloc(strlen(lpCmdLine) + 1);
    strcpy(command_line, lpCmdLine);
    
    argc = 1;
    arg  = command_line;
    
    while (arg[0] != 0) {

        while (arg[0] != 0 && arg[0] == ' ') {
            arg++;
        }

        if (arg[0] != 0) {
        
            argc++;
        
            while (arg[0] != 0 && arg[0] != ' ') {
                arg++;
            }
        
        }
    
    }    
    
    // tokenize the arguments

    argv = (char**)malloc(argc * sizeof(char*));

    arg = command_line;
    index = 1;

    while (arg[0] != 0) {

        while (arg[0] != 0 && arg[0] == ' ') {
            arg++;
        }

        if (arg[0] != 0) {
        
            argv[index] = arg;
            index++;
        
            while (arg[0] != 0 && arg[0] != ' ') {
                arg++;
            }
        
            if (arg[0] != 0) {
                arg[0] = 0;    
                arg++;
            }
        
        }
    
    }    

    // put the program name into argv[0]

    char filename[_MAX_PATH];
    
    GetModuleFileNameA(NULL, filename, _MAX_PATH);
    argv[0] = filename;

    for (int i = 1; i < argc; i++)
    {
        if (!stricmp(argv[i], "ProcessID") && i + 1 < argc)
        {
            char *pEnd;  

            long int pid = strtol (argv[i + 1], &pEnd, 10);

            CCApplication::sharedApplication().setCLIRubyProcessId(pid);
            
            break;
        }
    }

    
    free(argv);    
    free(command_line);

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
