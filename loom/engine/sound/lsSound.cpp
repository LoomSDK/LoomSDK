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
#include "loom/common/config/applicationConfig.h"
#include "loom/script/loomscript.h"
#include "loom/vendor/openal-soft/include/AL/al.h"
#include "loom/vendor/openal-soft/include/AL/alc.h"
#include "loom/vendor/openal-soft/include/AL/alext.h"

using namespace LS;

static ALCdevice *dev = NULL;
static ALCcontext *ctx = NULL;

lmDefineLogGroup(gLoomSoundLogGroup, "loom.sound", 1, LoomLogInfo);

// Nop for now
#define CHECK_OPENAL_ERROR() \
	err = alcGetError(dev); if (err != 0) lmLogError(gLoomSoundLogGroup, "OpenAL error %d %s:%d",err, __FILE__, __LINE__); 

extern "C"
{
    void loomsound_init()
    {
		ALCenum err;

        dev = alcOpenDevice(NULL);
        if(!dev)
        {
            lmLogError(gLoomSoundLogGroup, "Could not open OpenAL device.")
            return;
        }

        CHECK_OPENAL_ERROR();

        ALCint params[] =
        {
            ALC_FORMAT_CHANNELS_SOFT, LoomApplicationConfig::wants51Audio() ? ALC_5POINT1_SOFT : ALC_STEREO_SOFT,
            0, 0
        };

        ctx = alcCreateContext(dev, params);
        CHECK_OPENAL_ERROR();
        if(!ctx)
        {
            lmLogError(gLoomSoundLogGroup, "Could not create OpenAL context.")
            return;
        }

        alcMakeContextCurrent(ctx);
        CHECK_OPENAL_ERROR();
        
        // TODO: Detect failure.

        // Cheat and initialize the listener.
        ALfloat listenerOri[] = { 0.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f };

        alListener3f(AL_POSITION, 0, 0, 1.0f);
        CHECK_OPENAL_ERROR();
        alListener3f(AL_VELOCITY, 0, 0, 0);
        CHECK_OPENAL_ERROR();
        alListenerfv(AL_ORIENTATION, listenerOri);
        CHECK_OPENAL_ERROR();

		lmLogInfo(gLoomSoundLogGroup, "Loom Sound engine OpenAL '%s' initialized.", alcGetString(dev, ALC_ALL_DEVICES_SPECIFIER));
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

class OALBufferNote
{
public:
    const char *asset;
    ALuint buffer;

    OALBufferNote()
    {
        asset = NULL;
        buffer = 0;
    }
};

class OALBufferManager
{

public:
    
    static utHashTable<utHashedString, OALBufferNote *> buffers;

    static ALuint getBufferForAsset(const char *assetPath)
    {
		ALCenum err;

        // If we don't have it, create a new one.
        OALBufferNote **notePtr = buffers.get(assetPath);
        OALBufferNote *note = NULL;

        if(notePtr == NULL)
        {
            note = lmNew(NULL) OALBufferNote();
            note->asset = strdup(assetPath);

            // OpenAL buffer alloc.
            alGenBuffers((ALuint)1, &note->buffer);
            CHECK_OPENAL_ERROR();

            // Lock the asset.
            loom_asset_sound *sound = (loom_asset_sound *)loom_asset_lock(assetPath, LATSound, 1);

            if(sound)
            {
                alBufferData(note->buffer, sound->channels == 1 ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16, 
                    sound->buffer, sound->bufferSize, 44100);            
                CHECK_OPENAL_ERROR();
            }
            else
            {
                lmLogError(gLoomSoundLogGroup, "Failed to load sound asset '%s'!", assetPath);
            }

            loom_asset_unlock(assetPath);

            // And store back in the hash table.
            buffers.insert(assetPath, note);

            // Subscribe for updates. (Race condition?)
            loom_asset_subscribe(assetPath, soundUpdater, note, 0);
        }
        else
        {
            // Get the value from the hashtable.
            note = *notePtr;
        }

        // Return the buffer.
        return note->buffer;
    }

    static void soundUpdater(void *payload, const char *name);
};

utHashTable<utHashedString, OALBufferNote *> OALBufferManager::buffers;

class Sound
{
    friend class OALBufferManager;

protected:
    static Sound *smList;
    const static int csmMaxSounds = 64;
    static int count;

public:

    ALuint source;
    Sound *next;
    int needsRestart;

    static Sound *load(const char *assetPath)
    {
		ALCenum err;

        // Get the buffer.
        ALuint buffer = OALBufferManager::getBufferForAsset(assetPath);
        if(buffer <= 0)
        {
            // Failed, return a dummy sound.
            lmLogError(gLoomSoundLogGroup, "Failed to get buffer for sound '%s', returning dummy Sound...", assetPath);
            return lmNew(NULL) Sound();
        }

        // We got a live one!
        Sound *s = lmNew(NULL) Sound();

        // Check the list for dead sources if we exceeded our cap.
        Sound *walk = smList;
        if(count > csmMaxSounds)
        {
            while(walk)
            {
                if(walk->isPlaying() == false && walk->source != 0)
                {
                    // Snag the source and reuse it.
                    lmLogError(gLoomSoundLogGroup, "Too many active sources, reusing source #%d", walk->source);
                    s->source = walk->source;
                    walk->source = 0;
                    break;
                }

                walk = walk->next;
            }            
        }
        else
        {
            walk = NULL;
        }

        // If nothing, generate a source.
        if(!walk)
        {
            alGenSources((ALuint)1, &s->source);
            CHECK_OPENAL_ERROR();
        }
        
        // Set up source defaults.
        alSourcef(s->source, AL_PITCH, 1);
        CHECK_OPENAL_ERROR();
        alSourcef(s->source, AL_GAIN, 1);
        CHECK_OPENAL_ERROR();
        alSource3f(s->source, AL_POSITION, 0.f, 0.f, 0.f);
        CHECK_OPENAL_ERROR();
        alSource3f(s->source, AL_VELOCITY, 0.f, 0.f, 0.f);
        CHECK_OPENAL_ERROR();
        alSourcei(s->source, AL_LOOPING, AL_FALSE);
        CHECK_OPENAL_ERROR();
        
        // Bind the buffer.
        alSourcei(s->source, AL_BUFFER, buffer);
        CHECK_OPENAL_ERROR();

        // Link onto the end of the list.
        if(!smList)
        {
            smList = s;
        }
        else
        {
            walk = smList;
            while(walk)
            {
                if(walk->next == NULL)
                {
                    walk->next = s;
                    break;
                }
                walk = walk->next;
            }            
        }

        // Return the shiny new sound!
        return s;
    }

    Sound()
    {
        source = 0;
        next = NULL;
        needsRestart = 0;
        count++;
    }

    ~Sound()
    {
        // Remove from the list.
        Sound **walk = &smList;
        while(*walk)
        {
            if(*walk == this)
            {
                *walk = this->next;
                break;
            }

            walk = &(*walk)->next;
        }

        count--;
        lmAssert(count > 0, "Unbalanced Sound allocations! Should never delete more than we allocated!");

        if(source != 0)
            alDeleteSources(1, &source);
    }

    void setPosition(float x, float y, float z)
    {
		ALCenum err;
        alSource3f(source, AL_POSITION, x, y, z);
        CHECK_OPENAL_ERROR();
    }

    void setVelocity(float x, float y, float z)
    {
		ALCenum err;
		alSource3f(source, AL_VELOCITY, x, y, z);
        CHECK_OPENAL_ERROR();
    }

    void setListenerRelative(bool flag)
    {
		ALCenum err;
		alSourcei(source, AL_SOURCE_RELATIVE, flag ? 1 : 0);
        CHECK_OPENAL_ERROR();
    }

    void setFalloffRadius(float radius)
    {
		ALCenum err;
		alSourcef(source, AL_MAX_DISTANCE, radius);
        CHECK_OPENAL_ERROR();
    }

    void setGain(float gain)
    {
		ALCenum err;
		alSourcef(source, AL_GAIN, gain);
        CHECK_OPENAL_ERROR();
    }

    float getGain()
    {
        float v = 1.f;
        alGetSourcefv(source, AL_GAIN, &v);
        return v;
    }

    void setLooping(bool loop)
    {
		ALCenum err;
		alSourcei(source, AL_LOOPING, loop ? 1 : 0);
        CHECK_OPENAL_ERROR();
    }

    void setPitch(float pitchFactor)
    {
		ALCenum err;
		alSourcef(source, AL_PITCH, pitchFactor);
        CHECK_OPENAL_ERROR();
    }

    void play()
    {
		ALCenum err;
		alSourcePlay(source);
        CHECK_OPENAL_ERROR();
    }

    void pause()
    {
		ALCenum err;
		alSourcePause(source);
        CHECK_OPENAL_ERROR();
    }

    void stop()
    {
		ALCenum err;
		alSourceStop(source);
        CHECK_OPENAL_ERROR();
    }

    void rewind()
    {
		ALCenum err;
		alSourceRewind(source);
        CHECK_OPENAL_ERROR();
    }

    bool isPlaying()
    {
        ALint state = 0;
        alGetSourcei(source, AL_SOURCE_STATE, &state);
        return (state == AL_PLAYING || state == AL_PAUSED);
    }
};

Sound *Sound::smList = NULL;
int Sound::count = 0;

void OALBufferManager::soundUpdater(void *payload, const char *name)
{
	ALCenum err;
	
	// Update the buffer.
    loom_asset_sound *sound = (loom_asset_sound *)loom_asset_lock(name, LATSound, 1);

    if(!sound)
    {
        loom_asset_unlock(name);
        return;
    }

    // Walk the sources - stop the active ones and restart.
    OALBufferNote *note = (OALBufferNote*)payload;

    // Stop all the sounds using this buffer.
    Sound *walk = Sound::smList;
    while(walk)
    {
        // Filter by buffer ID.
        ALint buffer = 0;
        alGetSourcei(walk->source, AL_BUFFER, &buffer);
        if(buffer != note->buffer)
        {
            walk->needsRestart = 0;
            walk = walk->next;
            continue;
        }

        ALint state = 0;
        alGetSourcei(walk->source, AL_SOURCE_STATE, &state);
        if(state == AL_PLAYING || state == AL_PAUSED)
        {
            alSourceStop(walk->source);
            alSourcei(walk->source, AL_BUFFER, 0);
            walk->needsRestart = 2; // Updated this scan, needs play.
        }
        else
        {
			alSourcei(walk->source, AL_BUFFER, 0);
			walk->needsRestart = 1; // Updated this scan, no play needed.
        }

        walk = walk->next;
    }

    // Update the buffer.
    alBufferData(note->buffer, sound->channels == 1 ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16, 
        sound->buffer, sound->bufferSize, 44100);            
    CHECK_OPENAL_ERROR();

    // Now restart all the sources after assigning the new buffer.
    walk = Sound::smList;
    while(walk)
    {
        if(walk->needsRestart == 0)
        {
            walk = walk->next;
            continue;
        }

        alSourcei(walk->source, AL_BUFFER, note->buffer);
        if(walk->needsRestart == 2)
            alSourcePlay(walk->source);

        walk = walk->next;
    }
}

class Listener
{
public:

    static void setGain(float gainFactor)
    {
		ALCenum err;
		alListenerf(AL_GAIN, gainFactor);
        CHECK_OPENAL_ERROR();
    }

    static float getGain()
    {
        float v = 1.f;
        alGetListenerfv(AL_GAIN, &v);
        return v;
    }

    static void setPosition(float x, float y, float z)
    {
		ALCenum err;
		alListener3f(AL_POSITION, x, y, z);
        CHECK_OPENAL_ERROR();
    }

    static void setVelocity(float x, float y, float z)
    {
		ALCenum err;
		alListener3f(AL_VELOCITY, x, y, z);
        CHECK_OPENAL_ERROR();
    }

    static void setOrientation(float atX, float atY, float atZ, float upX, float upY, float upZ)
    {
		ALCenum err;
		float vars[] = { atX, atY, atZ, upX, upY, upZ };
        alListenerfv(AL_ORIENTATION, vars);
        CHECK_OPENAL_ERROR();
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
       .addMethod("getGain", &Sound::getGain)

       .addMethod("setLooping", &Sound::setLooping)
       .addMethod("setPitch", &Sound::setPitch)

       .addMethod("play", &Sound::play)
       .addMethod("pause", &Sound::pause)
       .addMethod("stop", &Sound::stop)
       .addMethod("rewind", &Sound::rewind)

       .addMethod("isPlaying", &Sound::isPlaying)
       
       .endClass()
    .endPackage();

    return 0;
}

static int registerLoomSoundListener(lua_State *L)
{
    beginPackage(L, "loom.sound")

       .beginClass<Listener>("Listener")
       .addStaticMethod("setGain", &Listener::setGain)
       .addStaticMethod("getGain", &Listener::getGain)
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
