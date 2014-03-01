/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import feathers.controls.text.ITextEditorViewPort;
    import feathers.controls.text.TextFieldTextEditorViewPort;
    import feathers.core.IFocusDisplayObject;
    import feathers.core.PropertyProxy;
    import feathers.events.FeathersEventType;

    import Loom2D.Math.Point;
    import flash.ui.Mouse;
    import flash.ui.MouseCursor;

    import Loom2D.Display.DisplayObject;
    import Loom2D.Events.Event;
    import Loom2D.Events.Touch;
    import Loom2D.Events.TouchEvent;
    import Loom2D.Events.TouchPhase;

    /**
     * Dispatched when the text area's `text` property changes.
     *
     * @eventType starling.events.Event.CHANGE
     */
    [Event(name="change",type="starling.events.Event")]

    /**
     * Dispatched when the text area receives focus.
     *
     * @eventType feathers.events.FeathersEventType.FOCUS_IN
     */
    [Event(name="focusIn",type="starling.events.Event")]

    /**
     * Dispatched when the text area loses focus.
     *
     * @eventType feathers.events.FeathersEventType.FOCUS_OUT
     */
    [Event(name="focusOut",type="starling.events.Event")]

    /**
     * A text entry control that allows users to enter and edit multiple lines
     * of uniformly-formatted text with the ability to scroll.
     *
     * **Important:** `TextArea` is not recommended
     * for mobile. Instead, you should generally use a `TextInput`
     * with a `StageTextTextEditor` that has its `multiline`
     * property set to `true`. In that situation, the
     * `StageText` instance will automatically provide its own
     * scroll bars.
     *
     * **Beta Component:** This is a new component, and its APIs
     * may need some changes between now and the next version of Feathers to
     * account for overlooked requirements or other issues. Upgrading to future
     * versions of Feathers may involve manual changes to your code that uses
     * this component. The
     * [Feathers deprecation policy](http://wiki.starling-framework.org/feathers/deprecation-policy)
     * will not go into effect until this component's status is upgraded from
     * beta to stable.
     *
     * @see http://wiki.starling-framework.org/feathers/text-area
     * @see feathers.controls.TextInput
     * @see http://wiki.starling-framework.org/feathers/text-editors
     */
    public class TextArea extends Scroller implements IFocusDisplayObject
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
        public function TextArea()
        {
            super();

            this.addEventListener(TouchEvent.TOUCH, textArea_touchHandler);
            this.addEventListener(Event.REMOVED_FROM_STAGE, textArea_removedFromStageHandler);
        }

        /**
         * @private
         */
        protected var textEditorViewPort:ITextEditorViewPort;

        /**
         * @private
         */
        protected var _textEditorHasFocus:Boolean = false;

        /**
         * @private
         */
        protected var _isWaitingToSetFocus:Boolean = false;

        /**
         * @private
         */
        protected var _pendingSelectionStartIndex:int = -1;

        /**
         * @private
         */
        protected var _pendingSelectionEndIndex:int = -1;

        /**
         * @private
         */
        protected var _textAreaTouchPointID:int = -1;

        /**
         * @private
         */
        protected var _oldMouseCursor:String = null;

        /**
         * @private
         */
        protected var _ignoreTextChanges:Boolean = false;

        /**
         * @private
         */
        protected var _text:String = "";

        /**
         * The text displayed by the text area. The text area dispatches
         * `Event.CHANGE` when the value of the `text`
         * property changes for any reason.
         *
         * @see #event:change
         */
        public function get text():String
        {
            return this._text;
        }

        /**
         * @private
         */
        public function set text(value:String):void
        {
            if(!value)
            {
                //don't allow null or undefined
                value = "";
            }
            if(this._text == value)
            {
                return;
            }
            this._text = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * @private
         */
        protected var _maxChars:int = 0;

        /**
         * The maximum number of characters that may be entered.
         */
        public function get maxChars():int
        {
            return this._maxChars;
        }

        /**
         * @private
         */
        public function set maxChars(value:int):void
        {
            if(this._maxChars == value)
            {
                return;
            }
            this._maxChars = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _restrict:String;

        /**
         * Limits the set of characters that may be entered.
         */
        public function get restrict():String
        {
            return this._restrict;
        }

        /**
         * @private
         */
        public function set restrict(value:String):void
        {
            if(this._restrict == value)
            {
                return;
            }
            this._restrict = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _isEditable:Boolean = true;

        /**
         * Determines if the text area is editable. If the text area is not
         * editable, it will still appear enabled.
         */
        public function get isEditable():Boolean
        {
            return this._isEditable;
        }

        /**
         * @private
         */
        public function set isEditable(value:Boolean):void
        {
            if(this._isEditable == value)
            {
                return;
            }
            this._isEditable = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _textEditorFactory:Function;

        /**
         * A function used to instantiate the text editor view port. If
         * `null`, a `TextFieldTextEditorViewPort` will
         * be instantiated. The text editor must be an instance of
         * `ITextEditorViewPort`. This factory can be used to change
         * properties on the text editor view port when it is first created. For
         * instance, if you are skinning Feathers components without a theme,
         * you might use this factory to set styles on the text editor view
         * port.
         *
         * The factory should have the following function signature:
         * `function():ITextEditorViewPort`
         *
         * @see feathers.controls.text.ITextEditorViewPort
         * @see feathers.controls.text.TextFieldTextEditorViewPort
         */
        public function get textEditorFactory():Function
        {
            return this._textEditorFactory;
        }

        /**
         * @private
         */
        public function set textEditorFactory(value:Function):void
        {
            if(this._textEditorFactory == value)
            {
                return;
            }
            this._textEditorFactory = value;
            this.invalidate(INVALIDATION_FLAG_TEXT_EDITOR);
        }

        /**
         * @private
         */
        protected var _textEditorProperties:PropertyProxy;

        /**
         * A set of key/value pairs to be passed down to the text area's text
         * editor view port. The text editor view port is an `ITextEditorViewPort`
         * instance that is created by `textEditorFactory`.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * Setting properties in a `textEditorFactory` function
         * instead of using `textEditorProperties` will result in
         * better performance.
         *
         * @see #textEditorFactory
         * @see feathers.controls.text.ITextEditorViewPort
         * @see feathers.controls.text.TextFieldTextEditorViewPort
         */
        public function get textEditorProperties():Object
        {
            if(!this._textEditorProperties)
            {
                this._textEditorProperties = new PropertyProxy(childProperties_onChange);
            }
            return this._textEditorProperties;
        }

        /**
         * @private
         */
        public function set textEditorProperties(value:Object):void
        {
            if(this._textEditorProperties == value)
            {
                return;
            }
            if(!value)
            {
                value = new PropertyProxy();
            }
            if(!(value is PropertyProxy))
            {
                const newValue:PropertyProxy = new PropertyProxy();
                for(var propertyName:String in value)
                {
                    newValue[propertyName] = value[propertyName];
                }
                value = newValue;
            }
            if(this._textEditorProperties)
            {
                this._textEditorProperties.removeOnChangeCallback(childProperties_onChange);
            }
            this._textEditorProperties = PropertyProxy(value);
            if(this._textEditorProperties)
            {
                this._textEditorProperties.addOnChangeCallback(childProperties_onChange);
            }
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @inheritDoc
         */
        override public function showFocus():void
        {
            if(!this._focusManager || this._focusManager.focus != this)
            {
                return;
            }
            this.selectRange(0, this._text.length);
            super.showFocus();
        }

        /**
         * Focuses the text area control so that it may be edited.
         */
        public function setFocus():void
        {
            if(this._textEditorHasFocus)
            {
                return;
            }
            if(this.textEditorViewPort)
            {
                this._isWaitingToSetFocus = false;
                this.textEditorViewPort.setFocus();
            }
            else
            {
                this._isWaitingToSetFocus = true;
                this.invalidate(INVALIDATION_FLAG_SELECTED);
            }
        }

        /**
         * Sets the range of selected characters. If both values are the same,
         * or the end index is `-1`, the text insertion position is
         * changed and nothing is selected.
         */
        public function selectRange(startIndex:int, endIndex:int = -1):void
        {
            if(endIndex < 0)
            {
                endIndex = startIndex;
            }
            if(startIndex < 0)
            {
                throw new RangeError("Expected start index >= 0. Received " + startIndex + ".");
            }
            if(endIndex > this._text.length)
            {
                throw new RangeError("Expected start index > " + this._text.length + ". Received " + endIndex + ".");
            }

            if(this.textEditorViewPort)
            {
                this._pendingSelectionStartIndex = -1;
                this._pendingSelectionEndIndex = -1;
                this.textEditorViewPort.selectRange(startIndex, endIndex);
            }
            else
            {
                this._pendingSelectionStartIndex = startIndex;
                this._pendingSelectionEndIndex = endIndex;
                this.invalidate(INVALIDATION_FLAG_SELECTED);
            }
        }

        /**
         * @private
         */
        override protected function draw():void
        {
            const textEditorInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_TEXT_EDITOR);
            const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);

            if(textEditorInvalid)
            {
                this.createTextEditor();
            }

            if(textEditorInvalid || stylesInvalid)
            {
                this.refreshTextEditorProperties();
            }

            if(textEditorInvalid || dataInvalid)
            {
                const oldIgnoreTextChanges:Boolean = this._ignoreTextChanges;
                this._ignoreTextChanges = true;
                this.textEditorViewPort.text = this._text;
                this._ignoreTextChanges = oldIgnoreTextChanges;
            }

            if(textEditorInvalid || stateInvalid)
            {
                this.textEditorViewPort.isEnabled = this._isEnabled;
                if(!this._isEnabled && Mouse.supportsNativeCursor && this._oldMouseCursor)
                {
                    Mouse.cursor = this._oldMouseCursor;
                    this._oldMouseCursor = null;
                }
            }

            super.draw();

            this.refreshFocusIndicator();

            this.doPendingActions();
        }

        /**
         * @private
         */
        protected function createTextEditor():void
        {
            if(this.textEditorViewPort)
            {
                this.textEditorViewPort.removeEventListener(Event.CHANGE, textEditor_changeHandler);
                this.textEditorViewPort.removeEventListener(FeathersEventType.FOCUS_IN, textEditor_focusInHandler);
                this.textEditorViewPort.removeEventListener(FeathersEventType.FOCUS_OUT, textEditor_focusOutHandler);
                this.textEditorViewPort = null;
            }

            if(this._textEditorFactory != null)
            {
                this.textEditorViewPort = ITextEditorViewPort(this._textEditorFactory());
            }
            else
            {
                this.textEditorViewPort = new TextFieldTextEditorViewPort();
            }
            this.textEditorViewPort.addEventListener(Event.CHANGE, textEditor_changeHandler);
            this.textEditorViewPort.addEventListener(FeathersEventType.FOCUS_IN, textEditor_focusInHandler);
            this.textEditorViewPort.addEventListener(FeathersEventType.FOCUS_OUT, textEditor_focusOutHandler);

            const oldViewPort:ITextEditorViewPort = ITextEditorViewPort(this._viewPort);
            this.viewPort = this.textEditorViewPort;
            if(oldViewPort)
            {
                //the view port setter won't do this
                oldViewPort.dispose();
            }
        }

        /**
         * @private
         */
        protected function doPendingActions():void
        {
            if(this._isWaitingToSetFocus || (this._focusManager && this._focusManager.focus == this))
            {
                this._isWaitingToSetFocus = false;
                if(!this._textEditorHasFocus)
                {
                    this.textEditorViewPort.setFocus();
                }
            }
            if(this._pendingSelectionStartIndex >= 0)
            {
                const startIndex:int = this._pendingSelectionStartIndex;
                const endIndex:int = this._pendingSelectionEndIndex;
                this._pendingSelectionStartIndex = -1;
                this._pendingSelectionEndIndex = -1;
                this.selectRange(startIndex, endIndex);
            }
        }

        /**
         * @private
         */
        protected function refreshTextEditorProperties():void
        {
            this.textEditorViewPort.maxChars = this._maxChars;
            this.textEditorViewPort.restrict = this._restrict;
            this.textEditorViewPort.isEditable = this._isEditable;
            const displayTextEditor:DisplayObject = DisplayObject(this.textEditorViewPort);
            for(var propertyName:String in this._textEditorProperties)
            {
                if(displayTextEditor.hasOwnProperty(propertyName))
                {
                    var propertyValue:Object = this._textEditorProperties[propertyName];
                    this.textEditorViewPort[propertyName] = propertyValue;
                }
            }
        }

        /**
         * @private
         */
        protected function setFocusOnTextEditorWithTouch(touch:Touch):void
        {
            touch.getLocation(this.stage, HELPER_POINT);
            const isInBounds:Boolean = this.contains(this.stage.hitTest(HELPER_POINT, true));
            if(!this._textEditorHasFocus && isInBounds)
            {
                this.globalToLocal(HELPER_POINT, HELPER_POINT);
                HELPER_POINT.x -= this._paddingLeft;
                HELPER_POINT.y -= this._paddingTop;
                this._isWaitingToSetFocus = false;
                this.textEditorViewPort.setFocus(HELPER_POINT);
            }
        }

        /**
         * @private
         */
        protected function textArea_touchHandler(event:TouchEvent):void
        {
            if(!this._isEnabled)
            {
                this._textAreaTouchPointID = -1;
                return;
            }

            const touches:Vector.<Touch> = event.getTouches(this, null, HELPER_TOUCHES_VECTOR);
            if(touches.length == 0)
            {
                //end hover
                if(Mouse.supportsNativeCursor && this._oldMouseCursor)
                {
                    Mouse.cursor = this._oldMouseCursor;
                    this._oldMouseCursor = null;
                }
                return;
            }

            const horizontalScrollBar:DisplayObject = DisplayObject(this.horizontalScrollBar);
            const verticalScrollBar:DisplayObject = DisplayObject(this.verticalScrollBar);
            if(this._textAreaTouchPointID >= 0)
            {
                var touch:Touch;
                for each(var currentTouch:Touch in touches)
                {
                    if(currentTouch.id == this._textAreaTouchPointID)
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
                if(touch.isTouching(verticalScrollBar) || touch.isTouching(horizontalScrollBar))
                {
                    return;
                }
                if(touch.phase == TouchPhase.ENDED)
                {
                    this.removeEventListener(Event.SCROLL, textArea_scrollHandler);
                    this._textAreaTouchPointID = -1;
                    if(this.textEditorViewPort.setTouchFocusOnEndedPhase)
                    {
                        this.setFocusOnTextEditorWithTouch(touch);
                    }
                }
            }
            else
            {
                for each(touch in touches)
                {
                    if(touch.isTouching(verticalScrollBar) || touch.isTouching(horizontalScrollBar))
                    {
                        continue;
                    }
                    if(touch.phase == TouchPhase.BEGAN)
                    {
                        this._textAreaTouchPointID = touch.id;
                        if(!this.textEditorViewPort.setTouchFocusOnEndedPhase)
                        {
                            this.setFocusOnTextEditorWithTouch(touch);
                        }
                        this.addEventListener(Event.SCROLL, textArea_scrollHandler);
                        break;
                    }
                    else if(touch.phase == TouchPhase.HOVER)
                    {
                        if(Mouse.supportsNativeCursor && !this._oldMouseCursor)
                        {
                            this._oldMouseCursor = Mouse.cursor;
                            Mouse.cursor = MouseCursor.IBEAM;
                        }
                        break;
                    }
                }
            }
            HELPER_TOUCHES_VECTOR.length = 0;
        }

        /**
         * @private
         */
        protected function textArea_scrollHandler(event:Event):void
        {
            this.removeEventListener(Event.SCROLL, textArea_scrollHandler);
            this._textAreaTouchPointID = -1;
        }

        /**
         * @private
         */
        protected function textArea_removedFromStageHandler(event:Event):void
        {
            this._isWaitingToSetFocus = false;
            this._textEditorHasFocus = false;
            this._textAreaTouchPointID = -1;
            this.removeEventListener(Event.SCROLL, textArea_scrollHandler);
            if(Mouse.supportsNativeCursor && this._oldMouseCursor)
            {
                Mouse.cursor = this._oldMouseCursor;
                this._oldMouseCursor = null;
            }
        }

        /**
         * @private
         */
        override protected function focusInHandler(event:Event):void
        {
            if(!this._focusManager)
            {
                return;
            }
            super.focusInHandler(event);
            this.setFocus();
        }

        /**
         * @private
         */
        override protected function focusOutHandler(event:Event):void
        {
            if(!this._focusManager)
            {
                return;
            }
            super.focusOutHandler(event);
            this.textEditorViewPort.clearFocus();
            this.invalidate(INVALIDATION_FLAG_STATE);
        }

        /**
         * @private
         */
        protected function textEditor_changeHandler(event:Event):void
        {
            if(this._ignoreTextChanges)
            {
                return;
            }
            this.text = this.textEditorViewPort.text;
        }

        /**
         * @private
         */
        protected function textEditor_focusInHandler(event:Event):void
        {
            this._textEditorHasFocus = true;
            this._touchPointID = -1;
            this.invalidate(INVALIDATION_FLAG_STATE);
            if(this._focusManager)
            {
                this._focusManager.focus = this;
            }
            else
            {
                this.dispatchEventWith(FeathersEventType.FOCUS_IN);
            }
        }

        /**
         * @private
         */
        protected function textEditor_focusOutHandler(event:Event):void
        {
            this._textEditorHasFocus = false;
            this.invalidate(INVALIDATION_FLAG_STATE);
            if(this._focusManager)
            {
                return;
            }
            this.dispatchEventWith(FeathersEventType.FOCUS_OUT);
        }
    }
}
