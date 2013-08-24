/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.layout
{
	import feathers.events.FeathersEventType;
	import feathers.system.DeviceCapabilities;

	import loom2d.events.EventDispatcher;

	/**
	 * Extra, optional data used by an `MultiColumnGridLayout`
	 * instance to position and size a display object.
	 *
	 * @see http://wiki.starling-framework.org/feathers/multi-column-grid-layout
	 * @see MultiColumnGridLayout
	 * @see ILayoutDisplayObject
	 */
	public class MultiColumnGridLayoutData extends EventDispatcher implements ILayoutData
	{
		/**
		 * Used to ignore phone or tablet span values.
		 */
		public static const SPAN_USE_DEFAULT:int = -1;

		/**
		 * Used to ignore phone or tablet offset values.
		 */
		public static const OFFSET_USE_DEFAULT:int = -1;

		/**
		 * Constructor.
		 */
		public function MultiColumnGridLayoutData()
		{
		}

		/**
		 * @private
		 */
		protected var _span:int = 1;

		/**
		 * The number of columns that this item spans. The value may be between
		 * `1` and the value of the `columnCount` of the
		 * `MultiColumnGridLayout` that is controlling this item.
		 */
		public function get span():int
		{
			return this._span;
		}

		/**
		 * @private
		 */
		public function set span(value:int):void
		{
			if(value < 1)
			{
				value = 1;
			}
			if(this._span == value)
			{
				return;
			}
			this._span = value;
			this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
		}

		/**
		 * @private
		 */
		protected var _spanPhone:int = SPAN_USE_DEFAULT;

		/**
		 * Overrides the `span` value for devices that are identified
		 * as phones. Set to `MultiGridColumnLayoutData.SPAN_USE_DEFAULT`
		 * to switch back to the default span value.
		 *
		 * @see #span
		 * @see #spanTablet
		 * @see feathers.system.DeviceCapabilities.isPhone()
		 */
		public function get spanPhone():int
		{
			return this._spanPhone;
		}

		/**
		 * @private
		 */
		public function set spanPhone(value:int):void
		{
			if(this._spanPhone == value)
			{
				return;
			}
			this._spanPhone = value;
			this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
		}

		/**
		 * @private
		 */
		protected var _spanTablet:int = SPAN_USE_DEFAULT;

		/**
		 * Overrides the `span` value for devices that are identified
		 * as tablets. Set to `MultiGridColumnLayoutData.SPAN_USE_DEFAULT`
		 * to switch back to the default span value.
		 *
		 * @see #span
		 * @see #spanPhone
		 * @see feathers.system.DeviceCapabilities.isTablet()
		 */
		public function get spanTablet():int
		{
			return this._spanTablet;
		}

		/**
		 * @private
		 */
		public function set spanTablet(value:int):void
		{
			if(this._spanTablet == value)
			{
				return;
			}
			this._spanTablet = value;
			this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
		}

		/**
		 * @private
		 */
		protected var _spanFunction:Function;

		/**
		 * Provides the ability to override the `span` value with
		 * custom rules instead of using the standard phone and tablet overrides
		 * provided by this class.
		 */
		public function get spanFunction():Function
		{
			return this._spanFunction;
		}

		/**
		 * @private
		 */
		public function set spanFunction(value:Function):void
		{
			if(this._spanFunction == value)
			{
				return;
			}
			this._spanFunction = value;
			this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
		}

		/**
		 * @private
		 */
		protected var _cachedSpan:int = int.MIN_VALUE;

		/**
		 * @private
		 */
		protected var _cacheSpanFunctionResult:Boolean = false;

		/**
		 * If `true`, the result of `spanFunction` will
		 * be stored after the function is called for the first time, and this
		 * result will always be used.
		 */
		public function get cacheSpanFunctionResult():Boolean
		{
			return this._cacheSpanFunctionResult;
		}

		/**
		 * @private
		 */
		public function set cacheSpanFunctionResult(value:Boolean):void
		{
			if(this._cacheSpanFunctionResult == value)
			{
				return;
			}
			this._cacheSpanFunctionResult = value;
			if(!value)
			{
				this._cachedSpan = int.MIN_VALUE;
			}
			this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
		}

		/**
		 * @private
		 */
		protected var _offset:int = 0;

		/**
		 * The number of columns that this item spans. The value may be between
		 * `1` and the value of the `columnCount` of the
		 * `MultiColumnGridLayout` that is controlling this item. If
		 * the value is greater than the column count, the `MultiColumnGridLayout`
		 * will automatically reduce it to the column count.
		 */
		public function get offset():int
		{
			return this._offset;
		}

		/**
		 * @private
		 */
		public function set offset(value:int):void
		{
			if(value < 0)
			{
				value = 0;
			}
			if(this._offset == value)
			{
				return;
			}
			this._offset = value;
			this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
		}

		/**
		 * @private
		 */
		protected var _offsetPhone:int = OFFSET_USE_DEFAULT;

		/**
		 * Overrides the `offset` value for devices that are identified
		 * as phones. Set to `MultiGridColumnLayoutData.OFFSET_USE_DEFAULT`
		 * to switch back to the default offset value.
		 *
		 * @see #offset
		 * @see #offsetTablet
		 * @see feathers.system.DeviceCapabilities.isPhone()
		 */
		public function get offsetPhone():int
		{
			return this._offsetPhone;
		}

		/**
		 * @private
		 */
		public function set offsetPhone(value:int):void
		{
			if(this._offsetPhone == value)
			{
				return;
			}
			this._offsetPhone = value;
			this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
		}

		/**
		 * @private
		 */
		protected var _offsetTablet:int = OFFSET_USE_DEFAULT;

		/**
		 * Overrides the `offset` value for devices that are identified
		 * as tablets. Set to `MultiGridColumnLayoutData.OFFSET_USE_DEFAULT`
		 * to switch back to the default offset value.
		 *
		 * @see #offset
		 * @see #offsetPhone
		 * @see feathers.system.DeviceCapabilities.isTablet()
		 */
		public function get offsetTablet():int
		{
			return this._offsetTablet;
		}

		/**
		 * @private
		 */
		public function set offsetTablet(value:int):void
		{
			if(this._offsetTablet == value)
			{
				return;
			}
			this._offsetTablet = value;
			this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
		}

		/**
		 * @private
		 */
		protected var _offsetFunction:Function;

		/**
		 * Provides the ability to override the `offset` value with
		 * custom rules instead of using the standard phone and tablet overrides
		 * provided by this class.
		 */
		public function get offsetFunction():Function
		{
			return this._offsetFunction;
		}

		/**
		 * @private
		 */
		public function set offsetFunction(value:Function):void
		{
			if(this._offsetFunction == value)
			{
				return;
			}
			this._offsetFunction = value;
			this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
		}

		/**
		 * @private
		 */
		protected var _cachedOffset:int = int.MIN_VALUE;

		/**
		 * @private
		 */
		protected var _cacheOffsetFunctionResult:Boolean = false;

		/**
		 * If `true`, the result of `offsetFunction` will
		 * be stored after the function is called for the first time, and this
		 * result will always be used.
		 */
		public function get cacheOffsetFunctionResult():Boolean
		{
			return this._cacheOffsetFunctionResult;
		}

		/**
		 * @private
		 */
		public function set cacheOffsetFunctionResult(value:Boolean):void
		{
			if(this._cacheOffsetFunctionResult == value)
			{
				return;
			}
			this._cacheOffsetFunctionResult = value;
			if(!value)
			{
				this._cachedOffset = int.MIN_VALUE;
			}
			this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
		}

		/**
		 * @private
		 */
		protected var _forceEndOfRow:Boolean = false;

		/**
		 * If `true` the item will be the last in the current row,
		 * and a new row will be started.
		 */
		public function get forceEndOfRow():Boolean
		{
			return this._forceEndOfRow;
		}

		/**
		 * @private
		 */
		public function set forceEndOfRow(value:Boolean):void
		{
			if(this._forceEndOfRow == value)
			{
				return;
			}
			this._forceEndOfRow = value;
			this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
		}

		/**
		 * Returns the span value for this item, taking into account the various
		 * available ways to override this value.
		 */
		public function getSpan():int
		{
			if(this._spanFunction != null)
			{
				if(this._cacheSpanFunctionResult && this._cachedSpan != int.MIN_VALUE)
				{
					return this._cachedSpan;
				}
				return this._spanFunction.call() as int;
			}

			if(this._spanPhone >= 0 && DeviceCapabilities.isPhone())
			{
				return this._spanPhone;
			}
			else if(this._spanTablet >= 0 && DeviceCapabilities.isTablet())
			{
				return this._spanTablet;
			}
			return this._span;
		}

		/**
		 * Returns the offset value for this item, taking into account the various
		 * available ways to override this value.
		 */
		public function getOffset():int
		{
			if(this._offsetFunction != null)
			{
				if(this._cacheOffsetFunctionResult && this._cachedOffset != int.MIN_VALUE)
				{
					return this._cachedOffset;
				}
				return this._offsetFunction.call() as int;
			}

			if(this._offsetPhone >= 0 && DeviceCapabilities.isPhone())
			{
				return this._offsetPhone;
			}
			else if(this._offsetTablet >= 0 && DeviceCapabilities.isTablet())
			{
				return this._offsetTablet;
			}
			return this._offset;
		}
	}
}
