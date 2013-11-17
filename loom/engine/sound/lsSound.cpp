/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#include "loom/common/core/log.h"
#include "loom/common/assets/assets.h"
#include "loom/common/assets/assetsSound.h"
#include "loom/script/loomscript.h"
#include "loom/vendor/openal-soft/include/AL/al.h"
#include "loom/vendor/openal-soft/include/AL/alc.h"

using namespace LS;

static ALCdevice *dev = NULL;
static ALCcontext *ctx = NULL;

lmDefineLogGroup(gLoomSoundLogGroup, "loom.sound", 1, LoomLogInfo);

extern "C"
{
    void loomsound_init()
    {
        dev = alcOpenDevice(NULL);
        if(!dev)
        {
            lmLogError(gLoomSoundLogGroup, "Could not open OpenAL device.")
            return;
        }

        ctx = alcCreateContext(dev, NULL);
        if(!ctx)
        {
            lmLogError(gLoomSoundLogGroup, "Could not create OpenAL context.")
            return;
        }

        alcMakeContextCurrent(ctx);
        // TODO: Detect failure.

        // Cheat and initialize the listener.
        ALfloat listenerOri[] = { 0.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f };

        alListener3f(AL_POSITION, 0, 0, 1.0f);
        // check for errors
        alListener3f(AL_VELOCITY, 0, 0, 0);
        // check for errors
        alListenerfv(AL_ORIENTATION, listenerOri);
        // check for errors     

        lmLogInfo(gLoomSoundLogGroup, "Loom Sound engine initialized.");
    }

    void loomsound_shutdown()
    {
        alcMakeContextCurrent(NULL);
        
        if(ctx)
            alcDestroyContext(ctx);
        ctx = NULL;

        if(dev)
            alcCloseDevice(dev);
        dev = NULL;
    }
};

class Sound
{
public:

    ALuint source;


    static Sound *load(const char *assetPath)
    {
        Sound *s = lmNew(NULL) Sound();
        alGenSources((ALuint)1, &s->source);
        // check for errors

        alSourcef(s->source, AL_PITCH, 1);
        // check for errors
        alSourcef(s->source, AL_GAIN, 1);
        // check for errors
        alSource3f(s->source, AL_POSITION, 0, 0, 0);
        // check for errors
        alSource3f(s->source, AL_VELOCITY, 0, 0, 0);
        // check for errors
        alSourcei(s->source, AL_LOOPING, AL_FALSE);
        // check for errros

        // Hackiest buffer alloc.
        ALuint buffer;
        alGenBuffers((ALuint)1, &buffer);

        // Lock the asset.
        loom_asset_sound *sound = (loom_asset_sound *)loom_asset_lock(assetPath, LATSound, 1);

        if(sound)
        {
            alBufferData(buffer, sound->channels == 1 ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16, 
                sound->buffer, sound->bufferSize, 44100);            
        }
        else
        {
            lmLogError(gLoomSoundLogGroup, "Failed to load sound asset '%s'!", assetPath);
        }

        loom_asset_unlock(assetPath);

        alSourcei(s->source, AL_BUFFER, buffer);

        return s;
    }

    void setPosition(float x, float y, float z)
    {
        alSource3f(source, AL_POSITION, x, y, z);
    }

    void setVelocity(float x, float y, float z)
    {

    }

    void setListenerRelative(bool flag)
    {

    }

    void setFalloffRadius(float radius)
    {

    }

    void setGain(float gain)
    {

    }

    void setLooping(bool loop)
    {

    }

    void setPitch(float pitchFactor)
    {

    }

    void play()
    {
        alSourcePlay(source);
    }

    void pause()
    {

    }

    void stop()
    {

    }

    void rewind()
    {

    }

};

class Listener
{
public:

    static void setGain(float gainFactor)
    {

    }

    static void setPosition(float x, float y, float z)
    {

    }

    static void setVelocity(float x, float y, float z)
    {

    }

    static void setOrientation(float atX, float atY, float atZ, float upX, float upY, float upZ)
    {

    }

};

static int registerLoomSoundSound(lua_State *L)
{
    beginPackage(L, "loom.sound")

       .beginClass<Sound>("Sound")

       .addStaticMethod("load", &Sound::load)

       .addMethod("setPosition", &Sound::setPosition)
       .addMethod("setVelocity", &Sound::setVelocity)
       .addMethod("setListenerRelative", &Sound::setListenerRelative)

       .addMethod("setFalloffRadius", &Sound::setFalloffRadius)
       .addMethod("setGain", &Sound::setGain)

       .addMethod("setLooping", &Sound::setLooping)
       .addMethod("setPitch", &Sound::setPitch)

       .addMethod("play", &Sound::play)
       .addMethod("pause", &Sound::pause)
       .addMethod("stop", &Sound::stop)
       .addMethod("rewind", &Sound::rewind)
       
       .endClass()
    .endPackage();

    return 0;
}

static int registerLoomSoundListener(lua_State *L)
{
    beginPackage(L, "loom.sound")

       .beginClass<Listener>("Listener")
       .addStaticMethod("setGain", &Listener::setGain)
       .addStaticMethod("setPosition", &Listener::setPosition)
       .addStaticMethod("setVelocity", &Listener::setVelocity)
       .addStaticMethod("setOrientation", &Listener::setOrientation)
       .endClass()
   .endPackage();

    return 0;
}


void installLoomSound()
{
    LOOM_DECLARE_MANAGEDNATIVETYPE(Sound, registerLoomSoundSound);
    LOOM_DECLARE_MANAGEDNATIVETYPE(Listener, registerLoomSoundListener);
}
