/*
* ===========================================================================
* Loom SDK
* Copyright 2011, 2012, 2013 
* The Game Engine Company, LLC
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
* ===========================================================================
*/

#include "loom/script/loomscript.h"
#include "loom/script/native/lsLuaBridge.h"
#include <ctime>

using namespace LS;

// Define a macro for getters and setters. There are a bunch of them!
#define DATE_GETTER_SETTER(var, tm_var) \
int get ## var() { return timeInfo.tm_ ## tm_var; } \
void set ## var(int value) { timeInfo.tm_ ## tm_var = value; } \
int get ## var ## UTC() { return timeInfoUTC.tm_ ## tm_var; } \
void set ## var ## UTC(int value) { timeInfoUTC.tm_ ## tm_var = value; }

/**
* Native side implementation for the Loom Date class. See Date.ls script class for more detailed documentation
*/
class Date {
private:
    // The buffer size when returning string data
    static const int BUFFER_SIZE = 1024;

    // Private variables, their fields will be accessed by public methods
    struct tm timeInfo;    // The time info for this Date instance. It will be accessed by various getters and setters in ls
    struct tm timeInfoUTC; // Same as timeInfo, but for UTC instead of local time

public:
    // Determine if the provided year is a leap year
    static bool isLeapYear(int year)
    {
        if (year % 4 != 0)
            return false;
        else if (year % 100 == 0 && year % 400 != 0)
            return false;
        else
            return true;
    }

    // A default constructor must be defined!
    Date()
    {
        initialize(-1);
    }

    Date(double inputTime)
    {
        initialize(inputTime);
    }

    // Initializes the date based on a 64 bit integer representing the time
    void initialize(double inputTime)
    {
        time_t rawtime;

        if (inputTime >= 0)
        {
            // If there was an input time, set the clock to that time!
            rawtime = (time_t)inputTime;
        }
        else
        {
            // Otherwise, get the current time
            time(&rawtime);
        }

        // Initialize tm structs
        timeInfo = *localtime(&rawtime);
        timeInfoUTC = *gmtime(&rawtime);
    }

    // Getters and setters for the local timeInfo
    DATE_GETTER_SETTER(Date, mday);
    DATE_GETTER_SETTER(Day, wday);
    DATE_GETTER_SETTER(Hours, hour);
    DATE_GETTER_SETTER(Minutes, min);
    DATE_GETTER_SETTER(Month, mon);
    DATE_GETTER_SETTER(Seconds, sec);
    #undef DATE_GETTER_SETTER

    // Year getters and setters must be defined seperately because of an offset
    int getYear() 
    { 
        return timeInfo.tm_year + 1900;
    }
    void setYear(int value) 
    { 
        timeInfo.tm_year = value - 1900;
    }

    int getYearUTC() 
    { 
        return timeInfoUTC.tm_year + 1900;
    }
    void setYearUTC(int value) 
    { 
        timeInfoUTC.tm_year = value - 1900;
    }


    const char *formatTime(const char *format)
    {
        char *buffer = (char*)malloc(sizeof(char) * BUFFER_SIZE);

        strftime(buffer, BUFFER_SIZE - 1, format, &timeInfo);
        
        return (const char*)buffer;
    }

    const char *formatTimeUTC(const char *format)
    {
        char *buffer = (char*)malloc(sizeof(char) * BUFFER_SIZE);

        strftime(buffer, BUFFER_SIZE, format, &timeInfoUTC);

        return (const char*)buffer;
    }
};

static int registerSystemDate(lua_State *L)
{
    beginPackage(L, "system")

        .beginClass<Date>("Date")

        .addConstructor<void (*)(double)>()

        // These methods are all defined with the DATE_GETTER_SETTER macro above
        .addMethod("getDate", &Date::getDate)
        .addMethod("setDate", &Date::setDate)
        .addMethod("getDay", &Date::getDay)
        .addMethod("setDay", &Date::setDay)
        .addMethod("getHours", &Date::getHours)
        .addMethod("setHours", &Date::setHours)
        .addMethod("getMinutes", &Date::getMinutes)
        .addMethod("setMinutes", &Date::setMinutes)
        .addMethod("getMonth", &Date::getMonth)
        .addMethod("setMonth", &Date::setMonth)
        .addMethod("getSeconds", &Date::getSeconds)
        .addMethod("setSeconds", &Date::setSeconds)
        .addMethod("getDateUTC", &Date::getDateUTC)
        .addMethod("setDateUTC", &Date::setDateUTC)
        .addMethod("getDayUTC", &Date::getDayUTC)
        .addMethod("setDayUTC", &Date::setDayUTC)
        .addMethod("getHoursUTC", &Date::getHoursUTC)
        .addMethod("setHoursUTC", &Date::setHoursUTC)
        .addMethod("getMinutesUTC", &Date::getMinutesUTC)
        .addMethod("setMinutesUTC", &Date::setMinutesUTC)
        .addMethod("getMonthUTC", &Date::getMonthUTC)
        .addMethod("setMonthUTC", &Date::setMonthUTC)
        .addMethod("getSecondsUTC", &Date::getSecondsUTC)
        .addMethod("setSecondsUTC", &Date::setSecondsUTC)

        .addMethod("getYear", &Date::getYear)
        .addMethod("setYear", &Date::setYear)
        .addMethod("getYearUTC", &Date::getYearUTC)
        .addMethod("setYearUTC", &Date::setYearUTC)
        .addMethod("formatTime", &Date::formatTime)
        .addMethod("formatTimeUTC", &Date::formatTimeUTC)

        .addStaticMethod("isLeapYear", &Date::isLeapYear)

        .endClass()

        .endPackage();

    return 0;
}

void installSystemDate()
{
    LOOM_DECLARE_MANAGEDNATIVETYPE(Date, registerSystemDate);
}
