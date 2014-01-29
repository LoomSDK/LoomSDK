title: Deploying To Android
description: An overview of building, running, and deploying your app on Android.
!------

Loom makes it easy to deploy to Android devices, just type the following in your command prompt:

~~~
loom run --android
~~~

## Deploying to Android

Android is pretty smooth. We don't have any standard troubleshooting steps. Loom will automatically download and install the appropriate Android SDK, and it will also automatically create a debug certificate if you don't have one. Simply do `loom run --android`.

To produce an unsigned Android APK ready to package for release, run `loom build android --unsigned`. Then follow the instructions in [the Android release signing instructions](http://developer.android.com/tools/publishing/app-signing.html#releasemode). Note that Loom CLI produces an unsigned release APK so you don't have to build with Ant or Eclipse.

`loom android log` is useful to debug mysterious app crashes. (It's the same as `adb logcat` but uses the Android SDK that Loom installed for you, so it's more likely to work.)