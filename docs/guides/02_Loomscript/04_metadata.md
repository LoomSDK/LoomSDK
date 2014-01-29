title: Metadata
description: Annotate your objects.
!------

LoomScript uses several metadata tags. Currently they are:

   - [Inject] on a field on a LoomComponent or LoomGameObject. The field is fulfilled from the LoomGroup that owns the LoomGameObject that owns the LoomComponent. `id` can optionally be specified. Implemented by LoomScript.
   - [Bind] on a field on a class bound to LML via LML.bind() or LML.apply(). The field is fulfilled based on the name of the field matching the name of a UI element in the LML. `id` can optionally be specified. Implemented by LoomScript.
   - [Native] or [Native(managed)] on a class. The latter indicates that the class should be managed by LoomScript; see the Loom Native Bindings section for details. Implemented by LSC.
   - [Deprecated] is used to mark a class, field, or method as not to be used.

Please note that you can add any metadata you like in LoomScript, with any number of parameters with optional values:

~~~
[MyMetadata(flagKey, key1=value1, key2=value2)]
~~~

Currently all metadata is included at runtime. It can be queried via `system.reflection.Type`.