title: Device Overview
description: An overview on working with devices.
!------

Loom makes it easy to deploy to different devices, just type the following in your command prompt:

~~~
loom run --ios --android
~~~

However, you can run into a few issues that prevent Loom from deploying onto your device. We'll discuss possible issues and give advice and troubleshooting tips.

NOTE: As of Sprint 31, Loom on Windows does not support deploying to iOS.

## Deploying to iOS [Mac Only]

You need to have XCode installed to deploy to iOS. You also need a valid iOS developer account with Apple.

To deploy a release version of your app, use the distribution provision from your iTunes account (read on for instructions). Then you have to manually create an IPA, by doing the following: 
   1. Create a folder named Payload. 
   2. Copy Myapp.app into the Payload directory. 
   3. Compress the Payload directory and rename the zip file to Myapp.ipa.

 (With thanks to [the "Create .ipa for iPhone" article on Stack Overflow](http://stackoverflow.com/questions/1191989/create-ipa-for-iphone).)

If you encounter issues, we recommend checking the forums. You can also try these tips:

**Check the organizer in XCode.** You should have a green provision on the device you are deploying to. If you do not have a green provision, then check the Apple developer provisioning site. Make sure the provision has your signing certificate and your device in it (click Edit to see). If you modify it, don't forget to wait for it to sign, then refresh in XCode Organizer under Library -> Provisioning Profiles. You also need to download the .mobileprovision file, and bring it into your Loom project by running:

~~~
loom ios provision pathToYour.mobileProvision
~~~

**Is your signing certificate signed against the private key on your computer?** You can export your keyring from one computer to another to get the same certificate everywhere.

**Do you have an appropriate version of iOS on your device?** Ideally, you should match the SDK version you are building against. You can find downloads of all iOS updates here: http://www.idownloadblog.com/iphone-downloads/ and they can be installed via the Organizer. You can determine your target iOS device's version at this site: http://www.everymac.com/ultimate-mac-lookup/?search_keywords=MC540LL

If you are getting mysterious crashes, the XCode Organizer lets you see console output which may give you a clue to the reason for the failure.

## Deploying to Android

Android is pretty smooth. We don't have any standard troubleshooting steps. Loom will automatically download and install the appropriate Android SDK, and it will also automatically create a debug certificate if you don't have one. Simply do `loom run --android`.

To produce an unsigned Android APK ready to package for release, run `loom build android --unsigned`. Then follow the instructions in [the Android release signing instructions](http://developer.android.com/tools/publishing/app-signing.html#releasemode). Note that Loom CLI produces an unsigned release APK so you don't have to build with Ant or Eclipse.

`loom android log` is useful to debug mysterious app crashes. (It's the same as `adb logcat` but uses the Android SDK that Loom installed for you, so it's more likely to work.)