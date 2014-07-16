title: Reflection
description: How to write introspective code.
!------

The `system.Reflection` API allows LoomScript programs to inspect and manipulate themselves programmatically. This is a very powerful building block, as it allows complex behaviors to be controlled by your program's structure. For instance, a UI could be built based directly on the fields making up a class, or a value object updated directly from a database without any glue code that must be maintained. Reflection reduces duplication of effort and helps code be more focused and self-documenting.

In LoomScript, the reflection API gives direct access to the runtime's internal type database. The heart of the reflection API is `system.Reflection.Type`. An instance of `Type` can be gotten in a few major ways:

* By class name (ie, `var t:Type = Object`), 
* From an instance of an object (ie, `var t:Type = something.getType()`),
* By fully qualified name (ie, `var t:Type = Type.getTypeByName("system.Object")`),
* Or from an `Assembly` (ie, `var t:Type = assembly.getTypeAtIndex(20)`).

Once you have your `Type`, the possibilities are infinite!

**Note:** Reflection APIs can be slow, so if you are using reflection in performance sensitive parts of your code, it is smart to pre-extract all the reflection info you need and store it in a format that is fast to use in your inner loops.

## Getting and Setting Values

`Type` provides two utility function for getting and setting values, the charmingly named `getFieldOrPropertyValueByName` and `setFieldOrPropertyValueByName`. They allow you to get and set fields by name:

~~~as3
class MyObject
{
	public var foo:String;
}

var mo = new MyObject();
var moType = mo.getType();

moType.setFieldOrPropertyValueByName(mo, "foo", "Hello, world!");
trace(moType.getFieldOrPropertyValueByName(mo, "foo"));
~~~

## Iterating Over Fields

`Type` lets you get a list of all the fields and properties in an object, as follows:

~~~as3
var fields:Array = something.getType().getFieldAndPropertyList();
~~~

Then you can set and get values programmatically, inspect metadata (see next section), or take other steps. 

Note that this only shows static fields, not dynamic fields as seen in `Dictionary` or `Array`. You want to use `for ... in` to iterate over the keys in those types.

## Metadata

It's often useful to annotate your code with metadata - a simple dictionary of string keys and values associated with a class, method, property, or field. Metadata can be used to extend language capabilities without cumbersome workarounds like secondary fields or registration functions. Examples of metadata use include building editor UIs, dependency injection, validating or populating fields on value objects, UI binding, and much much more.

### Common Usages

LoomScript commonly uses several metadata tags. Currently they are:

   - [Inject] on a field on a LoomComponent or LoomGameObject. The field is fulfilled from the LoomGroup that owns the LoomGameObject that owns the LoomComponent. `id` can optionally be specified. Implemented by LoomScript.
   - [Bind] on a field on a class bound to LML via LML.bind() or LML.apply(). The field is fulfilled based on the name of the field matching the name of a UI element in the LML. `id` can optionally be specified. Implemented by LoomScript.
   - [Native] or [Native(managed)] on a class. The latter indicates that the class should be managed by LoomScript; see the Loom Native Bindings section for details. Implemented by LSC.
   - [Deprecated] is used to mark a class, field, or method as not to be used.  Implemented by LSC.

### Examples

Here's a fictional LoomScript example showing how Metadata might be used to show a UI caption for a field on an object:

~~~as3
class Foo
{
	[UI(caption="Age of this item.")]
	public var itemAge:Number;	
}
~~~

Later, 'system.reflection.Type' can be used to query metadata as follows:

~~~as3
var foo = new Foo();
var fooType = foo.getType();
var iaInfo = fooType.getFieldInfoByName("itemAge");
trace("Field caption: " + iaInfo.getMetaInfo("UI").getAttribute("caption"));
~~~

Please note that you can add any metadata you like in LoomScript, with any number of parameters with optional values. Multiple metadata tags can apply to the same item. For instance:

~~~as3
[MyMetadata(flagKey, key1=value1, key2=value2)]
[MyOtherMetaData]
public class MyClass
{

}
~~~

