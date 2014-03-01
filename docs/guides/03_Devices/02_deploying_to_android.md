title: Deploying To Android
description: An overview of building, running, and deploying your app on Android.
!------

Loom makes it easy to deploy to Android devices, just type the following in your command prompt:

~~~
loom run --android
~~~

## Deploying to Android

Android is pretty smooth. Loom will automatically download and install the appropriate Android SDK, and it will also automatically create debug and release certificates if you don't have them. Simply do `loom run --android`.

To produce an Android APK ready for release, run `loom android release`. This process will produce a Google Play Store-ready APK, signed with your release certificate.  If you do not specifiy a release keystore via command arguments, and a default keystore does not exist, the CLI will ask you for a password and create one for you. Be sure to back this file up and remember your password, as you will need it to sign all future releases of your app.

To view command line options for releasing Android builds, type `loom android --help` in your console.

`loom android log` is useful to debug mysterious app crashes. (It's the same as `adb logcat` but uses the Android SDK that Loom installed for you, so it's more likely to work.)

## Troubleshooting

If you do happen to run into issues deploying to Android from Loom, the following may be helpful:

* **Do you have JDK 6 installed?** If you are getting INSTALL_PARSE_FAILED_NO_CERTIFICATED errors, you are probably on Windows and don't have JDK6 in your path. The code signing changed between JDK 6 and JDK 7 and as a result Loom right now requires JDK 6. See http://loomsdk.com/forums/troubleshooting-and-issues/topics/android-troubleshooting-megathread-i-got-99-devices-but-an-n7-ain-t-one/posts/1023 for more information.
* **Do you see INSTALL_FAILED_CPU_ABI_INCOMPATIBLE?** Loom right now only supports arm7 and above.