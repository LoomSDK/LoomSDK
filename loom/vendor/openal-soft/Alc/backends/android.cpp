/**
 * OpenAL cross platform audio library
 * Copyright (C) 2010 by Chris Robinson
 * This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 *  License along with this library; if not, write to the
 *  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 *  Boston, MA  02111-1307, USA.
 * Or go to http://www.gnu.org/copyleft/lgpl.html
 */

#include "loom/common/platform/platformAndroidJni.h"

lmDefineLogGroup(gOpenALAndroid, "openal.android", 1, LoomLogInfo);

#include "config.h"

#include <stdlib.h>
#include <pthread.h>
#include "alMain.h"
#include "AL/al.h"
#include "AL/alc.h"

static const ALCchar android_device[] = "Android Legacy";

static jclass cAudioTrack = NULL;

static jmethodID mAudioTrack;
static jmethodID mGetMinBufferSize;
static jmethodID mPlay;
static jmethodID mStop;
static jmethodID mRelease;
static jmethodID mWrite;

static JNIEnv *GetEnv()
{
    JNIEnv *env = NULL;
    if (LOOMJAVAVM) LOOMJAVAVM->GetEnv((void**)&env, JNI_VERSION_1_2);
    return env;
}

typedef struct
{
    pthread_t thread;
    volatile int running;
} AndroidData;

#define STREAM_MUSIC 3
#define CHANNEL_CONFIGURATION_MONO 2
#define CHANNEL_CONFIGURATION_STEREO 3
#define CHANNEL_CONFIGURATION_5_1 252
#define ENCODING_PCM_8BIT 3
#define ENCODING_PCM_16BIT 2
#define MODE_STREAM 1

static void* thread_function(void* arg)
{
    ALCdevice* device = (ALCdevice*)arg;
    AndroidData* data = (AndroidData*)device->ExtraData;

    JNIEnv* env;
    LOOMJAVAVM->AttachCurrentThread(&env, NULL);

    env->PushLocalFrame(2);

    int sampleRateInHz = device->Frequency;
    int channelConfig = CHANNEL_CONFIGURATION_STEREO;
    switch(ChannelsFromDevFmt(device->FmtChans))
    {
        case 1: channelConfig = CHANNEL_CONFIGURATION_MONO; break;
        case 2: channelConfig = CHANNEL_CONFIGURATION_STEREO; break;
        case 6: channelConfig = CHANNEL_CONFIGURATION_5_1; break;

        default:
        AL_PRINT("Failed to identify channelConfig, defaulting to stereo.");
        break;
    }

    lmLogDebug(gOpenALAndroid, "channel config = %d", channelConfig);

    int audioFormat = BytesFromDevFmt(device->FmtType) == 1 ? ENCODING_PCM_8BIT : ENCODING_PCM_16BIT;

    int bufferSizeInBytes = env->CallStaticIntMethod(cAudioTrack, 
        mGetMinBufferSize, sampleRateInHz, channelConfig, audioFormat);

    int bufferSizeInSamples = bufferSizeInBytes / FrameSizeFromDevFmt(device->FmtChans, device->FmtType);

    jobject track = env->NewObject(cAudioTrack, mAudioTrack,
        STREAM_MUSIC, sampleRateInHz, channelConfig, audioFormat, device->NumUpdates * bufferSizeInBytes, MODE_STREAM);

#ifdef HAVE_ANDROID_LOW_LATENCY
    int started = 0;
    size_t overallBytes = 0;
#else
    env->CallNonvirtualVoidMethod(track, cAudioTrack, mPlay);
#endif

    jarray buffer = env->NewByteArray(bufferSizeInBytes);

    while (data->running)
    {
        void* pBuffer = env->GetPrimitiveArrayCritical(buffer, NULL);

        if (pBuffer)
        {
            aluMixData(device, pBuffer, bufferSizeInSamples);
            env->ReleasePrimitiveArrayCritical(buffer, pBuffer, 0);

#ifdef HAVE_ANDROID_LOW_LATENCY
            if (bufferSizeInBytes >= 0)
            {
                if (started)
                {
#endif
                    env->CallNonvirtualIntMethod(track, cAudioTrack, mWrite, buffer, 0, bufferSizeInBytes);
#ifdef HAVE_ANDROID_LOW_LATENCY
                }
                else
                {
                    overallBytes += env->CallNonvirtualIntMethod(track, cAudioTrack, mWrite, buffer, 0, bufferSizeInBytes);
                    if (overallBytes >= (device->NumUpdates * bufferSizeInBytes))
                    {
                        env->CallNonvirtualVoidMethod(track, cAudioTrack, mPlay);
                        started = 1;
                    }
                }
            }
#endif
        }
        else
        {
            AL_PRINT("Failed to get pointer to array bytes");
        }
    }
    
    env->CallNonvirtualVoidMethod(track, cAudioTrack, mStop);
    env->CallNonvirtualVoidMethod(track, cAudioTrack, mRelease);

    env->PopLocalFrame(NULL);

    LOOMJAVAVM->DetachCurrentThread();
    return NULL;
}

static ALCenum android_open_playback(ALCdevice *device, const ALCchar *deviceName)
{
    JNIEnv* env = GetEnv();
    AndroidData* data;

    if (!cAudioTrack)
    {
        /* Cache AudioTrack class and it's method id's
         * And do this only once!
         */

        cAudioTrack = env->FindClass("android/media/AudioTrack");
        if (!cAudioTrack)
        {
            AL_PRINT("android.media.AudioTrack class is not found. Are you running at least 1.5 version?");
            return ALC_INVALID_VALUE;
        }

        cAudioTrack = (jclass)env->NewGlobalRef(cAudioTrack);

        mAudioTrack = env->GetMethodID(cAudioTrack, "<init>", "(IIIIII)V");
        mGetMinBufferSize = env->GetStaticMethodID(cAudioTrack, "getMinBufferSize", "(III)I");
        mPlay = env->GetMethodID(cAudioTrack, "play", "()V");
        mStop = env->GetMethodID(cAudioTrack, "stop", "()V");
        mRelease = env->GetMethodID(cAudioTrack, "release", "()V");
        mWrite = env->GetMethodID(cAudioTrack, "write", "([BII)I");
    }

    if (!deviceName)
    {
        deviceName = android_device;
    }
    else if (strcmp(deviceName, android_device) != 0)
    {
        return ALC_INVALID_VALUE;
    }

    data = (AndroidData*)calloc(1, sizeof(*data));
    device->szDeviceName = strdup(deviceName);
    device->ExtraData = data;

    device->FmtChans = DevFmtStereo;
    device->FmtType = DevFmtShort;

#ifdef HAVE_ANDROID_LOW_LATENCY
    device->Frequency = 22050;
    device->NumUpdates = 1;
#endif

    return ALC_NO_ERROR;
}

static void android_close_playback(ALCdevice *device)
{
    AndroidData* data = (AndroidData*)device->ExtraData;
    if (data != NULL)
    {
        free(data);
        device->ExtraData = NULL;
    }
}

static ALCboolean android_reset_playback(ALCdevice *device)
{
    AndroidData* data = (AndroidData*)device->ExtraData;

    // TODO: Validate format.
    //device->FmtChans = DevFmtX51; //ChannelsFromDevFmt(device->FmtChans) >= 2 ? DevFmtStereo : DevFmtMono;

    SetDefaultChannelOrder(device);

    return ALC_TRUE;
}

static ALCboolean android_start_playback(ALCdevice* device)
{
    AndroidData* data = (AndroidData*)device->ExtraData;

    data->running = 1;

    pthread_create(&data->thread, NULL, thread_function, device);

    return ALC_TRUE;
}

static void android_stop_playback(ALCdevice *device)
{
    AndroidData* data = (AndroidData*)device->ExtraData;

    if (data->running)
    {
        data->running = 0;
        pthread_join(data->thread, NULL);
    }
}

static const BackendFuncs android_funcs = {
    android_open_playback,
    android_close_playback,
    android_reset_playback,
    android_start_playback,
    android_stop_playback,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
};

ALCboolean alc_android_init(BackendFuncs *func_list)
{
    *func_list = android_funcs;
    return ALC_TRUE;
}

void alc_android_deinit(void)
{
    JNIEnv* env = GetEnv();

    /* release cached AudioTrack class */
    env->DeleteGlobalRef(cAudioTrack);
}

void alc_android_probe(enum DevProbe type)
{
    switch(type)
    {
        case ALL_DEVICE_PROBE:
            AppendAllDeviceList(android_device);
            break;
        case CAPTURE_DEVICE_PROBE:
            break;
    }
}
