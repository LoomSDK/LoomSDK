title: Deploying To TestFlight
description: Deploy your app to TestFlight straight from the Loom CLI
!------

[TestFlight][testflight] is a free platform used to distribute beta and internal iOS applications to team members over-the-air.

You can upload your app directly to TestFlight from Loom and then log in to TestFlight to make it available to your team.


## Preparation

To configure your project for TestFlight, you will need:

* A TestFlight account
* Your TestFlight team token
* Your TestFlight API token
* A version number for your app

You will also need the following iOS-specific items (if you don't have all of these, refer to the [Deploying To iOS][deploy-ios] section under _Guides_ > _Devices_ ):

* A distribution certificate
* An Ad Hoc mobile provision file with an app id that matches your app


### TestFlight Account

Register at https://testflightapp.com/register/


### TestFlight API Token

0. Log in to https://testflightapp.com/account/
0. Select _Upload API_ from the left-side menu
0. Copy your api token to the clipboard

Set the api token as the value of `testflight_api_token` in your `loom.config` file, making sure to replace `<your-token>` with the actual api token:

```bash
$ loom config testflight_api_token "<your-token>"
```


### TestFlight Team Token

0. Log in to https://testflightapp.com/dashboard/
0. If you don't have any teams, the dashboard will provide a link to _Create a new team_
0. Provide a team name
0. Open the dropdown next to your avatar in the top menu
0. Select a team and choose _Edit Info_
0. Copy your team token to the clipboard

Set the team token as the value of `testflight_team_token` in your `loom.config` file, making sure to replace `<your-token>` with the actual team token:

```bash
$ loom config testflight_team_token "<your-token>"
```


### App version

Set the value of `app_version` in your `loom.config` file. A [Semantic Versioning][semver] scheme is recommended:

```bash
$ loom config app_version 0.0.0
```


## Build and Upload To TestFlight

After you've completed the preparation above, you can use Loom to deploy new versions of your app through TestFlight by running the `testflight` command:

```bash
$ loom testflight ios
```

To see more options available to you such as distribution lists and notification settings, add the `--help` parameter:

```bash
$ loom testflight --help
```


[testflight]: https://www.testflightapp.com/
[deploy-ios]: ../03_Devices/01_deploying_to_ios.html
[semver]: http://semver.org/
