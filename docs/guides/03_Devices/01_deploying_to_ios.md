title: Deploying to iOS
description: An overview of building, running, and deploying your app on iOS.
!------

NOTE: Loom on Windows does not currently support deploying to iOS. The following instructions are for Mac only.

Before you can run your app on iOS, you will need the following:

* XCode
* An iOS Developer Certificate from Apple
* A .mobileProvision file from the Apple Developer Center (the Mobile Provision app id and the app id specified in your loom.config must match)

## Specifying the Developer Certificate and Mobile Provision

Once you have your certificate downloaded and installed, open your command prompt, navigate to your project directory, and run the following command to point to your certificate, making sure to replace
John Doe (XXXX) with your own certificate:

~~~
loom config ios_signing_identity "iPhone Developer: John Doe (XXXX)"
~~~

Next, point your project at your Mobile Provision with the following command, making sure to substitute 'app.mobileProvision' for the location of your app's .mobileProvision file.

~~~
loom ios provision 'app.mobileProvision'
~~~

## Running Your App

To run your app on iOS, type the following in your command prompt:

~~~
loom run --ios
~~~

## Troubleshooting

If you run into issues that prevent Loom from deploying to your device, here are some troubleshooting tips:

* **Check the forums!** If you are running into a problem, it is likely that someone else has run into the same issue and a solution has been posted.
* **Check the organizer in XCode.** You should have a green provision on the device you are deploying to. If you do not have a green provision, then check the Apple developer provisioning site. Make sure the provision has your signing certificate and your device in it (click Edit to see). If you modify it, don't forget to wait for it to sign, then refresh in XCode Organizer under Library -> Provisioning Profiles. You also need to download the .mobileprovision file, and bring it into your Loom project (see *Specifying the Developer Certificate and Mobile Provision*)
* **Is your signing certificate signed against the private key on your computer?** You can export your keyring from one computer to another to get the same certificate everywhere.
* **Do you have an appropriate version of iOS on your device?** Ideally, you should match the SDK version you are building against. You can find downloads of all iOS updates here: http://www.idownloadblog.com/iphone-downloads/ and they can be installed via the Organizer. You can determine your target iOS device's version at this site: http://www.everymac.com/ultimate-mac-lookup/?search_keywords=MC540LL
* **Are you using the right codesign?** If you run into the error, `object file format unrecognized, invalid, or unsuitable`, setting the CODESIGN_ALLOCATE environment like so may fix your issue: `export CODESIGN_ALLOCATE="/Applications/Xcode.app/Contents/Developer/usr/bin/codesign_allocate"` (see http://loomsdk.com/forums/troubleshooting-and-issues/topics/ios-deploy-troubleshooting-megathread-did-you-reinstall-your-certs)
* **Have you rebooted the device and desktop?** Simple, quick, easy, fixes stuff way more often than we'd want to admit. Sometimes the iOS/XCode deploy pipeline just gets clogged and a quick reboot fixes it.
* **"ambiguous" developer error** This happens if you have more than one developer certificate. You can specify the one you want Loom to use by the following command: `loom config --global ios_signing_identity "iPhone Developer: John Doe (XXXX)"`
* If you run into device install errors, try running a `loom clean`. This will delete your build artifacts, and possibly your issue.
* If you are getting mysterious crashes, the XCode Organizer lets you see console output which may give you a clue to the reason for the failure.