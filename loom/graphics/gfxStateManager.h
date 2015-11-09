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

#pragma once

/*
 * This set of functions enables interoperability of multiple renderers that
 * break each others GL states. It lets a renderer know if it's GL state needs
 * to set up it's state again or not.
 */

#ifdef __cplusplus
extern "C" {
#else
#include <stdbool.h>
#endif

enum Graphics_GLState {
    GFX_OPENGL_STATE_NANOVG = 0,
    GFX_OPENGL_STATE_QUAD   = 1,
    GFX_OPENGL_STATE_MAX    = 2,
};

/*
 * Checks if given state is still valid.
 * Returns false if it was invalidated or another state was set.
 */
bool Graphics_IsGLStateValid(enum Graphics_GLState state);

/*
 * Invalidates given state. Another state might still be valid if
 * the invalidated state was already invalid. This should be called
 * when somehting changes that affects given state.
 */
void Graphics_InvalidateGLState(enum Graphics_GLState state);

/*
 * Invalidates all other states and sets the given state as valid.
 * This should called after a GL state has been set up for given state.
 */
void Graphics_SetCurrentGLState(enum Graphics_GLState state);

#ifdef __cplusplus
};
#endif