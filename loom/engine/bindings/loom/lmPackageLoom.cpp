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

void installLoomApplication();
void installPackageCocos2DX();
void installLoomAssets();
void installPackageLoomPhysics();
void installLoomPropertyManager();
void installLoomWebView();
void installLoomAdMobAd();
void installLoomHTTPRequest();
void installLoomNativeStore();
void installLoomVideo();
void installLoomMobile();
void installLoomGraphics();
void installLoom2D();
void installPackageLoomSound();
void installLoomFacebook();
void installLoomTeak();

void installPackageLoom()
{
    installLoomApplication();
    installLoomWebView();
    installLoomAdMobAd();
    installLoomHTTPRequest();
    installLoomAssets();
    installPackageLoomPhysics();
    installLoomPropertyManager();
    installLoomNativeStore();
    installLoomVideo();
    installLoomMobile();
    installLoomFacebook();
    installLoomTeak();
    installPackageLoomSound();

    // Should be its own package for maximum correctness.
    installPackageCocos2DX();

    installLoomGraphics();
    installLoom2D();
}
