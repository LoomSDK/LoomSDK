#include "loom/common/xml/tinyxml2.h"

#include <cstdio>
#include <cstdlib>
#include <new>
#include <cstddef>

#include "loom/script/native/lsLuaBridge.h"
#include "loom/script/runtime/lsLuaState.h"

using namespace LS;
using namespace tinyxml2;


static int registerSystemXML(lua_State *L)
{
    beginPackage(L, "system.xml")

       .beginClass<XMLNode>("XMLNode")

    // XMLNode::SetValue takes a default arg, which makes it incompatible with property notation
    // and we can't cast as it strips the default arg
    //.addVarAccessor("value", &XMLNode::Value, (void (XMLNode::*) ( const char* )) &XMLNode::SetValue)
    //.addMethod("__pget_value", &XMLNode::Value)
    //.addMethod("__pset_value", (void (XMLNode::*) ( const char* )) &XMLNode::SetValue)

       .addMethod("getValue", &XMLNode::Value)
       .addMethod("setValue", &XMLNode::SetValue)

       .addMethod("getDocument", (XMLDocument * (XMLNode::*)()) & XMLNode::GetDocument)
       .addMethod("toElement", (XMLElement * (XMLNode::*)()) & XMLNode::ToElement)
       .addMethod("toText", (XMLText * (XMLNode::*)()) & XMLNode::ToText)
       .addMethod("toComment", (XMLComment * (XMLNode::*)()) & XMLNode::ToComment)
       .addMethod("toDocument", (XMLDocument * (XMLNode::*)()) & XMLNode::ToDocument)
       .addMethod("toDeclaration", (XMLDeclaration * (XMLNode::*)()) & XMLNode::ToDeclaration)

       .addMethod("deleteChildren", &XMLNode::DeleteChildren)
       .addMethod("deleteChild", &XMLNode::DeleteChild)

       .addMethod("shallowClone", &XMLNode::ShallowClone)
       .addMethod("shallowEqual", &XMLNode::ShallowEqual)

       .addMethod("insertEndChild", &XMLNode::InsertEndChild)
       .addMethod("linkEndChild", &XMLNode::LinkEndChild)
       .addMethod("insertFirstChild", &XMLNode::InsertFirstChild)
       .addMethod("insertAfterChild", &XMLNode::InsertAfterChild)

       .addMethod("getParent", (XMLNode * (XMLNode::*)()) & XMLNode::Parent)
       .addMethod("noChildren", &XMLNode::NoChildren)

       .addMethod("firstChild", (XMLNode * (XMLNode::*)()) & XMLNode::FirstChild)
       .addMethod("firstChildElement", (XMLElement * (XMLNode::*)(const char *)) & XMLNode::FirstChildElement)

       .addMethod("lastChild", (XMLNode * (XMLNode::*)()) & XMLNode::LastChild)
       .addMethod("lastChildElement", (XMLElement * (XMLNode::*)(const char *)) & XMLNode::LastChildElement)

       .addMethod("previousSibling", (XMLNode * (XMLNode::*)()) & XMLNode::PreviousSibling)
       .addMethod("previousSiblingElement", (XMLElement * (XMLNode::*)(const char *)) & XMLNode::PreviousSiblingElement)

       .addMethod("nextSibling", (XMLNode * (XMLNode::*)()) & XMLNode::NextSibling)
       .addMethod("nextSiblingElement", (XMLElement * (XMLNode::*)(const char *)) & XMLNode::NextSiblingElement)

       .endClass()

       .deriveClass<XMLElement, XMLNode> ("XMLElement")
       .addMethod("value", &XMLElement::Name)
       .addMethod("getText", &XMLElement::GetText)

       .addMethod("getAttribute", &XMLElement::Attribute)
       .addMethod("getNumberAttribute", &XMLElement::DoubleAttribute)
       .addMethod("getBoolAttribute", &XMLElement::BoolAttribute)

       .addMethod("setAttribute", (void (XMLElement::*)(const char *, const char *)) & XMLElement::SetAttribute)
       .addMethod("setNumberAttribute", (void (XMLElement::*)(const char *, double)) & XMLElement::SetAttribute)
       .addMethod("setBoolAttribute", (void (XMLElement::*)(const char *, bool)) & XMLElement::SetAttribute)

       .addMethod("firstAttribute", &XMLElement::FirstAttribute)
       .addMethod("findAttribute", (const XMLAttribute * (XMLElement::*)( const char * )const) & XMLElement::FindAttribute)
       .addMethod("deleteAttribute", &XMLElement::DeleteAttribute)

       .endClass()

       .deriveClass<XMLComment, XMLNode> ("XMLComment")
       .endClass()

       .deriveClass<XMLText, XMLNode> ("XMLText")

       .addMethod("__pget_cdata", &XMLText::CData)
       .addMethod("__pset_cdata", &XMLText::SetCData)

       .endClass()

       .deriveClass<XMLDeclaration, XMLNode> ("XMLDeclaration")
       .endClass()

       .deriveClass<XMLDocument, XMLNode>("XMLDocument")
    // default constructor uses placement new to a fixed buffer field on template class
       .addConstructor<void (*)(void)>()
       .addMethod("loadFile", (int (XMLDocument::*)(const char *)) & XMLDocument::LoadFile) // handle overload by explicit cast
       .addMethod("saveFile", (int (XMLDocument::*)(const char *)) & XMLDocument::SaveFile)
       .addMethod("parse", &XMLDocument::Parse)
       .addMethod("print", &XMLDocument::Print)
       .addMethod("rootElement", (XMLElement * (XMLDocument::*)()) & XMLDocument::RootElement)

       .addMethod("newElement", &XMLDocument::NewElement)
       .addMethod("newComment", &XMLDocument::NewComment)
       .addMethod("newText", &XMLDocument::NewText)
       .addMethod("newDeclaration", &XMLDocument::NewDeclaration)
       .addMethod("deleteNode", &XMLDocument::DeleteNode)
       .addMethod("getErrorStr1", &XMLDocument::GetErrorStr1)
       .addMethod("getErrorStr2", &XMLDocument::GetErrorStr2)

       .endClass()

       .beginClass<XMLAttribute>("XMLAttribute")
       .addMethod("__pget_name", &XMLAttribute::Name)
       .addMethod("__pget_value", &XMLAttribute::Value)
       .addMethod("__pget_next", &XMLAttribute::Next)
       .addMethod("__pget_numberValue", &XMLAttribute::DoubleValue)
       .addMethod("__pset_numberValue", (void (XMLAttribute::*)(double)) & XMLAttribute::SetAttribute)
       .addMethod("__pget_boolValue", &XMLAttribute::BoolValue)
       .addMethod("__pset_boolValue", (void (XMLAttribute::*)(bool)) & XMLAttribute::SetAttribute)
       .addMethod("__pget_stringValue", &XMLAttribute::Value)
       .addMethod("__pset_stringValue", (void (XMLAttribute::*)(const char *)) & XMLAttribute::SetAttribute)

    //TODO: Query methods

       .endClass()

       .beginClass<XMLPrinter>("XMLPrinter")
       .addConstructor<void (*)(void)>()
       .addMethod("getString", &XMLPrinter::CStr)
       .endClass()

       .endPackage();

    return 0;
}


void installSystemXML()
{
    NativeInterface::registerNativeType<XMLNode>(registerSystemXML);
    NativeInterface::registerNativeType<XMLDeclaration>(registerSystemXML);
    NativeInterface::registerNativeType<XMLComment>(registerSystemXML);
    NativeInterface::registerNativeType<XMLDocument>(registerSystemXML);
    NativeInterface::registerNativeType<XMLPrinter>(registerSystemXML);
    NativeInterface::registerNativeType<XMLAttribute>(registerSystemXML);
    NativeInterface::registerNativeType<XMLText>(registerSystemXML);
    NativeInterface::registerNativeType<XMLElement>(registerSystemXML);
}
