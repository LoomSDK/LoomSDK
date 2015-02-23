package com.modestmaps.extras.ui {

	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.display.Shape;
	import flash.display.StageDisplayState;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	public class FullScreenButton extends Button
	{	
		private var outIcon:Shape = new Shape();
		private var inIcon:Shape = new Shape();
		
		public function FullScreenButton()
		{
	        // draw out arrows
	        outIcon.graphics.lineStyle(1, 0x000000, 1.0, true, "normal", CapsStyle.NONE, JointStyle.BEVEL);
	        outIcon.graphics.moveTo(8,5);
	        outIcon.graphics.lineTo(4,4);
	        outIcon.graphics.lineTo(5,8);
	
	        outIcon.graphics.moveTo(11,5);
	        outIcon.graphics.lineTo(15,4);
	        outIcon.graphics.lineTo(14,8);
	
	        outIcon.graphics.moveTo(8,14);
	        outIcon.graphics.lineTo(4,15);
	        outIcon.graphics.lineTo(5,11);
	
	        outIcon.graphics.moveTo(11,14);
	        outIcon.graphics.lineTo(15,15);
	        outIcon.graphics.lineTo(14,11);
	        addChild(outIcon);
	
	        // draw out arrows
	        inIcon.graphics.lineStyle(1, 0x000000, 1.0, true, "normal", CapsStyle.NONE, JointStyle.BEVEL);
	        inIcon.graphics.moveTo(7,4);
	        inIcon.graphics.lineTo(8,8);
	        inIcon.graphics.lineTo(4,7);
	
	        inIcon.graphics.moveTo(12,4);
	        inIcon.graphics.lineTo(11,8);
	        inIcon.graphics.lineTo(15,7);
	
	        inIcon.graphics.moveTo(7,15);
	        inIcon.graphics.lineTo(8,11);
	        inIcon.graphics.lineTo(4,12);
	
	        inIcon.graphics.moveTo(12,15);
	        inIcon.graphics.lineTo(11,11);
	        inIcon.graphics.lineTo(15,12);
	        //addChild(inIcon);
		    
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(event:Event):void
		{
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreenEvent);
			
			// create the context menu, remove the built-in items,
			// and add our custom items
			var fullScreenCM:ContextMenu = new ContextMenu();
			fullScreenCM.hideBuiltInItems();
	
			var fs:ContextMenuItem = new ContextMenuItem("Go Full Screen" );
			fs.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, goFullScreen);
			fullScreenCM.customItems.push(fs);
	
			var xfs:ContextMenuItem = new ContextMenuItem("Exit Full Screen");
			xfs.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, exitFullScreen);
			fullScreenCM.customItems.push(xfs);
			
			// finally, attach the context menu to the parent
			this.parent.contextMenu = fullScreenCM;
		}
		
		public function toggleFullScreen(event:Event=null):void
		{
			if (stage.displayState == StageDisplayState.FULL_SCREEN) {
				exitFullScreen();
			}
			else {
				goFullScreen();
			}
		}
		
	 	// functions to enter and leave full screen mode
		public function goFullScreen(event:Event=null):void
		{
			try {
				stage.displayState = StageDisplayState.FULL_SCREEN;
			}
			catch(err:Error) {
				trace("Dang fullScreen is not allowed here");
			}
		}
		public function exitFullScreen(event:Event=null):void
		{
			try {
	    		stage.displayState = StageDisplayState.NORMAL;
			}
			catch(err:Error) {
			    trace("Problem setting displayState to normal, sorry");
			}
		}
		
		// function to enable and disable the context menu items,
		// based on what mode we are in.
		public function onFullScreenEvent(event:Event):void
		{
		   	if (stage.displayState == StageDisplayState.FULL_SCREEN)
		   	{
		   	    if (contains(outIcon)) {
		   	        removeChild(outIcon);
		   	    }
		   	    if (!contains(inIcon)) {
		   	        addChild(inIcon);
		   	    }
		    	this.parent.contextMenu.customItems[0].enabled = false;
		    	this.parent.contextMenu.customItems[1].enabled = true;
			}
		   	else
		   	{
		   	    if (!contains(outIcon)) {
		   	        addChild(outIcon);
		   	    }
		   	    if (contains(inIcon)) {
		   	        removeChild(inIcon);
		   	    }
		    	this.parent.contextMenu.customItems[0].enabled = true;
		    	this.parent.contextMenu.customItems[1].enabled = false;
		   	}
		}	
	}

}