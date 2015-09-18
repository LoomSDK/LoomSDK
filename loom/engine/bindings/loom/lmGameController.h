#include <SDL.h>

#include "loom/script/loomscript.h"

#define MAX_CONTROLLERS 4

class LoomGameController
{
public:
    LoomGameController();
    static void openAll();
    static void closeAll();
    static int addDevice(int device);
    static int removeDevice(int device);
    static int numDevices();
    static int indexOfDevice(int device);
    static bool isHaptic(int device);
    static void stopRumble(int device);
    static void startRumble(int device, float intensity, Uint32 ms);

    SDL_Haptic *getHaptic();

private:
    SDL_GameController *gamepad;
    SDL_Haptic *haptic;
    SDL_JoystickID instance_id;
    bool is_haptic;
    bool is_connected;

    static LoomGameController controllers[MAX_CONTROLLERS];
    static int getControllerIndex(SDL_JoystickID instance);

    void open(int device);
    void close();
};