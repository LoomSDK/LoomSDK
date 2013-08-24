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

package Test.Wildcards2
{

	public class UniqueWildCard2
	{
		public static var s:String = "A unique string";

		public function getString():String 
		{
			return s;
		}

	}

	public class WildCardImport1
	{
		public static var n:Number = 102;

		public function getNumber():Number 
		{
			return n;
		}

	}

	public class WildCardImport2
	{
		public static var s:String = "This is also a test";

		public function getString():String 
		{
			return s;
		}


	}

}