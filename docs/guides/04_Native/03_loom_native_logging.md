title: Logging
description: Using native logging in C++
!------

Loom includes a lightweight logging framework.

All log output is associated with a log group. Log groups provide a name,
an enabled switch and a filter level (controlling what severity of log message
is displayed).

## Log group definition

Log groups are defined with the following macro in global scope.

**An example**
~~~cpp
#include "loom/common/core/log.h"

lmDefineLogGroup(loom_asset, "loom.asset", 1, LoomLogWarn);
~~~

**Arguments**

The first argument is the name of the variable we are defining.

The second argument is the name that is going to be displayed along with the
log message.

The third argument is the enable switch. 1 for enabled, 0 for disabled.

The last argument if the default filter level of the log group. Lower levels
will not be shown. Filter levels are `LoomLogDebug`, `LoomLogInfo`,
`LoomLogWarn`, `LoomLogError` and `LoomLogMax` (same as `LoomLogError`).

## Sharing groups and declaration

Log groups may need to be shared across files. In this case you need one
instance of lmDefineLogGroup somewhere in your program, and the following
macro visible to the other files using the group:

~~~cpp
#include "loom/common/core/log.h"

lmDeclareLogGroup(loom_asset);
~~~

## Actual logging

To perform any logging, a log group definition or declaration must preceed
the log call. Then we can call one of the following macros: `lmLogDebug`,
`lmLogInfo`, `lmLogWarn`, `lmLogError` or `lmLog` (an alias to `lmLogInfo`). 

**A simple example**
~~~cpp
#include "loom/common/core/log.h"

// ...

lmLog(myGroup, "I'm using Loom native logging!");
~~~

Note that Loom logging enables the same syntax as `printf` and you can easily
format your messages.

~~~cpp
lmLog(myGroup, "Logged in as user \"%s\", ID:%d", username, id);
~~~

## Configuration

Users may configure the logging system using prefix based rules. This is
implemented here via `loom_log_addRule`, but users will generally configure
it via loom.config.

~~~cpp
#include "loom/common/core/log.h"

// There is no need to have a reference to the group object here.
// Just pass in the display name of the group in here along with
// enable and filter arguments.
loom_log_addRule("mygroup", 1, LoomLogError);
~~~

## Callbacks

Loom also supports registering callbacks, which can be used to pipe messages
to custom outputs.

~~~cpp
#include "loom/common/core/log.h"

lmDefineLogGroup(mygroup, "mygroup", 1, LoomLogInfo);

void listener(void \*payload, loom_logGroup_t \*group, loom_logLevel_t, const char \*msg)
{
    // Do your thing here
}

loom_log_addListener(&listener, NULL);

// And to optinally remove the listener call

loom_log_removeListener(&listener, NULL);
~~~

Note that `payload` can be a pointer to arbitrary data that will get passed down
to the listener and it must match when adding and removing listeners.