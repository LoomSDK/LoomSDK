/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.data
{
    import System.Errors.IllegalOperationError;

    /**
     * An `IListCollectionDataDescriptor` implementation for Vectors.
     * 
     * @see ListCollection
     * @see IListCollectionDataDescriptor
     */
    public class VectorListCollectionDataDescriptor implements IListCollectionDataDescriptor
    {
        /**
         * Constructor.
         */
        public function VectorListCollectionDataDescriptor()
        {
        }
        
        /**
         * @inheritDoc
         */
        public function getLength(data:Object):int
        {
            this.checkForCorrectDataType(data);
            return (data as Vector.<*>).length;
        }
        
        /**
         * @inheritDoc
         */
        public function getItemAt(data:Object, index:int):Object
        {
            this.checkForCorrectDataType(data);
            return (data as Vector.<*>)[index];
        }
        
        /**
         * @inheritDoc
         */
        public function setItemAt(data:Object, item:Object, index:int):void
        {
            this.checkForCorrectDataType(data);
            (data as Vector.<*>)[index] = item;
        }
        
        /**
         * @inheritDoc
         */
        public function addItemAt(data:Object, item:Object, index:int):void
        {
            this.checkForCorrectDataType(data);
            (data as Vector.<*>).splice(index, 0, item);
        }
        
        /**
         * @inheritDoc
         */
        public function removeItemAt(data:Object, index:int):Object
        {
            this.checkForCorrectDataType(data);
            return (data as Vector.<*>).splice(index, 1)[0];
        }

        /**
         * @inheritDoc
         */
        public function removeAll(data:Object):void
        {
            this.checkForCorrectDataType(data);
            (data as Vector.<*>).length = 0;
        }
        
        /**
         * @inheritDoc
         */
        public function getItemIndex(data:Object, item:Object):int
        {
            this.checkForCorrectDataType(data);
            return (data as Vector.<*>).indexOf(item);
        }
        
        /**
         * @private
         */
        protected function checkForCorrectDataType(data:Object):void
        {
            if(!(data is Vector.<*>))
            {
                throw new IllegalOperationError("Expected Vector. Received " + data.getTypeName() + " instead.");
            }
        }
    }
}