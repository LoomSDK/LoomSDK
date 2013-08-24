#include "loom/script/native/lsLuaBridge.h"
#include "loom/script/native/lsNativeDelegate.h"


using namespace LS;


class TestNativeDelegate {
    NativeDelegate nativeDelegate;
    NativeDelegate recursionDelegate;

public:

    const NativeDelegate *getNativeDelegate() const
    {
        return &nativeDelegate;
    }

    const NativeDelegate *getRecursionDelegate() const
    {
        return &recursionDelegate;
    }

    void go()
    {
        nativeDelegate.pushArgument(10);
        nativeDelegate.pushArgument(20);
        nativeDelegate.invoke();
    }

    int triggerDelegate(lua_State *L)
    {
        go();
        return 0;
    }

    void testRecursion(float one, float two, float three, float four, float five)
    {
        recursionDelegate.pushArgument(one);
        recursionDelegate.pushArgument(two);
        recursionDelegate.pushArgument(three);
        recursionDelegate.pushArgument(four);
        recursionDelegate.pushArgument(five);
        recursionDelegate.invoke();
    }
};


struct TestPoint2
{
    float             x;
    float             y;
    TestPoint2()
    {
        x = y = 0.0f;
    }

    static TestPoint2 *opAssignment(TestPoint2 *a, TestPoint2 *b)
    {
        if (!a)
        {
            LSError("null to");
        }

        if (!b)
        {
            LSError("null from");
        }

        *a = *b;

        return a;
    }
};

static int registerTestsTestNativeDelegate(lua_State *L)
{
    beginPackage(L, "tests")

       .beginClass<TestNativeDelegate> ("TestNativeDelegate")
       .addConstructor<void (*)(void)>()
       .addLuaFunction("triggerDelegate", &TestNativeDelegate::triggerDelegate)
       .addVarAccessor("nativeDelegate", &TestNativeDelegate::getNativeDelegate)
       .addVarAccessor("recursionDelegate", &TestNativeDelegate::getRecursionDelegate)
       .addMethod("testRecursion", &TestNativeDelegate::testRecursion)
       .endClass()

       .beginClass<TestPoint2> ("TestPoint2")
       .addConstructor<void (*)(void)>()
       .addVar("x", &TestPoint2::x)
       .addVar("y", &TestPoint2::y)
       .addStaticMethod("__op_assignment", &TestPoint2::opAssignment)
       .endClass()

       .endPackage();

    return 0;
}


void installTestDelegate()
{
    NativeInterface::registerNativeType<TestNativeDelegate>(registerTestsTestNativeDelegate);
    NativeInterface::registerNativeType<TestPoint2>(registerTestsTestNativeDelegate);
}
