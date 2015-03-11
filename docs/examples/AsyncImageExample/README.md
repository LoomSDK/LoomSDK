title: Async Image Example
description: Shows how to create an AsyncImage object that loads its texture asset asyncronously, and while it loads it optionally. displays a 'spinning' animation.
source: src/AsyncImageExample.ls
thumbnail: images/screenshot.png
!------

## Overview
Basic usage of an AsyncImage object in Loom.  This app contains 3 separate AsyncImage objects which will continuously cycle through async texture loads.  These loads can be either from the local /asset folder in the example or remotely via HTTP requests, and can be toggled between at any time with the button at the bottom of the app.  The HTTP images are public images requested from Flickr through their REST API, and the code to do so is freely availble in this app.

## Try It
@cli_usage

## Screenshot
![AsyncImageExample Screenshot](images/screenshot.png)

## Code
@insert_source
