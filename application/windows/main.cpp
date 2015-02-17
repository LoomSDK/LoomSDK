#include "main.h"
#include "../common/AppDelegate.h"
#include "CCEGLView.h"
#include "loom/engine/cocos2dx/loom/CCLoomCocos2D.h"

USING_NS_CC;

#include <io.h>
#include <fcntl.h>

#include "loom/script/native/core/system/lmProcess.h"

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

    bool fromRuby = false;

    for (int i = 1; i < argc; i++)
    {
        if (!stricmp(argv[i], "ProcessID") && i + 1 < argc)
        {
            fromRuby = true;

            char *pEnd;  

            long int pid = strtol (argv[i + 1], &pEnd, 10);

            CCApplication::sharedApplication().setCLIRubyProcessId(pid);

            memmove(argv + i, argv + i + 2, (argc - i - 2)*sizeof(char*));
            argc -= 2;
            i--;
            break;
        }
    }

    LS::Process::consoleAttached = false;
    if (!fromRuby && AttachConsole(ATTACH_PARENT_PROCESS))
    {
        HANDLE consoleHandleOut = GetStdHandle(STD_OUTPUT_HANDLE);
        int fdOut = _open_osfhandle((intptr_t)consoleHandleOut, _O_TEXT);
        FILE *fpOut = _fdopen(fdOut, "w");
        *stdout = *fpOut;
        setvbuf(stdout, NULL, _IONBF, 0);

        //redirect unbuffered STDERR to the console
        HANDLE consoleHandleError = GetStdHandle(STD_ERROR_HANDLE);
        int fdError = _open_osfhandle((intptr_t)consoleHandleError, _O_TEXT);
        FILE *fpError = _fdopen(fdError, "w");
        *stderr = *fpError;
        setvbuf(stderr, NULL, _IONBF, 0);

        LS::Process::consoleAttached = true;
    }


    LSLuaState::initCommandLine(argc, (const char**) argv);
    
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

    LS::Process::cleanupConsole();

    return r;
}
