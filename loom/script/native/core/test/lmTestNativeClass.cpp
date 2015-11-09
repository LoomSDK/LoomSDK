#include "loom/script/native/lsLuaBridge.h"
#include "loom/script/native/lsNativeDelegate.h"

using namespace LS;

// This is a native class which is exclusively used in unit tests
// You shouldn't have to be aware of its existance unless you
// are extending the unit tests

struct MyNativeStruct
{
    float       numberValue;
    const char  *stringValue;
    utString    anotherStringValue;
    bool        boolValue;

    MyNativeStruct(float _numberValue = 0.0f, const char *_stringValue = NULL, const utString& _anotherStringValue = "", bool _boolValue = false)
    {
        numberValue        = _numberValue;
        stringValue        = _stringValue;
        anotherStringValue = _anotherStringValue;
        boolValue          = _boolValue;
    }

    MyNativeStruct& operator=(const MyNativeStruct& rhs)
    {
        numberValue        = rhs.numberValue;
        stringValue        = rhs.stringValue;
        anotherStringValue = rhs.anotherStringValue;
        boolValue          = rhs.boolValue;
        return *this;
    }

    static void opAssignment(MyNativeStruct *a, MyNativeStruct *b)
    {
        if (!a || !b)
        {
            return;
        }

        *a = *b;
    }
};

// Note this could also be a static member of MyNativeStruct, but for example's sake, we can define the constructor
// outside of the class, which makes handling special native instance construction much easier/flexible
// when wrapping existing class hierarchies
static MyNativeStruct *CreateMyNativeStruct(lua_State *L, float _numberValue, const char *_stringValue, const char *_anotherStringValue, bool _boolValue)
{
    return lmNew(NULL) MyNativeStruct(_numberValue, _stringValue, _anotherStringValue, _boolValue);
}


class MyNativeClass {
protected:

    MyNativeStruct *structField;

public:

    float      floatField;
    int        intField;
    double     doubleField;
    const char *stringField;
    static int staticIntField;

    MyNativeClass()
    {
        floatField  = 0.0f;
        intField    = 0;
        doubleField = 0.0;
        stringField = NULL;
        structField = lmNew(NULL) MyNativeStruct();
    }

    virtual ~MyNativeClass()
    {
        lmSafeDelete(NULL, structField);
    }

    MyNativeStruct *getStructField() const
    {
        return structField;
    }

    void setStructField(MyNativeStruct *value)
    {
        *structField = *value;
    }

    MyNativeStruct passStructByValueReturnsByValue(MyNativeStruct structByValue)
    {
        return structByValue;
    }

    MyNativeStruct passStructByPointerReturnsByValue(MyNativeStruct *structByPointer)
    {
        return *structByPointer;
    }

    MyNativeStruct *passStructByValueReturnsByPointer(MyNativeStruct structByValue)
    {
        static MyNativeStruct temp;

        temp = structByValue;
        return &temp;
    }

    MyNativeStruct *passStructByPointerReturnsByPointer(MyNativeStruct *structByPointer)
    {
        return structByPointer;
    }

    const char *getDescString(int number)
    {
        static char text[1024];

        if (stringField)
        {
            sprintf(text, "%i %i %.2f %.2f %s", number, intField, floatField, (float)doubleField, stringField);
        }
        else
        {
            sprintf(text, "%i %i %.2f %.2f", number, intField, floatField, (float)doubleField);
        }

        return text;
    }

    const char *getDescString(bool value)
    {
        static char text[1024];

        if (stringField)
        {
            sprintf(text, "%s %i %.2f %.2f %s", value ? "true" : "false", intField, floatField, (float)doubleField, stringField);
        }
        else
        {
            sprintf(text, "%s %i %.2f %.2f", value ? "true" : "false", intField, floatField, (float)doubleField);
        }

        return text;
    }

    static bool checkStaticIntField(int value)
    {
        return staticIntField == value;
    }
};

int MyNativeClass::staticIntField = 1001;

class MyChildNativeClass : public MyNativeClass {
public:

    MyChildNativeClass()
    {
        floatField  = 1.0f;
        intField    = 1;
        doubleField = 1.0;
        stringField = "default string";
    }

    const char *getDescString(const char *string)
    {
        static char text[1024];

        if (stringField)
        {
            sprintf(text, "%s %i %.2f %.2f %s", string, intField, floatField, (float)doubleField, stringField);
        }
        else
        {
            sprintf(text, "%s %i %.2f %.2f", string, intField, floatField, (float)doubleField);
        }

        return text;
    }
};

class MyGrandChildNativeClass : public MyChildNativeClass {
public:

    MyGrandChildNativeClass(MyNativeStruct *_structField, float _floatField, int _intField, double _doubleField, const char *_stringField)
    {
        floatField  = _floatField;
        intField    = _intField;
        doubleField = _doubleField;
        stringField = _stringField;
        lmSafeDelete(NULL, structField);
        structField = _structField;
    }

    static MyNativeClass *getAsMyNativeClass(MyNativeClass *nc)
    {
        return nc;
    }

    static MyChildNativeClass *getAsMyChildNativeClass(MyNativeClass *nc)
    {
        return (MyChildNativeClass *)nc;
    }

    static MyGrandChildNativeClass *getAsMyGrandChildNativeClass(MyNativeClass *nc)
    {
        return (MyGrandChildNativeClass *)nc;
    }

    static MyGrandChildNativeClass *CreateMyGrandChildNativeClass(lua_State *L, MyNativeStruct *_structField, float _floatField, int _intField, double _doubleField, const char *_stringField)
    {
        return lmNew(NULL) MyGrandChildNativeClass(_structField, _floatField, _intField, _doubleField, _stringField);
    }
};


static int registerTestsTestNativeClass(lua_State *L)
{
    beginPackage(L, "tests")

       .beginClass<MyNativeStruct> ("MyNativeStruct")
       .addStaticConstructor(CreateMyNativeStruct, false)
       .addVar("numberValue", &MyNativeStruct::numberValue)
       .addVar("stringValue", &MyNativeStruct::stringValue)
       .addVar("anotherStringValue", &MyNativeStruct::anotherStringValue)
       .addVar("boolValue", &MyNativeStruct::boolValue)
       .addStaticMethod("__op_assignment", &MyNativeStruct::opAssignment)
       .endClass()

       .beginClass<MyNativeClass> ("MyNativeClass")
       .addConstructor<void (*)(void)>()
       .addVar("floatField", &MyNativeClass::floatField)
       .addVar("intField", &MyNativeClass::intField)
       .addVar("doubleField", &MyNativeClass::doubleField)
       .addVar("stringField", &MyNativeClass::stringField)
       .addStaticVar("staticIntField", &MyNativeClass::staticIntField)
       .addVarAccessor("structField", &MyNativeClass::getStructField, &MyNativeClass::setStructField)

    // We must cast the override method and specify a distinct method name
    // as LS does not support overrides based on different parameter types
       .addMethod("getDescString", (const char * (MyNativeClass::*)(int)) & MyNativeClass::getDescString)
       .addMethod("getDescStringBool", (const char * (MyNativeClass::*)(bool)) & MyNativeClass::getDescString)

    // struct passing tests
       .addMethod("passStructByValueReturnsByValue", &MyNativeClass::passStructByValueReturnsByValue)
       .addMethod("passStructByPointerReturnsByValue", &MyNativeClass::passStructByPointerReturnsByValue)
       .addMethod("passStructByValueReturnsByPointer", &MyNativeClass::passStructByValueReturnsByPointer)
       .addMethod("passStructByPointerReturnsByPointer", &MyNativeClass::passStructByPointerReturnsByPointer)

       .addStaticMethod("checkStaticIntField", &MyNativeClass::checkStaticIntField)

       .endClass()

       .deriveClass<MyChildNativeClass, MyNativeClass> ("MyChildNativeClass")

       .addConstructor<void (*)(void)>()

    // We don't have to do any casting here as MyChildNativeClass only has the single
    // getDescString overload and the compiler can tell what we intend
       .addMethod("getDescStringChildOverride", &MyChildNativeClass::getDescString)

       .endClass()

       .deriveClass<MyGrandChildNativeClass, MyChildNativeClass> ("MyGrandChildNativeClass")
       .addStaticConstructor(&MyGrandChildNativeClass::CreateMyGrandChildNativeClass, false)
       .addStaticMethod("getAsMyNativeClass", &MyGrandChildNativeClass::getAsMyNativeClass)
       .addStaticMethod("getAsMyChildNativeClass", &MyGrandChildNativeClass::getAsMyChildNativeClass)
       .addStaticMethod("getAsMyGrandChildNativeClass", &MyGrandChildNativeClass::getAsMyGrandChildNativeClass)

       .endClass()


       .endPackage();

    return 0;
}


void installTestNativeClass()
{
    NativeInterface::registerNativeType<MyNativeClass>(registerTestsTestNativeClass);
    NativeInterface::registerNativeType<MyChildNativeClass>(registerTestsTestNativeClass);
    NativeInterface::registerNativeType<MyGrandChildNativeClass>(registerTestsTestNativeClass);
    NativeInterface::registerNativeType<MyNativeStruct>(registerTestsTestNativeClass);
}
