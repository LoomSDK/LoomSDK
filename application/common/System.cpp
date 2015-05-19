#include "loom/script/loomscript.h"
#include "loom/common/utils/utString.h"
#include "loom/common/platform//platformThread.h"
#include <iostream>
#include <stdio.h>
#include <stdlib.h>

class System
{
private:
	static void zeroBuffer(char *buff)
	{
		unsigned int stringLength = strlen(buff);

		// We are using an unsigned int, so we can expect the value to roll over once we are finished with the loop
		for (unsigned int i = stringLength - 1; i >= 0 && i < stringLength; i--)
		{
			buff[i] = 0;
		}
	}

protected:
	static const int BUFFER_LENGTH = 1024;
	int id;
	FILE* pipe;
	char buffer[BUFFER_LENGTH];

	static int __stdcall getData(void *param)
	{
		System* self = (System*)param;

		// Zero out the buffer
		zeroBuffer(self->buffer);

		while (true/*!feof(self->pipe)*/) 
		{
			// Get the next character!
			int recievedChar = fgetc(self->pipe);

			// If getting the last character set the EOF flag, break out of the loop immedietly
			if (feof(self->pipe)) break;

			// Make sure we are getting actual characters
			if (recievedChar < 0) continue;

			if (recievedChar != 10 && recievedChar != 13)
			{
				// The recieved character is not a new line character, and we have room for it. Add it to the buffer
				self->buffer[strlen(self->buffer)] = static_cast<char>(recievedChar);
			}
			
			if (recievedChar == 10 || recievedChar == 13 || strlen(self->buffer) >= BUFFER_LENGTH)
			{
				// Either we hit a new line, or the buffer is full. send back the data!
				self->_OnDataDelegate.pushArgument(self->buffer);
				self->_OnDataDelegate.pushArgument(self->id);
				self->_OnDataDelegate.invoke();

				// Zero out the buffer to prepare for the next packet of data
				zeroBuffer(self->buffer);
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
		self->_OnFinishDelegate.pushArgument(self->id);
		self->_OnFinishDelegate.invoke();

		return 0;
	}

public:

	LOOM_DELEGATE(OnData);
	LOOM_DELEGATE(OnFinish);

	System(int i)
	{
		// Set the ID at construction
		id = i;
	}

	void cmd(const char *command)
	{
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

	int getId()
	{
		return id;
	}
};


static int registerLoomSystem(lua_State* L)
{
	beginPackage(L, "loom")

		.beginClass<System>("natSystem")

		.addConstructor <void(*)(int) >()

		.addMethod("cmd", &System::cmd)

		.addMethod("close", &System::close)

		.addMethod("getId", &System::getId)

		.addVarAccessor("onData", &System::getOnDataDelegate)

		.addVarAccessor("onFinish", &System::getOnFinishDelegate)

		.endClass()

		.endPackage();

	return 0;
}

void installLoomSystem()
{
	LOOM_DECLARE_NATIVETYPE(System, registerLoomSystem);
}
