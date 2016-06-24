title: Deploying to iOS
description: An overview of building, running, and deploying your app to iOS.
!------

> **Note**: Loom on Windows does not currently support deploying to iOS. The following instructions are for Mac only.


## Preparation

Before you can deploy your app to iOS, you will need the following:

* Xcode
* An Apple Developer Account
* One or more registered mobile device(s) to install onto
* An iOS Developer Certificate (`.cert`)
* An iOS Mobile Provisioning file (`.mobileProvision`)


### Xcode

> Xcode installs many command line tools which are required for building iOS apps.

0. Install Xcode from the [Mac App Store][xcode-app]
0. You can verify that the command line tools are installed by looking for their package receipts:

```console
$ pkgutil --pkg-info=com.apple.pkg.* --regexp | grep CL
```

* You should see one of the following:
  * `package-id: com.apple.pkg.CLTools_Executables` (OSX 10.9 Mavericks)
  * `package-id: com.apple.pkg.DeveloperToolsCLI` (OSX 10.8 Mountain Lion and earlier)
* If you get no results, you need to install the command line tools:
  * **OSX 10.9**: `xcode-select --install`
  * **OSX 10.8**: _Xcode_ > _Preferences_ > _Downloads : Components_ and click to install the command line tools


### Apple Developer Account

> You need an Apple Developer Account to be able to generate your code signing identity (developer certificate), and provisioning profiles for distribution.

Register at https://developer.apple.com/register/


### iOS Developer Certificate

> An iOS developer certificate is your code signing identity, used to cryptographically sign apps in preparation for distribution.

0. Log in to https://developer.apple.com/membercenter/
0. Select the _Certificates, Identifiers & Profiles_ section
0. Select _Certificates_ under _iOS Apps_
0. Use the (+) to _Add iOS Certificate_ . Choose _Production_ > _App Store and Ad Hoc_
0. Follow instructions to generate a Certificate Signing Request (CSR)
0. Upload the CSR file to Apple
0. Download your signing certificate and double-click to install it into Keychain Access


### Mobile Devices

> Any mobile devices you wish to be able to install your app on must be registered with Apple so they can be included in provisioning profiles.

0. Log in to https://developer.apple.com/membercenter/
0. Select the _Certificates, Identifiers & Profiles_ section
0. Select _Devices_ under _iOS Apps_
0. Use the (+) to _Add iOS Devices_ . Enter a name and the UDID and continue
  * **Note:** the UDID can be found by connecting the device to your Mac and opening iTunes:
     0. Open the summary page
     0. Click on the serial number to toggle it to show _Identifier (UDID)_
     0. Right-click and select _Copy_ to transfer the UDID to the clipboard


### Mobile Provisioning Profile

> A provisioning profile is embedded in the app when it is packaged for distribution, and determines where an app will be allowed to be installed.

0. Log in to https://developer.apple.com/membercenter/
0. Visit the _Certificates, Identifiers & Profiles_ section
0. Select _Provisioning Profiles_ under _iOS Apps_
0. Use the (+) to _Add iOS Provisioning Profile_ . Choose _Distribution_ > _Ad Hoc_ and continue
0. Select your App ID and continue
  * **Note:** the Mobile Provision App ID and the App ID specified in your loom.config must match. A wildcard App ID (`*`) in your provision will match everything.
0. Select the identity that will be signing the app
0. Select the devices you wish to enable installation for
0. Choose a name for this profile and generate it
0. Download (and remember the path for later)


## Specifying the Developer Certificate and Mobile Provision

Once you have your certificate downloaded and installed, open your command prompt, navigate to your project directory, and run the following command to point to your certificate, making sure to replace `<signing-identity>` with your own identity, e.g. `iPhone Developer: John Doe (XXXX)`:

```console
$ loom config ios_signing_identity "<signing-identity>"
```

Next, point your project at your Mobile Provision with the following command, making sure to substitute the path to your app's .mobileProvision file for `<path-to-provision>`.

```console
$ loom ios provision "<path-to-provision>"
```

## Running Your App on iOS

To run your app on iOS, type the following at your command prompt:

```console
$ loom run --ios
```

## Troubleshooting

If you run into issues that prevent Loom from deploying to your device, here are some troubleshooting tips:

**Check the forums!** If you are running into a problem, it is likely that someone else has run into the same issue and a solution has been posted.

**Check the organizer in Xcode.** You should have a green provision on the device you are deploying to. If you do not have a green provision, then check the Apple developer provisioning site. Make sure the provision has your signing certificate and your device in it (click Edit to see). If you modify it, don't forget to wait for it to sign, then refresh in Xcode Organizer under _Library_ > _Provisioning Profiles_. You also need to download the `.mobileprovision` file, and bring it into your Loom project (see [Specifying the Developer Certificate and Mobile Provision](#toc_6)).

**Is your signing certificate signed against the private key on your computer?** You can export your keyring from one computer to another to get the same certificate everywhere.

**Do you have an appropriate version of iOS on your device?** Ideally, you should match the SDK version you are building against. You can find downloads of all iOS updates here: http://www.idownloadblog.com/iphone-downloads/ and they can be installed via the Organizer. You can determine your target iOS device's version at this site: http://www.everymac.com/ultimate-mac-lookup/?search_keywords=MC540LL

**Are you using the right codesign?** If you run into the error, `object file format unrecognized, invalid, or unsuitable`, setting the `CODESIGN_ALLOCATE` environment variable like so may fix your issue (see http://loomsdk.com/forums/troubleshooting-and-issues/topics/ios-deploy-troubleshooting-megathread-did-you-reinstall-your-certs ):

```console
$ export CODESIGN_ALLOCATE="/Applications/Xcode.app/Contents/Developer/usr/bin/codesign_allocate"
```

**Have you rebooted the device and desktop?** Simple, quick, easy, and fixes stuff way more often than we'd want to admit. Sometimes the iOS/Xcode deploy pipeline just gets clogged and a quick reboot fixes it.

**"ambiguous" developer error** This happens if you have more than one developer certificate. You can specify the one you want Loom to use by the following command:

```console
$ loom config --global ios_signing_identity "iPhone Developer: John Doe (XXXX)"
```

If you run into device install errors, try running a `loom clean`. This will delete your build artifacts, and possibly your issue.

If you are getting mysterious crashes, the Xcode Organizer lets you see console output which may give you a clue to the reason for the failure.


[xcode-app]: http://itunes.apple.com/us/app/xcode/id497799835?ls=1&mt=12
