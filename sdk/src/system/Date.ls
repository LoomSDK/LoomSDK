/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013, 2015
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

package system {

/**
 * Provides native date utility.
 */
[Native(managed)]
native class Date {
    
    /**
     * Typical constructor with no parameters. On creation the Date class will automatically be populated with the
     * current date-time
     */
    public native function Date();
    
    // Private native getters and setters
    private native function getDate():int;
    private native function setDate(value:int):void;
    
    private native function getDay():int;
    private native function setDay(value:int):void;
    
    private native function getYear():int;
    private native function setYear(value:int):void;
    
    private native function getHours():int;
    private native function setHours(value:int):void;
    
    private native function getMinutes():int;
    private native function setMinutes(value:int):void;
    
    private native function getMonth():int;
    private native function setMonth(value:int):void;
    
    private native function getSeconds():int;
    private native function setSeconds(value:int):void;
    
    private native function getDateUTC():int;
    private native function setDateUTC(value:int):void;
    
    private native function getDayUTC():int;
    private native function setDayUTC(value:int):void;
    
    private native function getYearUTC():int;
    private native function setYearUTC(value:int):void;
    
    private native function getHoursUTC():int;
    private native function setHoursUTC(value:int):void;
    
    private native function getMinutesUTC():int;
    private native function setMinutesUTC(value:int):void;
    
    private native function getMonthUTC():int;
    private native function setMonthUTC(value:int):void;
    
    private native function getSecondsUTC():int;
    private native function setSecondsUTC(value:int):void;
    
    // Private helpers
    /**
     * @private
     * 
     * Checks bounds for date input
     * 
     * @param val Input value to be checked
     */
    private function checkDate(val:int):void
    {
        if (val < 0)
            Debug.assert(false, "Date input cannot be below 0! Input: " + val);
        
        var hitError = false;
        if (val > 28 && this.month == 1 && !isLeapYear(this.year))
            hitError = true;
        else if (val > 29 && this.month == 1 && isLeapYear(this.year))
            hitError = true;
        else if (val > 30 && (this.month == 3 || this.month == 5 || this.month == 8 || this.month == 10))
            hitError = true;
        else if (val > 31)
            hitError = true;
            
        if (hitError)
            Debug.assert(false, "Date input cannot be greater than the number of days in the month! Input: " + val);
    }
    
    /**
     * @private
     * 
     * Check bounds for day input
     * 
     * @param val Input value to be checked
     */
    private function checkDay(val:int):void
    {
        if (val < 0)
            Debug.assert(false, "Day input cannot be less than 0! Input: " + val);
        else if (val > 6)
            Debug.assert(false, "Day input can not be greater 6! Input: " + val);
    }
    
    /**
     * @private
     * 
     * Check bounds for hour input
     * 
     * @param val Input value to be checked
     */
    private function checkHours(val:int):void
    {
        if (val < 0)
            Debug.assert(false, "Hour input connot be less than 0! Input: " + val);
        else if (val > 23)
            Debug.assert(false, "Hour input cannot be greater than 23! Input: " + val);
    }
    
    /**
     * @private
     * 
     * Check bounds for minutes
     * 
     * @param val Input value to be checked
     */
    private function checkMinutes(val:int):void
    {
        if (val < 0)
            Debug.assert(false, "Minute input cannot be less than 0! Input: " + val);
        else if (val > 59)
            Debug.assert(false, "Minute input cannot be greater than 59! Input: " + val);
    }
    
    /**
     * @private
     * 
     * Check bounds for months
     * 
     * @param val Input value to be checked
     */
    private function checkMonth(val:int):void
    {
        if (val < 0)
            Debug.assert(false, "Month input cannot be less than 0! Input: " + val);
        else if (val > 11)
            Debug.assert(false, "Month input cannot be greater than 11! Input: " +val);
    }
    
    /**
     * @private
     * 
     * Check bounds for seconds
     * 
     * @param val Input value to be checked
     */
    private function checkSeconds(val:int):void
    {
        if (val < 0)
            Debug.assert(false, "Second input cannot be less than 0! Input: " + val);
        if (val > 60)
            Debug.assert(false, "Second input cannot be greater than 60! Input: " + val);
    }
    
    // Public properties
    /**
     * An integer between 1 and 31 representing day of the month in local time
     */
    public function get date():int 
    { 
        return getDate(); 
    }
    public function set date(val:int):void 
    { 
        checkDate(val);
        setDate(val); 
    }
    
    /**
     * The day of the week, starting at 0 for Sunday, 1 for Monday, and continuing to 6 for Saturday in local time
     */
    public function get day():int 
    { 
        return getDay(); 
    }
    public function set day(val:int):void 
    {
        checkDay(val);
        setDay(val);
    }
    
    /**
     * The full Gregorian year in local time
     */
    public function get year():int 
    { 
        return getYear(); 
    }
    public function set year(val:int):void 
    { 
        setYear(val);
    }
    
    /**
     * An integer between 0 and 23 representing the hour in local time
     */
    public function get hours():int 
    { 
        return getHours(); 
    }
    public function set hours(val:int):void 
    { 
        checkHours(val);
        setHours(val); 
    }
    
    /**
     * An integer between 0 and 59 representing the minute in local time
     */
    public function get minutes():int 
    { 
        return getMinutes(); 
    }
    public function set minutes(val:int):void 
    { 
        checkMinutes(val);
        setMinutes(val); 
    }
    
    /**
     * An integer between 0 and 11 representing the month in local time
     */
    public function get month():int 
    { 
        return getMonth(); 
    }
    public function set month(val:int):void 
    { 
        checkMonth(val);
        setMonth(val); 
    }
    
    /**
     * An integer between 0 and 60 representing seconds in local time. In the vast majority of cases the final second will be
     * number 59, but leap seconds are accounted for with the 60th second
     */
    public function get seconds():int 
    { 
        return getSeconds(); 
    }
    public function set seconds(val:int):void 
    { 
        checkSeconds(val);
        setSeconds(val); 
    }
    
    /**
     * An integer between 1 and 31 representing day of the month in UTC
     */
    public function get dateUTC():int 
    { 
        return getDateUTC(); 
    }
    public function set dateUTC(val:int):void 
    { 
        checkDate(val);
        setDateUTC(val); 
    }
    
    /**
     * The day of the week, starting at 0 for Sunday, 1 for Monday, and continuing to 6 for Saturday in UTC
     */
    public function get dayUTC():int 
    { 
        return getDayUTC(); 
    }
    public function set dayUTC(val:int):void 
    { 
        checkDay(val);
        setDayUTC(val); 
    }
    
    /**
     * The full Gregorian year in UTC
     */
    public function get yearUTC():int 
    { 
        return getYearUTC(); 
    }
    public function set yearUTC(val:int):void 
    { 
        setYearUTC(val); 
    }
    
    /**
     * An integer between 0 and 23 representing the hour in UTC
     */
    public function get hoursUTC():int 
    { 
        return getHoursUTC(); 
    }
    public function set hoursUTC(val:int):void 
    { 
        checkHours(val);
        setHoursUTC(val); 
    }
    
    /**
     * An integer between 0 and 59 representing the minute in UTC
     */
    public function get minutesUTC():int 
    { 
        return getMinutesUTC(); 
    }
    public function set minutesUTC(val:int):void 
    { 
        checkMinutes(val);
        setMinutesUTC(val); 
    }
    
    /**
     * An integer between 0 and 11 representing the month in UTC
     */
    public function get monthUTC():int 
    {
        return getMonthUTC(); 
    }
    public function set monthUTC(val:int):void 
    { 
        checkMonth(val);
        setMonthUTC(val); 
    }
    
    /**
     * An integer between 0 and 60 representing seconds in UTC. In the vast majority of cases the final second will be
     * number 59, but leap seconds are accounted for with the 60th second
     */
    public function get secondsUTC():int 
    { 
        return getSecondsUTC(); 
    }
    public function set secondsUTC(val:int):void 
    { 
        checkSeconds(val);
        setSecondsUTC(val); 
    }
    
    // Helper functions
    /**
     * This helper function takes a Gregorian year and will output whether or not it is a leap year.
     * 
     * @param year The year to be evaluated
     * @return If the evaluated year is a leap year
     */
    static public native function isLeapYear(year:int):Boolean;
    
    /**
     * This function wraps the native strftime function from the ctime C++ library, which is used to get a string representation of the saved local time
     * 
     * @param format The format string to be passed into the native strftime function. See [C++ documentation](http://www.cplusplus.com/reference/ctime/strftime/)
     * for details on formatting options.
     * @return A formatted string representing date information.
     */
    public native function formatTime(format:String):String;
    
    /**
     * This function wraps the native strftime function from the ctime C++ library, which is used to get a string representation of the saved UTC time. 
     * 
     * @param format The format string to be passed into the native strftime function. See [C++ documentation](http://www.cplusplus.com/reference/ctime/strftime/)
     * for details on formatting options.
     * @return A formatted string representing date information.
     */
    public native function formatTimeUTC(format:String):String;
    
    /**
     * toString is overloaded to return the output of `formatTime("%c")`
     * 
     * @return The date and time representation of the local time
     */
    public function toString():String 
    {
        return this.formatTime("%c");
    }
}   
}
