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

#ifndef _PLATFORM_PLATFORMTIME_H_
#define _PLATFORM_PLATFORMTIME_H_

#ifdef __cplusplus
extern "C" {
#endif

void platform_timeInitialize();

// Get a timestamp in milliseconds.
int platform_getMilliseconds();

typedef void * loom_precision_timer_t;
loom_precision_timer_t loom_startTimer();
void loom_resetTimer(loom_precision_timer_t timer);
int loom_readTimer(loom_precision_timer_t timer);
double loom_readTimerNano(loom_precision_timer_t timer);
void loom_destroyTimer(loom_precision_timer_t timer);

#ifdef __cplusplus
};
#endif
#endif
