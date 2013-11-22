/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.data
{
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
            return (data as Vector.<Object>).length;
        }
        
        /**
         * @inheritDoc
         */
        public function getItemAt(data:Object, index:int):Object
        {
            this.checkForCorrectDataType(data);
            var dataAsVector:Vector.<Object> = data as Vector.<Object>;
            return dataAsVector[index];
        }
        
        /**
         * @inheritDoc
         */
        public function setItemAt(data:Object, item:Object, index:int):void
        {
            this.checkForCorrectDataType(data);
            var dataAsVector:Vector.<Object> = data as Vector.<Object>;
            dataAsVector[index] = item;
        }
        
        /**
         * @inheritDoc
         */
        public function addItemAt(data:Object, item:Object, index:int):void
        {
            this.checkForCorrectDataType(data);
            var dataAsVector:Vector.<Object> = data as Vector.<Object>;
            dataAsVector.splice(index, 0, item);
        }
        
        /**
         * @inheritDoc
         */
        public function removeItemAt(data:Object, index:int):Object
        {
            this.checkForCorrectDataType(data);
            var dataAsVector:Vector.<Object> = data as Vector.<Object>;
            var splicedData:Vector.<Object> = dataAsVector.splice( index, 1 );
            return splicedData[ 0 ];
        }

        /**
         * @inheritDoc
         */
        public function removeAll(data:Object):void
        {
            this.checkForCorrectDataType(data);
            var dataAsVector:Vector.<Object> = data as Vector.<Object>;
            dataAsVector.length = 0;
        }
        
        /**
         * @inheritDoc
         */
        public function getItemIndex(data:Object, item:Object):int
        {
            this.checkForCorrectDataType(data);
            var dataAsVector:Vector.<Object> = data as Vector.<Object>;
            return dataAsVector.indexOf(item);
        }
        
        /**
         * @private
         */
        protected function checkForCorrectDataType(data:Object):void
        {
            Debug.assert( data.getType() == Vector, "Expected Vector. Received " + data.getTypeName() + " instead." );
        }
    }
}