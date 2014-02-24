title: Deploying To TestFlight
description: Deploy your app to TestFlight straight from the Loom CLI
!------

One of the many great features of Loom is its simple built-in TestFlight upload API integration. To upload your app to TestFlight, you will need:

* A TestFlight Account
* Your Team Token, which can be found at https://testflightapp.com/dashboard/team/edit/
* Your Upload API Token, which can be found at https://testflightapp.com/account/#api

If uploading an iOS app, you will also need to have the following already set up for your project:

* An Apple Distribution Certificate
* An Apple adhoc distribution .mobileProvision file with an app id that matches your app

( If you don't have these, check out the **Deploying To iOS** section under *Guides -> Devices* )

## Set Your API and Team Tokens

Modify your loom.config file to include the following:

~~~
"testflight_api_token": "YOUR_UPLOAD_API_TOKEN_HERE",
"testflight_team_token": "YOUR_TEAM_TOKEN_HERE"
~~~

## Upload To TestFlight

By this point you should be set up and ready to go. Upload your app by running `loom testflight ios` for iOS or `loom testflight android` for Android. That's it!
To see more options available to you such as distribution lists and notification settings, run the `loom testflight --help` command.