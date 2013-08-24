#include "loom/script/loomscript.h"

using namespace LS;

/*
 * Native side of BenchmarkNativeClass
 */
class BenchmarkNativeClass
{
public:

    int a;
    int b;
    int c;

    void setPositionX(float x)
    {
        _x = x;
    }

    float getPositionX() const
    {
        return _x;
    }

    void setPositionY(float y)
    {
        _y = y;
    }

    float getPositionY() const
    {
        return _y;
    }

    void setRotation(float rotation)
    {
        _rotation = rotation;
    }

    float getRotation() const
    {
        return _rotation;
    }

    float _x;
    float _y;
    float _rotation;
};

static int registerBenchmarkNativeClass(lua_State *L)
{
    beginPackage(L, "benchmark")

       .beginClass<BenchmarkNativeClass> ("BenchmarkNativeClass")
       .addConstructor<void (*)(void)>()
       .addVar("a", &BenchmarkNativeClass::a)
       .addVar("b", &BenchmarkNativeClass::b)
       .addVar("c", &BenchmarkNativeClass::c)

       .addProperty("x", &BenchmarkNativeClass::getPositionX, &BenchmarkNativeClass::setPositionX)
       .addProperty("y", &BenchmarkNativeClass::getPositionY, &BenchmarkNativeClass::setPositionY)
       .addProperty("rotation", &BenchmarkNativeClass::getRotation, &BenchmarkNativeClass::setRotation)

       .endClass()

       .endPackage();

    return 0;
}


void installBenchmarkNativeClass()
{
    LOOM_DECLARE_MANAGEDNATIVETYPE(BenchmarkNativeClass, registerBenchmarkNativeClass);
}
