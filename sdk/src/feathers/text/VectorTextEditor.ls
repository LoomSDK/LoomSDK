package feathers.text
{
    import feathers.text.VectorTextRenderer;
    import loom.Application;
    import loom.ApplicationEvents;    
    import loom.platform.IMEDelegate;
    import loom.platform.LoomKeyboardType;
    import loom2d.animation.Transitions;
    import loom2d.display.TextAlign;
    import loom2d.Loom2D;
    import loom2d.display.Quad;
    import loom2d.display.DisplayObject;
    import loom2d.display.Stage;
    import loom2d.math.Point;
    import loom2d.math.Rectangle;
    import loom2d.events.Event;
    import loom2d.events.EnterFrameEvent;
    import loom2d.animation.DelayedCall;
    import feathers.core.ITextEditor;
    import feathers.events.FeathersEventType;    
    import feathers.text.TextFormatAlign;
    import system.platform.Platform;
    import system.platform.PlatformType;
    
    /**
     * Feathers text editor implementation using Graphics vector font rendering.
     * It handles multiple text editors, Stage shifting from soft keyboards (on Android),
     * Input Method Editor support and other various text handling.
     * 
     * Use by returning it to the `textEditorFactory` and/or `stepperTextEditorFactory` of the Feathers theme.
     */
    public class VectorTextEditor extends VectorTextRenderer implements ITextEditor
    {
        /**
         * Used for input, IME support which includes handling the soft keyboard.
         */
        protected var _imeDelegate:IMEDelegate;
        
        protected var _displayAsPassword:Boolean = false;
        protected var _maxChars:int;
        protected var _restrict:String = "";
        protected var _isEditable:Boolean = true;
        protected var _keyboardType:LoomKeyboardType = 0;
        
        /** The rectangle display used for rendering the caret. */
        protected var _caretQuad:Quad = new Quad(2, 16, 0x000000);
        
        /** The delayed call used for blinking the caret. */
        protected var _cursorDelayedCall:DelayedCall;
        
        /** The caret blink delay in seconds. */
        protected var _cursorBlinkDelay = 0.7;
        
        /** The margin between the bottom of the text field and the top of the soft keyboard. */
        protected var _keyboardSafeZone = 16;

        /** Used to hold the current composition candidate. */
        protected var _composition:String = "";
        
        /**
         * The stage is scrolled when bringing up IME text entry and the text editor is obscured 
         * this is the Y value of the scroll. Only used on Android for now. iOS uses the SDL provided scroll.
         */
        private var _stageTargetY:Number = 0;

        /**
         * Tracks the current editor, this is important as there may be a number
         * of editors on the screen and the user can switch between them by selecting them
         * which can cause timing issues as the IME keyboard opens/closes to deal with selection.
         */
        protected static var _currentEditor:VectorTextEditor = null;
        
        /**
         * If an editor is focused and another editor is selected we have to wait for
         * the soft keyboard to close first (on Android). This holds the reference to
         * the second editor while the keyboard is closing.
         */
        protected static var _pendingEditor:VectorTextEditor = null;
        
        /** Keyboard state for when the keyboard is closed. */
        protected static const KEYBOARD_CLOSED = 0;
        /** Keyboard state for when the keyboard is closing. */
        protected static const KEYBOARD_CLOSING = 1;
        /** Keyboard state for when the keyboard is opening. */
        protected static const KEYBOARD_OPENING = 2;
        /** Keyboard state for when the keyboard is opened. */
        protected static const KEYBOARD_OPENED = 3;
        
        /**
         * The current soft keyboard state. Only supported on platforms where the keyboard
         * sizing is handled manually via KEYBOARD_RESIZE events (i.e. Android).
         */
        protected static var _keyboardState = KEYBOARD_CLOSED;
        
        public function VectorTextEditor()
        {
            _imeDelegate = new IMEDelegate();
            _imeDelegate.onInsertText += handleInsert;
            _imeDelegate.onDeleteBackward += handleDeleteBackward;
            _imeDelegate.onShowComposition += handleShowComposition;
            _caretQuad.addEventListener( Event.ADDED_TO_STAGE, onCursorAddedToStage );
            _caretQuad.addEventListener( Event.REMOVED_FROM_STAGE, onCursorRemovedFromStage );
            _cursorDelayedCall = new DelayedCall( toggleCursorVisibility, _cursorBlinkDelay );
            _cursorDelayedCall.repeatCount = 0;
            
            // Listen in on application events as we're interested in keyboard size changes
            // to clear focus if user closes the OS keyboard (this works on Android at least)
            Application.event += onAppEvent;
        }
        
        public function dispose():void
        {
            _imeDelegate.onInsertText -= handleInsert;
            _imeDelegate.onDeleteBackward -= handleDeleteBackward;
            _imeDelegate.onShowComposition -= handleShowComposition;
            Application.event -= onAppEvent;
            
            // if we're the current editor, make sure we clear the reference            
            if (_currentEditor == this)
                _currentEditor = null;
            if (_pendingEditor == this)
                _pendingEditor = null;
        }
        
        /**
         * Used for keyboard resize events meant for manual Stage scrolling (Android only for now).
         * @param type
         * @param payload
         */
        protected function onAppEvent(type:String, payload:String)        
        {
            if (type == ApplicationEvents.KEYBOARD_RESIZE)
            {            
                var stage = Loom2D.stage;
                
                var resize = int(payload);
                
                // If we're closing the IME text entry box, undo the stage shift.
                if (resize == 0)
                {
                    var closed = false;
                    if (_keyboardState == KEYBOARD_CLOSING && (_pendingEditor == null || _pendingEditor == this)) {
                        panStage();
                        closed = true;
                        _keyboardState = KEYBOARD_CLOSED;
                    }
                    
                    // If we're the current editor and we have focus, clear it.
                    if (_currentEditor == this)
                    {
                        //trace("Native keyboard closed, clearing focus");
                        panStage();
                        clearFocus();
                        _keyboardState = KEYBOARD_CLOSED;
                    }

                    if (closed && _pendingEditor) {
                        var editor = _pendingEditor;
                        _pendingEditor = null;
                        editor.setFocus();
                    }
                }
                else if (_currentEditor == this)
                {
                    _keyboardState = KEYBOARD_OPENED;

                    // resize is in device points, so we need to scale by stageHeight
                    var scale = stage.stageHeight / stage.nativeStageHeight;
                    resize *= scale;
                    
                    // find the bounds of the text edit field, used to test if 
                    // we're obscured or not (and thus need to scroll)
                    var bounds = getBounds(stage);
                    
                    // detect whether we need to scroll
                    if ((stage.stageHeight - bounds.bottom) < (resize + _keyboardSafeZone))
                    {
                        // we need to scroll!  We do this with some animation
                        // so the user's eye can follow what is happening
                        panStage(bounds, resize, scale);
                    } else {
                        panStage();
                    }
                }
                 
            }
        }
        
        /**
         * Pans/scrolls the stage based on the provided text field bounds, keyboard size
         * and display scale.
         * @param bounds    The bounds of the text field to pan to.
         * @param keyboardSize  The height of the soft keyboard.
         * @param scale The display scale to convert from stage points to device points.
         */
        protected function panStage(bounds:Rectangle = null, keyboardSize:Number = 0, scale:Number = 1)
        {
            if (bounds) {
                //trace("Panning stage to field");
                _stageTargetY = (stage.stageHeight - keyboardSize - bounds.bottom - _keyboardSafeZone) / scale;
                Loom2D.juggler.removeTweens(stage);
                Loom2D.juggler.tween(stage, 0.2, { y: _stageTargetY, transition: Transitions.EASE_OUT } );
            } else {
                //trace("Panning stage to origin");
                _stageTargetY = 0;
                Loom2D.juggler.removeTweens(stage);
                Loom2D.juggler.tween(stage, 0.3, { y: _stageTargetY, transition: Transitions.EASE_IN_OUT } );
            }
        }
        
        /**
         * Handle text input.
         * @param inText    The text to input.
         * @param length    The length of the text.
         */
        protected function handleInsert(inText:String, length:int):void
        {
            if(_currentEditor != this) return;
            
            if(!_isEditable)
                return;

            if(inText == "\n")
            {
                // We only support single line text input for now.
                trace("Line break detected, clearing focus");
                clearFocus();
            }

            text += inText;
            
            updateInput();
        }
        
        /**
         * Handle back-deletion of text (backspace).
         */
        protected function handleDeleteBackward():void
        {
            if(_currentEditor != this) return;
            
            if(!_isEditable)
                return;

            if(text.length > 0)
            {
                //check for a UTF8 character to make sure we delete them fully
                //NOTE: This only supports Latin UTF8 characters for now. Others alphabets such as Cyrillic or Mandarin will have unexpected results
                var newTextLen:int = text.length - 1;
                var endCharID:int = text.charCodeAt(newTextLen - 1);
                if((endCharID == 0xC2) || (endCharID == 0xC3))
                {
                    newTextLen--;
                }
                text = text.substr(0, newTextLen);            
            }
            
            updateInput();
        }
        
        /**
         * Handle the display of the currently selected IME composition candidate.
         * @param inText    The candidate to show.
         * @param len   The length of the candidate to show.
         * @param start The location to begin editing from.
         * @param length    The number of characters to edit from the start point.
         */
        protected function handleShowComposition(inText:String, len:int, start:int, length:int):void
        {
            if(_currentEditor != this) return;
            
            _composition = inText && inText.length > 0 ? inText : "";
            invalidate();
            updateInput();
        }
        
        /**
         * Updates various things after text change.
         * Keeps caret visible after edit.
         * Updates the IME text input rectangle.
         */
        private function updateInput() {
            // Use our improved implementation on Android for
            // the keyboard shift, use SDL implementation on others
            if (Platform.getPlatform() != PlatformType.ANDROID) {
                var tl = localToGlobal(new Point(0, 0));
                var br = localToGlobal(new Point(width, height));
                var rw = stage.nativeStageWidth/stage.stageWidth;
                var rh = stage.nativeStageHeight/stage.stageHeight;
                tl.x *= rw;
                tl.y *= rh;
                br.x *= rw;
                br.y *= rh;
                _imeDelegate.setTextInputRect(new Rectangle(tl.x, tl.y, br.x-tl.x, br.y-tl.y));
            }
            _caretQuad.visible = true;
            _cursorDelayedCall.advanceTime(-_cursorDelayedCall.currentTime);
        }
        
        /**
         * Directly set the text of the editor.
         * The text gets filtered by `restrict` and `maxChars`.
         */
        public function set text(v:String):void
        {
            // For now, don't allow tabs or newlines.
            var _localRestrict = "\t\n\r";

            // Restrict characters.
            for(var i:int=0; i<v.length; i++)
            {
                var curChar = v.charAt(i);
                if(_restrict.indexOf(curChar) == -1 && _localRestrict.indexOf(curChar) == -1)
                    continue;

                // Splice it out.
                var part1 = v.substring(0, i);
                var part2 = v.substr(i+1);
                v = part1 + part2;
                i--;
            }

            // Enforce length.
            if(v.length > maxChars && maxChars > 0)
                v = v.substr(0, maxChars);

            super.text = v;
            _imeDelegate.contentText = v;
            invalidate();
            dispatchEvent(new Event(Event.CHANGE));
        }
        
        /**
         * Rewrite text before it's displayed.
         * Provides candidate display and password replacement.
         * @param input The text before rewriting.
         * @return  The text after rewriting.
         */
        protected function processDisplayText(input:String):String
        {
            input += _composition;
            
            if(displayAsPassword)
            {
                var s:String = "";
                for(var i=0; i<input.length; i++)
                    s += "*";
                return s;
            }

            return input;
        }
        
        /**
         * The keyboard type to show with soft keyboards.
         * Currently only the default type is supported.
         */
        public function get keyboardType():LoomKeyboardType
        {
            return _keyboardType;
        }
        
        /**
         * The keyboard type to show with soft keyboards.
         * Currently only the default type is supported.
         */
        public function set keyboardType( value:LoomKeyboardType ):void
        {
            _keyboardType = value;
        }
        
        /**
         * Displays all the characters as stars.
         */
        public function get displayAsPassword():Boolean
        {
            return _displayAsPassword;
        }

        /**
         * Displays all the characters as stars.
         */
        public function set displayAsPassword(value:Boolean):void
        {
            _displayAsPassword = value;

            invalidate();
        }

        /**
         * The maximum number of characters allowed or 0 for unlimited.
         */
        public function get maxChars():int
        {
            return _maxChars;
        }

        /**
         * The maximum number of characters allowed or 0 for unlimited.
         */
        public function set maxChars(value:int):void
        {
            _maxChars = value;
        }
        
        /**
         * Strip out the provided characters.
         */
        public function get restrict():String
        {
            return _restrict;
        }
        
        /**
         * Strip out the provided characters.
         */
        public function set restrict(value:String):void
        {
            _restrict = value;
        }

        /**
         * Allow the editing of text. The text can't be changed if disabled.
         */
        public function get isEditable():Boolean
        {
            return _isEditable;
        }

        /**
         * Allow the editing of text. The text can't be changed if disabled.
         */
        public function set isEditable(value:Boolean):void
        {
            _isEditable = value;
        }
        
        /**
         * Determines if the owner should call setFocus() on TouchPhase.ENDED or on TouchPhase.BEGAN.
         */
        public function get setTouchFocusOnEndedPhase():Boolean
        {
            return true;
        }
        
        /**
         * Called when the editor gains focus.
         */
        public function setFocus():void
        {
            if(_currentEditor != null) return;
            if(_currentEditor == this) return;
            if (_keyboardState == KEYBOARD_CLOSING) {
                //trace("Pending focus due to keyboard closing");
                _pendingEditor = this;
                return;
            }
            //trace("Attaching IME");
            updateInput();
            addChild(_caretQuad);
            _currentEditor = this;
            dispatchEventWith(FeathersEventType.FOCUS_IN);
            _keyboardState = KEYBOARD_OPENING;
            _imeDelegate.attachWithIME( _keyboardType );
        }
        
        /**
         * Called when the editor's focus gets cleared either through
         * internal or external means (background pressed, soft keyboard closed, etc).
         */
        public function clearFocus():void
        {
            if (_currentEditor != this) return;
            //trace("Detaching IME");
            _currentEditor = null;
            removeChild( _caretQuad, false );
            if (_keyboardState == KEYBOARD_OPENED) {
                _keyboardState = KEYBOARD_CLOSING;
                //trace("Keyboard closing");
            }
            _imeDelegate.detachWithIME();
            dispatchEventWith(FeathersEventType.FOCUS_OUT);
        }
        
        /**
         * Currently unsupported.
         * Sets the range of selected characters.
         * If both values are the same, the text insertion position is changed and nothing is selected.
         * @param startIndex    The starting index of the selection.
         * @param endIndex  The ending index of the selection.
         */
        public function selectRange(startIndex:int, endIndex:int):void
        {
        }
        
        /**
         * Render the text and caret.
         */
        public function validate():void
        {
            _shape.setClipRect(0, 0, width, height);
            
            var tmp:String = processDisplayText(_text);
            var advance:Number = g.textLineAdvance(_textFormat, 0, 0, tmp);
            
            if (advance >= width) {
                _caretQuad.x = width;
                _offset = width-advance;
            } else {
                _caretQuad.x = advance;
                _offset = 0;
            }
            
            super.validate();
            
            var caretHeight:Number = _textFormat.size != NaN ? _textFormat.size : _textFormat.lineHeight; 
            _caretQuad.width = 2;
            _caretQuad.height = caretHeight;
            _caretQuad.y = (height - caretHeight) / 2;
            _caretQuad.color = _textFormat.color;
        }
        
        /**
         * Start blinking the caret when added to the stage.
         */
        private function onCursorAddedToStage( e:Event ):void
        {
            Loom2D.juggler.add( _cursorDelayedCall );
        }
        
        /**
         * Stop blinking the caret when removed from the stage.
         */
        private function onCursorRemovedFromStage( e:Event ):void
        {
            Loom2D.juggler.remove( _cursorDelayedCall );
        }
        
        /**
         * One half of a caret blink.
         */
        private function toggleCursorVisibility():void
        {
            _caretQuad.visible = !_caretQuad.visible;
            // Fancier fading
            //Loom2D.juggler.removeTweens(_caretQuad);
            //Loom2D.juggler.tween(_caretQuad, 0.1, { alpha: _caretQuad.alpha == 0 ? 1 : 0 } );
        }
        
    }
}