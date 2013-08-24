title: Code Style
description: Recommended code style and formatting guidelines.
!------

# Loom Code Style Guide

A day comes in every software project where code style must be documented. For Loom, today is that day.

Code style exists to make code uniform, consistent, and easy to understand. Therefore, the basic rule on code style when working Loom with is: **Always match your surroundings.**

## C/C++

This code style document will not exhaustively cover every possibility. Please refer to [The Google Code Style Guide](http://google-styleguide.googlecode.com/svn/trunk/cppguide.xml) in cases where this guide does not provide guidance.

General guidelines:
   
   * Use 4 space tabs. 
   * Do not cuddle braces. 
   * Wrap lines at 80 columns.
   * Prefix globals with a `g`, as in `gMyGlobal`.

Representative C++ code:

~~~cpp
class MyClass
{
public:

    void methodName(int param, const utString &param2)
    {
        if(param !=0)
        {
            // Do something.
        }
        else
        {
            // Do something else.
        }
    }
}
~~~

## LoomScript

For LoomScript, we largely follow ActionScript 3 style. The [Adobe Flex style guide](http://sourceforge.net/adobe/flexsdk/wiki/Coding%20Conventions/) is a decent starting point; please disregard the Flash/Flex specific conventions like naming movie clips and UI class prefixes!

You may also find Colin Moock's Essential ActionScript 3 helpful here.

General guidelines:

   * Use 4 space tabs. 
   * Do not cuddle braces. 
   * Wrap lines at 80 columns.
   * Break classes/structs into their own files. 
   * Delegates/enums can be in same file as related code.

Representative LoomScript code:

~~~as3
package com.mycompany 
{
    public class MyClass
    {
        public function methodName(param:Number, param2:String):void
        {
            if(param !=0)
            {
                // Do something.
            }
            else
            {
                // Do something else.
            }
        }
    }   
}
~~~