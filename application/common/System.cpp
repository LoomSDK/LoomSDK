#include "loom/script/loomscript.h"
#include "loom/common/utils/utString.h"
#include "loom/common/platform//platformThread.h"
#include <iostream>
#include <stdio.h>
#include <stdlib.h>

class System
{
protected:
	static const int BUFFER_LENGTH = 1024;
	FILE* pipe;
	char buffer[BUFFER_LENGTH];

	static int __stdcall getData(void *param)
	{
		System* self = (System*)param;

		// Zero out the buffer
		memset(self->buffer, 0, BUFFER_LENGTH);

		while (true) 
		{
			// Get the next character!
			int receivedChar = fgetc(self->pipe);

			// If getting the last character set the EOF flag, break out of the loop immedietly
			if (feof(self->pipe)) break;

			// Make sure we are getting actual characters
			if (receivedChar < 0) continue;

			if (receivedChar != 10 && receivedChar != 13)
			{
				// The received character is not a new line character, and we have room for it. Add it to the buffer

				self->buffer[strlen(self->buffer)] = static_cast<char>(receivedChar);
			}
			
			if (receivedChar == 10 || receivedChar == 13 || strlen(self->buffer) >= BUFFER_LENGTH)
			{
				// Either we hit a new line, or the buffer is full. send back the data!
				self->_OnDataDelegate.pushArgument(self->buffer);
				self->_OnDataDelegate.invoke();

				// Zero out the buffer to prepare for the next packet of data
				memset(self->buffer, 0, BUFFER_LENGTH);
			}
		}
        
		// The Loop finished, which means we hit an EOF (The pipe is finished giving back data) close it!
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
		_pclose(self->pipe);
#elif LOOM_PLATFORM == LOOM_PLATFORM_OSX
        pclose(self->pipe);
#else
        // Do nothing, there is no pipe to close!
#endif
		// After the pipe is closed, invoke the onFinish delegate
		self->_OnFinishDelegate.invoke();

		return 0;
	}

public:

	LOOM_DELEGATE(OnData);
	LOOM_DELEGATE(OnFinish);

	void run(const char *command)
	{
		// Copy our parameter into a char* so we can edit it
		//char *c = strdup(command);

		// Get data from STDOUT and STDERR
		//strcat(c, " 2>&1");

#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
		pipe = _popen(command, "r");
#elif LOOM_PLATFORM == LOOM_PLATFORM_OSX
		pipe = popen(command, "r");
#else
		pipe = NULL;
#endif
		loom_thread_start(getData, this);
	}

	void close()
	{
		// Close the pipe manually!
		if (pipe != NULL)
		{
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
			_pclose(pipe);
#elif LOOM_PLATFORM == LOOM_PLATFORM_OSX
			pclose(pipe);
#else
			// Do nothing, there is no pipe to close!
#endif
		}
	}
};


static int registerLoomSystem(lua_State* L)
{
	beginPackage(L, "loom")

		.beginClass<System>("System")

		.addConstructor <void(*)(void) >()

		.addMethod("run", &System::run)

		.addMethod("close", &System::close)

		.addVarAccessor("onData", &System::getOnDataDelegate)

		.addVarAccessor("onFinish", &System::getOnFinishDelegate)

		.endClass()

		.endPackage();

	return 0;
}

void installLoomSystem()
{
	LOOM_DECLARE_MANAGEDNATIVETYPE(System, registerLoomSystem);
}
