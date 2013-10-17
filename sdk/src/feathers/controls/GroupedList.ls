/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
	import feathers.controls.renderers.DefaultGroupedListHeaderOrFooterRenderer;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.supportClasses.GroupedListDataViewPort;
	import feathers.core.IFocusDisplayObject;
	import feathers.data.HierarchicalCollection;
	import feathers.events.CollectionEventType;
	import feathers.layout.ILayout;
	import feathers.layout.VerticalLayout;

	import loom2d.math.Point;
	//import flash.ui.Keyboard;

	import loom2d.events.Event;
	import loom2d.events.KeyboardEvent;

	/**
	 * Dispatched when the selected item changes.
	 *
	 * @eventType loom2d.events.Event.CHANGE
	 */
	[Event(name="change",type="loom2d.events.Event")]

	/**
	 * Dispatched when an item renderer is added to the list. When the layout is
	 * virtualized, item renderers may not exist for every item in the data
	 * provider. This event can be used to track which items currently have
	 * renderers.
	 *
	 * @eventType feathers.events.FeathersEventType.RENDERER_ADD
	 */
	[Event(name="rendererAdd",type="loom2d.events.Event")]

	/**
	 * Dispatched when an item renderer is removed from the list. When the layout is
	 * virtualized, item renderers may not exist for every item in the data
	 * provider. This event can be used to track which items currently have
	 * renderers.
	 *
	 * @eventType feathers.events.FeathersEventType.RENDERER_REMOVE
	 */
	[Event(name="rendererRemove",type="loom2d.events.Event")]

	[DefaultProperty(value="dataProvider")]
	/**
	 * Displays a list of items divided into groups or sections. Takes a
	 * hierarchical provider limited to two levels of hierarchy. This component
	 * supports scrolling, custom item (and header and footer) renderers, and
	 * custom layouts.
	 *
	 * Layouts may be, and are highly encouraged to be, _virtual_,
	 * meaning that the List is capable of creating a limited number of item
	 * renderers to display a subset of the data provider instead of creating a
	 * renderer for every single item. This allows for optimal performance with
	 * very large data providers.
	 *
	 * The following example creates a grouped list, gives it a data
	 * provider, and listens for when the selection changes:
	 *
	 * ~~~as3
	 * var list:GroupedList = new GroupedList();
	 * list.dataProvider = new HierarchicalCollection(
	 * {
	 *     header: "A",
	 *     children:
	 *     [
	 *         { text: "Aardvark" },
	 *         { text: "Alligator" }
	 *     ]
	 * },
	 * {
	 *     header: "B",
	 *     children:
	 *     [
	 *         { text: "Baboon" }
	 *     ]
	 * });
	 * list.addEventListener( Event.CHANGE, list_changeHandler );
	 * this.addChild( list );
         * ~~~
	 *
	 * @see http://wiki.starling-framework.org/feathers/grouped-list
	 */
	public class GroupedList extends Scroller implements IFocusDisplayObject
	{
		/**
		 * @private
		 */
		private static const HELPER_POINT:Point = new Point();

		/**
		 * An alternate name to use with GroupedList to allow a theme to give it
		 * an inset style. If a theme does not provide a skin for the inset
		 * grouped list, the theme will automatically fall back to using the
		 * default grouped list skin.
		 *
		 * An alternate name should always be added to a component's
		 * `nameList` before the component is added to the stage for
		 * the first time.
		 *
		 * In the following example, the inset style is applied to a grouped
		 * list:
		 *
		 * ~~~as3
		 * var list:GroupedList = new GroupedList();
		 * list.nameList.add( GroupedList.ALTERNATE_NAME_INSET_GROUPED_LIST );
		 * this.addChild( list );
         * ~~~
		 *
		 * @see feathers.core.IFeathersControl#nameList
		 */
		public static const ALTERNATE_NAME_INSET_GROUPED_LIST:String = "feathers-inset-grouped-list";

		/**
		 * The default name to use with header renderers.
		 *
		 * @see feathers.core.IFeathersControl#nameList
		 */
		public static const DEFAULT_CHILD_NAME_HEADER_RENDERER:String = "feathers-grouped-list-header-renderer";

		/**
		 * An alternate name to use with header renderers to give them an inset
		 * style. This name is usually only referenced inside themes.
		 *
		 * In the following example, the inset style is applied to a grouped
		 * list's header:
		 *
		 * ~~~as3
		 * list.headerRendererName = GroupedList.ALTERNATE_CHILD_NAME_INSET_HEADER_RENDERER;
         * ~~~
		 *
		 * @see feathers.core.IFeathersControl#nameList
		 */
		public static const ALTERNATE_CHILD_NAME_INSET_HEADER_RENDERER:String = "feathers-grouped-list-inset-header-renderer";

		/**
		 * The default name to use with footer renderers.
		 *
		 * @see feathers.core.IFeathersControl#nameList
		 */
		public static const DEFAULT_CHILD_NAME_FOOTER_RENDERER:String = "feathers-grouped-list-footer-renderer";

		/**
		 * An alternate name to use with footer renderers to give them an inset
		 * style. This name is usually only referenced inside themes.
		 *
		 * In the following example, the inset style is applied to a grouped
		 * list's footer:
		 *
		 * ~~~as3
		 * list.footerRendererName = GroupedList.ALTERNATE_CHILD_NAME_INSET_FOOTER_RENDERER;
         * ~~~
		 */
		public static const ALTERNATE_CHILD_NAME_INSET_FOOTER_RENDERER:String = "feathers-grouped-list-inset-footer-renderer";

		/**
		 * An alternate name to use with item renderers to give them an inset
		 * style. This name is usually only referenced inside themes.
		 *
		 * In the following example, the inset style is applied to a grouped
		 * list's item renderer:
		 *
		 * ~~~as3
		 * list.itemRendererRendererName = GroupedList.ALTERNATE_CHILD_NAME_INSET_ITEM_RENDERER;
         * ~~~
		 *
		 * @see feathers.core.IFeathersControl#nameList
		 */
		public static const ALTERNATE_CHILD_NAME_INSET_ITEM_RENDERER:String = "feathers-grouped-list-inset-item-renderer";

		/**
		 * An alternate name to use for item renderers to give them an inset
		 * style. Typically meant to be used for the renderer of the first item
		 * in a group. This name is usually only referenced inside themes.
		 *
		 * In the following example, the inset style is applied to a grouped
		 * list's first item renderer:
		 *
		 * ~~~as3
		 * list.firstItemRendererRendererName = GroupedList.ALTERNATE_CHILD_NAME_INSET_FIRST_ITEM_RENDERER;
         * ~~~
		 *
		 * @see feathers.core.IFeathersControl#nameList
		 */
		public static const ALTERNATE_CHILD_NAME_INSET_FIRST_ITEM_RENDERER:String = "feathers-grouped-list-inset-first-item-renderer";

		/**
		 * An alternate name to use for item renderers to give them an inset
		 * style. Typically meant to be used for the renderer of the last item
		 * in a group. This name is usually only referenced inside themes.
		 *
		 * In the following example, the inset style is applied to a grouped
		 * list's last item renderer:
		 *
		 * ~~~as3
		 * list.lastItemRendererRendererName = GroupedList.ALTERNATE_CHILD_NAME_INSET_LAST_ITEM_RENDERER;
         * ~~~
		 *
		 * @see feathers.core.IFeathersControl#nameList
		 */
		public static const ALTERNATE_CHILD_NAME_INSET_LAST_ITEM_RENDERER:String = "feathers-grouped-list-inset-last-item-renderer";

		/**
		 * An alternate name to use for item renderers to give them an inset
		 * style. Typically meant to be used for the renderer of an item in a
		 * group that has no other items. This name is usually only referenced
		 * inside themes.
		 *
		 * In the following example, the inset style is applied to a grouped
		 * list's single item renderer:
		 *
		 * ~~~as3
		 * list.singleItemRendererName = GroupedList.ALTERNATE_CHILD_NAME_INSET_SINGLE_ITEM_RENDERER;
         * ~~~
		 *
		 * @see feathers.core.IFeathersControl#nameList
		 */
		public static const ALTERNATE_CHILD_NAME_INSET_SINGLE_ITEM_RENDERER:String = "feathers-grouped-list-inset-single-item-renderer";

		/**
		 * @copy feathers.controls.Scroller#SCROLL_POLICY_AUTO
		 *
		 * @see feathers.controls.Scroller#horizontalScrollPolicy
		 * @see feathers.controls.Scroller#verticalScrollPolicy
		 */
		public static const SCROLL_POLICY_AUTO:String = "auto";

		/**
		 * @copy feathers.controls.Scroller#SCROLL_POLICY_ON
		 *
		 * @see feathers.controls.Scroller#horizontalScrollPolicy
		 * @see feathers.controls.Scroller#verticalScrollPolicy
		 */
		public static const SCROLL_POLICY_ON:String = "on";

		/**
		 * @copy feathers.controls.Scroller#SCROLL_POLICY_OFF
		 *
		 * @see feathers.controls.Scroller#horizontalScrollPolicy
		 * @see feathers.controls.Scroller#verticalScrollPolicy
		 */
		public static const SCROLL_POLICY_OFF:String = "off";

		/**
		 * @copy feathers.controls.Scroller#SCROLL_BAR_DISPLAY_MODE_FLOAT
		 *
		 * @see feathers.controls.Scroller#scrollBarDisplayMode
		 */
		public static const SCROLL_BAR_DISPLAY_MODE_FLOAT:String = "float";

		/**
		 * @copy feathers.controls.Scroller#SCROLL_BAR_DISPLAY_MODE_FIXED
		 *
		 * @see feathers.controls.Scroller#scrollBarDisplayMode
		 */
		public static const SCROLL_BAR_DISPLAY_MODE_FIXED:String = "fixed";

		/**
		 * @copy feathers.controls.Scroller#SCROLL_BAR_DISPLAY_MODE_NONE
		 *
		 * @see feathers.controls.Scroller#scrollBarDisplayMode
		 */
		public static const SCROLL_BAR_DISPLAY_MODE_NONE:String = "none";

		/**
		 * @copy feathers.controls.Scroller#INTERACTION_MODE_TOUCH
		 *
		 * @see feathers.controls.Scroller#interactionMode
		 */
		public static const INTERACTION_MODE_TOUCH:String = "touch";

		/**
		 * @copy feathers.controls.Scroller#INTERACTION_MODE_MOUSE
		 *
		 * @see feathers.controls.Scroller#interactionMode
		 */
		public static const INTERACTION_MODE_MOUSE:String = "mouse";

		/**
		 * Constructor.
		 */
		public function GroupedList()
		{
			super();
		}

		/**
		 * @private
		 * The guts of the List's functionality. Handles layout and selection.
		 */
		protected var dataViewPort:GroupedListDataViewPort;

		/**
		 * @private
		 */
		protected var _layout:ILayout;

		/**
		 * The layout algorithm used to position and, optionally, size the
		 * list's items.
		 *
		 * The following example tells the list to use a horizontal layout:
		 *
		 * ~~~as3
		 * var layout:HorizontalLayout = new HorizontalLayout();
		 * layout.gap = 20;
		 * layout.padding = 20;
		 * list.layout = layout;
         * ~~~
		 */
		public function get layout():ILayout
		{
			return this._layout;
		}

		/**
		 * @private
		 */
		public function set layout(value:ILayout):void
		{
			if(this._layout == value)
			{
				return;
			}
			this._layout = value;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
		}

		/**
		 * @private
		 */
		protected var _dataProvider:HierarchicalCollection;

		/**
		 * The collection of data displayed by the list.
		 *
		 * The following example passes in a data provider:
		 *
		 * ~~~as3
		 * list.dataProvider = new HierarchicalCollection(
		 * {
		 *     header: "A",
		 *     children:
		 *     [
		 *         { text: "Aardvark" },
		 *         { text: "Alligator" }
		 *     ]
		 * },
		 * {
		 *     header: "B",
		 *     children:
		 *     [
		 *         { text: "Baboon" }
		 *     ]
		 * });
         * ~~~
		 *
		 * By default, a `HierarchicalCollection` accepts an
		 * `Array` containing objects for each group. By default, the
		 * `header` and `footer` fields in each group will
		 * contain data to pass to the header and footer renderers of the
		 * grouped list. The `children` field of each group should be
		 * be an `Array` of data where each item is passed to an item
		 * renderer.
		 *
		 * A custom _data descriptor_ may be passed to the
		 * `HierarchicalCollection` to tell it to parse the data
		 * source differently than the default behavior described above. For
		 * instance, you might want to use `Vector` instead of
		 * `Array` or structure the data differently. Custom data
		 * descriptors may be implemented with the
		 * `IHierarchicalCollectionDataDescriptor` interface.
		 *
		 * @see feathers.data.HierarchicalCollection
		 * @see feathers.data.IHierarchicalCollectionDataDescriptor
		 */
		public function get dataProvider():HierarchicalCollection
		{
			return this._dataProvider;
		}

		/**
		 * @private
		 */
		public function set dataProvider(value:HierarchicalCollection):void
		{
			if(this._dataProvider == value)
			{
				return;
			}
			if(this._dataProvider)
			{
				this._dataProvider.removeEventListener(CollectionEventType.RESET, dataProvider_resetHandler);
			}
			this._dataProvider = value;
			if(this._dataProvider)
			{
				this._dataProvider.addEventListener(CollectionEventType.RESET, dataProvider_resetHandler);
			}

			//reset the scroll position because this is a drastic change and
			//the data is probably completely different
			this.horizontalScrollPosition = 0;
			this.verticalScrollPosition = 0;

			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _isSelectable:Boolean = true;

		/**
		 * Determines if an item in the list may be selected.
		 *
		 * The following example disables selection:
		 *
		 * ~~~as3
	 	 * list.isSelectable = false;
         * ~~~
		 */
		public function get isSelectable():Boolean
		{
			return this._isSelectable;
		}

		/**
		 * @private
		 */
		public function set isSelectable(value:Boolean):void
		{
			if(this._isSelectable == value)
			{
				return;
			}
			this._isSelectable = value;
			if(!this._isSelectable)
			{
				this.setSelectedLocation(-1, -1);
			}
			this.invalidate(INVALIDATION_FLAG_SELECTED);
		}

		/**
		 * @private
		 */
		protected var _selectedGroupIndex:int = -1;

		/**
		 * The group index of the currently selected item. Returns -1 if no item
		 * is selected.
		 *
		 * The following example listens for when selection changes and
		 * requests the selected group index and selected item index:
		 *
		 * ~~~as3
		 * function list_changeHandler( event:Event ):void
		 * {
		 *     var list:List = List(event.currentTarget);
		 *     var groupIndex:int = list.selectedGroupIndex;
		 *     var itemIndex:int = list.selectedItemIndex;
		 *
		 * }
		 * list.addEventListener( Event.CHANGE, list_changeHandler );
         * ~~~
		 *
		 * @see #selectedItemIndex
		 */
		public function get selectedGroupIndex():int
		{
			return this._selectedGroupIndex;
		}

		/**
		 * @private
		 */
		protected var _selectedItemIndex:int = -1;

		/**
		 * The item index of the currently selected item. Returns -1 if no item
		 * is selected.
		 *
		 * The following example listens for when selection changes and
		 * requests the selected group index and selected item index:
		 *
		 * ~~~as3
		 * function list_changeHandler( event:Event ):void
		 * {
		 *     var list:List = List(event.currentTarget);
		 *     var groupIndex:int = list.selectedGroupIndex;
		 *     var itemIndex:int = list.selectedItemIndex;
		 *
		 * }
		 * list.addEventListener( Event.CHANGE, list_changeHandler );
         * ~~~
		 *
		 * @see #selectedGroupIndex
		 */
		public function get selectedItemIndex():int
		{
			return this._selectedItemIndex;
		}

		/**
		 * The currently selected item. Returns null if no item is selected.
		 *
		 * The following example listens for when selection changes and
		 * requests the selected item:
		 *
		 * ~~~as3
		 * function list_changeHandler( event:Event ):void
		 * {
		 *     var list:List = List(event.currentTarget);
		 *     var selectedItem:Object = list.selectedItem;
		 *
		 * }
		 * list.addEventListener( Event.CHANGE, list_changeHandler );
         * ~~~
		 */
		public function get selectedItem():Object
		{
			if(!this._dataProvider || this._selectedGroupIndex < 0 || this._selectedItemIndex < 0)
			{
				return null;
			}

			return this._dataProvider.getItemAt(this._selectedGroupIndex, this._selectedItemIndex);
		}

		/**
		 * @private
		 */
		public function set selectedItem(value:Object):void
		{
			const result:Vector.<int> = this._dataProvider.getItemLocation(value);
			if(result.length == 2)
			{
				this.setSelectedLocation(result[0], result[1]);
			}
			else
			{
				this.setSelectedLocation(-1, -1);
			}
		}

		/**
		 * @private
		 */
		protected var _itemRendererType:Type = DefaultGroupedListItemRenderer;

		/**
		 * The class used to instantiate item renderers. Must implement the
		 * `IGroupedListItemRenderer` interface.
		 *
		 * The following example changes the item renderer type:
		 *
		 * ~~~as3
		 * list.itemRendererType = CustomItemRendererClass;
         * ~~~
		 *
		 * The first item and last item in a group may optionally use
		 * different item renderer types, if desired. Use the
		 * `firstItemRendererType` and `lastItemRendererType`,
		 * respectively. Additionally, if a group contains only one item, it may
		 * also have a different type. Use the `singleItemRendererType`.
		 * Finally, factories for each of these types may also be customized.
		 *
		 * @see feathers.controls.renderer.IGroupedListItemRenderer
		 * @see #itemRendererFactory
		 * @see #firstItemRendererType
		 * @see #lastItemRendererType
		 * @see #singleItemRendererType
		 */
		public function get itemRendererType():Type
		{
			return this._itemRendererType;
		}

		/**
		 * @private
		 */
		public function set itemRendererType(value:Type):void
		{
			if(this._itemRendererType == value)
			{
				return;
			}

			this._itemRendererType = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _itemRendererFactory:Function;

		/**
		 * A function called that is expected to return a new item renderer. Has
		 * a higher priority than `itemRendererType`. Typically, you
		 * would use an `itemRendererFactory` instead of an
		 * `itemRendererType` if you wanted to initialize some
		 * properties on each separate item renderer, such as skins.
		 *
		 * The function is expected to have the following signature:
		 *
		 * `function():IGroupedListItemRenderer`
		 *
		 * The following example provides a factory for the item renderer:
		 *
		 * ~~~as3
		 * list.itemRendererFactory = function():IGroupedListItemRenderer
		 * {
		 *     var renderer:CustomItemRendererClass = new CustomItemRendererClass();
		 *     renderer.backgroundSkin = new Quad( 10, 10, 0xff0000 );
		 *     return renderer;
		 * };
         * ~~~
		 *
		 * The first item and last item in a group may optionally use
		 * different item renderer factories, if desired. Use the
		 * `firstItemRendererFactory` and `lastItemRendererFactory`,
		 * respectively. Additionally, if a group contains only one item, it may
		 * also have a different factory. Use the `singleItemRendererFactory`.
		 *
		 * @see feathers.controls.renderers.IGroupedListItemRenderer
		 * @see #itemRendererType
		 * @see #firstItemRendererFactory
		 * @see #lastItemRendererFactory
		 * @see #singleItemRendererFactory
		 */
		public function get itemRendererFactory():Function
		{
			return this._itemRendererFactory;
		}

		/**
		 * @private
		 */
		public function set itemRendererFactory(value:Function):void
		{
			if(this._itemRendererFactory == value)
			{
				return;
			}

			this._itemRendererFactory = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _typicalItem:Object = null;

		/**
		 * An item used to create a sample item renderer used for virtual layout
		 * measurement.
		 *
		 * The following example provides a typical item:
		 *
		 * ~~~as3
		 * list.typicalItem = { text: "A typical item", icon: texture };
		 * list.itemRendererProperties.labelField = "text";
		 * list.itemRendererProperties.iconSourceField = "icon";
         * ~~~
		 */
		public function get typicalItem():Object
		{
			return this._typicalItem;
		}

		/**
		 * @private
		 */
		public function set typicalItem(value:Object):void
		{
			if(this._typicalItem == value)
			{
				return;
			}
			this._typicalItem = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _itemRendererName:String;

		/**
		 * A name to add to all item renderers in this list. Typically used by a
		 * theme to provide different skins to different lists.
		 *
		 * The following example sets the item renderer name:
		 *
		 * ~~~as3
		 * list.itemRendererName = "my-custom-item-renderer-name";
         * ~~~
		 *
		 * In your theme, you can target this item renderer name to provide
		 * different skins than the default style:
		 *
		 * ~~~as3
		 * setInitializerForClass( DefaultListItemRenderer, customItemRendererInitializer, "my-custom-item-renderer-name");
         * ~~~
		 *
		 * @see feathers.core.FeathersControl#nameList
		 * @see #firstItemRendererName
		 * @see #lastItemRendererName
		 * @see #singleItemRendererName
		 */
		public function get itemRendererName():String
		{
			return this._itemRendererName;
		}

		/**
		 * @private
		 */
		public function set itemRendererName(value:String):void
		{
			if(this._itemRendererName == value)
			{
				return;
			}
			this._itemRendererName = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _itemRendererProperties:Dictionary.<String, Object>;

		/**
		 * A set of key/value pairs to be passed down to all of the list's item
		 * renderers. These values are shared by each item renderer, so values
		 * that cannot be shared (such as display objects that need to be added
		 * to the display list) should be passed to the item renderers using the
		 * `itemRendererFactory` or with a theme. The item renderers
		 * are instances of `IGroupedListItemRenderer`. The available
		 * properties depend on which `IGroupedListItemRenderer`
		 * implementation is returned by `itemRendererFactory`.
		 *
		 * The following example customizes some item renderer properties:
		 *
		 * ~~~as3
		 * list.itemRendererProperties.&#64;defaultLabelProperties.textFormat = new BitmapFontTextFormat( bitmapFont );
		 * list.itemRendererProperties.padding = 20;
         * ~~~
		 *
		 * If the subcomponent has its own subcomponents, their properties
		 * can be set too, using attribute `&#64;` notation. For example,
		 * to set the skin on the thumb of a `SimpleScrollBar`
		 * which is in a `Scroller` which is in a `List`,
		 * you can use the following syntax:
		 * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
		 *
		 * Setting properties in a `itemRendererFactory` function instead
		 * of using `itemRendererProperties` will result in better
		 * performance.
		 *
		 * @see #itemRendererFactory
		 * @see feathers.controls.renderers.IGroupedListItemRenderer
		 * @see feathers.controls.renderers.DefaultGroupedListItemRenderer
		 */
		public function get itemRendererProperties():Dictionary.<String, Object>
		{
			if(!this._itemRendererProperties)
			{
				this._itemRendererProperties = new Dictionary.<String, Object>();
			}
			return this._itemRendererProperties;
		}

		/**
		 * @private
		 */
		public function set itemRendererProperties(value:Dictionary.<String, Object>):void
		{
			if(this._itemRendererProperties == value)
			{
				return;
			}
			this._itemRendererProperties = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _firstItemRendererType:Type;

		/**
		 * The class used to instantiate the item renderer for the first item in
		 * a group. Must implement the `IGroupedListItemRenderer`
		 * interface.
		 *
		 * The following example changes the first item renderer type:
		 *
		 * ~~~as3
		 * list.firstItemRendererType = CustomItemRendererClass;
         * ~~~
		 *
		 * @see feathers.controls.renderer.IGroupedListItemRenderer
		 * @see #itemRendererType
		 * @see #lastItemRendererType
		 * @see #singleItemRendererType
		 */
		public function get firstItemRendererType():Type
		{
			return this._firstItemRendererType;
		}

		/**
		 * @private
		 */
		public function set firstItemRendererType(value:Type):void
		{
			if(this._firstItemRendererType == value)
			{
				return;
			}

			this._firstItemRendererType = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _firstItemRendererFactory:Function;

		/**
		 * A function called that is expected to return a new item renderer for
		 * the first item in a group. Has a higher priority than
		 * `firstItemRendererType`. Typically, you would use an
		 * `firstItemRendererFactory` instead of an
		 * `firstItemRendererType` if you wanted to initialize some
		 * properties on each separate item renderer, such as skins.
		 *
		 * The function is expected to have the following signature:
		 *
		 * `function():IGroupedListItemRenderer`
		 *
		 * The following example provides a factory for the item renderer
		 * used for the first item in a group:
		 *
		 * ~~~as3
		 * list.firstItemRendererFactory = function():IGroupedListItemRenderer
		 * {
		 *     var renderer:CustomItemRendererClass = new CustomItemRendererClass();
		 *     renderer.backgroundSkin = new Quad( 10, 10, 0xff0000 );
		 *     return renderer;
		 * };
         * ~~~
		 *
		 * @see feathers.controls.renderers.IGroupedListItemRenderer
		 * @see #firstItemRendererType
		 * @see #itemRendererFactory
		 * @see #lastItemRendererFactory
		 * @see #singleItemRendererFactory
		 */
		public function get firstItemRendererFactory():Function
		{
			return this._firstItemRendererFactory;
		}

		/**
		 * @private
		 */
		public function set firstItemRendererFactory(value:Function):void
		{
			if(this._firstItemRendererFactory == value)
			{
				return;
			}

			this._firstItemRendererFactory = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _firstItemRendererName:String;

		/**
		 * A name to add to all item renderers in this list that are the first
		 * item in a group. Typically used by a theme to provide different skins
		 * to different lists, and to differentiate first items from regular
		 * items if they are created with the same class. If this value is null
		 * the regular `itemRendererName` will be used instead.
		 *
		 * The following example provides an name for the first item renderer
		 * in a group:
		 *
		 * ~~~as3
		 * list.firstItemRendererName = "my-custom-first-item-renderer-name";
         * ~~~
		 *
		 * In your theme, you can target this item renderer name to provide
		 * different skins than the default style:
		 *
		 * ~~~as3
		 * setInitializerForClass( DefaultListItemRenderer, customFirstItemRendererInitializer, "my-custom-first-item-renderer-name");
         * ~~~
		 *
		 * @see feathers.core.FeathersControl#nameList
		 * @see #itemRendererName
		 * @see #lastItemRendererName
		 * @see #singleItemRendererName
		 */
		public function get firstItemRendererName():String
		{
			return this._firstItemRendererName;
		}

		/**
		 * @private
		 */
		public function set firstItemRendererName(value:String):void
		{
			if(this._firstItemRendererName == value)
			{
				return;
			}
			this._firstItemRendererName = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _lastItemRendererType:Type;

		/**
		 * The class used to instantiate the item renderer for the last item in
		 * a group. Must implement the `IGroupedListItemRenderer`
		 * interface.
		 *
		 * The following example changes the last item renderer type:
		 *
		 * ~~~as3
		 * list.lastItemRendererType = CustomItemRendererClass;
         * ~~~
		 *
		 * @see feathers.controls.renderer.IGroupedListItemRenderer
		 * @see #lastItemRendererFactory
		 * @see #itemRendererType
		 * @see #firstItemRendererType
		 * @see #singleItemRendererType
		 */
		public function get lastItemRendererType():Type
		{
			return this._lastItemRendererType;
		}

		/**
		 * @private
		 */
		public function set lastItemRendererType(value:Type):void
		{
			if(this._lastItemRendererType == value)
			{
				return;
			}

			this._lastItemRendererType = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _lastItemRendererFactory:Function;

		/**
		 * A function called that is expected to return a new item renderer for
		 * the last item in a group. Has a higher priority than
		 * `lastItemRendererType`. Typically, you would use an
		 * `lastItemRendererFactory` instead of an
		 * `lastItemRendererType` if you wanted to initialize some
		 * properties on each separate item renderer, such as skins.
		 *
		 * The function is expected to have the following signature:
		 *
		 * `function():IGroupedListItemRenderer`
		 *
		 * The following example provides a factory for the item renderer
		 * used for the last item in a group:
		 *
		 * ~~~as3
		 * list.firstItemRendererFactory = function():IGroupedListItemRenderer
		 * {
		 *     var renderer:CustomItemRendererClass = new CustomItemRendererClass();
		 *     renderer.backgroundSkin = new Quad( 10, 10, 0xff0000 );
		 *     return renderer;
		 * };
         * ~~~
		 *
		 * @see feathers.controls.renderers.IGroupedListItemRenderer
		 * @see #lastItemRendererType
		 * @see #itemRendererFactory
		 * @see #firstItemRendererFactory
		 * @see #singleItemRendererFactory
		 */
		public function get lastItemRendererFactory():Function
		{
			return this._lastItemRendererFactory;
		}

		/**
		 * @private
		 */
		public function set lastItemRendererFactory(value:Function):void
		{
			if(this._lastItemRendererFactory == value)
			{
				return;
			}

			this._lastItemRendererFactory = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _lastItemRendererName:String;

		/**
		 * A name to add to all item renderers in this list that are the last
		 * item in a group. Typically used by a theme to provide different skins
		 * to different lists, and to differentiate last items from regular
		 * items if they are created with the same class. If this value is null
		 * the regular `itemRendererName` will be used instead.
		 *
		 * The following example provides an name for the last item renderer
		 * in a group:
		 *
		 * ~~~as3
		 * list.lastItemRendererName = "my-custom-last-item-renderer-name";
         * ~~~
		 *
		 * In your theme, you can target this item renderer name to provide
		 * different skins than the default style:
		 *
		 * ~~~as3
		 * setInitializerForClass( DefaultListItemRenderer, customLastItemRendererInitializer, "my-custom-last-item-renderer-name");
         * ~~~
		 *
		 * @see feathers.core.FeathersControl#nameList
		 * @see #itemRendererName
		 * @see #firstItemRendererName
		 * @see #singleItemRendererName
		 */
		public function get lastItemRendererName():String
		{
			return this._lastItemRendererName;
		}

		/**
		 * @private
		 */
		public function set lastItemRendererName(value:String):void
		{
			if(this._lastItemRendererName == value)
			{
				return;
			}
			this._lastItemRendererName = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _singleItemRendererType:Type;

		/**
		 * The class used to instantiate the item renderer for an item in a
		 * group with no other items. Must implement the
		 * `IGroupedListItemRenderer` interface.
		 *
		 * The following example changes the single item renderer type:
		 *
		 * ~~~as3
		 * list.singleItemRendererType = CustomItemRendererClass;
         * ~~~
		 *
		 * @see feathers.controls.renderer.IGroupedListItemRenderer
		 * @see #singleItemRendererFactory
		 * @see #itemRendererType
		 * @see #firstItemRendererType
		 * @see #lastItemRendererType
		 */
		public function get singleItemRendererType():Type
		{
			return this._singleItemRendererType;
		}

		/**
		 * @private
		 */
		public function set singleItemRendererType(value:Type):void
		{
			if(this._singleItemRendererType == value)
			{
				return;
			}

			this._singleItemRendererType = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _singleItemRendererFactory:Function;

		/**
		 * A function called that is expected to return a new item renderer for
		 * an item in a group with no other items. Has a higher priority than
		 * `singleItemRendererType`. Typically, you would use an
		 * `singleItemRendererFactory` instead of an
		 * `singleItemRendererType` if you wanted to initialize some
		 * properties on each separate item renderer, such as skins.
		 *
		 * The function is expected to have the following signature:
		 *
		 * `function():IGroupedListItemRenderer`
		 *
		 * The following example provides a factory for the item renderer
		 * used for when only one item appears in a group:
		 *
		 * ~~~as3
		 * list.firstItemRendererFactory = function():IGroupedListItemRenderer
		 * {
		 *     var renderer:CustomItemRendererClass = new CustomItemRendererClass();
		 *     renderer.backgroundSkin = new Quad( 10, 10, 0xff0000 );
		 *     return renderer;
		 * };
         * ~~~
		 *
		 * @see feathers.controls.renderers.IGroupedListItemRenderer
		 * @see #singleItemRendererType
		 * @see #itemRendererFactory
		 * @see #firstItemRendererFactory
		 * @see #lastItemRendererFactory
		 */
		public function get singleItemRendererFactory():Function
		{
			return this._singleItemRendererFactory;
		}

		/**
		 * @private
		 */
		public function set singleItemRendererFactory(value:Function):void
		{
			if(this._singleItemRendererFactory == value)
			{
				return;
			}

			this._singleItemRendererFactory = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _singleItemRendererName:String;

		/**
		 * A name to add to all item renderers in this list that are an item in
		 * a group with no other items. Typically used by a theme to provide
		 * different skins to different lists, and to differentiate single items
		 * from other items if they are created with the same class. If this
		 * value is null the regular `itemRendererName` will be used
		 * instead.
		 *
		 * The following example provides an name for a single item renderer
		 * in a group:
		 *
		 * ~~~as3
		 * list.singleItemRendererName = "my-custom-single-item-renderer-name";
         * ~~~
		 *
		 * In your theme, you can target this item renderer name to provide
		 * different skins than the default style:
		 *
		 * ~~~as3
		 * setInitializerForClass( DefaultListItemRenderer, customSingleItemRendererInitializer, "my-custom-single-item-renderer-name");
         * ~~~
		 *
		 * @see feathers.core.FeathersControl#nameList
		 * @see #itemRendererName
		 * @see #firstItemRendererName
		 * @see #lastItemRendererName
		 */
		public function get singleItemRendererName():String
		{
			return this._singleItemRendererName;
		}

		/**
		 * @private
		 */
		public function set singleItemRendererName(value:String):void
		{
			if(this._singleItemRendererName == value)
			{
				return;
			}
			this._singleItemRendererName = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _headerRendererType:Type = DefaultGroupedListHeaderOrFooterRenderer;

		/**
		 * The class used to instantiate header renderers. Must implement the
		 * `IGroupedListHeaderOrFooterRenderer` interface.
		 *
		 * The following example changes the header renderer type:
		 *
		 * ~~~as3
		 * list.headerRendererType = CustomHeaderRendererClass;
         * ~~~
		 *
		 * @see feathers.controls.renderers.IGroupedListHeaderOrFooterRenderer
		 * @see #headerRendererFactory
		 */
		public function get headerRendererType():Type
		{
			return this._headerRendererType;
		}

		/**
		 * @private
		 */
		public function set headerRendererType(value:Type):void
		{
			if(this._headerRendererType == value)
			{
				return;
			}

			this._headerRendererType = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _headerRendererFactory:Function;

		/**
		 * A function called that is expected to return a new header renderer.
		 * Has a higher priority than `headerRendererType`.
		 * Typically, you would use an `headerRendererFactory`
		 * instead of a `headerRendererType` if you wanted to
		 * initialize some properties on each separate header renderer, such as
		 * skins.
		 *
		 * The function is expected to have the following signature:
		 *
		 * `function():IGroupedListHeaderOrFooterRenderer`
		 *
		 * The following example provides a factory for the header renderer:
		 *
		 * ~~~as3
		 * list.itemRendererFactory = function():IGroupedListHeaderOrFooterRenderer
		 * {
		 *     var renderer:CustomHeaderRendererClass = new CustomHeaderRendererClass();
		 *     renderer.backgroundSkin = new Quad( 10, 10, 0xff0000 );
		 *     return renderer;
		 * };
         * ~~~
		 *
		 * @see feathers.controls.renderers.IGroupedListHeaderOrFooterRenderer
		 * @see #headerRendererType
		 */
		public function get headerRendererFactory():Function
		{
			return this._headerRendererFactory;
		}

		/**
		 * @private
		 */
		public function set headerRendererFactory(value:Function):void
		{
			if(this._headerRendererFactory == value)
			{
				return;
			}

			this._headerRendererFactory = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _typicalHeader:Object = null;

		/**
		 * Used to auto-size the grouped list. If the list's width or height is
		 * `NaN`, the grouped list will try to automatically pick an
		 * ideal size. This data is used in that process to create a sample
		 * header renderer.
		 *
		 * The following example provides a typical header:
		 *
		 * ~~~as3
		 * list.typicalHeader = { text: "A typical header" };
		 * list.headerRendererProperties.contentLabelField = "text";
         * ~~~
		 */
		public function get typicalHeader():Object
		{
			return this._typicalHeader;
		}

		/**
		 * @private
		 */
		public function set typicalHeader(value:Object):void
		{
			if(this._typicalHeader == value)
			{
				return;
			}
			this._typicalHeader = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _headerRendererName:String = DEFAULT_CHILD_NAME_HEADER_RENDERER;

		/**
		 * A name to add to all header renderers in this grouped list. Typically
		 * used by a theme to provide different skins to different lists.
		 *
		 * The following example sets the header renderer name:
		 *
		 * ~~~as3
		 * list.headerRendererName = "my-custom-header-renderer-name";
         * ~~~
		 *
		 * In your theme, you can target this header renderer name to provide
		 * different skins than the default style:
		 *
		 * ~~~as3
		 * setInitializerForClass( DefaultGroupedListHeaderOrFooterRenderer, customHeaderRendererInitializer, "my-custom-header-renderer-name");
         * ~~~
		 *
		 * @see feathers.core.FeathersControl#nameList
		 */
		public function get headerRendererName():String
		{
			return this._headerRendererName;
		}

		/**
		 * @private
		 */
		public function set headerRendererName(value:String):void
		{
			if(this._headerRendererName == value)
			{
				return;
			}
			this._headerRendererName = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _headerRendererProperties:Dictionary.<String, Object>;

		/**
		 * A set of key/value pairs to be passed down to all of the grouped
		 * list's header renderers. These values are shared by each header
		 * renderer, so values that cannot be shared (such as display objects
		 * that need to be added to the display list) should be passed to the
		 * header renderers using the `headerRendererFactory` or in a
		 * theme. The header renderers are instances of
		 * `IGroupedListHeaderOrFooterRenderer`. The available
		 * properties depend on which `IGroupedListItemRenderer`
		 * implementation is returned by `headerRendererFactory`.
		 *
		 * The following example customizes some header renderer properties:
		 *
		 * ~~~as3
		 * list.headerRendererProperties.&#64;contentLabelProperties.textFormat = new BitmapFontTextFormat( bitmapFont );
		 * list.headerRendererProperties.padding = 20;
         * ~~~
		 *
		 * If the subcomponent has its own subcomponents, their properties
		 * can be set too, using attribute `&#64;` notation. For example,
		 * to set the skin on the thumb of a `SimpleScrollBar`
		 * which is in a `Scroller` which is in a `List`,
		 * you can use the following syntax:
		 * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
		 *
		 * Setting properties in a `headerRendererFactory` function instead
		 * of using `headerRendererProperties` will result in better
		 * performance.
		 *
		 * @see #headerRendererFactory
		 * @see feathers.controls.renderers.IGroupedListHeaderOrFooterRenderer
		 * @see feathers.controls.renderers.DefaultGroupedListHeaderOrFooterRenderer
		 */
		public function get headerRendererProperties():Dictionary.<String, Object>
		{
			if(!this._headerRendererProperties)
			{
				this._headerRendererProperties = new Dictionary.<String, Object>();
			}
			return this._headerRendererProperties;
		}

		/**
		 * @private
		 */
		public function set headerRendererProperties(value:Dictionary.<String, Object>):void
		{
			if(this._headerRendererProperties == value)
			{
				return;
			}
			if(!value)
			{
				value = new Dictionary.<String, Object>();
			}
			this._headerRendererProperties = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _footerRendererType:Type = DefaultGroupedListHeaderOrFooterRenderer;

		/**
		 * The class used to instantiate footer renderers. Must implement the
		 * `IGroupedListHeaderOrFooterRenderer` interface.
		 *
		 * The following example changes the footer renderer type:
		 *
		 * ~~~as3
		 * list.footerRendererType = CustomFooterRendererClass;
         * ~~~
		 *
		 * @see feathers.controls.renderers.IGroupedListHeaderOrFooterRenderer
		 * @see #footerRendererFactory
		 */
		public function get footerRendererType():Type
		{
			return this._footerRendererType;
		}

		/**
		 * @private
		 */
		public function set footerRendererType(value:Type):void
		{
			if(this._footerRendererType == value)
			{
				return;
			}

			this._footerRendererType = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _footerRendererFactory:Function;

		/**
		 * A function called that is expected to return a new footer renderer.
		 * Has a higher priority than `footerRendererType`.
		 * Typically, you would use an `footerRendererFactory`
		 * instead of a `footerRendererType` if you wanted to
		 * initialize some properties on each separate footer renderer, such as
		 * skins.
		 *
		 * The function is expected to have the following signature:
		 *
		 * `function():IGroupedListHeaderOrFooterRenderer`
		 *
		 * The following example provides a factory for the footer renderer:
		 *
		 * ~~~as3
		 * list.itemRendererFactory = function():IGroupedListHeaderOrFooterRenderer
		 * {
		 *     var renderer:CustomFooterRendererClass = new CustomFooterRendererClass();
		 *     renderer.backgroundSkin = new Quad( 10, 10, 0xff0000 );
		 *     return renderer;
		 * };
         * ~~~
		 *
		 * @see feathers.controls.renderers.IGroupedListHeaderOrFooterRenderer
		 * @see #footerRendererType
		 */
		public function get footerRendererFactory():Function
		{
			return this._footerRendererFactory;
		}

		/**
		 * @private
		 */
		public function set footerRendererFactory(value:Function):void
		{
			if(this._footerRendererFactory == value)
			{
				return;
			}

			this._footerRendererFactory = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _typicalFooter:Object = null;

		/**
		 * Used to auto-size the grouped list. If the grouped list's width or
		 * height is `NaN`, the grouped list will try to
		 * automatically pick an ideal size. This data is used in that process
		 * to create a sample footer renderer.
		 *
		 * The following example provides a typical footer:
		 *
		 * ~~~as3
		 * list.typicalHeader = { text: "A typical footer" };
		 * list.footerRendererProperties.contentLabelField = "text";
         * ~~~
		 */
		public function get typicalFooter():Object
		{
			return this._typicalFooter;
		}

		/**
		 * @private
		 */
		public function set typicalFooter(value:Object):void
		{
			if(this._typicalFooter == value)
			{
				return;
			}
			this._typicalFooter = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _footerRendererName:String = DEFAULT_CHILD_NAME_FOOTER_RENDERER;

		/**
		 * A name to add to all footer renderers in this grouped list. Typically
		 * used by a theme to provide different skins to different lists.
		 *
		 * The following example sets the footer renderer name:
		 *
		 * ~~~as3
		 * list.footerRendererName = "my-custom-footer-renderer-name";
         * ~~~
		 *
		 * In your theme, you can target this footer renderer name to provide
		 * different skins than the default style:
		 *
		 * ~~~as3
		 * setInitializerForClass( DefaultGroupedListHeaderOrFooterRenderer, customFooterRendererInitializer, "my-custom-footer-renderer-name");
         * ~~~
		 *
		 *
		 * @see feathers.core.FeathersControl#nameList
		 */
		public function get footerRendererName():String
		{
			return this._footerRendererName;
		}

		/**
		 * @private
		 */
		public function set footerRendererName(value:String):void
		{
			if(this._footerRendererName == value)
			{
				return;
			}
			this._footerRendererName = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _footerRendererProperties:Dictionary.<String, Object>;

		/**
		 * A set of key/value pairs to be passed down to all of the grouped
		 * list's footer renderers. These values are shared by each footer
		 * renderer, so values that cannot be shared (such as display objects
		 * that need to be added to the display list) should be passed to the
		 * footer renderers using a `footerRendererFactory` or with
		 * a theme. The header renderers are instances of
		 * `IGroupedListHeaderOrFooterRenderer`. The available
		 * properties depend on which `IGroupedListItemRenderer`
		 * implementation is returned by `headerRendererFactory`.
		 *
		 * The following example customizes some header renderer properties:
		 *
		 * ~~~as3
		 * list.footerRendererProperties.&#64;contentLabelProperties.textFormat = new BitmapFontTextFormat( bitmapFont );
		 * list.footerRendererProperties.padding = 20;
         * ~~~
		 *
		 * If the subcomponent has its own subcomponents, their properties
		 * can be set too, using attribute `&#64;` notation. For example,
		 * to set the skin on the thumb of a `SimpleScrollBar`
		 * which is in a `Scroller` which is in a `List`,
		 * you can use the following syntax:
		 * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
		 *
		 * Setting properties in a `footerRendererFactory` function instead
		 * of using `footerRendererProperties` will result in better
		 * performance.
		 *
		 * @see #footerRendererFactory
		 * @see feathers.controls.renderers.IGroupedListHeaderOrFooterRenderer
		 * @see feathers.controls.renderers.DefaultGroupedListHeaderOrFooterRenderer
		 */
		public function get footerRendererProperties():Dictionary.<String, Object>
		{
			if(!this._footerRendererProperties)
			{
				this._footerRendererProperties = new Dictionary.<String, Object>();
			}
			return this._footerRendererProperties;
		}

		/**
		 * @private
		 */
		public function set footerRendererProperties(value:Dictionary.<String, Object>):void
		{
			if(this._footerRendererProperties == value)
				return;
			this._footerRendererProperties = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _headerField:String = "header";

		/**
		 * The field in a group that contains the data for a header. If the
		 * group does not have this field, and a `headerFunction` is
		 * not defined, then no header will be displayed for the group. In other
		 * words, a header is optional, and a group may not have one.
		 *
		 * All of the header fields and functions, ordered by priority:
		 * 
		 *     1. `headerFunction`
		 *     2. `headerField`

		 *
		 * The following example sets the header field:
		 *
		 * ~~~as3
		 * list.headerField = "header";
         * ~~~
		 *
		 * @see #headerFunction
		 */
		public function get headerField():String
		{
			return this._headerField;
		}

		/**
		 * @private
		 */
		public function set headerField(value:String):void
		{
			if(this._headerField == value)
			{
				return;
			}
			this._headerField = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _headerFunction:Function;

		/**
		 * A function used to generate header data for a specific group. If this
		 * function is not null, then the `headerField` will be
		 * ignored.
		 *
		 * The function is expected to have the following signature:
		 * `function( item:Object ):Object`
		 *
		 * All of the header fields and functions, ordered by priority:
		 * 
		 *     1. `headerFunction`
		 *     2. `headerField`

		 *
		 * The following example sets the header function:
		 *
		 * ~~~as3
		 * list.headerFunction = function( group:Object ):Object
		 * {
		 *    return group.header;
		 * };
         * ~~~
		 *
		 * @see #headerField
		 */
		public function get headerFunction():Function
		{
			return this._headerFunction;
		}

		/**
		 * @private
		 */
		public function set headerFunction(value:Function):void
		{
			if(this._headerFunction == value)
			{
				return;
			}
			this._headerFunction = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _footerField:String = "footer";

		/**
		 * The field in a group that contains the data for a footer. If the
		 * group does not have this field, and a `footerFunction` is
		 * not defined, then no footer will be displayed for the group. In other
		 * words, a footer is optional, and a group may not have one.
		 *
		 * All of the footer fields and functions, ordered by priority:
		 * 
		 *     1. `footerFunction`
		 *     2. `footerField`

		 *
		 * The following example sets the footer field:
		 *
		 * ~~~as3
		 * list.footerField = "footer";
         * ~~~
		 *
		 * @see #footerFunction
		 */
		public function get footerField():String
		{
			return this._footerField;
		}

		/**
		 * @private
		 */
		public function set footerField(value:String):void
		{
			if(this._footerField == value)
			{
				return;
			}
			this._footerField = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _footerFunction:Function;

		/**
		 * A function used to generate footer data for a specific group. If this
		 * function is not null, then the `footerField` will be
		 * ignored.
		 *
		 * The function is expected to have the following signature:
		 * `function( item:Object ):Object`
		 *
		 * All of the footer fields and functions, ordered by priority:
		 * 
		 *     1. `footerFunction`
		 *     2. `footerField`

		 *
		 * The following example sets the footer function:
		 *
		 * ~~~as3
		 * list.footerFunction = function( group:Object ):Object
		 * {
		 *    return group.footer;
		 * };
         * ~~~
		 *
		 * @see #footerField
		 */
		public function get footerFunction():Function
		{
			return this._footerFunction;
		}

		/**
		 * @private
		 */
		public function set footerFunction(value:Function):void
		{
			if(this._footerFunction == value)
			{
				return;
			}
			this._footerFunction = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * The pending group index to scroll to after validating. A value of
		 * `-1` means that the scroller won't scroll to a group after
		 * validating.
		 */
		protected var pendingGroupIndex:int = -1;

		/**
		 * The pending item index to scroll to after validating. A value of
		 * `-1` means that the scroller won't scroll to an item after
		 * validating.
		 */
		protected var pendingItemIndex:int = -1;

		/**
		 * @private
		 */
		override public function dispose():void
		{
			if(this._layout)
			{
				var l = this._layout;
				this._layout = null;
			}
			this.dataProvider = null;
			super.dispose();
			if(l) (l as Object).deleteNative();
		}

		/**
		 * @private
		 */
		override public function scrollToPosition(horizontalScrollPosition:Number, verticalScrollPosition:Number, animationDuration:Number = 0):void
		{
			this.pendingItemIndex = -1;
			super.scrollToPosition(horizontalScrollPosition, verticalScrollPosition, animationDuration);
		}

		/**
		 * @private
		 */
		override public function scrollToPageIndex(horizontalPageIndex:int, verticalPageIndex:int, animationDuration:Number = 0):void
		{
			this.pendingGroupIndex = -1;
			this.pendingItemIndex = -1;
			super.scrollToPageIndex(horizontalPageIndex, verticalPageIndex, animationDuration);
		}

		/**
		 * After the next validation, scrolls the list so that the specified
		 * item is visible. If `animationDuration` is greater than
		 * zero, the scroll will animate. The duration is in seconds.
		 */
		public function scrollToDisplayIndex(groupIndex:int, itemIndex:int, animationDuration:Number = 0):void
		{
			this.pendingHorizontalPageIndex = -1;
			this.pendingVerticalPageIndex = -1;
			this.pendingHorizontalScrollPosition = NaN;
			this.pendingVerticalScrollPosition = NaN;
			if(this.pendingGroupIndex == groupIndex &&
				this.pendingItemIndex == itemIndex &&
				this.pendingScrollDuration == animationDuration)
			{
				return;
			}
			this.pendingGroupIndex = groupIndex;
			this.pendingItemIndex = itemIndex;
			this.pendingScrollDuration = animationDuration;
			this.invalidate(INVALIDATION_FLAG_PENDING_SCROLL);
		}

		/**
		 * Sets the selected group and item index.
		 */
		public function setSelectedLocation(groupIndex:int, itemIndex:int):void
		{
			if(this._selectedGroupIndex == groupIndex && this._selectedItemIndex == itemIndex)
			{
				return;
			}
			if((groupIndex < 0 && itemIndex >= 0) || (groupIndex >= 0 && itemIndex < 0))
			{
				throw new ArgumentError("To deselect items, group index and item index must both be < 0.");
			}
			this._selectedGroupIndex = groupIndex;
			this._selectedItemIndex = itemIndex;

			this.invalidate(INVALIDATION_FLAG_SELECTED);
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * Extracts header data from a group object.
		 */
		public function groupToHeaderData(group:Object):Object
		{
			if(this._headerFunction != null)
			{
				return this._headerFunction.call(null, group);
			}
			else if(this._headerField != null 
				&& group 
				&& group.getType().getFieldOrPropertyValueByName(group, this._headerField) != null)
			{
				return group.getType().getFieldOrPropertyValueByName(group, this._headerField);
			}

			return null;
		}

		/**
		 * Extracts footer data from a group object.
		 */
		public function groupToFooterData(group:Object):Object
		{
			if(this._footerFunction != null)
			{
				return this._footerFunction.call(null, group);
			}
			else if(this._footerField != null && group && group.getType().getFieldOrPropertyValueByName(group, this._footerField))
			{
				return group.getType().getFieldOrPropertyValueByName(group, this._footerField);
			}

			return null;
		}

		/**
		 * @private
		 */
		override protected function initialize():void
		{
			const hasLayout:Boolean = this._layout != null;

			super.initialize();

			if(!this.dataViewPort)
			{
				this.viewPort = this.dataViewPort = new GroupedListDataViewPort();
				this.dataViewPort.owner = this;
				this.dataViewPort.addEventListener(Event.CHANGE, dataViewPort_changeHandler);
				this.viewPort = this.dataViewPort;
			}

			if(!hasLayout)
			{
				if(this._hasElasticEdges &&
					this._verticalScrollPolicy == SCROLL_POLICY_AUTO &&
					this._scrollBarDisplayMode != SCROLL_BAR_DISPLAY_MODE_FIXED)
				{
					//so that the elastic edges work even when the max scroll
					//position is 0, similar to iOS.
					this.verticalScrollPolicy = SCROLL_POLICY_ON;
				}

				const layout:VerticalLayout = new VerticalLayout();
				layout.useVirtualLayout = true;
				layout.paddingTop = layout.paddingRight = layout.paddingBottom =
					layout.paddingLeft = 0;
				layout.gap = 0;
				layout.horizontalAlign = VerticalLayout.HORIZONTAL_ALIGN_JUSTIFY;
				layout.verticalAlign = VerticalLayout.VERTICAL_ALIGN_TOP;
				layout.manageVisibility = true;
				this._layout = layout;
			}
		}

		/**
		 * @private
		 */
		override protected function draw():void
		{
			this.refreshDataViewPortProperties();
			super.draw();
			this.refreshFocusIndicator();
		}

		/**
		 * @private
		 */
		protected function refreshDataViewPortProperties():void
		{
			this.dataViewPort.isSelectable = this._isSelectable;
			this.dataViewPort.setSelectedLocation(this._selectedGroupIndex, this._selectedItemIndex);
			this.dataViewPort.dataProvider = this._dataProvider;

			this.dataViewPort.itemRendererType = this._itemRendererType;
			this.dataViewPort.itemRendererFactory = this._itemRendererFactory;
			this.dataViewPort.itemRendererProperties = this._itemRendererProperties;
			this.dataViewPort.itemRendererName = this._itemRendererName;
			this.dataViewPort.typicalItem = this._typicalItem;

			this.dataViewPort.firstItemRendererType = this._firstItemRendererType;
			this.dataViewPort.firstItemRendererFactory = this._firstItemRendererFactory;
			this.dataViewPort.firstItemRendererName = this._firstItemRendererName;

			this.dataViewPort.lastItemRendererType = this._lastItemRendererType;
			this.dataViewPort.lastItemRendererFactory = this._lastItemRendererFactory;
			this.dataViewPort.lastItemRendererName = this._lastItemRendererName;

			this.dataViewPort.singleItemRendererType = this._singleItemRendererType;
			this.dataViewPort.singleItemRendererFactory = this._singleItemRendererFactory;
			this.dataViewPort.singleItemRendererName = this._singleItemRendererName;

			this.dataViewPort.headerRendererType = this._headerRendererType;
			this.dataViewPort.headerRendererFactory = this._headerRendererFactory;
			this.dataViewPort.headerRendererProperties = this._headerRendererProperties;
			this.dataViewPort.headerRendererName = this._headerRendererName;
			this.dataViewPort.typicalHeader = this._typicalHeader;

			this.dataViewPort.footerRendererType = this._footerRendererType;
			this.dataViewPort.footerRendererFactory = this._footerRendererFactory;
			this.dataViewPort.footerRendererProperties = this._footerRendererProperties;
			this.dataViewPort.footerRendererName = this._footerRendererName;
			this.dataViewPort.typicalFooter = this._typicalFooter;

			this.dataViewPort.layout = this._layout;
		}

		/**
		 * @private
		 */
		override protected function handlePendingScroll():void
		{
			if(this.pendingGroupIndex >= 0 && this.pendingItemIndex >= 0)
			{
				const item:Object = this._dataProvider.getItemAt(this.pendingGroupIndex, this.pendingItemIndex);
				if(item is Object)
				{
					HELPER_POINT = this.dataViewPort.getScrollPositionForIndex(this.pendingGroupIndex, this.pendingItemIndex);
					this.pendingGroupIndex = -1;
					this.pendingItemIndex = -1;

					if(this.pendingScrollDuration > 0)
					{
						this.throwTo(Math.max(0, Math.min(HELPER_POINT.x, this._maxHorizontalScrollPosition)),
							Math.max(0, Math.min(HELPER_POINT.y, this._maxVerticalScrollPosition)), this.pendingScrollDuration);
					}
					else
					{
						this.horizontalScrollPosition = Math.max(0, Math.min(HELPER_POINT.x, this._maxHorizontalScrollPosition));
						this.verticalScrollPosition = Math.max(0, Math.min(HELPER_POINT.y, this._maxVerticalScrollPosition));
					}
				}
			}
			super.handlePendingScroll();
		}

		/**
		 * @private
		 */
		override protected function focusInHandler(event:Event):void
		{
			super.focusInHandler(event);
			//this.stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
		}

		/**
		 * @private
		 */
		override protected function focusOutHandler(event:Event):void
		{
			super.focusOutHandler(event);
			//this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
		}

		/**
		 * @private
		 */
/*		protected function stage_keyDownHandler(event:KeyboardEvent):void
		{
			if(!this._dataProvider)
			{
				return;
			}
			if(event.keyCode == Keyboard.HOME)
			{
				if(this._dataProvider.getLength() > 0 && this._dataProvider.getLength(0) > 0)
				{
					this.setSelectedLocation(0, 0);
				}
			}
			if(event.keyCode == Keyboard.END)
			{
				var groupIndex:int = this._dataProvider.getLength();
				var itemIndex:int = -1;
				do
				{
					groupIndex--;
					if(groupIndex >= 0)
					{
						itemIndex = this._dataProvider.getLength(groupIndex) - 1;
					}
				}
				while(groupIndex > 0 && itemIndex < 0)
				if(groupIndex >= 0 && itemIndex >= 0)
				{
					this.setSelectedLocation(groupIndex, itemIndex);
				}
			}
			else if(event.keyCode == Keyboard.UP)
			{
				groupIndex = this._selectedGroupIndex;
				itemIndex = this._selectedItemIndex - 1;
				if(itemIndex < 0)
				{
					do
					{
						groupIndex--;
						if(groupIndex >= 0)
						{
							itemIndex = this._dataProvider.getLength(groupIndex) - 1;
						}
					}
					while(groupIndex > 0 && itemIndex < 0)
				}
				if(groupIndex >= 0 && itemIndex >= 0)
				{
					this.setSelectedLocation(groupIndex, itemIndex);
				}
			}
			else if(event.keyCode == Keyboard.DOWN)
			{
				groupIndex = this._selectedGroupIndex;
				if(groupIndex < 0)
				{
					itemIndex = -1;
				}
				else
				{
					itemIndex = this._selectedItemIndex + 1;
				}
				if(groupIndex < 0 || itemIndex >= this._dataProvider.getLength(groupIndex))
				{
					itemIndex = -1;
					groupIndex++;
					const groupCount:int = this._dataProvider.getLength();
					while(groupIndex < groupCount && itemIndex < 0)
					{
						if(this._dataProvider.getLength(groupIndex) > 0)
						{
							itemIndex = 0;
						}
						else
						{
							groupIndex++;
						}
					}
				}
				if(groupIndex >= 0 && itemIndex >= 0)
				{
					this.setSelectedLocation(groupIndex, itemIndex);
				}
			}
		} */

		/**
		 * @private
		 */
		protected function dataProvider_resetHandler(event:Event):void
		{
			this.horizontalScrollPosition = 0;
			this.verticalScrollPosition = 0;
		}

		/**
		 * @private
		 */
		protected function dataViewPort_changeHandler(event:Event):void
		{
			this.setSelectedLocation(this.dataViewPort.selectedGroupIndex, this.dataViewPort.selectedItemIndex);
		}
	}
}
