package feathers.text
{
    import loom.Application;
    import loom.ApplicationEvents;	
	import loom.platform.IMEDelegate;
	import loom.platform.LoomKeyboardType;
	import loom2d.Loom2D;
	import loom2d.display.Quad;
	import loom2d.math.Point;
	import loom2d.math.Rectangle;
	import loom2d.events.Event;
	import loom2d.animation.DelayedCall;
	import feathers.core.ITextEditor;
	import feathers.events.FeathersEventType;
	import feathers.text.TextFormatAlign;

	public class BitmapFontTextEditor extends BitmapFontTextRenderer implements ITextEditor
	{
		protected var imeDelegate:IMEDelegate;
		protected var editableText:String;
		protected var _displayAsPassword:Boolean = false;
		protected var _maxChars:int;
		protected var _restrict:String = "";
		protected var _isEditable:Boolean = true;
		protected var _keyboardType:LoomKeyboardType = 0;
		protected var _caretQuad:Quad = new Quad(2, 16, 0x000000);
		protected var _hasIMEFocus:Boolean = false;
		protected var _cursorDelayedCall:DelayedCall;

		public function BitmapFontTextEditor()
		{
			imeDelegate = new IMEDelegate();
			imeDelegate.onInsertText += handleInsert;
			imeDelegate.onDeleteBackward += handleDeleteBackward;
            _caretQuad.addEventListener( Event.ADDED_TO_STAGE, onCursorAddedToStage );
            _caretQuad.addEventListener( Event.REMOVED_FROM_STAGE, onCursorRemovedFromStage );
            _cursorDelayedCall = new DelayedCall( toggleCursorVisibility, 0.7 );
            _cursorDelayedCall.repeatCount = 0;

            // Listen in on application events as we're interested in keyboard size changes
            // to clear focus if user closes the OS keyboard (this works on iOS and Android)
            Application.event += onAppEvent;
		}

		public function dispose():void
		{
			imeDelegate.onInsertText -= handleInsert;
			imeDelegate.onDeleteBackward -= handleDeleteBackward;		
			Application.event -= onAppEvent;	
		}

		protected function onAppEvent(type:String, payload:String)		
		{
			// if we're resizing keyboard to 0 (hiding it), clear focus
			if (type == ApplicationEvents.KEYBOARD_HIDE && _hasIMEFocus)
			{				
				clearFocus();
			}			
		}

		protected function handleInsert(inText:String, length:int):void
		{
			if(!_isEditable)
				return;

			text += inText;
		}

		protected function handleDeleteBackward():void
		{
			if(!_isEditable)
				return;

			if(text.length > 0)
				text = text.substr(0, text.length-1);			
		}

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
			imeDelegate.contentText = v;
			invalidate();
			dispatchEvent(new Event(Event.CHANGE));
		}

		protected function processDisplayText(input:String):String
		{
			if(displayAsPassword)
			{
				var s:String = "";
				for(var i=0; i<input.length; i++)
					s += "*";
				return s;
			}

			return input;
		}

		public function get keyboardType():LoomKeyboardType
		{
			return _keyboardType;
		}
		
		public function set keyboardType( value:LoomKeyboardType ):void
		{
			_keyboardType = value;
		}
		
		public function get displayAsPassword():Boolean
		{
			return _displayAsPassword;
		}

		public function set displayAsPassword(value:Boolean):void
		{
			_displayAsPassword = value;

			invalidate();
		}

		public function get maxChars():int
		{
			return _maxChars;
		}

		public function set maxChars(value:int):void
		{
			_maxChars = value;
		}

		public function get restrict():String
		{
			return _restrict;
		}

		public function set restrict(value:String):void
		{
			_restrict = value;
		}

		public function get isEditable():Boolean
		{
			return _isEditable;
		}

		public function set isEditable(value:Boolean):void
		{
			_isEditable = value;
		}

		public function get setTouchFocusOnEndedPhase():Boolean
		{
			return true;
		}

		public function setFocus():void
		{
            if(!_hasIMEFocus)
			{
				//trace("Attaching IME");
                imeDelegate.attachWithIME( _keyboardType );
				addChild(_caretQuad);
				_hasIMEFocus = true;
                dispatchEventWith(FeathersEventType.FOCUS_IN);              
			}
		}

		public function clearFocus():void
		{
			if(_hasIMEFocus)
			{
				//trace("Detaching IME");
	            imeDelegate.detachWithIME();
    			_hasIMEFocus = false;
				removeChild( _caretQuad, false );
                dispatchEventWith(FeathersEventType.FOCUS_OUT);             
    	   }
		}

		public function selectRange(startIndex:int, endIndex:int):void
		{
		}

		public function validate():void
		{
			super.validate();

			// Add a caret to the quadbatch.
			var bounds:Rectangle = _quadBatch.getBounds(_quadBatch);

			// Just show a centered caret if we have no bounds.
			if(bounds.width > 0)
			{
				_caretQuad.x = bounds.right;
			}
			else
			{
				// Position based on alignment.
				switch(align)
				{
					case TextFormatAlign.LEFT:
						_caretQuad.x = 3;
						break;
					case TextFormatAlign.CENTER:
						_caretQuad.x = explicitWidth / 2;
						break;
					case TextFormatAlign.RIGHT:
						_caretQuad.x = explicitWidth - 3;
						break;
				}
			}

            var caretHeight:Number = _textFormat.size != NaN ? _textFormat.size : _textFormat.font.lineHeight; 
            _caretQuad.width = 2;
            _caretQuad.height = caretHeight;
			_caretQuad.y = (height - caretHeight) / 2;
            _caretQuad.color = _textFormat.color;
		}
		
        private function onCursorAddedToStage( e:Event ):void
        {
            Loom2D.juggler.add( _cursorDelayedCall );
        }
        
        private function onCursorRemovedFromStage( e:Event ):void
        {
            Loom2D.juggler.remove( _cursorDelayedCall );
        }
        
        private function toggleCursorVisibility():void
        {
            _caretQuad.visible = !_caretQuad.visible;
        }
        
	}
}