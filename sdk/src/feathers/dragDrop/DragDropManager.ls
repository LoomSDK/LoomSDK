/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.dragDrop
{
	import feathers.core.PopUpManager;
	import feathers.events.DragDropEvent;

	import system.errors.IllegalOperationError;
	import loom2d.math.Point;

	import loom2d.display.DisplayObject;
	import loom2d.display.Stage;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import loom2d.events.KeyboardEvent;
	import loom.platform.LoomKey;

	import loom2d.Loom2D;

	/**
	 * Handles drag and drop operations based on Starling touch events.
	 *
	 * @see IDragSource
	 * @see IDropTarget
	 * @see DragData
	 */
	public class DragDropManager
	{
		/**
		 * @private
		 */
		private static const HELPER_POINT:Point = new Point();

		/**
		 * @private
		 */
		private static const HELPER_TOUCHES_VECTOR:Vector.<Touch> = new <Touch>[];

		/**
		 * @private
		 */
		protected static var _touchPointID:int = -1;

		/**
		 * The ID of the touch that initiated the current drag. Returns `-1`
		 * if there is not an active drag action. In multi-touch applications,
		 * knowing the touch ID is useful if additional actions need to happen
		 * using the same touch.
		 */
		public static function get touchPointID():int
		{
			return _touchPointID;
		}

		/**
		 * @private
		 */
		protected static var _dragSource:IDragSource;

		/**
		 * The `IDragSource` that started the current drag.
		 */
		public static function get dragSource():IDragSource
		{
			return _dragSource;
		}

		/**
		 * @private
		 */
		protected static var _dragData:DragData;

		/**
		 * Determines if the drag and drop manager is currently handling a drag.
		 * Only one drag may be active at a time.
		 */
		public static function get isDragging():Boolean
		{
			return _dragData != null;
		}

		/**
		 * The data associated with the current drag. Returns `null`
		 * if there is not a current drag.
		 */
		public static function get dragData():DragData
		{
			return _dragData;
		}

		/**
		 * @private
		 * The current target of the current drag.
		 */
		protected static var dropTarget:IDropTarget;

		/**
		 * @private
		 * Indicates if the current drag has been accepted by the dropTarget.
		 */
		protected static var isAccepted:Boolean = false;

		/**
		 * @private
		 * The avatar for the current drag data.
		 */
		protected static var avatar:DisplayObject;

		/**
		 * @private
		 */
		protected static var avatarOffsetX:Number;

		/**
		 * @private
		 */
		protected static var avatarOffsetY:Number;

		/**
		 * @private
		 */
		protected static var dropTargetLocalX:Number;

		/**
		 * @private
		 */
		protected static var dropTargetLocalY:Number;

		/**
		 * @private
		 */
		protected static var avatarOldTouchable:Boolean;

		/**
		 * Starts a new drag. If another drag is currently active, it is
		 * immediately cancelled. Includes an optional "avatar", a visual
		 * representation of the data that is being dragged.
		 */
		public static function startDrag(source:IDragSource, touch:Touch, data:DragData, dragAvatar:DisplayObject = null, dragAvatarOffsetX:Number = 0, dragAvatarOffsetY:Number = 0):void
		{
			if(isDragging)
			{
				cancelDrag();
			}
			if(!source)
			{
				throw new ArgumentError("Drag source cannot be null.");
			}
			if(!data)
			{
				throw new ArgumentError("Drag data cannot be null.");
			}
			_dragSource = source;
			_dragData = data;
			_touchPointID = touch.id;
			avatar = dragAvatar;
			avatarOffsetX = dragAvatarOffsetX;
			avatarOffsetY = dragAvatarOffsetY;
			
			HELPER_POINT = touch.getLocation(Loom2D.stage);
			
			if(avatar)
			{
				avatarOldTouchable = avatar.touchable;
				avatar.touchable = false;
				avatar.x = HELPER_POINT.x + avatarOffsetX;
				avatar.y = HELPER_POINT.y + avatarOffsetY;
				PopUpManager.addPopUp(avatar, false, false);
			}
			Loom2D.stage.addEventListener(TouchEvent.TOUCH, stage_touchHandler);
			//Loom2D.stage.addEventListener(KeyboardEvent.KEY_DOWN, nativeStage_keyDownHandler, false, 0, true);
			_dragSource.dispatchEvent(new DragDropEvent(DragDropEvent.DRAG_START, data, false));

			updateDropTarget(HELPER_POINT);
		}

		/**
		 * Tells the drag and drop manager if the target will accept the current
		 * drop. Meant to be called in a listener for the target's
		 * `DragDropEvent.DRAG_ENTER` event.
		 */
		public static function acceptDrag(target:IDropTarget):void
		{
			if(dropTarget != target)
			{
				throw new ArgumentError("Drop target cannot accept a drag at this time. Acceptance may only happen after the DragDropEvent.DRAG_ENTER event is dispatched and before the DragDropEvent.DRAG_EXIT event is dispatched.");
			}
			isAccepted = true;
		}

		/**
		 * Immediately cancels the current drag.
		 */
		public static function cancelDrag():void
		{
			if(!isDragging)
			{
				return;
			}
			completeDrag(false);
		}

		/**
		 * @private
		 */
		protected static function completeDrag(isDropped:Boolean):void
		{
			if(!isDragging)
			{
				throw new IllegalOperationError("Drag cannot be completed because none is currently active.");
			}
			if(dropTarget)
			{
				dropTarget.dispatchEvent(new DragDropEvent(DragDropEvent.DRAG_EXIT, _dragData, false, dropTargetLocalX, dropTargetLocalY));
				dropTarget = null;
			}
			const source:IDragSource = _dragSource;
			const data:DragData = _dragData;
			cleanup();
			source.dispatchEvent(new DragDropEvent(DragDropEvent.DRAG_COMPLETE, data, isDropped));
		}

		/**
		 * @private
		 */
		protected static function cleanup():void
		{
			if(avatar)
			{
				//may have been removed from parent already in the drop listener
				if(PopUpManager.isPopUp(avatar))
				{
					PopUpManager.removePopUp(avatar);
				}
				avatar.touchable = avatarOldTouchable;
				avatar = null;
			}
			Loom2D.stage.removeEventListener(TouchEvent.TOUCH, stage_touchHandler);
			//Loom2D.nativeStage.removeEventListener(KeyboardEvent.KEY_DOWN, nativeStage_keyDownHandler);
			_dragSource = null;
			_dragData = null;
		}

		/**
		 * @private
		 */
		protected static function updateDropTarget(location:Point):void
		{
			var target:DisplayObject = Loom2D.stage.hitTest(location, true);
			while(target && !(target is IDropTarget))
			{
				target = target.parent;
			}
			if(target)
			{
				location = target.globalToLocal(location);
			}
			if(target as Object != dropTarget as Object)
			{
				if(dropTarget)
				{
					//notice that we can reuse the previously saved location
					dropTarget.dispatchEvent(new DragDropEvent(DragDropEvent.DRAG_EXIT, _dragData, false, dropTargetLocalX, dropTargetLocalY));
				}
				dropTarget = IDropTarget(target);
				isAccepted = false;
				if(dropTarget)
				{
					dropTargetLocalX = location.x;
					dropTargetLocalY = location.y;
					dropTarget.dispatchEvent(new DragDropEvent(DragDropEvent.DRAG_ENTER, _dragData, false, dropTargetLocalX, dropTargetLocalY));
				}
			}
			else if(dropTarget)
			{
				dropTargetLocalX = location.x;
				dropTargetLocalY = location.y;
				dropTarget.dispatchEvent(new DragDropEvent(DragDropEvent.DRAG_MOVE, _dragData, false, dropTargetLocalX, dropTargetLocalY));
			}
		}

		/**
		 * @private
		 */

		protected static function nativeStage_keyDownHandler(event:KeyboardEvent):void
		{
			if(event.keyCode == LoomKey.ESCAPE || event.keyCode == LoomKey.BUTTON_BACK)
			{
				cancelDrag();
			}
		}

		/**
		 * @private
		 */
		protected static function stage_touchHandler(event:TouchEvent):void
		{
			const stage:Stage = Loom2D.stage;
			const touches:Vector.<Touch> = event.getTouches(stage, null, HELPER_TOUCHES_VECTOR);
			if(touches.length == 0 || _touchPointID < 0)
			{
				HELPER_TOUCHES_VECTOR.length = 0;
				return;
			}
			var touch:Touch;
			for each(var currentTouch:Touch in touches)
			{
				if(currentTouch.id == _touchPointID)
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
			if(touch.phase == TouchPhase.MOVED)
			{
				HELPER_POINT = touch.getLocation(stage);
				if(avatar)
				{
					avatar.x = HELPER_POINT.x + avatarOffsetX;
					avatar.y = HELPER_POINT.y + avatarOffsetY;
				}
				updateDropTarget(HELPER_POINT);
			}
			else if(touch.phase == TouchPhase.ENDED)
			{
				_touchPointID = -1;
				var isDropped:Boolean = false;
				if(dropTarget && isAccepted)
				{
					dropTarget.dispatchEvent(new DragDropEvent(DragDropEvent.DRAG_DROP, _dragData, true, dropTargetLocalX, dropTargetLocalY));
					isDropped = true;
				}
				dropTarget = null;
				completeDrag(isDropped);
			}
			HELPER_TOUCHES_VECTOR.length = 0;
		}
	}
}
