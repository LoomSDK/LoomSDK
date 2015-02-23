/**
 * vim:et sts=4 sw=4 cindent:
 * $Id$
 * @author allens
 */
package com.modestmaps.flex
{
	/**
	 * The flex.MapComponent class is an ActionScript UI component. To use it in your application,
	 * simply specify a new namespace in the root node of your application. As long as the
	 * com.modestmaps.flex namespace is in your path, Flex Builder should find the class
	 * and auto-complete the element name once you've opened a new tag and typed the namespace.
	 * 
	 * <mx:Application xmlns:modest="com.modestmaps.flex.*" ...>
	 *   <modest:Map provider="BLUE_MARBLE" zoom="5" center="37.5, -122.0"
	 * 		top="0" left="0" bottom="0" right="0" />
	 * </mx:Application>
	 * 
	 * The MXML component doesn't currently support the full com.modestmaps.Map API, but the
	 * instance of that class is accessible via the (read-only) "map" getter if you need to
	 * call any of its methods.
	 */
	import com.modestmaps.Map;
	import com.modestmaps.core.*;
	import com.modestmaps.events.MapEvent;
	import com.modestmaps.geo.*;
	import com.modestmaps.mapproviders.*;
	import com.modestmaps.mapproviders.microsoft.*;
	import com.modestmaps.mapproviders.yahoo.*;
	
	import flash.events.Event;
	import mx.core.UIComponent;

    [Event(name="startZooming",      type="com.modestmaps.events.MapEvent")]
    [Event(name="stopZooming",       type="com.modestmaps.events.MapEvent")]
    [Event(name="zoomedBy",          type="com.modestmaps.events.MapEvent")]
    [Event(name="startPanning",      type="com.modestmaps.events.MapEvent")]
    [Event(name="stopPanning",       type="com.modestmaps.events.MapEvent")]
    [Event(name="panned",            type="com.modestmaps.events.MapEvent")]
    [Event(name="resized",           type="com.modestmaps.events.MapEvent")]
    [Event(name="mapProviderChanged",type="com.modestmaps.events.MapEvent")]
    [Event(name="beginExtentChange", type="com.modestmaps.events.MapEvent")]
    [Event(name="extentChanged",     type="com.modestmaps.events.MapEvent")]
    [Event(name="beginTileLoading",  type="com.modestmaps.events.MapEvent")]
    [Event(name="allTilesLoaded",    type="com.modestmaps.events.MapEvent")]
    [Event(name="rendered",          type="com.modestmaps.events.MapEvent")]
    [Event(name="markerRollOver",    type="com.modestmaps.events.MarkerEvent")]
    [Event(name="markerRollOut",     type="com.modestmaps.events.MarkerEvent")]
    [Event(name="markerClick",       type="com.modestmaps.events.MarkerEvent")]
    public class MapComponent extends UIComponent
	{
		public static const DEFAULT_MEASURED_WIDTH:Number = 400;
	    public static const DEFAULT_MEASURED_MIN_WIDTH:Number = 100;
	    public static const DEFAULT_MEASURED_HEIGHT:Number = 400;
	    public static const DEFAULT_MEASURED_MIN_HEIGHT:Number = 100;
	    public static const DEFAULT_MAX_WIDTH:Number = 10000;
	    public static const DEFAULT_MAX_HEIGHT:Number = 10000;

	    public static const DEFAULT_MAP_PROVIDER:IMapProvider = new BlueMarbleMapProvider();
		
		protected var _map:Map;
		protected var mapInitDirty:Boolean = true;

		public function MapComponent()
		{
			super();
		}

		/**
		 * Since we're not yet supporting the full Map interface,
		 * make the instance gettable, read-only.
		 */
		public function get map():com.modestmaps.Map
		{
			return _map;
		}
		
		override protected function createChildren():void
		{
			trace("Map.createChildren()");
			
			super.createChildren();
			if (mapInitDirty && _map == null)
			{
				// TODO: implement draggable switch?
				//trace(' * initializing map: ' + w + 'x' + h + ', ' + _draggable + ', provider: ' + _mapProvider.toString());
				//_map.init(w, h, _draggable, _mapProvider || DEFAULT_MAP_PROVIDER);
				_map = new Map(unscaledWidth, unscaledHeight, _draggable, _mapProvider || DEFAULT_MAP_PROVIDER);
				addChild(_map);
				mapProviderDirty = false;
				mapInitDirty = false;
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if (_map.getWidth() != unscaledWidth || _map.getHeight() != unscaledHeight)
			{
				_map.setSize(unscaledWidth, unscaledHeight);
			}
			
			// save extent setting until the map has a valid size
	        if (mapExtentDirty && _map.getWidth() > 0 && _map.getHeight() > 0)
	        {
				trace(' * extent is dirty, setting to: ' + _extent);
	            _map.setExtent(_extent);
	            mapExtentDirty = false;
	        }
		}

		protected var mapExtentDirty:Boolean = false;
		protected var _extent:MapExtent;
		protected var _mapExtentString:String;
		
		protected var mapCenterDirty:Boolean = true;
		protected var _centerLocation:Location = new Location(0, 0);
		protected var mapZoomDirty:Boolean = true;
		protected var _zoom:int = 1;

		/**
		 * The "extent" setter accepts either a MapExtent instance or a String;
		 * the latter is converted into a MapExtent using the static fromString()
		 * method. This allows the extent to be defined as a string in MXML
		 * attributes, a la "north, south, east, west".
		 */
		[Inspectable(category="MapComponent")]
		public function set extent(mapExtent:*):void
		{
			if (mapExtent is String)
			{
				// TODO: try/catch MapExtent.fromString()
				mapExtent = MapExtent.fromString(mapExtent);
			}
			
			if (!(mapExtent is MapExtent))
			{
				throw new Error("Invalid extent supplied");
			}
			trace("got extent: " + mapExtent);
			
			_extent = mapExtent;
			mapExtentDirty = true;
			mapCenterDirty = false;
			mapZoomDirty = false;
			invalidateProperties();
		}

		public function get extent():MapExtent
		{
			return _map ? _map.getExtent() : _extent;
		}

		/**
		 * Like the "extent" setter, the "center" setter accepts a String in addition to
		 * a Location object, so that locations can be specified in MXML attributes as
		 * strings ("lat, lon").
		 */
		[Inspectable(category="Map", defaultValue="0,0")]		
		public function set center(location:*):void
		{
			if (location is String)
			{
				location = Location.fromString(location);
			}

			if (!(location is Location))
			{
				throw new Error("Invalid location supplied");
			}
			
			_centerLocation = location;
			mapCenterDirty = true;
			mapExtentDirty = false;
			invalidateProperties();
		}

		public function get center():Location
		{
			return _map ? _map.getCenter() : _centerLocation;
		}
		
		public function set zoom(zoomLevel:int):void
		{
			_zoom = zoomLevel;
			mapZoomDirty = true;
			mapExtentDirty = false;
			invalidateProperties();
		}

		protected var mapProviderDirty:Boolean = true;
		protected var _mapProvider:IMapProvider = DEFAULT_MAP_PROVIDER;

		/**
		 * The "provider" setter accepts either a String (Flex Builder should provide
		 * a list of valid values per the Inspectable() metadata tag) or an IMapProvider
		 * instance. You can specify the latter in MXML by wrapping the constructor in
		 * braces:
		 * 
		 * <modest:Map provider="{new FancyCustomMapProvider()}" .../>
		 */
		[Inspectable(category="Map",
					 enumeration="BLUE_MARBLE,MICROSOFT_AERIAL,MICROSOFT_ROAD,MICROSOFT_HYBRID,YAHOO_ROAD,YAHOO_AERIAL,YAHOO_HYBRID,OPEN_STREET_MAP",
					 defaultValue="BLUE_MARBLE")]
		public function set provider(provider:*):void
		{
			if(provider is IMapProvider) {
				_mapProvider = provider;

			} else {
				switch(provider) {
					case "BLUE_MARBLE":
						_mapProvider = new BlueMarbleMapProvider();
						break;
					case "OPEN_STREET_MAP":
						_mapProvider = new OpenStreetMapProvider();
						break;
					case "MICROSOFT_AERIAL":
						_mapProvider = new MicrosoftAerialMapProvider();
						break;
					case "MICROSOFT_HYBRID":
						_mapProvider = new MicrosoftHybridMapProvider();
						break;
					case "MICROSOFT_ROAD":
						_mapProvider = new MicrosoftRoadMapProvider();
						break;
					case "YAHOO_AERIAL":
						_mapProvider = new YahooAerialMapProvider();
						break;
					case "YAHOO_HYBRID":
						_mapProvider = new YahooHybridMapProvider();
						break;
					case "YAHOO_ROAD":
						_mapProvider = new YahooRoadMapProvider();
						break;
				}
			}
			mapProviderDirty = true;
			invalidateProperties();
		}

		public function get provider():IMapProvider
		{
			if (_map)
			{
				var provider:IMapProvider = _map.getMapProvider();
				return provider ? provider : _mapProvider;
			}
			else
			{
				return _mapProvider;
			}
		}

		protected var _draggable:Boolean = true;

		/**
		 * Currently the "draggable" setter will only work pre-initialization.
		 * In other words, setting draggable after the component has been
		 * initialized will have no effect; it's provided merely as a means for
		 * setting the property in MXML.
		 */
		[Inspectable(category="Map")]
		public function set draggable(isDraggable:Boolean):void
		{
			trace('draggable', isDraggable);
			if (initialized)
			{
				throw new Error("'draggable' is not settable post initialization");
			}
			else
			{
				_draggable = isDraggable;
			}
		}
		
		public function get draggable():Boolean
		{
			return _draggable;
		}

		/**
		 * Updates the map's provider, extent or center/zoom, and size. This is called
		 * by the Flex framework when necessary. There's probably some more optimization that
		 * could be done in the whole invalidation/validation/update process; for instance,
		 * a flag set in invalidateSize() could be used to determine whether or not we should
		 * call _map.setSize(), rather than just comparing the size.
		 */

		// http://ccgi.arutherford.plus.com/blog/wordpress/?p=169
		override protected function commitProperties():void
		{
			trace('commitProperties()', this.id);
			
		    if (_map!=null)
		    {
		        if (mapZoomDirty)
		        {
		        	trace (' * zoom is dirty...');
		            _map.setZoom(_zoom);
		            mapZoomDirty = false;
		        }
		
		        if (mapCenterDirty)
		        {
					trace (' * center is dirty...');
		            _map.setCenter(_centerLocation);
		            mapCenterDirty = false;
		        }
		
		        if (mapExtentDirty && _map.getWidth() > 0 && _map.getHeight() > 0)
		        {
					trace(' * extent is dirty, setting to: ' + _extent);
		            _map.setExtent(_extent);
		            mapExtentDirty = false;
		        }

				if (mapProviderDirty)
				{
					trace(' * setting map provider: ' + _mapProvider.toString());
					_map.setMapProvider(_mapProvider);
					mapProviderDirty = false;
				}
				
		    }

		    super.commitProperties();		

		}

	}	
}
