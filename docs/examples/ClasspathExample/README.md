title: Classpath Example
description: How to use the loom.config classpath array to specify source folders to compile.
source: loom.config
thumbnail: images/screenshot.png
!------

## Overview
How to use the loom.config classpath array to specify source folders to compile.

## Try It
@cli_usage

## Screenshot
![ClasspathExample Screenshot](images/screenshot.png)

## Code

~~~text
{
  "sdk_version": "latest",
  "classpath": [
    "source",
    "../ClasspathExample/relativesources"
  ],
  "executable": "Main.loom",
  "display": {
    "width": 480,
    "height": 320,
    "title": "ClasspathExample",
    "stats": true
  },
  "app_name": "ClasspathExample",
  "app_id": "com.loomengine.ClasspathExample"
}
~~~
