title: Metadata
description: Annotate your objects.
!------

It's often useful to annotate your code with metadata - a simple dictionary of string keys and values associated with a class, method, property, or field. Metadata can be used to extend language capabilities without cumbersome workarounds like secondary fields or registration functions. Examples of metadata use include building editor UIs, dependency injection, validating or populating fields on value objects, UI binding, and much much more.

## Common Usage

LoomScript commonly uses several metadata tags. Currently they are:

   - [Inject] on a field on a LoomComponent or LoomGameObject. The field is fulfilled from the LoomGroup that owns the LoomGameObject that owns the LoomComponent. `id` can optionally be specified. Implemented by LoomScript.
   - [Bind] on a field on a class bound to LML via LML.bind() or LML.apply(). The field is fulfilled based on the name of the field matching the name of a UI element in the LML. `id` can optionally be specified. Implemented by LoomScript.
   - [Native] or [Native(managed)] on a class. The latter indicates that the class should be managed by LoomScript; see the Loom Native Bindings section for details. Implemented by LSC.
   - [Deprecated] is used to mark a class, field, or method as not to be used.  Implemented by LSC.

## Examples

Here's a fictional LoomScript example showing how Metadata might be used to show a UI caption for a field on an object:

~~~
class Foo
{
	[UI(caption="Age of this item.")]
	public var itemAge:Number;	
}
~~~

Later, 'system.reflection.Type' can be used to query metadata as follows:

~~~
var foo = new Foo();
var fooType = foo.getType();
var iaInfo = fooType.getFieldInfoByName("itemAge");
trace("Field caption: " + iaInfo.getMetaInfo("UI").getAttribute("caption"));
~~~

Please note that you can add any metadata you like in LoomScript, with any number of parameters with optional values. Multiple metadata tags can apply to the same item. For instance:

~~~
[MyMetadata(flagKey, key1=value1, key2=value2)]
[MyOtherMetaData]
public class MyClass
{

}
~~~

