/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

package loom.lml {

import loom.utils.Injector;

/*
    Base class representing a Node in lml.
*/
public class LMLNode 
{
    //_________________________________________________
    //  Constructor
    //_________________________________________________
    public function LMLNode(element:XMLElement, documentPath:String):void
    {
        super();

        // get the type
        type = Type.getTypeByName(element.getValue());

        if(!type)
        {
            Console.print("WARNING: ", documentPath + ": Type " + element.getValue() + " does not exist");
            return;
        }

        // generate field infos
        for(var i = 0; i<type.getFieldInfoCount(); i++)
        {
            var info = type.getFieldInfo(i);
            fields[info.getName()] = info;
        }

        // generate property infos
        for(var j = 0; j<type.getPropertyInfoCount(); j++)
        {
            var propInfo = type.getPropertyInfo(j);
            properties[propInfo.getName()] = propInfo;
        }

        // set the id
        id = element.getAttribute("id", null);

        // attributes
        attributes = element.firstAttribute();

        // recurse children
        var child:XMLNode = element.firstChild();
        while(child) {
            if(child.toElement())
            {
                var celement:XMLElement = child.toElement();
                children.push(new LMLNode(celement, documentPath));
            }

            // go to the next element
            child = child.nextSibling();
        }
    }

    //_________________________________________________
    //  Public Properties
    //_________________________________________________
    public var id:String;
    public var children:Vector.<LMLNode> = new Vector.<LMLNode>();
    public var attributes:XMLAttribute;
    public var type:Type;
    public var fields:Dictionary.<String,FieldInfo> = new Dictionary.<String,FieldInfo>();
    public var properties:Dictionary.<String,PropertyInfo> = new Dictionary.<String,PropertyInfo>(); 
    public var owningDocument:XMLDocument;

    //_________________________________________________
    //  Public Functions
    //_________________________________________________
    public function construct(injector:Injector=null):Object
    {
        if(!type) return null;

        var parent:Object = type.getConstructor().invoke();
        var lmlNode:ILMLNode = parent as ILMLNode;

        if(lmlNode)
            lmlNode.preinitializeLMLNode(id);
    
        var attr = attributes;
        while(attr) {

            var name = attr.name;
            // skip for id
            if(name != "id")
            {
                var field = fields[name];
                var prop = properties[name];

                if(field)
                    setField(field,attr,parent);
                else if(prop)
                    setProperty(prop,attr,parent);
                else
                    Console.print("WARNING: Field " + name + " does not exist on type " + type.getFullName() + " while instantiating an LML file.");
            }

            attr = attr.next;
        }

        for(var i = 0; i<children.length; i++)
        {
            var child = children[i];
            var lmlChild = child.construct(injector);

            var lmlParent:ILMLParent = parent as ILMLParent;
            
            if(!lmlChild)
                continue;

            if(lmlParent)
                lmlParent.addLMLChild(child.id, lmlChild);
            else
                Console.print("WARNING: ", parent.getTypeName(), " must implement ILMLParent to have children in LML");
        }

        if(injector && id)
            injector.mapValue(parent,type,id);
        
        if(lmlNode)
            lmlNode.initializeLMLNode(id);

        return parent;
    }

    //_________________________________________________
    //  Protected Functions
    //_________________________________________________
    protected function setField(field:FieldInfo, attribute:XMLAttribute, target:Object):void
    {
        var name = field.getTypeInfo().getFullName();
        switch(name)
        {
            case "system.String":
                field.setValue(target, attribute.value);
                break;

            case "system.Number":
                field.setValue(target, attribute.numberValue);
                break;

            case "system.Boolean":
                field.setValue(target, attribute.boolValue);
                break;

            default:
                Console.print("WARNING: " + field.getDeclaringType().getName() + "." + field.getName() + " is not supported through LML attributes");
                break;
        }
    }

    protected function setProperty(prop:PropertyInfo, attribute:XMLAttribute, target:Object):void
    {
        var name = prop.getTypeInfo().getFullName();
        var setter = prop.getSetMethod();
        Debug.assert(setter, "Setter for " + prop.getName() + " does not exist");
        switch(name)
        {
            case "system.String":
                setter.invoke(target, attribute.value);
                break;

            case "system.Number":
                setter.invoke(target, attribute.numberValue);
                break;

            case "system.Boolean":
                setter.invoke(target, attribute.boolValue);
                break;

            default:
                Console.print("WARNING: " + prop.getSetMethod().getDeclaringType().getName() + "." + prop.getSetMethod().getName() + " is not supported through LML attributes");
                break;
        }
    }
}
}