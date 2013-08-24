/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

/**
 * These classes are based on the PriorityQueue class from as3ds, and as such
 * must include this notice:
 * 
 * DATA STRUCTURES FOR GAME PROGRAMMERS
 * Copyright (c) 2007 Michael Baczynski, http://www.polygonal.de
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
package loom.utils
{
    /**
     * Minimal interface required by SimplePriorityQueue.
     * 
     * Items are prioritized so that the highest priority is returned first.
     * 
     * @see SimplePriorityQueue
     */
    public interface IPrioritizable
    {
        function get priority():int;
        
        /**
         * Change the priority. You only need to implement this if you want
         * SimplePriorityHeap.reprioritize to work. Otherwise it can
         * simply throw an Error.
         */
        function set priority(value:int):void;
    }

    /**
     * A priority queue to manage prioritized data.
     * The implementation is based on the heap structure.
     * 
     * This implementation is based on the as3ds PriorityHeap.
     */
    public class SimplePriorityQueue
    {
        private var _heap:Vector.<IPrioritizable>;
        private var _size:int;
        private var _count:int;
        private var _posLookup:Dictionary.<IPrioritizable, int>;
        
        /**
         * Initializes a priority queue with a given size.
         * 
         * @param size The size of the priority queue.
         */
        public function SimplePriorityQueue(size:int)
        {
            _size = size + 1;
            _heap = new Vector.<IPrioritizable>(_size);
            _posLookup = new Dictionary.<Object, int>; // TODO: Keep weak ref.
            _count = 0;
        }
        
        /**
         * The front item or null if the heap is empty.
         */
        public function get front():IPrioritizable
        {
            return _heap[1];
        }
        
        /**
         * The maximum capacity.
         */
        public function get maxSize():int
        {
            return _size;
        }
        
        /**
         * Enqueues a prioritized item.
         * 
         * @param obj The prioritized data.
         * @return False if the queue is full, otherwise true.
         */
        public function enqueue(obj:IPrioritizable):Boolean
        {
            if (_count + 1 < _size)
            {
                _count++;
                _heap[_count] = obj;
                _posLookup[obj] = _count;
                walkUp(_count);
                return true;
            }
            return false;
        }
        
        /**
         * Dequeues and returns the front item.
         * This is always the item with the highest priority.
         * 
         * @return The queue's front item or null if the heap is empty.
         */
        public function dequeue():IPrioritizable
        {
            if (_count >= 1)
            {
                var o:Object = _heap[1];
                _posLookup.deleteKey(o);
                
                _heap[1] = _heap[_count];
                walkDown(1);
                
                _heap[_count] = null;
                _count--;
                return o as IPrioritizable;
            }
            return null;
        }
        
        /**
         * Reprioritizes an item.
         * 
         * @param obj         The object whose priority is changed.
         * @param newPriority The new priority.
         * @return True if the repriorization succeeded, otherwise false.
         */
        public function reprioritize(obj:IPrioritizable, newPriority:int):Boolean
        {
            if (!_posLookup[obj]) return false;
            
            var oldPriority:int = obj.priority;
            obj.priority = newPriority;
            var pos:int = _posLookup[obj];
            newPriority > oldPriority ? walkUp(pos) : walkDown(pos);
            return true;
        }
        
        /**
         * Removes an item.
         * 
         * @param obj The item to remove.
         * @return True if removal succeeded, otherwise false.
         */
        public function remove(obj:IPrioritizable):Boolean
        {
            if (_count >= 1)
            {
                var pos:int = _posLookup[obj];
                
                var o:Object = _heap[pos];
                _posLookup.deleteKey(o);
                
                _heap[pos] = _heap[_count];
                
                walkDown(pos);
                
                _heap[_count] = null;
                _posLookup.deleteKey([_count]);
                _count--;
                return true;
            }
            
            return false;
        }
        
        /**
         * @inheritDoc
         */
        public function contains(obj:Object):Boolean
        {
            return _posLookup[obj] != null;
        }
        
        /**
         * @inheritDoc
         */
        public function clear():void
        {
            // TODO: Allow setting size.
            //https://theengineco.atlassian.net/browse/LOOM-642
            _heap = new Vector.<IPrioritizable>(/*_size*/); 
            _posLookup = new Dictionary.<Object, int>(); // TODO: Make this weakref.
            _count = 0;
        }
        
        /**
         * @inheritDoc
         */
        public function get size():int
        {
            return _count;
        }
        
        /**
         * @inheritDoc
         */
        public function isEmpty():Boolean
        {
            return _count == 0;
        }
        
        /**
         * @inheritDoc
         */
        /*public function toArray():Array
        {
            return _heap.slice(1, _count + 1);
        }*/
        
        /**
         * Prints out a string representing the current object.
         * 
         * @return A string representing the current object.
         */
        public function toString():String
        {
            return "[SimplePriorityQueue, size=" + _size +"]";
        }
        
        /**
         * Prints all elements (for debug/demo purposes only).
         */
        public function dump():String
        {
            if (_count == 0) return "SimplePriorityQueue (empty)";
            
            var s:String = "SimplePriorityQueue\n{\n";
            var k:int = _count + 1;
            for (var i:int = 1; i < k; i++)
            {
                s += "\t" + _heap[i] + "\n";
            }
            s += "\n}";
            return s;
        }
        
        private function walkUp(index:int):void
        {
            var parent:int = index >> 1;
            var parentObj:IPrioritizable;
            
            var tmp:IPrioritizable = _heap[index];
            var p:int = tmp.priority;
            
            while (parent > 0)
            {
                parentObj = _heap[parent];
                
                if (p - parentObj.priority > 0)
                {
                    _heap[index] = parentObj;
                    _posLookup[parentObj] = index;
                    
                    index = parent;
                    parent >>= 1;
                }
                else break;
            }
            
            _heap[index] = tmp;
            _posLookup[tmp] = index;
        }
        
        private function walkDown(index:int):void
        {
            var child:int = index << 1;
            var childObj:IPrioritizable;
            
            var tmp:IPrioritizable = _heap[index];
            var p:int = tmp.priority;
            
            while (child < _count)
            {
                if (child < _count - 1)
                {
                    if (_heap[child].priority - _heap[child + 1].priority < 0)
                        child++;
                }
                
                childObj = _heap[child];
                
                if (p - childObj.priority < 0)
                {
                    _heap[index] = childObj;
                    _posLookup[childObj] = index;
                    
                    _posLookup[tmp] = child;
                    
                    index = child;
                    child <<= 1;
                }
                else break;
            }
            _heap[index] = tmp;
            _posLookup[tmp] = index;
        }
    }    
}