title: Parse Example
description: Basic usage of Parse REST and Cloud Code/Push Notification functions.
source: src/ParseExample.ls
thumbnail: images/screenshot.png
!------

## Overview
Loom has native functions that allow you to interface with Parse (http://www.parse.com) via some of its common REST interfaces. Loom also supports receiving Parse push notes sent through the Parse system. This example showcases two of the common REST functions, and Push Notes.
Please be aware that Loom currently only supports push note functions on Android and iOS.

## Try It
@cli_usage
You will then need to set up a basic Parse application before running this example.
Instructions for application setup can be found when signing up at http://www.parse.com.

Once your Parse app is set up, you will then need to do the following:

- Create a new user (or two!) in the Data Browser on the application's dashboard on the Parse site.
- Create an empty Installation object in the app's Data Browser (click on New Class, and select Installation as the object type). Add a column to the Installation object called “userId”.
- If you are deploying to iOS, set your Apple push certificate values in the Settings tab.
- Open up loom.config in the example's directory, and copy the required application keys from your Parse app into the relevant fields. You will require the Application ID, REST API key, and client key.
- You will also need to upload the Cloud Code for this example to your account.  Detailed instructions for cloud code upload can be found at https://www.parse.com/docs/cloud_code_guide. The javascript source can be found in main.js under the Parse directory in your example (ParseCloudSrc/parse/cloud/main.js).

You can now run the example! Log in to a user account and try sending yourself a push notification. Better still, try logging in to separate accounts from two devices, and send notes to each other!

## Screenshot
![Screenshot](images/screenshot.png)

## Code
@insert_source
