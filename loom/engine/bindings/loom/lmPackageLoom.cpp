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
void installLoomBox2D();
void installLoomPropertyManager();
void installLoomWebView();
void installLoomAdMobAd();
void installLoomHTTPRequest();
void installLoomNativeStore();
void installLoomVideo();
void installLoomMobile();
void installLoomParse();
void installPackageSDL();
void installLoomGraphics();
void installLoom2D();
void installPackageLoomSound();
void installLoomFacebook();
void installLoomTeak();
void installLoomSystem();
void installLoomSQLite();
void installLoomModestMaps();
void installLoomGameController();
void installLoomUserDefault();
void installCSSParser();

void installPackageLoom()
{
    installLoomApplication();
    installLoomWebView();
    installLoomAdMobAd();
    installLoomHTTPRequest();
    installLoomAssets();
    installLoomBox2D();
    installLoomPropertyManager();
    installLoomNativeStore();
    installLoomVideo();
    installLoomMobile();
    installLoomFacebook();
    installLoomTeak();
    installLoomParse();
    installLoomSQLite();
    installLoomModestMaps();
    installPackageLoomSound();
	installLoomSystem();
    installLoomGameController();
    installLoomUserDefault();
    installCSSParser();

    // Should be its own package for maximum correctness.
    //installPackageCocos2DX();
    installPackageSDL();

    installLoomGraphics();
    installLoom2D();
}
