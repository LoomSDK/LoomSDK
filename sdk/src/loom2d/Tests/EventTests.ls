// =================================================================================================
//
//  Starling Framework
//  Copyright 2011 Gamua OG. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.tests
{
    import loom2d.display.Sprite;
    import loom2d.events.Event;
    import loom2d.events.EventDispatcher;
    
    /**
     * Tests for the Event class and friends.
     */
    public class EventTest
    {       
        
        public function run()
        {
            trace("Test bubbling.");
            testBubbling();
            trace("Test test bubble with modified chain.");
            testBubbleWithModifiedChain();
            trace("Test duplicate event handler.");
            testDuplicateEventHandler();
            trace("Test redispatch");
            testRedispatch();
            trace("Test remove event listeners.");
            testRemoveEventListeners();
            trace("Test stop propagation.");
            testStopPropagation();
        }
        
        [Test]
        public function testBubbling():void
        {
            const eventType:String = "test";
            
            var grandParent:Sprite = new Sprite();
            var parent:Sprite = new Sprite();
            var child:Sprite = new Sprite();
            
            var grandParentEventHandlerHit:Boolean = false;
            var parentEventHandlerHit:Boolean = false;
            var childEventHandlerHit:Boolean = false;
            var hitCount:int = 0; 
            
            var onGrandParentEvent = function(event:Event):void
            {
                grandParentEventHandlerHit = true;                
                Assert.assertEquals(child, event.target);
                Assert.assertEquals(grandParent, event.currentTarget);
                hitCount++;
            };
            
            var onParentEvent = function(event:Event):void
            {
                parentEventHandlerHit = true;                
                Assert.assertEquals(child, event.target);
                Assert.assertEquals(parent, event.currentTarget);
                hitCount++;
            };
            
            var onChildEvent = function(event:Event):void
            {
                childEventHandlerHit = true;                               
                Assert.assertEquals(child, event.target);
                Assert.assertEquals(child, event.currentTarget);
                hitCount++;
            };
            
            grandParent.addChild(parent);
            parent.addChild(child);
            
            // bubble up
            
            grandParent.addEventListener(eventType, onGrandParentEvent);
            parent.addEventListener(eventType, onParentEvent);
            child.addEventListener(eventType, onChildEvent);
            
            var event:Event = new Event(eventType, true);
            
            child.dispatchEvent(event);
            
            Assert.assertTrue(grandParentEventHandlerHit);
            Assert.assertTrue(parentEventHandlerHit);
            Assert.assertTrue(childEventHandlerHit);
            
            Assert.assertEquals(3, hitCount);
            
            // remove event handler
            
            parentEventHandlerHit = false;
            parent.removeEventListener(eventType, onParentEvent);
            child.dispatchEvent(event);
            
            Assert.assertFalse(parentEventHandlerHit);
            Assert.assertEquals(5, hitCount);
            
            // don't bubble
            
            event = new Event(eventType);
            
            grandParentEventHandlerHit = parentEventHandlerHit = childEventHandlerHit = false;
            parent.addEventListener(eventType, onParentEvent);
            child.dispatchEvent(event);
            
            Assert.assertEquals(6, hitCount);
            Assert.assertTrue(childEventHandlerHit);
            Assert.assertFalse(parentEventHandlerHit);
            Assert.assertFalse(grandParentEventHandlerHit);
        }
        
        [Test]
        public function testStopPropagation():void
        {
            const eventType:String = "test";
            
            var grandParent:Sprite = new Sprite();
            var parent:Sprite = new Sprite();
            var child:Sprite = new Sprite();
            
            grandParent.addChild(parent);
            parent.addChild(child);
            
            var hitCount:int = 0;
            
            var onEvent = function(event:Event):void
            {
                hitCount++;
            };
            
            var onEvent_StopPropagation = function(event:Event):void
            {
                event.stopPropagation();
                hitCount++;
            };
            
            var onEvent_StopImmediatePropagation = function(event:Event):void
            {
                event.stopImmediatePropagation();
                hitCount++;
            };
            
            
            // stop propagation at parent
            
            child.addEventListener(eventType, onEvent);
            parent.addEventListener(eventType, onEvent_StopPropagation);
            parent.addEventListener(eventType, onEvent);
            grandParent.addEventListener(eventType, onEvent);
            
            child.dispatchEvent(new Event(eventType, true));
            
            Assert.assertEquals(3, hitCount);
            
            // stop immediate propagation at parent
            
            parent.removeEventListener(eventType, onEvent_StopPropagation);
            parent.removeEventListener(eventType, onEvent);
            
            parent.addEventListener(eventType, onEvent_StopImmediatePropagation);
            parent.addEventListener(eventType, onEvent);
            
            child.dispatchEvent(new Event(eventType, true));
            
            Assert.assertEquals(5, hitCount);
            
        }
        
        [Test]
        public function testRemoveEventListeners():void
        {
            var hitCount:int = 0;
            var dispatcher:EventDispatcher = new EventDispatcher();

            var onEvent = function(event:Event):void
            {
                ++hitCount;
            };

            
            dispatcher.addEventListener("Type1", onEvent);
            dispatcher.addEventListener("Type2", onEvent);
            dispatcher.addEventListener("Type3", onEvent);
            
            hitCount = 0;
            dispatcher.dispatchEvent(new Event("Type1"));
            Assert.assertEquals(1, hitCount);
            
            dispatcher.dispatchEvent(new Event("Type2"));
            Assert.assertEquals(2, hitCount);
            
            dispatcher.dispatchEvent(new Event("Type3"));
            Assert.assertEquals(3, hitCount);
            
            hitCount = 0;
            dispatcher.removeEventListener("Type1", onEvent);
            dispatcher.dispatchEvent(new Event("Type1"));
            Assert.assertEquals(0, hitCount);
            
            dispatcher.dispatchEvent(new Event("Type3"));
            Assert.assertEquals(1, hitCount);
            
            hitCount = 0;
            dispatcher.removeEventListeners();
            dispatcher.dispatchEvent(new Event("Type1"));
            dispatcher.dispatchEvent(new Event("Type2"));
            dispatcher.dispatchEvent(new Event("Type3"));
            Assert.assertEquals(0, hitCount);
            
        }
        
        /*[Test]
        public function testBlankEventDispatcher():void
        {
            var dispatcher:EventDispatcher = new EventDispatcher();
            
            Helpers.assertDoesNotThrow(function():void
            {
                dispatcher.removeEventListener("Test", null);
            });
            
            Helpers.assertDoesNotThrow(function():void
            {
                dispatcher.removeEventListeners("Test");
            });
        }*/
        
        [Test]
        public function testDuplicateEventHandler():void
        {
            var dispatcher:EventDispatcher = new EventDispatcher();
            var callCount:int = 0;

            var onEvent = function(event:Event):void
            {
                callCount++;
            };

            dispatcher.addEventListener("test", onEvent);
            dispatcher.addEventListener("test", onEvent);
            
            dispatcher.dispatchEvent(new Event("test"));
            Assert.assertEquals(1, callCount);
            
        }
        
        [Test]
        public function testBubbleWithModifiedChain():void
        {

            const eventType:String = "test";
            
            var grandParent:Sprite = new Sprite();
            var parent:Sprite = new Sprite();
            var child:Sprite = new Sprite();
            
            grandParent.addChild(parent);
            parent.addChild(child);
            
            var hitCount:int = 0;
            
            var onEvent = function():void
            {
                hitCount++;
            };
            
            var onEvent_removeFromParent = function():void
            {
                parent.removeFromParent();
            };

            // listener on 'child' changes display list; bubbling must not be affected.
            
            grandParent.addEventListener(eventType, onEvent);
            parent.addEventListener(eventType, onEvent);
            child.addEventListener(eventType, onEvent);
            child.addEventListener(eventType, onEvent_removeFromParent);
            
            child.dispatchEvent(new Event(eventType, true));
            
            Assert.assertNull(parent.parent);
            Assert.assertEquals(3, hitCount);
            
        }
        
        [Test]
        public function testRedispatch():void
        {
            const eventType:String = "test";
            
            var grandParent = new Sprite();
            var parent = new Sprite();
            var child = new Sprite();
            
            var targets = [];
            var currentTargets = [];

            var onEvent = function (event:Event):void
            {
                targets.push(event.target);
                currentTargets.push(event.currentTarget);
            };
            
            var onEvent_redispatch:Function = function(event:Event):void
            {
                parent.removeEventListener(eventType, onEvent_redispatch);
                parent.dispatchEvent(event);
            };

            grandParent.addChild(parent);
            parent.addChild(child);
            
            grandParent.addEventListener(eventType, onEvent);
            parent.addEventListener(eventType, onEvent);
            child.addEventListener(eventType, onEvent);
            parent.addEventListener(eventType, onEvent_redispatch);
            
            
            child.dispatchEventWith(eventType, true);
            
            // main bubble
            Assert.assertEquals(targets[0], child);
            Assert.assertEquals(currentTargets[0], child);
            
            // main bubble
            Assert.assertEquals(targets[1], child);
            Assert.assertEquals(currentTargets[1], parent);
            
            // inner bubble
            Assert.assertEquals(targets[2], parent);
            Assert.assertEquals(currentTargets[2], parent);
            
            // inner bubble
            Assert.assertEquals(targets[3], parent);
            Assert.assertEquals(currentTargets[3], grandParent);
            
            // main bubble
            Assert.assertEquals(targets[4], child);
            Assert.assertEquals(currentTargets[4], grandParent);
            
        }
    }
}