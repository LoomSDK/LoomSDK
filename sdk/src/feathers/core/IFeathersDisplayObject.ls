/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.core
{
	import loom2d.math.Matrix;
	import loom2d.math.Point;
	import loom2d.math.Rectangle;

	import loom2d.display.DisplayObject;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Stage;

	/**
	 * Public properties and functions from `loom2d.display.DisplayObject`
	 * in helpful interface form.
	 *
	 * Never cast an object to this type. Cast to `DisplayObject`
	 * instead. This interface exists only to support easier code hinting.
	 *
	 * @see loom2d.display.DisplayObject
	 */
	public interface IFeathersDisplayObject extends IFeathersEventDispatcher
	{
		/**
		 * @see loom2d.display.DisplayObject#x
		 */
		function get x():Number;

		/**
		 * @private
		 */
		function set x(value:Number):void;

		/**
		 * @see loom2d.display.DisplayObject#y
		 */
		function get y():Number;

		/**
		 * @private
		 */
		function set y(value:Number):void;

		/**
		 * @see loom2d.display.DisplayObject#width
		 */
		function get width():Number;

		/**
		 * @private
		 */
		function set width(value:Number):void;

		/**
		 * @see loom2d.display.DisplayObject#height
		 */
		function get height():Number;

		/**
		 * @private
		 */
		function set height(value:Number):void;

		/**
		 * @see loom2d.display.DisplayObject#pivotX
		 */
		function get pivotX():Number;

		/**
		 * @private
		 */
		function set pivotX(value:Number):void;

		/**
		 * @see loom2d.display.DisplayObject#pivotY
		 */
		function get pivotY():Number;

		/**
		 * @private
		 */
		function set pivotY(value:Number):void;

		/**
		 * @see loom2d.display.DisplayObject#scaleX
		 */
		function get scaleX():Number;

		/**
		 * @private
		 */
		function set scaleX(value:Number):void;

		/**
		 * @see loom2d.display.DisplayObject#scaleY
		 */
		function get scaleY():Number;

		/**
		 * @private
		 */
		function set scaleY(value:Number):void;

		/**
		 * @see loom2d.display.DisplayObject#skewX
		 */
		function get skewX():Number;

		/**
		 * @private
		 */
		function set skewX(value:Number):void;

		/**
		 * @see loom2d.display.DisplayObject#skewY
		 */
		function get skewY():Number;

		/**
		 * @private
		 */
		function set skewY(value:Number):void;

		/**
		 * @see loom2d.display.DisplayObject#blendMode
		 */
		function get blendMode():String;

		/**
		 * @private
		 */
		function set blendMode(value:String):void;

		/**
		 * @see loom2d.display.DisplayObject#name
		 */
		function get name():String;

		/**
		 * @private
		 */
		function set name(value:String):void;

		/**
		 * @see loom2d.display.DisplayObject#touchable
		 */
		function get touchable():Boolean;

		/**
		 * @private
		 */
		function set touchable(value:Boolean):void;

		/**
		 * @see loom2d.display.DisplayObject#visible
		 */
		function get visible():Boolean;

		/**
		 * @private
		 */
		function set visible(value:Boolean):void;

		/**
		 * @see loom2d.display.DisplayObject#alpha
		 */
		function get alpha():Number;

		/**
		 * @private
		 */
		function set alpha(value:Number):void;

		/**
		 * @see loom2d.display.DisplayObject#rotation
		 */
		function get rotation():Number;

		/**
		 * @private
		 */
		function set rotation(value:Number):void;

		/**
		 * @see loom2d.display.DisplayObject#parent
		 */
		function get parent():DisplayObjectContainer;

		/**
		 * @see loom2d.display.DisplayObject#base
		 */
		function get base():DisplayObject;

		/**
		 * @see loom2d.display.DisplayObject#root
		 */
		function get root():DisplayObject;

		/**
		 * @see loom2d.display.DisplayObject#stage
		 */
		function get stage():Stage;

		/**
		 * @see loom2d.display.DisplayObject#hasVisibleArea
		 */
		function get hasVisibleArea():Boolean;

		/**
		 * @see loom2d.display.DisplayObject#transformationMatrix
		 */
		function get transformationMatrix():Matrix;

		/**
		 * @see loom2d.display.DisplayObject#useHandCursor
		 */
		function get useHandCursor():Boolean;

		/**
		 * @private
		 */
		function set useHandCursor(value:Boolean):void;

		/**
		 * @see loom2d.display.DisplayObject#bounds
		 */
		function get bounds():Rectangle;

		/**
		 * @see loom2d.display.DisplayObject#removeFromParent()
		 */
		function removeFromParent(dispose:Boolean = false):void;

		/**
		 * @see loom2d.display.DisplayObject#hitTest()
		 */
		function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject;

		/**
		 * @see loom2d.display.DisplayObject#localToGlobal()
		 */
		function localToGlobal(localPoint:Point):Point;

		/**
		 * @see loom2d.display.DisplayObject#globalToLocal()
		 */
		function globalToLocal(globalPoint:Point):Point;

		/**
		 * @see loom2d.display.DisplayObject#getTransformationMatrix()
		 */
		function getTransformationMatrix(targetSpace:DisplayObject, resultMatrix:Matrix = null):Matrix;

		/**
		 * @see loom2d.display.DisplayObject#getBounds()
		 */
		function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle;

		/**
		 * @see loom2d.display.DisplayObject#render()
		 */
		function render():void;

		/**
		 * @see loom2d.display.DisplayObject#dispose()
		 */
		function dispose():void;
	}
}
