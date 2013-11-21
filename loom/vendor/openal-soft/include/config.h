#include "loom/common/platform/platform.h"

/* API declaration export attribute */
#define AL_API  
#define ALC_API 

/* Define to the library version */
#define ALSOFT_VERSION "alsoft-loom-1.0.0"

#define AL_ALEXT_PROTOTYPES

/* Define if we have the ALSA backend */
//#define HAVE_ALSA

/* Define if we have the OSS backend */
//#define HAVE_OSS

/* Define if we have the Solaris backend */
//#define HAVE_SOLARIS

/* Define if we have the SndIO backend */
//#define HAVE_SNDIO

/* Define if we have the MMDevApi backend */
//#define HAVE_MMDEVAPI

/* Define if we have the DSound backend */
#if LOOM_PLATFORM == LOOM_LPATFORM_WIN32
#define HAVE_DSOUND

/* Define if we have the Windows Multimedia backend */
//#define HAVE_WINMM
#endif

/* Define if we have the PortAudio backend */
//#define HAVE_PORTAUDIO

/* Define if we have the PulseAudio backend */
//#define HAVE_PULSEAUDIO

/* Define if we have the CoreAudio backend */
#if LOOM_PLATFORM_IS_APPLE == 1
#define HAVE_COREAUDIO
#endif

/* Define if we have the OpenSL backend */
//#define HAVE_OPENSL

/* Define if we have the OpenSL 1.1 backend */
//#define HAVE_OPENSL_1_1

/* Define if we have the Android backend */
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
#define HAVE_ANDROID
#define HAVE_ANDROID_LOW_LATENCY
#endif

/* Define if we want to use the low latency Android backend */
//#define HAVE_ANDROID_LOW_LATENCY

/* Define if we have the Wave Writer backend */
#define HAVE_WAVE

/* Define if we have dlfcn.h */
//#define HAVE_DLFCN_H

/* Define if we have the stat function */
//#define HAVE_STAT

/* Define if we have the powf function */
#define HAVE_POWF

/* Define if we have the sqrtf function */
#define HAVE_SQRTF

/* Define if we have the cosf function */
#define HAVE_COSF

/* Define if we have the sinf function */
#define HAVE_SINF

/* Define if we have the acosf function */
#define HAVE_ACOSF

/* Define if we have the asinf function */
#define HAVE_ASINF

/* Define if we have the atanf function */
#define HAVE_ATANF

/* Define if we have the atan2f function */
#define HAVE_ATAN2F

/* Define if we have the fabsf function */
#define HAVE_FABSF

/* Define if we have the log10f function */
#define HAVE_LOG10F

/* Define if we have the floorf function */
#define HAVE_FLOORF

#if LOOM_PLATFORM != LOOM_PLATFORM_WIN32
/* Define if we have the strtof function */
#define HAVE_STRTOF
#else
#undef HAVE_STRTOF
#endif

/* Define if we have stdint.h */
#define HAVE_STDINT_H

/* Define if we have the __int64 type */
#define HAVE___INT64

/* Define to the size of a long int type */
#define SIZEOF_LONG 4

/* Define to the size of a long long int type */
#define SIZEOF_LONG_LONG 8

#if LOOM_COMPILER == LOOM_COMPILER_GNU

/* Define if we have GCC's destructor attribute */
#define HAVE_GCC_DESTRUCTOR

/* Define if we have GCC's format attribute */
#define HAVE_GCC_FORMAT

#else

#undef HAVE_GCC_DESTRUCTOR
#undef HAVE_GCC_FORMAT

#endif

/* Define if we have pthread_np.h */
#undef HAVE_PTHREAD_NP_H

/* Define if we have arm_neon.h */
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
#define HAVE_ARM_NEON_H
#else
#undef HAVE_ARM_NEON_H
#endif

/* Define if we have guiddef.h */
#undef HAVE_GUIDDEF_H

/* Define if we have guiddef.h */
#undef HAVE_INITGUID_H

/* Define if we have ieeefp.h */
#undef HAVE_IEEEFP_H

/* Define if we have float.h */
#define HAVE_FLOAT_H

/* Define if we have fpu_control.h */
#undef HAVE_FPU_CONTROL_H

/* Define if we have fenv.h */
#if LOOM_PLATFORM != LOOM_PLATFORM_WIN32
#define HAVE_FENV_H
#else

// Fake up the rounding behavior.
#include <float.h>
#pragma fenv_access (on)
#define FE_TOWARDUP    _RC_UP
#define FE_TOWARDDOWN  _RC_DOWN
#define FE_TOWARDZERO  _RC_CHOP
#define FE_TOWARDNEAR  _RC_NEAR
static int fegetround(void) // The fegetround function gets the current rounding direction.
{
                  return (_control87(0, 0) & _MCW_RC);
}
static int fesetround(int rounding_mode)
{
                  _control87(rounding_mode, _MCW_RC);
                  if( (_control87(0, 0) & _MCW_RC) != rounding_mode ){ return -1; }
                  return 0;
}

#endif

/* Define if we have fesetround() */
#define HAVE_FESETROUND

/* Define if we have _controlfp() */
#undef HAVE__CONTROLFP

/* Define if we have pthread_setschedparam() */
#define HAVE_PTHREAD_SETSCHEDPARAM

#if LOOM_PLATFORM_IS_APPLE == 1

/* Define if we have the restrict keyword */
#define HAVE_RESTRICT

/* Define if we have the __restrict keyword */
#define HAVE___RESTRICT

#else

#undef HAVE_RESTRICT
#undef HAVE___RESTRICT

#endif
