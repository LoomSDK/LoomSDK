title: Facebook and Teak Example
description: A very basic implementation of Facebook login and optional calls to Teak social library.
source: src/FeathersComponentExplorer.ls
thumbnail: images/screenshot.png
!------

## Overview
Loom has basic API support for Facebook session and permissions control, and optionally supports calls to the Teak API (http://www.teak.io) for Facebook social object creation and posting.
Facebook and Teak support are only available for iOS and Android.

## Try It
@cli_usage

You will need to set up a test application on Facebook and Teak before this example will work correctly. Instructions for app setup on Facebook and Teak can be found at:
 - https://developers.facebook.com/docs/web/tutorials/scrumptious/register-facebook-application/
 - http://www.teak.io (once signed up)

Once your test app is set up on Teak and Facebook, you will then need to do the following:

- Be sure that your Facebook app contains the proper Android Keyhash and/or iOS Bundle ID for the device you wish to deploy to, or Facebook will reject login attempts from your app.
- Create an achievement called “teakWorks” in your Teak app. Add whatever title, image and message you want.
- Place your Facebook Application Name (found on your Facebook app page) in the example's loom.config file under "facebook_display_name"
- Place your Facebook Application ID (found on your Facebook app page) in the example's loom.config file under "facebook_app_id"
- Place your Teak App Secret (found on the Teak app settings page) in the example's loom.config file under "teak_app_secret".

You can now run the example!

## Screenshot
![FileExample Screenshot](images/screenshot.png)

## Code
@insert_source
