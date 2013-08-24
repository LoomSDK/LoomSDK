// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.animation
{
    /**  The IAnimatable interface describes objects that are animated depending on the passed time. 
     *   Any object that implements this interface can be added to a juggler.
     *   
     *   When an object should no longer be animated, it has to be removed from the juggler. 
     *   To do this, you can manually remove it via the method `juggler.remove(object)`,
     *   or the object can request to be removed by dispatching a Starling event with the type
     *   `Event.REMOVE_FROM_JUGGLER`. The "Tween" class is an example of a class that
     *   dispatches such an event; you don't have to remove tweens manually from the juggler. 
     *   
     *   @see Juggler
     *   @see Tween
     */
    public interface IAnimatable 
    {
        /** Advance the time by a number of seconds. @param time in seconds. */
        function advanceTime(time:Number):void;
    }
}