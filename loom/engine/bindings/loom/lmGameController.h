#include <SDL.h>

#define MAX_CONTROLLERS 4

class GameController
{
public:
    GameController();
    static void openAll();
    static void closeAll();

private:
    SDL_Joystick *gamepad;
    SDL_Haptic *haptic;
    SDL_JoystickID instance_id;
    bool is_connected;

    static GameController controllers[MAX_CONTROLLERS];
    static int getControllerIndex(SDL_JoystickID instance);

    void open(int device);
    void close();
};