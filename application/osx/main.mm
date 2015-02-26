#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif

#include <SDL.h>

#include "loom/graphics/gfxGraphics.h"
#include "loom/engine/loom2d/l2dStage.h"
#include "loom/common/config/applicationConfig.h"

#define WINDOW_WIDTH    640
#define WINDOW_HEIGHT   480

extern "C"
{
    void loom_appSetup();
    void loom_appShutdown();
    void loom_tick();
    void supplyEmbeddedAssets();
};

SDL_GLContext context;
SDL_Window *window = NULL;

int done = 0;

void loop()
{
    SDL_Event event;

    // Get the stage as it will receive most events.
    Loom2D::Stage *stage = Loom2D::Stage::smMainStage;
    
    /* Check for events */
    while (SDL_PollEvent(&event))
    {
        if (event.type == SDL_QUIT)
        {
            done = 1;
        }

        // Bail on the rest if no stage!
        if(!stage)
            continue;

        if(event.type == SDL_KEYDOWN)
        {
            // Handle a key!
            stage->_KeyDownDelegate.pushArgument(event.key.keysym.scancode);
            stage->_KeyDownDelegate.pushArgument(event.key.keysym.sym);
            stage->_KeyDownDelegate.pushArgument(event.key.keysym.mod);
            stage->_KeyDownDelegate.invoke();

        }
        else if(event.type == SDL_KEYUP)
        {
            stage->_KeyUpDelegate.pushArgument(event.key.keysym.scancode);
            stage->_KeyUpDelegate.pushArgument(event.key.keysym.sym);
            stage->_KeyUpDelegate.pushArgument(event.key.keysym.mod);
            stage->_KeyUpDelegate.invoke();
        }
/* On Mac, these are from the touchpad.
        else if(event.type == SDL_FINGERMOTION)
        {
            stage->_TouchBeganDelegate.pushArgument((int)event.tfinger.touchId);
            stage->_TouchBeganDelegate.pushArgument(event.tfinger.x);
            stage->_TouchBeganDelegate.pushArgument(event.tfinger.y);
            stage->_TouchBeganDelegate.invoke();
        }
        else if(event.type == SDL_FINGERUP)
        {
            stage->_TouchEndedDelegate.pushArgument((int)event.tfinger.touchId);
            stage->_TouchEndedDelegate.pushArgument(event.tfinger.x);
            stage->_TouchEndedDelegate.pushArgument(event.tfinger.y);
            stage->_TouchEndedDelegate.invoke();
        }
        else if(event.type == SDL_FINGERMOTION)
        {
            stage->_TouchMovedDelegate.pushArgument((int)event.tfinger.touchId);
            stage->_TouchMovedDelegate.pushArgument(event.tfinger.x);
            stage->_TouchMovedDelegate.pushArgument(event.tfinger.y);
            stage->_TouchMovedDelegate.invoke();
        }*/
        else if(event.type == SDL_MOUSEBUTTONDOWN)
        {
            stage->_TouchBeganDelegate.pushArgument((int)event.motion.which);
            stage->_TouchBeganDelegate.pushArgument(event.motion.x);
            stage->_TouchBeganDelegate.pushArgument(event.motion.y);
            stage->_TouchBeganDelegate.invoke();
        }
        else if(event.type == SDL_MOUSEBUTTONUP)
        {
            stage->_TouchEndedDelegate.pushArgument((int)event.motion.which);
            stage->_TouchEndedDelegate.pushArgument(event.motion.x);
            stage->_TouchEndedDelegate.pushArgument(event.motion.y);
            stage->_TouchEndedDelegate.invoke();
        }
        else if(event.type == SDL_MOUSEMOTION)
        {
            stage->_TouchMovedDelegate.pushArgument((int)event.motion.which);
            stage->_TouchMovedDelegate.pushArgument(event.motion.x);
            stage->_TouchMovedDelegate.pushArgument(event.motion.y);
            stage->_TouchMovedDelegate.invoke();
        }
        else if(event.type == SDL_MOUSEWHEEL)
        {
            stage->_ScrollWheelYMovedDelegate.pushArgument(event.wheel.y * (event.wheel.direction == SDL_MOUSEWHEEL_NORMAL ? 1 : -1));
            stage->_ScrollWheelYMovedDelegate.invoke();

        }
        else if (event.type == SDL_WINDOWEVENT && (event.window.event == SDL_WINDOWEVENT_RESIZED || event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED))
        {
            stage->setNativeSize(event.window.data1, event.window.data2);
        }
    }
    
    /* Tick and render Loom. */
    loom_tick();
    
    /* Update the screen! */
    SDL_GL_SwapWindow(window);
}

int
main(int argc, char *argv[])
{
    /* Enable standard application logging */
    SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);
    
    if ((window = SDL_CreateWindow(
                        "Loom", 
                        0, 0,
                        100,
                        100,
                        SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIDDEN | SDL_WINDOW_OPENGL
                        | SDL_WINDOW_ALLOW_HIGHDPI)) == NULL)
    {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_CreateWindow(): %s\n", SDL_GetError());
        exit(0);
    }

    context = SDL_GL_CreateContext(window);
    if (!context) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_GL_CreateContext(): %s\n", SDL_GetError());
        exit(2);
    }

    // Initialize Loom!
    loom_appSetup();    
    supplyEmbeddedAssets();

    // And show the window with proper settings.
    SDL_SetWindowTitle(window, LoomApplicationConfig::displayTitle().c_str());
    SDL_SetWindowSize(window, LoomApplicationConfig::displayWidth(), LoomApplicationConfig::displayHeight());
    SDL_ShowWindow(window);

    if(Loom2D::Stage::smMainStage != NULL)
        Loom2D::Stage::smMainStage->setNativeSize(LoomApplicationConfig::displayWidth(), LoomApplicationConfig::displayHeight());

    /* Main render loop */
    done = 0;
    
#ifdef __EMSCRIPTEN__
    emscripten_set_main_loop(loop, 0, 1);
#else
    while (!done) loop();
#endif
    
    loom_appShutdown();
    
    exit(0);
    return 0; /* to prevent compiler warning */
}
