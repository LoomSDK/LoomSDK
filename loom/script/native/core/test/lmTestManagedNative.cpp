#include "loom/script/loomscript.h"


using namespace LS;

class MyManagedNativeClass {
public:

    float                floatField;
    int                  intField;
    double               doubleField;
    const char           *stringField;
    MyManagedNativeClass *child;

    int _intProperty;

    static utArray<MyManagedNativeClass *> nativeInstances;

    MyManagedNativeClass()
    {
        floatField   = 0.0f;
        intField     = 0;
        doubleField  = 0.0;
        stringField  = NULL;
        child        = NULL;
        _intProperty = 101;
    }

    virtual ~MyManagedNativeClass()
    {
        LS::NativeInterface::managedPointerReleased(this);
    }

    int getIntProperty() const
    {
        return _intProperty;
    }

    void setIntProperty(int value)
    {
        _intProperty = value;
    }

    MyManagedNativeClass *getChild()
    {
        return child;
    }

    static void addInstance(MyManagedNativeClass *instance)
    {
        nativeInstances.push_back(instance);
    }

    static MyManagedNativeClass *getInstance(UTsize idx)
    {
        return nativeInstances.at(idx);
    }

    static UTsize getNumInstances()
    {
        return nativeInstances.size();
    }

    static void deleteRandomInstance()
    {
        UTsize               idx       = (UTsize)(rand() % nativeInstances.size());
        MyManagedNativeClass *instance = nativeInstances.at(idx);

        nativeInstances.erase(idx);
        lmDelete(NULL, instance);
    }

    static MyManagedNativeClass *createdNativeInstance()
    {
        MyManagedNativeClass *instance = lmNew(NULL) MyManagedNativeClass();

        instance->stringField = "I was created natively";
        return instance;
    }

    static void deleteNativeInstance(MyManagedNativeClass *instance)
    {
        lmDelete(NULL, instance);
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
};

utArray<MyManagedNativeClass *> MyManagedNativeClass::nativeInstances;


class MyChildManagedNativeClass : public MyManagedNativeClass {
public:

    MyChildManagedNativeClass(const char *stringArg = "native default string")
    {
        floatField  = 1.0f;
        intField    = 1;
        doubleField = 1.0;
        stringField = stringArg;
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

    static MyChildManagedNativeClass *CreateMyChildManagedNativeClass(lua_State *L, const char *stringArg)
    {
        return lmNew(NULL) MyChildManagedNativeClass(stringArg);
    }

    static MyChildManagedNativeClass *createMyChildManagedNativeClassNativeSide()
    {
        return lmNew(NULL) MyChildManagedNativeClass("created native side");
    }

    static MyManagedNativeClass *createMyChildManagedNativeClassAsMyManagedNativeClass()
    {
        return lmNew(NULL) MyChildManagedNativeClass("created by createMyChildManagedNativeClassAsMyManagedNativeClass");
    }
};

static int registerNative(lua_State *L)
{
    beginPackage(L, "tests")

       .beginClass<MyManagedNativeClass> ("MyManagedNativeClass")
       .addConstructor<void (*)(void)>()
       .addVar("floatField", &MyManagedNativeClass::floatField)
       .addVar("intField", &MyManagedNativeClass::intField)
       .addVar("doubleField", &MyManagedNativeClass::doubleField)
       .addVar("stringField", &MyManagedNativeClass::stringField)
       .addVar("child", &MyManagedNativeClass::child)
       .addProperty("intProperty", &MyManagedNativeClass::getIntProperty, &MyManagedNativeClass::setIntProperty)

    // We must cast the override method and specify a distinct method name
    // as LS does not support overrides based on different parameter types
       .addMethod("getDescString", (const char * (MyManagedNativeClass::*)(int)) & MyManagedNativeClass::getDescString)
       .addMethod("getDescStringBool", (const char * (MyManagedNativeClass::*)(bool)) & MyManagedNativeClass::getDescString)
       .addMethod("getChild", &MyManagedNativeClass::getChild)
       .addStaticMethod("addInstance", &MyManagedNativeClass::addInstance)
       .addStaticMethod("getInstance", &MyManagedNativeClass::getInstance)
       .addStaticMethod("getNumInstances", &MyManagedNativeClass::getNumInstances)
       .addStaticMethod("deleteRandomInstance", &MyManagedNativeClass::deleteRandomInstance)
       .addStaticMethod("createdNativeInstance", &MyManagedNativeClass::createdNativeInstance)
       .addStaticMethod("deleteNativeInstance", &MyManagedNativeClass::deleteNativeInstance)

       .endClass()

       .deriveClass<MyChildManagedNativeClass, MyManagedNativeClass> ("MyChildManagedNativeClass")

    //.addConstructor <void (*)(void) >()
       .addStaticConstructor(&MyChildManagedNativeClass::CreateMyChildManagedNativeClass)

    // We don't have to do any casting here as MyChildNativeClass only has the single
    // getDescString overload and the compiler can tell what we intend
       .addMethod("getDescStringChildOverride", &MyChildManagedNativeClass::getDescString)

       .addStaticMethod("createMyChildManagedNativeClassNativeSide", &MyChildManagedNativeClass::createMyChildManagedNativeClassNativeSide)
       .addStaticMethod("createMyChildManagedNativeClassAsMyManagedNativeClass", &MyChildManagedNativeClass::createMyChildManagedNativeClassAsMyManagedNativeClass)

       .endClass()


       .endPackage();

    return 0;
}


void installTestManagedNativeClass()
{
    NativeInterface::registerManagedNativeType<MyManagedNativeClass>(registerNative);
    NativeInterface::registerManagedNativeType<MyChildManagedNativeClass>(registerNative);
}
