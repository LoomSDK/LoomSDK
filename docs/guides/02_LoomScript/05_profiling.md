title: Profiling
description: How to profile Loom memory and CPU usage.
!------

Games and apps must run well to deliver acceptable experiences. When performance issues are encountered, optimization is required. The best way to improve a bad performance scenario is a simple loop: measure, optimize, repeat until performance is better. Measuring performance to identify what is slowing down your app helps you direct your development effort for maximum return - that is, fix the slowest part first!

How to measure? Loom provides a rich set of proiling tools. They are simple but effective.

Let's begin by profiling something. First, start your application normally with:

~~~console
$ loom run
~~~

then at the command console enter:

~~~console
$ profilerEnable
~~~

You should then see:

~~~console
[asset.protocol] LOG: Enabling profiler...
~~~

This means the profiler is running and generating metrics for both object allocation/deallocation and timings on methods being called.

Now, do something meaningful in your application. In terms of looking for memory leaks, this might mean cycling between screens or playing a couple rounds of a game - anything that exhibits subpar performance.  Once you have done this enter the following into the command console:

~~~console
$ profilerDump
~~~

You will be rewarded with a huge amount of information on what Loom was doing while you ran the profiler. The following sections explain what this output means and how to use it.

**Advanced Note:** You may drive the profiler programmatically via the `system.Profiler` API. `profilerReset` will reset all counts in the profiler.

## Tracking Performance

Loom tracks detailed timing information on both the script and native sides to give you a complete view on performance. In the output from the profiler, you will see two reports - the "Ordered by non-sub total time" and the "Ordered by strack trace total time" reports.

The first, the non-sub time report, shows the time spent in a function less the time spent in its children - its "non-sub" time. In other words, this report shows the functions taking up the most execution time globally. Suppose you have a function A that has little code, and does its work by calling another function B many times. A will show up low on this report, while B will be near the top. Here's some example output:

~~~text
 Ordered by non-sub total time -
 %NSTime  % Time  Invoke #  Name
  30.436  81.067      590 loom.Application.onCocosFrame
   4.133   5.762       93 loom2d.display.DisplayObjectContainer.getChildEventListeners
   3.782   7.344       97 loom2d.text.BitmapFont.arrangeChars
   3.716  41.502      961 loom2d.events.EventDispatcher.invokeEvent
   2.703   2.706        1 loom.Application.onProfilerDump
   2.289   2.289     1560 system.Vector.Vector
   ... trimmed for length ...
 Suppressed 104 items with < 0.1% of measured time.
~~~

The above shows that 30% of all observed time was spent in `Application.onCocosFrame`! Why might this be? It's an internal function that's run on every frame. Because the profiled application was running very well, not very much time was measured and even a lightweight function like `onCocosFrame` will show up high in the profiler's report. Try running the profiler with a slower program and you'll rapidly see your code rise to the top!

However, while the above report gives us some good insights on the slowest parts, we don't see context. Suppose that some utility function - like `VertexData.setPosition` - was high on the non-sub time report. This function is hard to micro-optimize because all it does is shuffle a little data around. But it could be being used in a very non-optimal way - perhaps a custom UI component is updating itself too often. So we want to see when it is being called and why.

This is where the stack trace report comes in. It shows program execution as a tree. Each function's calls are shown as children in the tree, and the whole thing is sorted to show the slowest branches first. Here's a snippet from a real profiler dump:

~~~text
 Ordered by stack trace total time -
 % Time  % NSTime  Invoke #  Name
 100.000 100.000        0 ROOT
  81.067  30.436      590   loom.Application.onCocosFrame
  39.646   1.615      590     display.Stage.advanceTime
  37.650   1.282      590       events.EventDispatcher.dispatchEvent
  35.739   2.608      590         events.EventDispatcher.invokeEvent
  30.664   0.554      590           feathers.core.ValidationQueue.process
  13.088   0.094       35             text.BitmapFontTextRenderer.validate
  12.584   0.373       35               text.BitmapFont.fillQuadBatch
   4.417   0.113      352                 display.QuadBatch.addImage
   4.304   0.778      352                   display.QuadBatch.addQuad
   3.526   0.243      352                     display.Image.updateVertexData
   2.823   1.015      352                       SubTexture.adjustVertexData
   0.794   0.568     1408                         utils.VertexData.getTexCoords
   0.226   0.226     1408                           utils.VertexData.getOffset
   0.717   0.494     1408                         utils.VertexData.setTexCoords
   0.223   0.223     1408                           utils.VertexData.getOffset
   0.225   0.225     1408                         math.Point.__op_assignment
   0.459   0.459      352                       utils.VertexData.copyTo
   2.848   0.618      352                 display.Image.__pset_texture
   1.673   0.420      299                   display.Image.readjustSize
   0.597   0.412     1196                     utils.VertexData.setPosition
   0.185   0.185     1196                       utils.VertexData.getOffset
   0.548   0.245      299                     Texture.__pget_frameReadOnly
   0.153   0.107      299                       SubTexture.__pget_width
   0.150   0.105      299                       SubTexture.__pget_height
   0.287   0.194      598                   SubTexture.__pget_premultipliedAlpha
   0.114   0.114      299                   textures.Texture.__pget_nativeID
   2.761   1.441       35                 text.BitmapFont.arrangeChars
   0.618   0.231      740                   text.BitmapChar.__pget_width
   0.387   0.265      740                     textures.SubTexture.__pget_width
   0.121   0.121      740                       ConcreteTexture.__pget_width
 ... trimmed for length, package names also reduced for width ...
 Suppressed 433 items with < 0.1% of measured time.
~~~

As you can see, a lot of code is showing up! But before we jump to conclusion, let's dig into the numbers.

First, it's often useful to look at the invoke counts. They give a picture of how often things are being run. We can spot frame counts by looking for our old friend `onCocosFrame` - the name suggests that it's called every frame and you'd be right to think that. For instance, we can see that `onCocosFrame` was run 590 times in the profiling period, but `BitmapFontTextRenderer.validate` was only run 35 times. So this branch of execution, which dominates the top of our profiler dump, was run less than 10% of frames - not so much of a concern now, is it?

We can also look at the non-sub and total time percents for the  `BitmapFontTextRenderer` branch - 13% of total time is a fair chunk. However, before you rewrite the `validate` call, consider that the non-sub time (the time spent just in that function) is 0.09%. If you want any wins they'll have to be found deeper in the call stack.

So what do we know now? Well, we can see that for our profiling code not much code was run, and the profile is pretty flat - that is, most code paths take about the same amount of time. The only outlier is `onCocosFrame`, and this only appears to be taking a huge chunk because the app is doing so little - so doing anything takes a lot of time! In a real app or game, business logic, physics, graphics, or AI code would likely dominate the profiler.

Methods with `__pget_` in them are getters, by the way, and `__pset_` are setters. Functions starting with `__op_` are operators.

## Tracking Memory

If performance is time, memory is space. Naturally, Loom's profiler tracks both. In the profiler output, you will see a hierarchical list of objects created and destroyed since profiling began, broken out by the method doing the allocation.

For instance, here is one section showing a single object's allocation behavior (ignoring logger prefix output, and with package names trimmed for width):

~~~text
    Alive: 14, Total: 45, Type: skins.SmartDisplayObjectStateValueSelector
         Alive 0, Total 4 (MetalWorksMobileTheme.buttonGroupButtonInitializer)
         Alive 4, Total 8 (MetalWorksMobileTheme.buttonInitializer)
         Alive 8, Total 31 (MetalWorksMobileTheme.itemRendererInitializer)
         Alive 1, Total 1 (MetalWorksMobileTheme.simpleButtonInitializer)
         Alive 1, Total 1 (MetalWorksMobileTheme.toggleSwitchTrackInitializer)
~~~

This is letting us know that since profiling began, 45 `SmartDisplayObjectStateValueSelector` were created and 14 are still instantiated (31 were created and garbage collected to arrive at the reported total of 45).  We can also see which specific methods both created and destroyed the instances to find possible instance leaks.  In this case, the `itemRendererInitializer` method is the largest source of "churn" or allocations and destructions.

If the number of "Alive" instances grows continuously, this is a good indication of a leak.

If you see methods with high churn, it usually means that you are creating temporary objects. If those same methods show up as hotspots in the profiler, or you see a lot of time spent in the GC, it's a huge sign that you should reuse objects instead of constantly recreating them.
