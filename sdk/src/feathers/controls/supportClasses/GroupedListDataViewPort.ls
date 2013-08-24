/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls.supportClasses
{
	import feathers.controls.GroupedList;
	import feathers.controls.Scroller;
	import feathers.controls.renderers.IGroupedListHeaderOrFooterRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.core.FeathersControl;
	import feathers.core.IFeathersControl;
	import feathers.data.HierarchicalCollection;
	import feathers.events.CollectionEventType;
	import feathers.events.FeathersEventType;
	import feathers.layout.ILayout;
	import feathers.layout.IVariableVirtualLayout;
	import feathers.layout.IVirtualLayout;
	import feathers.layout.LayoutBoundsResult;
	import feathers.layout.ViewPortBounds;

	import loom2d.math.Point;
	import loom2d.math.Rectangle;

	import loom2d.display.DisplayObject;
	import loom2d.events.Event;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;

	/**
	 * @private
	 * Used internally by GroupedList. Not meant to be used on its own.
	 */
	public final class GroupedListDataViewPort extends FeathersControl implements IViewPort
	{
		private static const INVALIDATION_FLAG_ITEM_RENDERER_FACTORY:String = "itemRendererFactory";

		private static const HELPER_POINT:Point = new Point();
		private static const HELPER_BOUNDS:ViewPortBounds = new ViewPortBounds();
		private static const HELPER_LAYOUT_RESULT:LayoutBoundsResult = new LayoutBoundsResult();
		private static const HELPER_VECTOR:Vector.<int> = new <int>[];
		private static const HELPER_TOUCHES_VECTOR:Vector.<Touch> = new <Touch>[];

		public function GroupedListDataViewPort()
		{
			super();
			addEventListener(TouchEvent.TOUCH, touchHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
		}

		private var touchPointID:int = -1;

		private var _minVisibleWidth:Number = 0;

		public function get minVisibleWidth():Number
		{
			return _minVisibleWidth;
		}

		public function set minVisibleWidth(value:Number):void
		{
			if(_minVisibleWidth == value)
			{
				return;
			}
			if(isNaN(value))
			{
				throw new ArgumentError("minVisibleWidth cannot be NaN");
			}
			_minVisibleWidth = value;
			invalidate(INVALIDATION_FLAG_SIZE);
		}

		private var _maxVisibleWidth:Number = Number.POSITIVE_INFINITY;

		public function get maxVisibleWidth():Number
		{
			return _maxVisibleWidth;
		}

		public function set maxVisibleWidth(value:Number):void
		{
			if(_maxVisibleWidth == value)
			{
				return;
			}
			if(isNaN(value))
			{
				throw new ArgumentError("maxVisibleWidth cannot be NaN");
			}
			_maxVisibleWidth = value;
			invalidate(INVALIDATION_FLAG_SIZE);
		}

		private var actualVisibleWidth:Number = NaN;

		private var explicitVisibleWidth:Number = NaN;

		public function get visibleWidth():Number
		{
			return actualVisibleWidth;
		}

		public function set visibleWidth(value:Number):void
		{
			if(explicitVisibleWidth == value || (isNaN(value) && isNaN(explicitVisibleWidth)))
			{
				return;
			}
			explicitVisibleWidth = value;
			invalidate(INVALIDATION_FLAG_SIZE);
		}

		private var _minVisibleHeight:Number = 0;

		public function get minVisibleHeight():Number
		{
			return _minVisibleHeight;
		}

		public function set minVisibleHeight(value:Number):void
		{
			if(_minVisibleHeight == value)
			{
				return;
			}
			if(isNaN(value))
			{
				throw new ArgumentError("minVisibleHeight cannot be NaN");
			}
			_minVisibleHeight = value;
			invalidate(INVALIDATION_FLAG_SIZE);
		}

		private var _maxVisibleHeight:Number = Number.POSITIVE_INFINITY;

		public function get maxVisibleHeight():Number
		{
			return _maxVisibleHeight;
		}

		public function set maxVisibleHeight(value:Number):void
		{
			if(_maxVisibleHeight == value)
			{
				return;
			}
			if(isNaN(value))
			{
				throw new ArgumentError("maxVisibleHeight cannot be NaN");
			}
			_maxVisibleHeight = value;
			invalidate(INVALIDATION_FLAG_SIZE);
		}

		private var actualVisibleHeight:Number;

		private var explicitVisibleHeight:Number = NaN;

		public function get visibleHeight():Number
		{
			return actualVisibleHeight;
		}

		public function set visibleHeight(value:Number):void
		{
			if(explicitVisibleHeight == value || (isNaN(value) && isNaN(explicitVisibleHeight)))
			{
				return;
			}
			explicitVisibleHeight = value;
			invalidate(INVALIDATION_FLAG_SIZE);
		}

		public function get horizontalScrollStep():Number
		{
			return Math.min(_typicalItemWidth, _typicalItemHeight);
		}

		public function get verticalScrollStep():Number
		{
			return Math.min(_typicalItemWidth, _typicalItemHeight);
		}

		private var _typicalItemWidth:Number = NaN;

		public function get typicalItemWidth():Number
		{
			return _typicalItemWidth;
		}

		private var _typicalItemHeight:Number = NaN;

		public function get typicalItemHeight():Number
		{
			return _typicalItemHeight;
		}

		private var _typicalHeaderWidth:Number = NaN;

		public function get typicalHeaderWidth():Number
		{
			return _typicalHeaderWidth;
		}

		private var _typicalHeaderHeight:Number = NaN;

		public function get typicalHeaderHeight():Number
		{
			return _typicalHeaderHeight;
		}

		private var _typicalFooterWidth:Number = NaN;

		public function get typicalFooterWidth():Number
		{
			return _typicalFooterWidth;
		}

		private var _typicalFooterHeight:Number = NaN;

		public function get typicalFooterHeight():Number
		{
			return _typicalFooterHeight;
		}

		private var _layoutItems:Vector.<DisplayObject> = new <DisplayObject>[];

		private var _unrenderedItems:Vector.<int> = new <int>[];
		private var _inactiveItemRenderers:Vector.<IGroupedListItemRenderer> = new <IGroupedListItemRenderer>[];
		private var _activeItemRenderers:Vector.<IGroupedListItemRenderer> = new <IGroupedListItemRenderer>[];
		private var _itemRendererMap:Dictionary.<Object, IGroupedListItemRenderer> = new Dictionary.<String, IGroupedListItemRenderer>(true);

		private var _unrenderedFirstItems:Vector.<int>;
		private var _inactiveFirstItemRenderers:Vector.<IGroupedListItemRenderer>;
		private var _activeFirstItemRenderers:Vector.<IGroupedListItemRenderer>;
		private var _firstItemRendererMap:Dictionary.<Object, IGroupedListItemRenderer> = new Dictionary.<Object, IGroupedListItemRenderer>(true);

		private var _unrenderedLastItems:Vector.<int>;
		private var _inactiveLastItemRenderers:Vector.<IGroupedListItemRenderer>;
		private var _activeLastItemRenderers:Vector.<IGroupedListItemRenderer>;
		private var _lastItemRendererMap:Dictionary.<Object, IGroupedListItemRenderer>;

		private var _unrenderedSingleItems:Vector.<int>;
		private var _inactiveSingleItemRenderers:Vector.<IGroupedListItemRenderer>;
		private var _activeSingleItemRenderers:Vector.<IGroupedListItemRenderer>;
		private var _singleItemRendererMap:Dictionary.<Object, IGroupedListItemRenderer>;

		private var _unrenderedHeaders:Vector.<int> = new <int>[];
		private var _inactiveHeaderRenderers:Vector.<IGroupedListHeaderOrFooterRenderer> = new <IGroupedListHeaderOrFooterRenderer>[];
		private var _activeHeaderRenderers:Vector.<IGroupedListHeaderOrFooterRenderer> = new <IGroupedListHeaderOrFooterRenderer>[];
		private var _headerRendererMap:Dictionary.<Object, IGroupedListHeaderOrFooterRenderer> = new Dictionary.<Object, IGroupedListHeaderOrFooterRenderer>(true);

		private var _unrenderedFooters:Vector.<int> = new <int>[];
		private var _inactiveFooterRenderers:Vector.<IGroupedListHeaderOrFooterRenderer> = new <IGroupedListHeaderOrFooterRenderer>[];
		private var _activeFooterRenderers:Vector.<IGroupedListHeaderOrFooterRenderer> = new <IGroupedListHeaderOrFooterRenderer>[];
		private var _footerRendererMap:Dictionary.<Object, IGroupedListHeaderOrFooterRenderer> = new Dictionary.<Object, IGroupedListHeaderOrFooterRenderer>(true);

		private var _headerIndices:Vector.<int> = new <int>[];
		private var _footerIndices:Vector.<int> = new <int>[];

		private var _isScrolling:Boolean = false;

		private var _owner:GroupedList;

		public function get owner():GroupedList
		{
			return _owner;
		}

		public function set owner(value:GroupedList):void
		{
			if(_owner == value)
			{
				return;
			}
			if(_owner)
			{
				_owner.removeEventListener(Event.SCROLL, owner_scrollHandler);
			}
			_owner = value;
			if(_owner)
			{
				_owner.addEventListener(Event.SCROLL, owner_scrollHandler);
			}
		}

		private var _dataProvider:HierarchicalCollection;

		public function get dataProvider():HierarchicalCollection
		{
			return _dataProvider;
		}

		public function set dataProvider(value:HierarchicalCollection):void
		{
			if(_dataProvider == value)
			{
				return;
			}
			if(_dataProvider)
			{
				_dataProvider.removeEventListener(Event.CHANGE, dataProvider_changeHandler);
				_dataProvider.removeEventListener(CollectionEventType.RESET, dataProvider_resetHandler);
				_dataProvider.removeEventListener(CollectionEventType.ADD_ITEM, dataProvider_addItemHandler);
				_dataProvider.removeEventListener(CollectionEventType.REMOVE_ITEM, dataProvider_removeItemHandler);
				_dataProvider.removeEventListener(CollectionEventType.REPLACE_ITEM, dataProvider_replaceItemHandler);
				_dataProvider.removeEventListener(CollectionEventType.UPDATE_ITEM, dataProvider_updateItemHandler);
			}
			_dataProvider = value;
			if(_dataProvider)
			{
				_dataProvider.addEventListener(Event.CHANGE, dataProvider_changeHandler);
				_dataProvider.addEventListener(CollectionEventType.RESET, dataProvider_resetHandler);
				_dataProvider.addEventListener(CollectionEventType.ADD_ITEM, dataProvider_addItemHandler);
				_dataProvider.addEventListener(CollectionEventType.REMOVE_ITEM, dataProvider_removeItemHandler);
				_dataProvider.addEventListener(CollectionEventType.REPLACE_ITEM, dataProvider_replaceItemHandler);
				_dataProvider.addEventListener(CollectionEventType.UPDATE_ITEM, dataProvider_updateItemHandler);
			}
			if(_layout is IVariableVirtualLayout)
			{
				IVariableVirtualLayout(_layout).resetVariableVirtualCache();
			}
			invalidate(INVALIDATION_FLAG_DATA);
		}

		private var _isSelectable:Boolean = true;

		public function get isSelectable():Boolean
		{
			return _isSelectable;
		}

		public function set isSelectable(value:Boolean):void
		{
			if(_isSelectable == value)
			{
				return;
			}
			_isSelectable = value;
			if(!_isSelectable)
			{
				setSelectedLocation(-1, -1);
			}
			invalidate(INVALIDATION_FLAG_SELECTED);
		}

		private var _selectedGroupIndex:int = -1;

		public function get selectedGroupIndex():int
		{
			return _selectedGroupIndex;
		}

		private var _selectedItemIndex:int = -1;

		public function get selectedItemIndex():int
		{
			return _selectedItemIndex;
		}

		private var _itemRendererType:Type;

		public function get itemRendererType():Type
		{
			return _itemRendererType;
		}

		public function set itemRendererType(value:Type):void
		{
			if(_itemRendererType == value)
			{
				return;
			}

			_itemRendererType = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _itemRendererFactory:Function;

		public function get itemRendererFactory():Function
		{
			return _itemRendererFactory;
		}

		public function set itemRendererFactory(value:Function):void
		{
			if(_itemRendererFactory == value)
			{
				return;
			}

			_itemRendererFactory = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _itemRendererName:String;

		public function get itemRendererName():String
		{
			return _itemRendererName;
		}

		public function set itemRendererName(value:String):void
		{
			if(_itemRendererName == value)
			{
				return;
			}
			_itemRendererName = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _typicalItem:Object = null;

		public function get typicalItem():Object
		{
			return _typicalItem;
		}

		public function set typicalItem(value:Object):void
		{
			if(_typicalItem == value)
			{
				return;
			}
			_typicalItem = value;
			invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private var _itemRendererProperties:Dictionary.<String, Object>;

		public function get itemRendererProperties():Dictionary.<String, Object>
		{
			return _itemRendererProperties;
		}

		public function set itemRendererProperties(value:Dictionary.<String, Object>):void
		{
			if(_itemRendererProperties == value)
			{
				return;
			}
			_itemRendererProperties = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _firstItemRendererType:Type;

		public function get firstItemRendererType():Type
		{
			return _firstItemRendererType;
		}

		public function set firstItemRendererType(value:Type):void
		{
			if(_firstItemRendererType == value)
			{
				return;
			}

			_firstItemRendererType = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _firstItemRendererFactory:Function;

		public function get firstItemRendererFactory():Function
		{
			return _firstItemRendererFactory;
		}

		public function set firstItemRendererFactory(value:Function):void
		{
			if(_firstItemRendererFactory == value)
			{
				return;
			}

			_firstItemRendererFactory = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _firstItemRendererName:String;

		public function get firstItemRendererName():String
		{
			return _firstItemRendererName;
		}

		public function set firstItemRendererName(value:String):void
		{
			if(_firstItemRendererName == value)
			{
				return;
			}
			_firstItemRendererName = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _lastItemRendererType:Type;

		public function get lastItemRendererType():Type
		{
			return _lastItemRendererType;
		}

		public function set lastItemRendererType(value:Type):void
		{
			if(_lastItemRendererType == value)
			{
				return;
			}

			_lastItemRendererType = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _lastItemRendererFactory:Function;

		public function get lastItemRendererFactory():Function
		{
			return _lastItemRendererFactory;
		}

		public function set lastItemRendererFactory(value:Function):void
		{
			if(_lastItemRendererFactory == value)
			{
				return;
			}

			_lastItemRendererFactory = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _lastItemRendererName:String;

		public function get lastItemRendererName():String
		{
			return _lastItemRendererName;
		}

		public function set lastItemRendererName(value:String):void
		{
			if(_lastItemRendererName == value)
			{
				return;
			}
			_lastItemRendererName = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _singleItemRendererType:Type;

		public function get singleItemRendererType():Type
		{
			return _singleItemRendererType;
		}

		public function set singleItemRendererType(value:Type):void
		{
			if(_singleItemRendererType == value)
			{
				return;
			}

			_singleItemRendererType = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _singleItemRendererFactory:Function;

		public function get singleItemRendererFactory():Function
		{
			return _singleItemRendererFactory;
		}

		public function set singleItemRendererFactory(value:Function):void
		{
			if(_singleItemRendererFactory == value)
			{
				return;
			}

			_singleItemRendererFactory = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _singleItemRendererName:String;

		public function get singleItemRendererName():String
		{
			return _singleItemRendererName;
		}

		public function set singleItemRendererName(value:String):void
		{
			if(_singleItemRendererName == value)
			{
				return;
			}
			_singleItemRendererName = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _headerRendererType:Type;

		public function get headerRendererType():Type
		{
			return _headerRendererType;
		}

		public function set headerRendererType(value:Type):void
		{
			if(_headerRendererType == value)
			{
				return;
			}

			_headerRendererType = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _headerRendererFactory:Function;

		public function get headerRendererFactory():Function
		{
			return _headerRendererFactory;
		}

		public function set headerRendererFactory(value:Function):void
		{
			if(_headerRendererFactory == value)
			{
				return;
			}

			_headerRendererFactory = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _headerRendererName:String;

		public function get headerRendererName():String
		{
			return _headerRendererName;
		}

		public function set headerRendererName(value:String):void
		{
			if(_headerRendererName == value)
			{
				return;
			}
			_headerRendererName = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _typicalHeader:Object = null;

		public function get typicalHeader():Object
		{
			return _typicalHeader;
		}

		public function set typicalHeader(value:Object):void
		{
			if(_typicalHeader == value)
			{
				return;
			}
			_typicalHeader = value;
			invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private var _headerRendererProperties:Dictionary.<String, Object>;

		public function get headerRendererProperties():Dictionary.<String, Object>
		{
			return _headerRendererProperties;
		}

		public function set headerRendererProperties(value:Dictionary.<String, Object>):void
		{
			if(_headerRendererProperties == value)
			{
				return;
			}
			_headerRendererProperties = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _footerRendererType:Type;

		public function get footerRendererType():Type
		{
			return _footerRendererType;
		}

		public function set footerRendererType(value:Type):void
		{
			if(_footerRendererType == value)
			{
				return;
			}

			_footerRendererType = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _footerRendererFactory:Function;

		public function get footerRendererFactory():Function
		{
			return _footerRendererFactory;
		}

		public function set footerRendererFactory(value:Function):void
		{
			if(_footerRendererFactory == value)
			{
				return;
			}

			_footerRendererFactory = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _footerRendererName:String;

		public function get footerRendererName():String
		{
			return _footerRendererName;
		}

		public function set footerRendererName(value:String):void
		{
			if(_footerRendererName == value)
			{
				return;
			}
			_footerRendererName = value;
			invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _typicalFooter:Object = null;

		public function get typicalFooter():Object
		{
			return _typicalFooter;
		}

		public function set typicalFooter(value:Object):void
		{
			if(_typicalFooter == value)
			{
				return;
			}
			_typicalFooter = value;
			invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private var _footerRendererProperties:Dictionary.<String, Object>;

		public function get footerRendererProperties():Dictionary.<String, Object>
		{
			return _footerRendererProperties;
		}

		public function set footerRendererProperties(value:Dictionary.<String, Object>):void
		{
			if(_footerRendererProperties == value)
			{
				return;
			}
			_footerRendererProperties = value;
			invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _ignoreLayoutChanges:Boolean = false;
		private var _ignoreRendererResizing:Boolean = false;

		private var _layout:ILayout;

		public function get layout():ILayout
		{
			return _layout;
		}

		public function set layout(value:ILayout):void
		{
			if(_layout == value)
			{
				return;
			}
			if(_layout)
			{
				_layout.removeEventListener(Event.CHANGE, layout_changeHandler);
			}
			_layout = value;
			if(_layout)
			{
				if(_layout is IVariableVirtualLayout)
				{
					const variableVirtualLayout:IVariableVirtualLayout = IVariableVirtualLayout(_layout);
					variableVirtualLayout.hasVariableItemDimensions = true;
					variableVirtualLayout.resetVariableVirtualCache();
				}
				_layout.addEventListener(Event.CHANGE, layout_changeHandler);
			}
			invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private var _horizontalScrollPosition:Number = 0;

		public function get horizontalScrollPosition():Number
		{
			return _horizontalScrollPosition;
		}

		public function set horizontalScrollPosition(value:Number):void
		{
			if(_horizontalScrollPosition == value)
			{
				return;
			}
			_horizontalScrollPosition = value;
			invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private var _verticalScrollPosition:Number = 0;

		public function get verticalScrollPosition():Number
		{
			return _verticalScrollPosition;
		}

		public function set verticalScrollPosition(value:Number):void
		{
			if(_verticalScrollPosition == value)
			{
				return;
			}
			_verticalScrollPosition = value;
			invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private var _minimumItemCount:int;
		private var _minimumHeaderCount:int;
		private var _minimumFooterCount:int;
		private var _minimumFirstAndLastItemCount:int;
		private var _minimumSingleItemCount:int;

		private var _ignoreSelectionChanges:Boolean = false;

		public function setSelectedLocation(groupIndex:int, itemIndex:int):void
		{
			if(_selectedGroupIndex == groupIndex && _selectedItemIndex == itemIndex)
			{
				return;
			}
			if((groupIndex < 0 && itemIndex >= 0) || (groupIndex >= 0 && itemIndex < 0))
			{
				throw new ArgumentError("To deselect items, group index and item index must both be < 0.");
			}
			_selectedGroupIndex = groupIndex;
			_selectedItemIndex = itemIndex;

			invalidate(INVALIDATION_FLAG_SELECTED);
			dispatchEventWith(Event.CHANGE);
		}

		public function getScrollPositionForIndex(groupIndex:int, itemIndex:int):Point
		{
			const displayIndex:int = locationToDisplayIndex(groupIndex, itemIndex);
			return _layout.getScrollPositionForIndex(displayIndex, _layoutItems, 0, 0, actualVisibleWidth, actualVisibleHeight);
		}

		override public function dispose():void
		{
			owner = null;
			dataProvider = null;
			layout = null;
			super.dispose();
		}

		override protected function draw():void
		{
			const dataInvalid:Boolean = isInvalid(INVALIDATION_FLAG_DATA);
			const scrollInvalid:Boolean = isInvalid(INVALIDATION_FLAG_SCROLL);
			const sizeInvalid:Boolean = isInvalid(INVALIDATION_FLAG_SIZE);
			const selectionInvalid:Boolean = isInvalid(INVALIDATION_FLAG_SELECTED);
			const itemRendererInvalid:Boolean = isInvalid(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
			const stylesInvalid:Boolean = isInvalid(INVALIDATION_FLAG_STYLES);
			const stateInvalid:Boolean = isInvalid(INVALIDATION_FLAG_STATE);

			if(stylesInvalid || dataInvalid || itemRendererInvalid)
			{
				calculateTypicalValues();
			}

			if(scrollInvalid || sizeInvalid || dataInvalid || itemRendererInvalid)
			{
				refreshRenderers(itemRendererInvalid);
			}
			if(scrollInvalid || sizeInvalid || dataInvalid || stylesInvalid || itemRendererInvalid)
			{
				refreshHeaderRendererStyles();
				refreshFooterRendererStyles();
				refreshItemRendererStyles();
			}
			if(scrollInvalid || selectionInvalid || sizeInvalid || dataInvalid || itemRendererInvalid)
			{
				refreshSelection();
			}

			if(scrollInvalid || stateInvalid || sizeInvalid || dataInvalid || itemRendererInvalid)
			{
				refreshEnabled();
			}

			if(scrollInvalid || dataInvalid || itemRendererInvalid || sizeInvalid || stylesInvalid)
			{
				_ignoreRendererResizing = true;
				_layout.layout(_layoutItems, HELPER_BOUNDS, HELPER_LAYOUT_RESULT);
				_ignoreRendererResizing = false;
				setSizeInternal(HELPER_LAYOUT_RESULT.contentWidth, HELPER_LAYOUT_RESULT.contentHeight, false);
				actualVisibleWidth = HELPER_LAYOUT_RESULT.viewPortWidth;
				actualVisibleHeight = HELPER_LAYOUT_RESULT.viewPortHeight;
			}
		}

		private function refreshEnabled():void
		{
			var rendererCount:int = _activeItemRenderers.length;
			for(var i:int = 0; i < rendererCount; i++)
			{
				var renderer:DisplayObject = DisplayObject(_activeItemRenderers[i]);
				if(renderer is FeathersControl)
				{
					FeathersControl(renderer).isEnabled = _isEnabled;
				}
			}
			if(_activeFirstItemRenderers)
			{
				rendererCount = _activeFirstItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					renderer = DisplayObject(_activeFirstItemRenderers[i]);
					if(renderer is FeathersControl)
					{
						FeathersControl(renderer).isEnabled = _isEnabled;
					}
				}
			}
			if(_activeLastItemRenderers)
			{
				rendererCount = _activeLastItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					renderer = DisplayObject(_activeLastItemRenderers[i]);
					if(renderer is FeathersControl)
					{
						FeathersControl(renderer).isEnabled = _isEnabled;
					}
				}
			}
			if(_activeSingleItemRenderers)
			{
				rendererCount = _activeSingleItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					renderer = DisplayObject(_activeSingleItemRenderers[i]);
					if(renderer is FeathersControl)
					{
						FeathersControl(renderer).isEnabled = _isEnabled;
					}
				}
			}
			rendererCount = _activeHeaderRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				renderer = DisplayObject(_activeHeaderRenderers[i]);
				if(renderer is FeathersControl)
				{
					FeathersControl(renderer).isEnabled = _isEnabled;
				}
			}
			rendererCount = _activeFooterRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				renderer = DisplayObject(_activeFooterRenderers[i]);
				if(renderer is FeathersControl)
				{
					FeathersControl(renderer).isEnabled = _isEnabled;
				}
			}
		}
		
		private function invalidateParent():void
		{
			Scroller(parent).invalidate(INVALIDATION_FLAG_DATA);
		}

		private function calculateTypicalValues():void
		{
			var typicalHeader:Object = _typicalHeader;
			var typicalFooter:Object = _typicalFooter;
			if(!typicalHeader || !typicalFooter)
			{
				if(_dataProvider && _dataProvider.getLength() > 0)
				{
					var group:Object = _dataProvider.getItemAt(0);
					if(!typicalHeader)
					{
						typicalHeader = _owner.groupToHeaderData(group);
					}
					if(!typicalFooter)
					{
						typicalFooter = _owner.groupToFooterData(group);
					}
				}
				else
				{
					_typicalHeaderWidth = 0;
					_typicalFooterWidth = 0;
					_typicalFooterHeight= 0;
					_typicalHeaderHeight = 0;
				}
			}

			//headers are optional
			if(typicalHeader)
			{
				var needsDestruction:Boolean = true;
				var typicalHeaderRenderer:IGroupedListHeaderOrFooterRenderer = IGroupedListHeaderOrFooterRenderer(_headerRendererMap[typicalHeader]);
				if(typicalHeaderRenderer)
				{
					typicalHeaderRenderer.width = NaN;
					typicalHeaderRenderer.height = NaN;
					needsDestruction = false;
				}
				else
				{
					typicalHeaderRenderer = createHeaderRenderer(typicalHeader, 0, 0, true);
				}
				refreshOneHeaderRendererStyles(typicalHeaderRenderer);
				if(typicalHeaderRenderer is FeathersControl)
				{
					FeathersControl(typicalHeaderRenderer).validate();
				}
				_typicalHeaderWidth = typicalHeaderRenderer.width;
				_typicalHeaderHeight = typicalHeaderRenderer.height;
				if(needsDestruction)
				{
					destroyHeaderRenderer(typicalHeaderRenderer);
				}
			}

			//footers are optional
			if(typicalFooter)
			{
				needsDestruction = true;
				var typicalFooterRenderer:IGroupedListHeaderOrFooterRenderer = IGroupedListHeaderOrFooterRenderer(_footerRendererMap[typicalFooter]);
				if(typicalFooterRenderer)
				{
					needsDestruction = false;
					typicalFooterRenderer.width = NaN;
					typicalFooterRenderer.height = NaN;
				}
				else
				{
					typicalFooterRenderer = createFooterRenderer(typicalFooter, 0, 0, true);
				}
				refreshOneFooterRendererStyles(typicalFooterRenderer);
				if(typicalFooterRenderer is FeathersControl)
				{
					FeathersControl(typicalFooterRenderer).validate();
				}
				_typicalFooterWidth = typicalFooterRenderer.width;
				_typicalFooterHeight = typicalFooterRenderer.height;
				if(needsDestruction)
				{
					destroyFooterRenderer(typicalFooterRenderer);
				}
			}

			var typicalItem:Object = _typicalItem;
			if(!typicalItem)
			{
				if(_dataProvider && _dataProvider.getLength() > 0)
				{
					typicalItem = _dataProvider.getItemAt(0);
				}
				else
				{
					_typicalItemWidth = 0;
					_typicalItemHeight = 0;
					return;
				}
			}

			needsDestruction = true;
			var typicalItemRenderer:IGroupedListItemRenderer = _itemRendererMap[typicalItem];
			if(typicalItemRenderer)
			{
				needsDestruction = false;
				typicalItemRenderer.width = NaN;
				typicalItemRenderer.height = NaN;
			}
			else
			{
				typicalItemRenderer = createItemRenderer(_inactiveItemRenderers,
				_activeItemRenderers, _itemRendererMap, _itemRendererType, _itemRendererFactory,
				_itemRendererName, typicalItem, 0, 0, 0, true);
			}
			refreshOneItemRendererStyles(typicalItemRenderer);
			if(typicalItemRenderer is FeathersControl)
			{
				FeathersControl(typicalItemRenderer).validate();
			}
			_typicalItemWidth = typicalItemRenderer.width;
			_typicalItemHeight = typicalItemRenderer.height;
			if(needsDestruction)
			{
				destroyItemRenderer(typicalItemRenderer);
			}
		}

		private function refreshItemRendererStyles():void
		{
			for each(var renderer:IGroupedListItemRenderer in _activeItemRenderers)
			{
				refreshOneItemRendererStyles(renderer);
			}
			for each(renderer in _activeFirstItemRenderers)
			{
				refreshOneItemRendererStyles(renderer);
			}
			for each(renderer in _activeLastItemRenderers)
			{
				refreshOneItemRendererStyles(renderer);
			}
			for each(renderer in _activeSingleItemRenderers)
			{
				refreshOneItemRendererStyles(renderer);
			}
		}

		private function refreshHeaderRendererStyles():void
		{
			for each(var renderer:IGroupedListHeaderOrFooterRenderer in _activeHeaderRenderers)
			{
				refreshOneHeaderRendererStyles(renderer);
			}
		}

		private function refreshFooterRendererStyles():void
		{
			for each(var renderer:IGroupedListHeaderOrFooterRenderer in _activeFooterRenderers)
			{
				refreshOneFooterRendererStyles(renderer);
			}
		}

		private function refreshOneItemRendererStyles(renderer:IGroupedListItemRenderer):void
		{
			Dictionary.mapToObject(_itemRendererProperties, renderer);
		}

		private function refreshOneHeaderRendererStyles(renderer:IGroupedListHeaderOrFooterRenderer):void
		{
			Dictionary.mapToObject(_headerRendererProperties, renderer);
		}

		private function refreshOneFooterRendererStyles(renderer:IGroupedListHeaderOrFooterRenderer):void
		{
			Dictionary.mapToObject(_footerRendererProperties, renderer);
		}

		private function refreshSelection():void
		{
			_ignoreSelectionChanges = true;
			for each(var renderer:IGroupedListItemRenderer in _activeItemRenderers)
			{
				renderer.isSelected = renderer.groupIndex == _selectedGroupIndex &&
					renderer.itemIndex == _selectedItemIndex;
			}
			for each(renderer in _activeFirstItemRenderers)
			{
				renderer.isSelected = renderer.groupIndex == _selectedGroupIndex &&
					renderer.itemIndex == _selectedItemIndex;
			}
			for each(renderer in _activeLastItemRenderers)
			{
				renderer.isSelected = renderer.groupIndex == _selectedGroupIndex &&
					renderer.itemIndex == _selectedItemIndex;
			}
			for each(renderer in _activeSingleItemRenderers)
			{
				renderer.isSelected = renderer.groupIndex == _selectedGroupIndex &&
					renderer.itemIndex == _selectedItemIndex;
			}
			_ignoreSelectionChanges = false;
		}

		private function refreshRenderers(itemRendererTypeIsInvalid:Boolean):void
		{
			var temp:Vector.<IGroupedListItemRenderer> = _inactiveItemRenderers;
			_inactiveItemRenderers = _activeItemRenderers;
			_activeItemRenderers = temp;
			_activeItemRenderers.length = 0;
			if(_inactiveFirstItemRenderers)
			{
				temp = _inactiveFirstItemRenderers;
				_inactiveFirstItemRenderers = _activeFirstItemRenderers;
				_activeFirstItemRenderers = temp;
				_activeFirstItemRenderers.length = 0;
			}
			if(_inactiveLastItemRenderers)
			{
				temp = _inactiveLastItemRenderers;
				_inactiveLastItemRenderers = _activeLastItemRenderers;
				_activeLastItemRenderers = temp;
				_activeLastItemRenderers.length = 0;
			}
			if(_inactiveSingleItemRenderers)
			{
				temp = _inactiveSingleItemRenderers;
				_inactiveSingleItemRenderers = _activeSingleItemRenderers;
				_activeSingleItemRenderers = temp;
				_activeSingleItemRenderers.length = 0;
			}
			var temp2:Vector.<IGroupedListHeaderOrFooterRenderer> = _inactiveHeaderRenderers;
			_inactiveHeaderRenderers = _activeHeaderRenderers;
			_activeHeaderRenderers = temp2;
			_activeHeaderRenderers.length = 0;
			temp2 = _inactiveFooterRenderers;
			_inactiveFooterRenderers = _activeFooterRenderers;
			_activeFooterRenderers = temp2;
			_activeFooterRenderers.length = 0;
			if(itemRendererTypeIsInvalid)
			{
				recoverInactiveRenderers();
				freeInactiveRenderers();
			}
			_headerIndices.length = 0;
			_footerIndices.length = 0;

			HELPER_BOUNDS.x = HELPER_BOUNDS.y = 0;
			HELPER_BOUNDS.scrollX = _horizontalScrollPosition;
			HELPER_BOUNDS.scrollY = _verticalScrollPosition;
			HELPER_BOUNDS.explicitWidth = explicitVisibleWidth;
			HELPER_BOUNDS.explicitHeight = explicitVisibleHeight;
			HELPER_BOUNDS.minWidth = _minVisibleWidth;
			HELPER_BOUNDS.minHeight = _minVisibleHeight;
			HELPER_BOUNDS.maxWidth = _maxVisibleWidth;
			HELPER_BOUNDS.maxHeight = _maxVisibleHeight;

			findUnrenderedData();
			recoverInactiveRenderers();
			renderUnrenderedData();
			freeInactiveRenderers();
		}

		private function findUnrenderedData():void
		{
			const hasCustomFirstItemRenderer:Boolean = _firstItemRendererType || _firstItemRendererFactory != null || _firstItemRendererName;
			const hasCustomLastItemRenderer:Boolean = _lastItemRendererType || _lastItemRendererFactory != null || _lastItemRendererName;
			const hasCustomSingleItemRenderer:Boolean = _singleItemRendererType || _singleItemRendererFactory != null || _singleItemRendererName;

			if(hasCustomFirstItemRenderer)
			{
				if(!_firstItemRendererMap)
				{
					_firstItemRendererMap = new Dictionary(true);
				}
				if(!_inactiveFirstItemRenderers)
				{
					_inactiveFirstItemRenderers = new <IGroupedListItemRenderer>[];
				}
				if(!_activeFirstItemRenderers)
				{
					_activeFirstItemRenderers = new <IGroupedListItemRenderer>[];
				}
				if(!_unrenderedFirstItems)
				{
					_unrenderedFirstItems = new <int>[];
				}
			}
			else
			{
				_firstItemRendererMap = null;
				_inactiveFirstItemRenderers = null;
				_activeFirstItemRenderers = null;
				_unrenderedFirstItems = null;
			}
			if(hasCustomLastItemRenderer)
			{
				if(!_lastItemRendererMap)
				{
					_lastItemRendererMap = new Dictionary(true);
				}
				if(!_inactiveLastItemRenderers)
				{
					_inactiveLastItemRenderers = new <IGroupedListItemRenderer>[];
				}
				if(!_activeLastItemRenderers)
				{
					_activeLastItemRenderers = new <IGroupedListItemRenderer>[];
				}
				if(!_unrenderedLastItems)
				{
					_unrenderedLastItems = new <int>[];
				}
			}
			else
			{
				_lastItemRendererMap = null;
				_inactiveLastItemRenderers = null;
				_activeLastItemRenderers = null;
				_unrenderedLastItems = null;
			}
			if(hasCustomSingleItemRenderer)
			{
				if(!_singleItemRendererMap)
				{
					_singleItemRendererMap = new Dictionary(true);
				}
				if(!_inactiveSingleItemRenderers)
				{
					_inactiveSingleItemRenderers = new <IGroupedListItemRenderer>[];
				}
				if(!_activeSingleItemRenderers)
				{
					_activeSingleItemRenderers = new <IGroupedListItemRenderer>[];
				}
				if(!_unrenderedSingleItems)
				{
					_unrenderedSingleItems = new <int>[];
				}
			}
			else
			{
				_singleItemRendererMap = null;
				_inactiveSingleItemRenderers = null;
				_activeSingleItemRenderers = null;
				_unrenderedSingleItems = null;
			}

			const groupCount:int = _dataProvider ? _dataProvider.getLength() : 0;
			var totalLayoutCount:int = 0;
			var totalHeaderCount:int = 0;
			var totalFooterCount:int = 0;
			var totalSingleItemCount:int = 0;
			var averageItemsPerGroup:int = 0;
			for(var i:int = 0; i < groupCount; i++)
			{
				var group:Object = _dataProvider.getItemAt(i);
				if(_owner.groupToHeaderData(group) != null)
				{
					_headerIndices.push(totalLayoutCount);
					totalLayoutCount++;
					totalHeaderCount++;
				}
				var currentItemCount:int = _dataProvider.getLength(i);
				totalLayoutCount += currentItemCount;
				averageItemsPerGroup += currentItemCount;
				if(currentItemCount == 0)
				{
					totalSingleItemCount++;
				}
				if(_owner.groupToFooterData(group) != null)
				{
					_footerIndices.push(totalLayoutCount);
					totalLayoutCount++;
					totalFooterCount++;
				}
			}
			_layoutItems.length = totalLayoutCount;
			const virtualLayout:IVirtualLayout = _layout as IVirtualLayout;
			const useVirtualLayout:Boolean = virtualLayout && virtualLayout.useVirtualLayout;
			if(useVirtualLayout)
			{
				_ignoreLayoutChanges = true;
				virtualLayout.typicalItemWidth = _typicalItemWidth;
				virtualLayout.typicalItemHeight = _typicalItemHeight;
				_ignoreLayoutChanges = false;
				HELPER_POINT = virtualLayout.measureViewPort(totalLayoutCount, HELPER_BOUNDS);
				virtualLayout.getVisibleIndicesAtScrollPosition(_horizontalScrollPosition, _verticalScrollPosition, HELPER_POINT.x, HELPER_POINT.y, totalLayoutCount, HELPER_VECTOR);

				averageItemsPerGroup /= groupCount;
				_minimumFirstAndLastItemCount = _minimumSingleItemCount = _minimumHeaderCount = _minimumFooterCount = Math.ceil(HELPER_POINT.y / (_typicalItemHeight * averageItemsPerGroup));
				_minimumHeaderCount = Math.min(_minimumHeaderCount, totalHeaderCount);
				_minimumFooterCount = Math.min(_minimumFooterCount, totalFooterCount);
				_minimumSingleItemCount = Math.min(_minimumSingleItemCount, totalSingleItemCount);

				//assumes that zero headers/footers might be visible
				_minimumItemCount = Math.ceil(HELPER_POINT.y / _typicalItemHeight) + 1;
			}
			var currentIndex:int = 0;
			for(i = 0; i < groupCount; i++)
			{
				group = _dataProvider.getItemAt(i);
				var header:Object = _owner.groupToHeaderData(group);
				if(header != null)
				{
					//the end index is included in the visible items
					if(useVirtualLayout && HELPER_VECTOR.indexOf(currentIndex) < 0)
					{
						_layoutItems[currentIndex] = null;
					}
					else
					{
						var headerOrFooterRenderer:IGroupedListHeaderOrFooterRenderer = IGroupedListHeaderOrFooterRenderer(_headerRendererMap[header]);
						if(headerOrFooterRenderer)
						{
							headerOrFooterRenderer.layoutIndex = currentIndex;
							headerOrFooterRenderer.groupIndex = i;
							_activeHeaderRenderers.push(headerOrFooterRenderer);
							_inactiveHeaderRenderers.splice(_inactiveHeaderRenderers.indexOf(headerOrFooterRenderer), 1);
							headerOrFooterRenderer.visible = true;
							_layoutItems[currentIndex] = DisplayObject(headerOrFooterRenderer);
						}
						else
						{
							_unrenderedHeaders.push(i);
							_unrenderedHeaders.push(currentIndex);
						}
					}
					currentIndex++;
				}
				currentItemCount = _dataProvider.getLength(i);
				var currentGroupLastIndex:int = currentItemCount - 1;
				for(var j:int = 0; j < currentItemCount; j++)
				{
					if(useVirtualLayout && HELPER_VECTOR.indexOf(currentIndex) < 0)
					{
						_layoutItems[currentIndex] = null;
					}
					else
					{
						var item:Object = _dataProvider.getItemAt(i, j);
						if(hasCustomSingleItemRenderer && j == 0 && j == currentGroupLastIndex)
						{
							findRendererForItem(item, i, j, currentIndex, _singleItemRendererMap, _inactiveSingleItemRenderers,
								_activeSingleItemRenderers, _unrenderedSingleItems);
						}
						else if(hasCustomFirstItemRenderer && j == 0)
						{
							findRendererForItem(item, i, j, currentIndex, _firstItemRendererMap, _inactiveFirstItemRenderers,
								_activeFirstItemRenderers, _unrenderedFirstItems);
						}
						else if(hasCustomLastItemRenderer && j == currentGroupLastIndex)
						{
							findRendererForItem(item, i, j, currentIndex, _lastItemRendererMap, _inactiveLastItemRenderers,
								_activeLastItemRenderers, _unrenderedLastItems);
						}
						else
						{
							findRendererForItem(item, i, j, currentIndex, _itemRendererMap, _inactiveItemRenderers,
								_activeItemRenderers, _unrenderedItems);
						}
					}
					currentIndex++;
				}
				var footer:Object = _owner.groupToFooterData(group);
				if(footer != null)
				{
					if(useVirtualLayout && HELPER_VECTOR.indexOf(currentIndex) < 0)
					{
						_layoutItems[currentIndex] = null;
					}
					else
					{
						headerOrFooterRenderer = IGroupedListHeaderOrFooterRenderer(_footerRendererMap[footer]);
						if(headerOrFooterRenderer)
						{
							headerOrFooterRenderer.groupIndex = i;
							headerOrFooterRenderer.layoutIndex = currentIndex;
							_activeFooterRenderers.push(headerOrFooterRenderer);
							_inactiveFooterRenderers.splice(_inactiveFooterRenderers.indexOf(headerOrFooterRenderer), 1);
							headerOrFooterRenderer.visible = true;
							_layoutItems[currentIndex] = DisplayObject(headerOrFooterRenderer);
						}
						else
						{
							_unrenderedFooters.push(i);
							_unrenderedFooters.push(currentIndex);
						}
					}
					currentIndex++;
				}
			}
		}

		private function findRendererForItem(item:Object, groupIndex:int, itemIndex:int, layoutIndex:int,
			rendererMap:Dictionary.<Object, IGroupedListItemRenderer>, inactiveRenderers:Vector.<IGroupedListItemRenderer>,
			activeRenderers:Vector.<IGroupedListItemRenderer>, unrenderedItems:Vector.<int>):void
		{
			var itemRenderer:IGroupedListItemRenderer = IGroupedListItemRenderer(rendererMap[item]);
			if(itemRenderer)
			{
				itemRenderer.groupIndex = groupIndex;
				itemRenderer.itemIndex = itemIndex;
				itemRenderer.layoutIndex = layoutIndex;
				activeRenderers.push(itemRenderer);
				inactiveRenderers.splice(inactiveRenderers.indexOf(itemRenderer), 1);
				itemRenderer.visible = true;
				_layoutItems[layoutIndex] = DisplayObject(itemRenderer);
			}
			else
			{
				unrenderedItems.push(groupIndex);
				unrenderedItems.push(itemIndex);
				unrenderedItems.push(layoutIndex);
			}
		}

		private function renderUnrenderedData():void
		{
			var rendererCount:int = _unrenderedItems.length;
			for(var i:int = 0; i < rendererCount; i += 3)
			{
				var groupIndex:int = _unrenderedItems.shift() as int;
				var itemIndex:int = _unrenderedItems.shift() as int;
				var layoutIndex:int = _unrenderedItems.shift() as int;
				var item:Object = _dataProvider.getItemAt(groupIndex, itemIndex);
				var itemRenderer:IGroupedListItemRenderer = createItemRenderer(_inactiveItemRenderers,
					_activeItemRenderers, _itemRendererMap, _itemRendererType, _itemRendererFactory,
					_itemRendererName, item, groupIndex, itemIndex, layoutIndex, false);
				_layoutItems[layoutIndex] = DisplayObject(itemRenderer);
			}

			if(_unrenderedFirstItems)
			{
				rendererCount = _unrenderedFirstItems.length;
				for(i = 0; i < rendererCount; i += 3)
				{
					groupIndex = _unrenderedFirstItems.shift() as Number;
					itemIndex = _unrenderedFirstItems.shift() as Number;
					layoutIndex = _unrenderedFirstItems.shift() as Number;
					item = _dataProvider.getItemAt(groupIndex, itemIndex);
					var type:Type = _firstItemRendererType ? _firstItemRendererType : _itemRendererType;
					var factory:Function = _firstItemRendererFactory != null ? _firstItemRendererFactory : _itemRendererFactory;
					var name:String = _firstItemRendererName ? _firstItemRendererName : _itemRendererName;
					itemRenderer = createItemRenderer(_inactiveFirstItemRenderers, _activeFirstItemRenderers,
						_firstItemRendererMap, type, factory, name, item, groupIndex, itemIndex, layoutIndex, false);
					_layoutItems[layoutIndex] = DisplayObject(itemRenderer);
				}
			}

			if(_unrenderedLastItems)
			{
				rendererCount = _unrenderedLastItems.length;
				for(i = 0; i < rendererCount; i += 3)
				{
					groupIndex = _unrenderedLastItems.shift();
					itemIndex = _unrenderedLastItems.shift();
					layoutIndex = _unrenderedLastItems.shift();
					item = _dataProvider.getItemAt(groupIndex, itemIndex);
					type = _lastItemRendererType ? _lastItemRendererType : _itemRendererType;
					factory = _lastItemRendererFactory != null ? _lastItemRendererFactory : _itemRendererFactory;
					name = _lastItemRendererName ? _lastItemRendererName : _itemRendererName;
					itemRenderer = createItemRenderer(_inactiveLastItemRenderers, _activeLastItemRenderers,
						_lastItemRendererMap, type,  factory,  name, item, groupIndex, itemIndex, layoutIndex, false);
					_layoutItems[layoutIndex] = DisplayObject(itemRenderer);
				}
			}

			if(_unrenderedSingleItems)
			{
				rendererCount = _unrenderedSingleItems.length;
				for(i = 0; i < rendererCount; i += 3)
				{
					groupIndex = _unrenderedSingleItems.shift();
					itemIndex = _unrenderedSingleItems.shift();
					layoutIndex = _unrenderedSingleItems.shift();
					item = _dataProvider.getItemAt(groupIndex, itemIndex);
					type = _singleItemRendererType ? _singleItemRendererType : _itemRendererType;
					factory = _singleItemRendererFactory != null ? _singleItemRendererFactory : _itemRendererFactory;
					name = _singleItemRendererName ? _singleItemRendererName : _itemRendererName;
					itemRenderer = createItemRenderer(_inactiveSingleItemRenderers, _activeSingleItemRenderers,
						_singleItemRendererMap, type,  factory,  name, item, groupIndex, itemIndex, layoutIndex, false);
					_layoutItems[layoutIndex] = DisplayObject(itemRenderer);
				}
			}

			rendererCount = _unrenderedHeaders.length;
			for(i = 0; i < rendererCount; i += 2)
			{
				groupIndex = _unrenderedHeaders.shift();
				layoutIndex = _unrenderedHeaders.shift();
				item = _dataProvider.getItemAt(groupIndex);
				item = _owner.groupToHeaderData(item);
				var headerOrFooterRenderer:IGroupedListHeaderOrFooterRenderer = createHeaderRenderer(item, groupIndex, layoutIndex, false);
				_layoutItems[layoutIndex] = DisplayObject(headerOrFooterRenderer);
			}

			rendererCount = _unrenderedFooters.length;
			for(i = 0; i < rendererCount; i += 2)
			{
				groupIndex = _unrenderedFooters.shift();
				layoutIndex = _unrenderedFooters.shift();
				item = _dataProvider.getItemAt(groupIndex);
				item = _owner.groupToFooterData(item);
				headerOrFooterRenderer = createFooterRenderer(item, groupIndex, layoutIndex, false);
				_layoutItems[layoutIndex] = DisplayObject(headerOrFooterRenderer);
			}
		}

		private function recoverInactiveRenderers():void
		{
			var rendererCount:int = _inactiveItemRenderers.length;
			for(var i:int = 0; i < rendererCount; i++)
			{
				var itemRenderer:IGroupedListItemRenderer = _inactiveItemRenderers[i];
				_owner.dispatchEventWith(FeathersEventType.RENDERER_REMOVE, false, itemRenderer);
				//delete _itemRendererMap[itemRenderer.data];
				_itemRendererMap[itemRenderer.data] = null;
			}

			if(_inactiveFirstItemRenderers)
			{
				rendererCount = _inactiveFirstItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					itemRenderer = _inactiveFirstItemRenderers[i];
					_owner.dispatchEventWith(FeathersEventType.RENDERER_REMOVE, false, itemRenderer);
					//delete _firstItemRendererMap[itemRenderer.data];
					_firstItemRendererMap[itemRenderer.data] = null;
				}
			}

			if(_inactiveLastItemRenderers)
			{
				rendererCount = _inactiveLastItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					itemRenderer = _inactiveLastItemRenderers[i];
					_owner.dispatchEventWith(FeathersEventType.RENDERER_REMOVE, false, itemRenderer);
					//delete _lastItemRendererMap[itemRenderer.data];
					_lastItemRendererMap[itemRenderer.data] = null;
				}
			}

			if(_inactiveSingleItemRenderers)
			{
				rendererCount = _inactiveSingleItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					itemRenderer = _inactiveSingleItemRenderers[i];
					_owner.dispatchEventWith(FeathersEventType.RENDERER_REMOVE, false, itemRenderer);
					//delete _singleItemRendererMap[itemRenderer.data];
					_singleItemRendererMap[itemRenderer.data] = null;
				}
			}

			rendererCount = _inactiveHeaderRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				var headerOrFooterRenderer:IGroupedListHeaderOrFooterRenderer = _inactiveHeaderRenderers[i];
				_owner.dispatchEventWith(FeathersEventType.RENDERER_REMOVE, false, headerOrFooterRenderer);
				//delete _headerRendererMap[headerOrFooterRenderer.data];
				_headerRendererMap[headerOrFooterRenderer.data] = null;
			}

			rendererCount = _inactiveFooterRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				headerOrFooterRenderer = _inactiveFooterRenderers[i];
				_owner.dispatchEventWith(FeathersEventType.RENDERER_REMOVE, false, headerOrFooterRenderer);
				//delete _footerRendererMap[headerOrFooterRenderer.data];
				_footerRendererMap[headerOrFooterRenderer.data] = null;
			}
		}

		private function freeInactiveRenderers():void
		{
			//we may keep around some extra renderers to avoid too much
			//allocation and garbage collection. they'll be hidden.
			var keepCount:int = Math.min(_minimumItemCount - _activeItemRenderers.length, _inactiveItemRenderers.length);
			for(var i:int = 0; i < keepCount; i++)
			{
				var itemRenderer:IGroupedListItemRenderer = _inactiveItemRenderers.shift() as IGroupedListItemRenderer;
				itemRenderer.visible = false;
				_activeItemRenderers.push(itemRenderer);
			}
			var rendererCount:int = _inactiveItemRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				itemRenderer = _inactiveItemRenderers.shift();
				destroyItemRenderer(itemRenderer);
			}

			if(_activeFirstItemRenderers)
			{
				keepCount = Math.min(_minimumFirstAndLastItemCount - _activeFirstItemRenderers.length, _inactiveFirstItemRenderers.length);
				for(i = 0; i < keepCount; i++)
				{
					itemRenderer = _inactiveFirstItemRenderers.shift();
					itemRenderer.visible = false;
					_activeFirstItemRenderers.push(itemRenderer);
				}
				rendererCount = _inactiveFirstItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					itemRenderer = _inactiveFirstItemRenderers.shift();
					destroyItemRenderer(itemRenderer);
				}
			}

			if(_activeLastItemRenderers)
			{
				keepCount = Math.min(_minimumFirstAndLastItemCount - _activeLastItemRenderers.length, _inactiveLastItemRenderers.length);
				for(i = 0; i < keepCount; i++)
				{
					itemRenderer = _inactiveLastItemRenderers.shift();
					itemRenderer.visible = false;
					_activeLastItemRenderers.push(itemRenderer);
				}
				rendererCount = _inactiveLastItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					itemRenderer = _inactiveLastItemRenderers.shift();
					destroyItemRenderer(itemRenderer);
				}
			}

			if(_activeSingleItemRenderers)
			{
				keepCount = Math.min(_minimumSingleItemCount - _activeSingleItemRenderers.length, _inactiveSingleItemRenderers.length);
				for(i = 0; i < keepCount; i++)
				{
					itemRenderer = _inactiveSingleItemRenderers.shift();
					itemRenderer.visible = false;
					_activeSingleItemRenderers.push(itemRenderer);
				}
				rendererCount = _inactiveSingleItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					itemRenderer = _inactiveSingleItemRenderers.shift();
					destroyItemRenderer(itemRenderer);
				}
			}

			keepCount = Math.min(_minimumHeaderCount - _activeHeaderRenderers.length, _inactiveHeaderRenderers.length);
			for(i = 0; i < keepCount; i++)
			{
				var headerOrFooterRenderer:IGroupedListHeaderOrFooterRenderer = _inactiveHeaderRenderers.shift() as IGroupedListHeaderOrFooterRenderer;
				headerOrFooterRenderer.visible = false;
				_activeHeaderRenderers.push(headerOrFooterRenderer);
			}
			rendererCount = _inactiveHeaderRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				headerOrFooterRenderer = _inactiveHeaderRenderers.shift();
				destroyHeaderRenderer(headerOrFooterRenderer);
			}

			keepCount = Math.min(_minimumFooterCount - _activeFooterRenderers.length, _inactiveFooterRenderers.length);
			for(i = 0; i < keepCount; i++)
			{
				headerOrFooterRenderer = _inactiveFooterRenderers.shift();
				headerOrFooterRenderer.visible = false;
				_activeFooterRenderers.push(headerOrFooterRenderer);
			}
			rendererCount = _inactiveFooterRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				headerOrFooterRenderer = _inactiveFooterRenderers.shift();
				destroyFooterRenderer(headerOrFooterRenderer);
			}
		}

		private function createItemRenderer(inactiveRenderers:Vector.<IGroupedListItemRenderer>,
			activeRenderers:Vector.<IGroupedListItemRenderer>, rendererMap:Dictionary.<Object, IGroupedListItemRenderer>,
			_type:Type, factory:Function, name:String, item:Object, groupIndex:int, itemIndex:int,
			layoutIndex:int, isTemporary:Boolean = false):IGroupedListItemRenderer
		{
			if(isTemporary || inactiveRenderers.length == 0)
			{
				var renderer:IGroupedListItemRenderer;
				if(factory != null)
				{
					renderer = IGroupedListItemRenderer(factory.call());
				}
				else
				{
					renderer = _type.getConstructor().invoke() as IGroupedListItemRenderer;
				}
				var uiRenderer:IFeathersControl = IFeathersControl(renderer);
				if(name && name.length > 0)
				{
					uiRenderer.nameList.add(name);
				}
				addChild(DisplayObject(renderer));
			}
			else
			{
				renderer = inactiveRenderers.shift();
			}
			renderer.data = item;
			renderer.groupIndex = groupIndex;
			renderer.itemIndex = itemIndex;
			renderer.layoutIndex = layoutIndex;
			renderer.owner = _owner;
			renderer.visible = true;

			if(!isTemporary)
			{
				rendererMap[item] = renderer;
				activeRenderers.push(renderer);
				renderer.addEventListener(Event.CHANGE, renderer_changeHandler);
				renderer.addEventListener(FeathersEventType.RESIZE, itemRenderer_resizeHandler);
				_owner.dispatchEventWith(FeathersEventType.RENDERER_ADD, false, renderer);
			}

			return renderer;
		}

		private function createHeaderRenderer(header:Object, groupIndex:int, layoutIndex:int, isTemporary:Boolean = false):IGroupedListHeaderOrFooterRenderer
		{
			if(isTemporary || _inactiveHeaderRenderers.length == 0)
			{
				var renderer:IGroupedListHeaderOrFooterRenderer;
				if(_headerRendererFactory != null)
				{
					renderer = IGroupedListHeaderOrFooterRenderer(_headerRendererFactory.call());
				}
				else
				{
					renderer = _headerRendererType.getConstructor().invoke() as IGroupedListHeaderOrFooterRenderer;
				}
				var uiRenderer:IFeathersControl = IFeathersControl(renderer);
				if(_headerRendererName && _headerRendererName.length > 0)
				{
					uiRenderer.nameList.add(_headerRendererName);
				}
				addChild(DisplayObject(renderer));
			}
			else
			{
				renderer = _inactiveHeaderRenderers.shift();
			}
			renderer.data = header;
			renderer.groupIndex = groupIndex;
			renderer.layoutIndex = layoutIndex;
			renderer.owner = _owner;
			renderer.visible = true;

			if(!isTemporary)
			{
				_headerRendererMap[header] = renderer;
				_activeHeaderRenderers.push(renderer);
				renderer.addEventListener(FeathersEventType.RESIZE, headerOrFooterRenderer_resizeHandler);
				_owner.dispatchEventWith(FeathersEventType.RENDERER_ADD, false, renderer);
			}

			return renderer;
		}

		private function createFooterRenderer(footer:Object, groupIndex:int, layoutIndex:int, isTemporary:Boolean = false):IGroupedListHeaderOrFooterRenderer
		{
			if(isTemporary || _inactiveFooterRenderers.length == 0)
			{
				var renderer:IGroupedListHeaderOrFooterRenderer;
				if(_footerRendererFactory != null)
				{
					renderer = IGroupedListHeaderOrFooterRenderer(_footerRendererFactory.call());
				}
				else
				{
					renderer = _footerRendererType.getConstructor().invoke() as IGroupedListHeaderOrFooterRenderer;
				}
				var uiRenderer:IFeathersControl = IFeathersControl(renderer);
				if(_footerRendererName && _footerRendererName.length > 0)
				{
					uiRenderer.nameList.add(_footerRendererName);
				}
				addChild(DisplayObject(renderer));
			}
			else
			{
				renderer = _inactiveFooterRenderers.shift() as IGroupedListHeaderOrFooterRenderer;
			}
			renderer.data = footer;
			renderer.groupIndex = groupIndex;
			renderer.layoutIndex = layoutIndex;
			renderer.owner = _owner;
			renderer.visible = true;

			if(!isTemporary)
			{
				_footerRendererMap[footer] = renderer;
				_activeFooterRenderers.push(renderer);
				renderer.addEventListener(FeathersEventType.RESIZE, headerOrFooterRenderer_resizeHandler);
				_owner.dispatchEventWith(FeathersEventType.RENDERER_ADD, false, renderer);
			}

			return renderer;
		}

		private function destroyItemRenderer(renderer:IGroupedListItemRenderer):void
		{
			renderer.removeEventListener(Event.CHANGE, renderer_changeHandler);
			renderer.removeEventListener(FeathersEventType.RESIZE, itemRenderer_resizeHandler);
			renderer.owner = null;
			renderer.data = null;
			removeChild(DisplayObject(renderer), true);
		}

		private function destroyHeaderRenderer(renderer:IGroupedListHeaderOrFooterRenderer):void
		{
			renderer.removeEventListener(FeathersEventType.RESIZE, headerOrFooterRenderer_resizeHandler);
			renderer.owner = null;
			renderer.data = null;
			removeChild(DisplayObject(renderer), true);
		}

		private function destroyFooterRenderer(renderer:IGroupedListHeaderOrFooterRenderer):void
		{
			renderer.removeEventListener(FeathersEventType.RESIZE, headerOrFooterRenderer_resizeHandler);
			renderer.owner = null;
			renderer.data = null;
			removeChild(DisplayObject(renderer), true);
		}

		private function groupToHeaderDisplayIndex(groupIndex:int):int
		{
			var group:Object = _dataProvider.getItemAt(groupIndex);
			var header:Object = _owner.groupToHeaderData(group);
			if(!header)
			{
				return -1;
			}
			var displayIndex:int = 0;
			const groupCount:int = _dataProvider.getLength();
			for(var i:int = 0; i < groupCount; i++)
			{
				group = _dataProvider.getItemAt(i);
				header = _owner.groupToHeaderData(group);
				if(header)
				{
					if(groupIndex == i)
					{
						return displayIndex;
					}
					displayIndex++;
				}
				var groupLength:int = _dataProvider.getLength(i);
				for(var j:int = 0; j < groupLength; j++)
				{
					displayIndex++;
				}
				var footer:Object = _owner.groupToFooterData(group);
				if(footer)
				{
					displayIndex++;
				}
			}
			return -1;
		}

		private function groupToFooterDisplayIndex(groupIndex:int):int
		{
			var group:Object = _dataProvider.getItemAt(groupIndex);
			var footer:Object = _owner.groupToFooterData(group);
			if(!footer)
			{
				return -1;
			}
			var displayIndex:int = 0;
			const groupCount:int = _dataProvider.getLength();
			for(var i:int = 0; i < groupCount; i++)
			{
				group = _dataProvider.getItemAt(i);
				var header:Object = _owner.groupToHeaderData(group);
				if(header)
				{
					displayIndex++;
				}
				var groupLength:int = _dataProvider.getLength(i);
				for(var j:int = 0; j < groupLength; j++)
				{
					displayIndex++;
				}
				footer = _owner.groupToFooterData(group);
				if(footer)
				{
					if(groupIndex == i)
					{
						return displayIndex;
					}
					displayIndex++;
				}
			}
			return -1;
		}

		private function locationToDisplayIndex(groupIndex:int, itemIndex:int):int
		{
			var displayIndex:int = 0;
			const groupCount:int = _dataProvider.getLength();
			for(var i:int = 0; i < groupCount; i++)
			{
				var group:Object = _dataProvider.getItemAt(i);
				var header:Object = _owner.groupToHeaderData(group);
				if(header)
				{
					displayIndex++;
				}
				var groupLength:int = _dataProvider.getLength(i);
				for(var j:int = 0; j < groupLength; j++)
				{
					if(groupIndex == i && itemIndex == j)
					{
						return displayIndex;
					}
					displayIndex++;
				}
				var footer:Object = _owner.groupToFooterData(group);
				if(footer)
				{
					displayIndex++;
				}
			}
			return -1;
		}

		private function owner_scrollHandler(event:Event):void
		{
			_isScrolling = true;
		}

		private function dataProvider_changeHandler(event:Event):void
		{
			invalidate(INVALIDATION_FLAG_DATA);
			invalidateParent();
		}

		private function dataProvider_addItemHandler(event:Event, indices:Array):void
		{
			const layout:IVariableVirtualLayout = _layout as IVariableVirtualLayout;
			if(!layout || !layout.hasVariableItemDimensions)
			{
				return;
			}
			const groupIndex:int = indices[0] as int;
			if(indices.length > 1) //adding an item
			{
				const itemIndex:int = indices[1] as int;
				const itemDisplayIndex:int = locationToDisplayIndex(groupIndex, itemIndex);
				layout.addToVariableVirtualCacheAtIndex(itemDisplayIndex);
			}
			else //adding a whole group
			{
				const headerDisplayIndex:int = groupToHeaderDisplayIndex(groupIndex);
				if(headerDisplayIndex >= 0)
				{
					layout.addToVariableVirtualCacheAtIndex(headerDisplayIndex);
				}
				var groupLength:int = _dataProvider.getLength(groupIndex);
				if(groupLength > 0)
				{
					var displayIndex:int = headerDisplayIndex;
					if(displayIndex < 0)
					{
						displayIndex = locationToDisplayIndex(groupIndex, 0);
					}
					groupLength += displayIndex;
					for(var i:int = displayIndex; i < groupLength; i++)
					{
						layout.addToVariableVirtualCacheAtIndex(displayIndex);
					}
				}
				const footerDisplayIndex:int = groupToFooterDisplayIndex(groupIndex);
				if(footerDisplayIndex >= 0)
				{
					layout.addToVariableVirtualCacheAtIndex(footerDisplayIndex);
				}
			}
		}

		private function dataProvider_removeItemHandler(event:Event, indices:Array):void
		{
			const layout:IVariableVirtualLayout = _layout as IVariableVirtualLayout;
			if(!layout || !layout.hasVariableItemDimensions)
			{
				return;
			}
			const groupIndex:int = indices[0] as int;
			if(indices.length > 1) //removing an item
			{
				const itemIndex:int = indices[1] as int;
				const displayIndex:int = locationToDisplayIndex(groupIndex, itemIndex);
				layout.removeFromVariableVirtualCacheAtIndex(displayIndex);
			}
			else //removing a whole group
			{
				//TODO: figure out the length of the previous group so that we
				//don't need to reset the whole cache
				layout.resetVariableVirtualCache();
			}
		}

		private function dataProvider_replaceItemHandler(event:Event, indices:Array):void
		{
			const layout:IVariableVirtualLayout = _layout as IVariableVirtualLayout;
			if(!layout || !layout.hasVariableItemDimensions)
			{
				return;
			}
			const groupIndex:int = indices[0] as int;
			if(indices.length > 1) //replacing an item
			{
				const itemIndex:int = indices[1] as int;
				const displayIndex:int = locationToDisplayIndex(groupIndex, itemIndex);
				layout.resetVariableVirtualCacheAtIndex(displayIndex);
			}
			else //replacing a whole group
			{
				//TODO: figure out the length of the previous group so that we
				//don't need to reset the whole cache
				layout.resetVariableVirtualCache();
			}
		}

		private function dataProvider_resetHandler(event:Event):void
		{
			const layout:IVariableVirtualLayout = _layout as IVariableVirtualLayout;
			if(!layout || !layout.hasVariableItemDimensions)
			{
				return;
			}
			layout.resetVariableVirtualCache();
		}

		private function dataProvider_updateItemHandler(event:Event, indices:Array):void
		{
			const groupIndex:int = indices[0] as int;
			if(indices.length > 1) //updating a whole group
			{
				const itemIndex:int = indices[1] as int;
				const item:Object = _dataProvider.getItemAt(groupIndex, itemIndex);
				var renderer:IGroupedListItemRenderer = IGroupedListItemRenderer(_itemRendererMap[item]);
				if(!renderer)
				{
					if(_firstItemRendererMap)
					{
						renderer = IGroupedListItemRenderer(_firstItemRendererMap[item]);
					}
					if(!renderer)
					{
						if(_lastItemRendererMap)
						{
							renderer = IGroupedListItemRenderer(_lastItemRendererMap[item]);
						}
						if(!renderer)
						{
							if(_singleItemRendererMap)
							{
								renderer = IGroupedListItemRenderer(_singleItemRendererMap[item]);
							}
							if(!renderer)
							{
								return;
							}
						}
					}
				}
				renderer.data = null;
				renderer.data = item;
			}
			else //updating a whole group
			{
				const layout:IVariableVirtualLayout = _layout as IVariableVirtualLayout;
				if(!layout || !layout.hasVariableItemDimensions)
				{
					return;
				}
				//TODO: figure out the length of the previous group so that we
				//don't need to reset the whole cache
				layout.resetVariableVirtualCache();
			}
		}

		private function layout_changeHandler(event:Event):void
		{
			if(_ignoreLayoutChanges)
			{
				return;
			}
			invalidate(INVALIDATION_FLAG_SCROLL);
			invalidateParent();
		}

		private function itemRenderer_resizeHandler(event:Event):void
		{
			if(_ignoreRendererResizing)
			{
				return;
			}
			const layout:IVariableVirtualLayout = _layout as IVariableVirtualLayout;
			if(!layout || !layout.hasVariableItemDimensions)
			{
				return;
			}
			const renderer:IGroupedListItemRenderer = IGroupedListItemRenderer(event.currentTarget);
			layout.resetVariableVirtualCacheAtIndex(renderer.layoutIndex, DisplayObject(renderer));
			invalidate(INVALIDATION_FLAG_SCROLL);
			invalidateParent();
		}

		private function headerOrFooterRenderer_resizeHandler(event:Event):void
		{
			if(_ignoreRendererResizing)
			{
				return;
			}
			const layout:IVariableVirtualLayout = _layout as IVariableVirtualLayout;
			if(!layout || !layout.hasVariableItemDimensions)
			{
				return;
			}
			const renderer:IGroupedListHeaderOrFooterRenderer = IGroupedListHeaderOrFooterRenderer(event.currentTarget);
			layout.resetVariableVirtualCacheAtIndex(renderer.layoutIndex, DisplayObject(renderer));
			invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private function renderer_changeHandler(event:Event):void
		{
			if(_ignoreSelectionChanges)
			{
				return;
			}
			const renderer:IGroupedListItemRenderer = IGroupedListItemRenderer(event.currentTarget);
			const isAlreadySelected:Boolean = _selectedGroupIndex == renderer.groupIndex &&
				_selectedItemIndex == renderer.itemIndex;
			if(!_isSelectable || _isScrolling || isAlreadySelected)
			{
				//reset to the old value
				renderer.isSelected = isAlreadySelected;
				return;
			}
			setSelectedLocation(renderer.groupIndex, renderer.itemIndex);
		}

		private function removedFromStageHandler(event:Event):void
		{
			touchPointID = -1;
		}

		private function touchHandler(event:TouchEvent):void
		{
			if(!_isEnabled)
			{
				touchPointID = -1;
				return;
			}

			const touches:Vector.<Touch> = event.getTouches(this, null, HELPER_TOUCHES_VECTOR);
			if(touches.length == 0)
			{
				return;
			}
			if(touchPointID >= 0)
			{
				var touch:Touch;
				for each(var currentTouch:Touch in touches)
				{
					if(currentTouch.id == touchPointID)
					{
						touch = currentTouch;
						break;
					}
				}
				if(!touch)
				{
					HELPER_TOUCHES_VECTOR.length = 0;
					return;
				}
				if(touch.phase == TouchPhase.ENDED)
				{
					touchPointID = -1;
				}
			}
			else
			{
				for each(touch in touches)
				{
					if(touch.phase == TouchPhase.BEGAN)
					{
						touchPointID = touch.id;
						_isScrolling = false;
						break;
					}
				}
			}
			HELPER_TOUCHES_VECTOR.length = 0;
		}
	}
}
