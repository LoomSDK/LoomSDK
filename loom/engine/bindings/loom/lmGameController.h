#include <SDL.h>

#define MAX_CONTROLLERS 4

class GameController
{
public:
    GameController();
    static void openAll();
    static void closeAll();
    static int addDevice(int device);
    static int removeDevice(int device);

private:
    SDL_GameController *gamepad;
    SDL_Haptic *haptic;
    SDL_JoystickID instance_id;
    bool is_connected;

    static GameController controllers[MAX_CONTROLLERS];
    static int getControllerIndex(SDL_JoystickID instance);

    void open(int device);
    void close();
};