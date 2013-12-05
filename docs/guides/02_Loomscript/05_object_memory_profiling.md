title: Object Memory Profiling
description: How to profile Object instances in Loom
!------

First, start your application normally with:

**loom run**

then at the command console enter:

**profilerEnable**

You should then see: **[asset.protocol] LOG: Enabling profiler...**

This means the profiler is running and generating metrics for both Object allocation/deallocation and timings on methods being called.

You should now do something meaningful in your application, in terms of looking for memory leaks this might mean cycling between screens or playing a couple rounds of a game.  Once you have done this enter the following into the command console:

**profilerDump**

This will dump out a hierarchical list of Objects created/destroyed since profiling began.  It will also tell you the methods that created the Objects.

For instance:

    [asset.protocol] LOG: [Profiler] Alive: 14, Total: 45, Type: feathers.skins.SmartDisplayObjectStateValueSelector
    [asset.protocol] LOG: [Profiler]      Alive 0, Total 4 (feathers.themes.MetalWorksMobileTheme.buttonGroupButtonInitializer)
    [asset.protocol] LOG: [Profiler]      Alive 4, Total 8 (feathers.themes.MetalWorksMobileTheme.buttonInitializer)
    [asset.protocol] LOG: [Profiler]      Alive 8, Total 31 (feathers.themes.MetalWorksMobileTheme.itemRendererInitializer)
    [asset.protocol] LOG: [Profiler]      Alive 1, Total 1 (feathers.themes.MetalWorksMobileTheme.simpleButtonInitializer)
    [asset.protocol] LOG: [Profiler]      Alive 1, Total 1 (feathers.themes.MetalWorksMobileTheme.toggleSwitchTrackInitializer)

This is letting us know that since profiling began, 45 `SmartDisplayObjectStateValueSelector` were created and 14 are still instantiated (31 were created and garbage collected to arrive at the reported total of 45).  We can also see which specific methods both created and destroyed the instances to find possible instance leaks.  In this case, the `itemRendererInitializer` method is the largest source of "churn" or allocations and destructions.  If the number of "Alive" instances continues to grow in a method, this is a good indication of a leak.

**Advanced Usage**: Please note that it is also possible to use the Loom Object Profiler from your scripts using the `system.Profiler` API.  This can be helpful when targeting specific code sections.  Also, note that when running under the JIT VM instances allocated/destroyed by native methods are credited to their calling script function.




