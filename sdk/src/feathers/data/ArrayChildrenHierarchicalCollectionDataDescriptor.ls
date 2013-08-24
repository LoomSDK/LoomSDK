/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.data
{
	/**
	 * A hierarchical data descriptor where children are defined as arrays in a
	 * property defined on each branch. The property name defaults to `"children"`,
	 * but it may be customized.
	 *
	 * The basic structure of the data source takes the following form. The
	 * root must always be an Array.
	 * 
	 * ~~~json
	 * [
	 *     {
	 *         text: "Branch 1",
	 *         children:
	 *         [
	 *             { text: "Child 1-1" },
	 *             { text: "Child 1-2" }
	 *         ]
	 *     },
	 *     {
	 *         text: "Branch 2",
	 *         children:
	 *         [
	 *             { text: "Child 2-1" },
	 *             { text: "Child 2-2" },
	 *             { text: "Child 2-3" }
	 *         ]
	 *     }
	 * ]
	 * ~~~
	 * 
	 */
	public class ArrayChildrenHierarchicalCollectionDataDescriptor implements IHierarchicalCollectionDataDescriptor
	{
		/**
		 * Constructor.
		 */
		public function ArrayChildrenHierarchicalCollectionDataDescriptor()
		{
		}

		/**
		 * The field used to access the Array of a branch's children.
		 */
		public var childrenField:String = "children";

		/**
		 * @inheritDoc
		 */
		public function getLength(data:Object, ...rest:Vector.<Object>):int
		{
			var branch:Vector.<Object> = data as Vector.<Object>;
			const indexCount:int = rest.length;
			for(var i:int = 0; i < indexCount; i++)
			{
				var index:int = rest[i] as int;
				
				var potentialNewBranch:Object = branch[index];
				var potentialNewBranchType = potentialNewBranch.getType();
				branch = potentialNewBranchType.getFieldOrPropertyValueByName(potentialNewBranch, childrenField) as Vector.<Object>;
			}

			return branch.length;
		}

		/**
		 * @inheritDoc
		 */
		public function getItemAt(data:Object, index:int, ...rest:Vector.<Object>):Object
		{
			rest.unshift(index);
			var branch:Vector.<Object> = data as Vector.<Object>;
			const indexCount:int = rest.length - 1;
			for(var i:int = 0; i < indexCount; i++)
			{
				index = rest[i] as int;

				var potentialNewBranch:Object = branch[index];
				var potentialNewBranchType = potentialNewBranch.getType();
				branch = potentialNewBranchType.getFieldOrPropertyValueByName(potentialNewBranch, childrenField) as Vector.<Object>;
			}
			const lastIndex:int = rest[indexCount] as int;
			return branch[lastIndex];
		}

		/**
		 * @inheritDoc
		 */
		public function setItemAt(data:Object, item:Object, index:int, ...rest:Vector.<Object>):void
		{
			rest.unshift(index);
			var branch:Vector.<Object> = data as Vector.<Object>;
			const indexCount:int = rest.length - 1;
			for(var i:int = 0; i < indexCount; i++)
			{
				index = rest[i] as int;

				var potentialNewBranch:Object = branch[index];
				var potentialNewBranchType = potentialNewBranch.getType();
				branch = potentialNewBranchType.getFieldOrPropertyValueByName(potentialNewBranch, childrenField) as Vector.<Object>;
			}
			const lastIndex:int = rest[indexCount] as int;
			branch[lastIndex] = item;
		}

		/**
		 * @inheritDoc
		 */
		public function addItemAt(data:Object, item:Object, index:int, ...rest:Vector.<Object>):void
		{
			rest.unshift(index);
			var branch:Vector.<Object> = data as Vector.<Object>;
			const indexCount:int = rest.length - 1;
			for(var i:int = 0; i < indexCount; i++)
			{
				index = rest[i] as int;

				var potentialNewBranch:Object = branch[index];
				var potentialNewBranchType = potentialNewBranch.getType();
				branch = potentialNewBranchType.getFieldOrPropertyValueByName(potentialNewBranch, childrenField) as Vector.<Object>;
			}
			const lastIndex:int = rest[indexCount] as int;
			branch.splice(lastIndex, 0, item);
		}

		/**
		 * @inheritDoc
		 */
		public function removeItemAt(data:Object, index:int, ...rest:Vector.<Object>):Object
		{
			rest.unshift(index);
			var branch:Vector.<Object> = data as Vector.<Object>;
			const indexCount:int = rest.length - 1;
			for(var i:int = 0; i < indexCount; i++)
			{
				index = rest[i] as int;

				var potentialNewBranch:Object = branch[index];
				var potentialNewBranchType = potentialNewBranch.getType();
				branch = potentialNewBranchType.getFieldOrPropertyValueByName(potentialNewBranch, childrenField) as Vector.<Object>;
			}
			const lastIndex:int = rest[indexCount] as int;
			const item:Object = branch[lastIndex];
			branch.splice(lastIndex, 1);
			return item;
		}

		/**
		 * @inheritDoc
		 */
		public function getItemLocation(data:Object, item:Object, result:Vector.<int> = null, ...rest:Vector.<Object>):Vector.<int>
		{
			if(!result)
			{
				result = new <int>[];
			}
			else
			{
				result.length = 0;
			}
			var branch:Vector.<Object> = data as Vector.<Object>;
			const restCount:int = rest.length;
			for(var i:int = 0; i < restCount; i++)
			{
				var index:int = rest[i] as int;
				result[i] = index;

				var potentialNewBranch:Object = branch[index];
				var potentialNewBranchType = potentialNewBranch.getType();
				branch = potentialNewBranchType.getFieldOrPropertyValueByName(potentialNewBranch, childrenField) as Vector.<Object>;
			}

			const isFound:Boolean = this.findItemInBranch(branch, item, result);
			if(!isFound)
			{
				result.length = 0;
			}
			return result;
		}

		/**
		 * @inheritDoc
		 */
		public function isBranch(node:Object):Boolean
		{
			if(!node.hasOwnProperty(this.childrenField))
				return false;

			var potentialNewBranchType = node.getType();
			var branch:Vector.<Object> = potentialNewBranchType.getFieldOrPropertyValueByName(node, childrenField) as Vector.<Object>;

			return branch && branch is Vector.<Object>;
		}

		/**
		 * @private
		 */
		protected function findItemInBranch(branch:Vector.<Object>, item:Object, result:Vector.<int>):Boolean
		{
			const index:int = branch.indexOf(item);
			if(index >= 0)
			{
				result.push(index);
				return true;
			}

			const branchLength:int = branch.length;
			for(var i:int = 0; i < branchLength; i++)
			{
				var branchItem:Object = branch[i];
				if(this.isBranch(branchItem))
				{
					result.push(i);
					var branchItemType = branchItem.getType();
					var branchItemValue:Vector.<Object> = branchItemType.getFieldOrPropertyValueByName(branchItem, childrenField) as Vector.<Object>;
					var isFound:Boolean = this.findItemInBranch(branchItemValue, item, result);
					if(isFound)
					{
						return true;
					}
					result.pop();
				}
			}
			return false;
		}
	}
}
