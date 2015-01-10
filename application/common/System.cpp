#include "loom/script/loomscript.h"
#include "loom/common/utils/utString.h"
#include "loom/common/platform//platformThread.h"
#include <iostream>
#include <stdio.h>
#include <stdlib.h>

class System
{
protected:
	FILE* pipe;
	char buffer[128];

	static int __stdcall getData(void *param)
	{
		System* self = (System*)param;
		while (!feof(self->pipe)) {
			if (fgets(self->buffer, 128, self->pipe) != NULL)//Think about increasing buffer size
				//result += buffer;
			{
				self->_OnDataDelegate.pushArgument(self->buffer);
				self->_OnDataDelegate.invoke();
			}
		}

		_pclose(self->pipe);

		return 0;
	}

public:
	LOOM_DELEGATE(OnData);

	void cmd(const char *command)
	{
		pipe = _popen(command, "r");
		//if (!pipe) return "ERROR";
		loom_thread_start(getData, this);
	}
};


static int registerLoomSystem(lua_State* L)
{
	beginPackage(L, "loom")

		.beginClass<System>("System")

		.addConstructor <void(*)(void) >()

		.addMethod("cmd", &System::cmd)

		.addVarAccessor("onData", &System::getOnDataDelegate)

		.endClass()

		.endPackage();

	return 0;
}

void installLoomSystem()
{
	LOOM_DECLARE_NATIVETYPE(System, registerLoomSystem);
}
