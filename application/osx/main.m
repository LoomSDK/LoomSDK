#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif

#include <SDL.h>

#define WINDOW_WIDTH    640
#define WINDOW_HEIGHT   480

extern void loom_appSetup();
extern void loom_appShutdown();
extern void loom_tick();
extern void supplyEmbeddedAssets();

SDL_GLContext context;
SDL_Window *window = NULL;

int done = 0;

void loop()
{
    SDL_Event event;
    
    /* Check for events */
    while (SDL_PollEvent(&event))
    {
        if (event.type == SDL_QUIT)
        {
            done = 1;
        }

        if(event.type == SDL_KEYDOWN)
        {
            // Handle a key!
            printf("Someone hit a key\n");
        }
        
        if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_RESIZED)
        {
            printf("Window %d resized to %dx%d\n",
                   event.window.windowID, event.window.data1,
                   event.window.data2);
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
                        "Loom", 0, 0,
                        WINDOW_WIDTH,
                        WINDOW_HEIGHT,
                        SDL_WINDOW_RESIZABLE
                        | SDL_WINDOW_ALLOW_HIGHDPI)) == NULL)
    {
        exit(0);
    }
    
    context = SDL_GL_CreateContext(window);
    if (!context) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_GL_CreateContext(): %s\n", SDL_GetError());
        exit(2);
    }
    
    
    /* Main render loop */
    done = 0;
    
    loom_appSetup();
    
    supplyEmbeddedAssets();
    
#ifdef __EMSCRIPTEN__
    emscripten_set_main_loop(loop, 0, 1);
#else
    while (!done) loop();
#endif
    
    loom_appShutdown();
    
    exit(0);
    return 0; /* to prevent compiler warning */
}
