package
{
	import Loom.Application;
   import System.XML.XMLDocument;
   import System.XML.XMLNode;
   import System.Process;

   enum GenerationMode
   {
      GENERATE_SCRIPT,
      GENERATE_NATIVE
   }

   /**
    * Reads SWIG XML output and convert it to LoomScript C++ and script bindings.
    *
    * This is ugly but useful. If you have an API to convert, process it with SWIG
    * and generate XML output with a command like the following:
    *
    * swig -c++ -xml -o tmp/output.xml cocos2dx.i
    *
    * If you want to see what the cocos2dx.i file looks like, it's included with
    * this tool.
    *
    * Once you get the XML generated, this tool will generated C++ and script bindings.
    *
    * A few notes:
    *    There are some semi-hardcoded tweaking options throughout this program. We highly
    *    recommend reading the source code thoroughly before attempting to generate
    *    bindings. Most of them relate to Cocos conventions that may not be useful or
    *    relevant for other libraries.
    *
    *    Some hand-teaking is still required. For instance, some type names might require
    *    minor adjustments (_ccColor3B to ccColor3B). Also, if there are overrides on the
    *    C++ side, this tool will generate ALL the overrides - requiring you to delete or
    *    comment or rename them.
    *
    *    The script and C++ bindings are output sequentially; you can then copy them into
    *    the source file of your choosing to include in your project. It can be useful to 
    *    comment out either the C++ or script binding generation functions in main() to
    *    reduce the amount of output generated.
    *
    *    The path to the SWIG XML file is hardcoded; you'll need to go to main() and
    *    modify it to suit your needs.
    *
    * Feel free to ask for help/input on the forums! However, also understand that we do 
    * not promise this generator will work flawlessly on any code you bring in. Binding
    * a large library will take SOME work and knowledge of both LoomScript and the library!
    */
	class Program
	{
      // These are not output nor are any function/method signatures
      // that reference them.
      public static var ignoredTypes:Vector.<String> = 
      [
         "CCCallFunc",
         "CCCallFuncN",
         "CCCallFuncND",
         "CCCallFuncO",
         "CCRGBAProtocol",
         "CCTextureProtocol",
         "CCLabelProtocol",
         "CCDirectorDelegate",
         "CCSetIterator",
         "ccArray",
         "_ccArray",
         "CCGLProgram",
         "CCBlendProtocol",
         "CCScheduler",
         "CCTouch",
         "CCEvent",
         "ccVertex3F",
         "CCTexture2D",
         "_ccV2F_C4B_T2F",
         "_ccV2F_C4F_T2F",
         "_ccV3F_C4B_T2F",
         "_ccV2F_C4B_T2F_Quad",
         "_ccV2F_C4F_T2F_Quad",
         "_ccV3F_C4B_T2F_Quad",
         "ccV3F_C4B_T2F_Quad",
         "_ccT2F_Quad",
         "ccQuad3",
         "Tile",
         "_FontDefHashElement",
         "CCDictElement",
         "ccGLServerState",
         "sImageTGA",
         "SEL_SCHEDULE",
         "SEL_CallFunc",
         "SEL_CallFuncN",
         "SEL_CallFuncND",
         "SEL_CallFuncO",
         "SEL_MenuHandler",
         "CCActionTweenDelegate",
         "CCActionTween",
         "CCTransitionEaseScene", // This is a pure virtual.
         "p.q(const).char", // this is how const char ** comes out
         "VolatileTexture)>"  // This is an array of VolatileTextures
      ];

      // Used to generate the package listing for native.
      static var classNameMap:Dictionary.<String, String> = new Dictionary.<String, String>();

      // Store the base class for each class.
      static var classBaseMap:Dictionary.<String, String> = new Dictionary.<String, String>();

      public static function convertNativeToScriptType(nativeType:String):String
      {
         // First, strip off the namespace.
         Debug.assert(nativeType);
         var parts:Vector.<String> = nativeType.split("::");
         var simpleType:String = parts[parts.length() - 1];

         // Apply some rewrite rules.
         switch(simpleType)
         {
            case "bool": simpleType = "Boolean"; break;

            case "p.q(const).char": simpleType = "String"; break;
            case "q(const).char": simpleType = "String"; break;
            case "p.char": simpleType = "String"; break;

            case "p.void": simpleType = "Object"; break;
            case "p.q(const).void": simpleType = "Object"; break;
         }

         // Look for some prefixes we can ignore.
         if(simpleType.indexOf("r.") == 0)
            simpleType = simpleType.substr(2);
         if(simpleType.indexOf("p.") == 0)
            simpleType = simpleType.substr(2);
         if(simpleType.indexOf("q(const).") == 0)
            simpleType = simpleType.substr(9);

         // Apply some more rewrite rules.
         switch(simpleType)
         {
            case "bool": simpleType = "Boolean"; break;

            case "string": simpleType = "String"; break;
            case "CCString": simpleType = "String"; break;

            case "unsigned char": simpleType = "int"; break;
            case "unsigned int": simpleType = "int"; break;
            case "GLuint": simpleType = "int"; break;
            case "GLubyte": simpleType = "int"; break;
            case "GLint": simpleType = "int"; break;
            case "GLshort": simpleType = "int"; break;
            case "short": simpleType = "int"; break;

            case "GLfloat": simpleType = "Number"; break;
            case "float": simpleType = "Number"; break;
            case "double": simpleType = "Number"; break;

            case "_ccColor3B": simpleType = "ccColor3B"; break;
            case "_ccColor4B": simpleType = "ccColor4B"; break;
            case "_ccColor4F": simpleType = "ccColor4F"; break;
            case "_ccVertex2F": simpleType = "ccVertex2F"; break;
            case "_ccVertex3F": simpleType = "ccVertex3F"; break;
            case "_ccTex2F": simpleType = "ccTex2F"; break;
            case "_ccPointSprite": simpleType = "ccPointSprite"; break;
            case "_ccQuad2": simpleType = "ccQuad2"; break;
            case "_ccQuad3": simpleType = "ccQuad3"; break;

         }

         return simpleType;
      }

      public static function convertNativeToNativeType(val:String):String
      {
         // Rewrite silly swig types.
         switch(val)
         {
            case "p.q(const).char": val = "const char *"; break;
            case "q(const).char": val = "const char *"; break;
            case "p.char": val = "char *"; break;
            case "p.void": val = "void *"; break;
            case "p.q(const).void": val = "const void *"; break;
         }

         // If it still starts with p. make it a pointer.
         if(val.substr(0, 2) == "p.")
            val = val.substr(2) + " *";

         if(val.substr(0, 2) == "r.")
            val = val.substr(2) + " &";

         if(val.substr(0, 9) == "q(const).")
            val = "const " + val.substr(9);

         return val;
      }

      // Helper function to get an attribute from a SWIG XML tag (SWIG stores
      // attributes in a subtag).
      public static function lookupAttributeByName(node:XMLElement, name:String):String
      {
         Debug.assert(node, "Can't look up on null!");
         var list = node.firstChildElement("attributelist");
         if(!list)
            return null;

         var walk = list.firstChildElement("attribute");
         while(walk)
         {
            if(walk.getAttribute("name") == name)
               return walk.getAttribute("value");

            walk = walk.nextSiblingElement("attribute");
         }

         return null;
      }

      // Helper to look at the parmlist in a SWIG XML node and return howmany
      // parameters there are.
      public static function getFunctionParmCount(node:XMLElement):int
      {
         var list = node.firstChildElement("attributelist");
         if(list == null)
            return 0;

         list = list.firstChildElement("parmlist");
         if(!list)
            return 0;
         
         var count = 0;
         var walk = list.firstChildElement("parm");
         while(walk)
         {
            count++;
            walk = walk.nextSiblingElement("parm");
         }

         return count;
      }

      // Get a function's parameter by index.
      public static function getFunctionParmByIndex(node:XMLElement, index:int):XMLElement
      {
         var list = node.firstChildElement("attributelist");
         Debug.assert(list, "Should have found an attributelist tag!");
         list = list.firstChildElement("parmlist");
         Debug.assert(list, "Should have found a parmlist tag!");
         
         var count = 0;
         var walk = list.firstChildElement("parm");
         while(walk)
         {
            if(count == index)
               return walk;
            count++;
            walk = walk.nextSiblingElement("parm");
         }

         return null;         
      }

      // C++ classes can have lots of base clases. But we only ever care about
      // the first one.
      public static function findFirstBaseClass(node:XMLElement):String
      {
         var list = node.firstChildElement("attributelist");
         if(!list) return null;
         list = list.firstChildElement("baselist");
         if(!list) return null;
         list = list.firstChildElement("base");
         if(!list) return null;
         return list.getAttribute("name");
      }

      // Utility function to join a vector.
      // TODO: LOOM-606
      public static function joinVector(inVec:Vector.<String>, delim:String):String
      {
         var out:String = "";
         for(var i:int=0; i<inVec.length(); i++)
         {
            out += inVec[i]
            if(i != inVec.length()-1)
               out += delim;
         }
         return out;
      }

      // Strip the namespace off of a native class.
      public static function stripNativeClass(nativeType:String):String
      {
         // First, strip off the namespace.
         Debug.assert(nativeType);
         var parts:Vector.<String> = nativeType.split("::");
         var simpleType:String = parts[parts.length() - 1];
         return simpleType;
      }

      // Process a class' XML definition and output script or native bindings
      // depending on mode.
      public static function handleClass(node:XMLElement, mode:GenerationMode)
      {
         // What class is it?
         var className = lookupAttributeByName(node, "name");
         var baseClassName = findFirstBaseClass(node);
         var scriptClassName = convertNativeToScriptType(className);

         // Filter ignored classes.
         if(ignoredTypes.contains(scriptClassName))
            return;

         if(mode == GenerationMode.GENERATE_SCRIPT)
         {
            // Print the class definition start.
            Console.print("[Native(managed)]");
            if(baseClassName != null)
               Console.print("public native class " + scriptClassName + " extends " + convertNativeToScriptType(baseClassName));
            else
               Console.print("public native class " + scriptClassName);
            Console.print("{");
         }
         else
         {
            // Note the registration function for later emission.
            classNameMap[stripNativeClass(className)] = "register" + stripNativeClass(className);
            classBaseMap[stripNativeClass(className)] = baseClassName;

            // Print the C++ registration function prologue.
            Console.print("static int register" + stripNativeClass(className) + "(lua_State *L)");
            Console.print("{");
            Console.print("   beginPackage(L, \"cocos2d\")");
            Console.print("");

            // Is it derived or a root class?
            if(baseClassName != null)
               Console.print("   .deriveClass<" + className + ", " + baseClassName + ">(\"cocos2d::" + convertNativeToScriptType(className) + "\")");
            else
               Console.print("   .beginClass<" + className + ">(\"" + convertNativeToScriptType(className) + "\")");

            // C++ wants a basic constructor; you can add more as needed.
            Console.print("   .addConstructor<void (*)(void)>()")
         }

         // Build up a map of method names so we can detect overloads.
         var walk = node.firstChildElement("cdecl");
         var functionCountMap:Dictionary.<String, int> = new Dictionary.<String, int>();
         while(walk)
         {
            // Only consider public members.
            var cdeclAccess = lookupAttributeByName(walk, "access");
            if(cdeclAccess != "public")
            {
               walk = walk.nextSiblingElement("cdecl");
               continue;
            }

            // Only consider functions - everything else isn't a method!
            var cdeclKind = lookupAttributeByName(walk, "kind");
            if(cdeclKind != "function")
            {
               walk = walk.nextSiblingElement("cdecl");
               continue;               
            }

            // Note the count.
            var cdeclName = lookupAttributeByName(walk, "name");
            var hashName = "__" + cdeclName;

            if(functionCountMap[hashName] == null)
               functionCountMap[hashName] = 0;
            functionCountMap[hashName]++;

            walk = walk.nextSiblingElement("cdecl");            
         }

         // Now we want to find the cdecls.
         var walk = node.firstChildElement("cdecl");
         while(walk)
         {
            // Only consider public members.
            var cdeclAccess = lookupAttributeByName(walk, "access");
            if(cdeclAccess != "public")
            {
               walk = walk.nextSiblingElement("cdecl");
               continue;
            }

            var cdeclKind = lookupAttributeByName(walk, "kind");
            var cdeclType = lookupAttributeByName(walk, "type");
            var cdeclName = lookupAttributeByName(walk, "name");
            var cdeclStorage = lookupAttributeByName(walk, "storage");

            if(cdeclKind == "function")
            {
               // Set if we can't map this function.
               var skipIt:Boolean = false;

               // Get all the args for the script bindings.
               var funcArgs:Vector.<String> = new Vector.<String>();
               var funcCArgs:Vector.<String> = new Vector.<String>();
               var argCount = getFunctionParmCount(walk);
               for(var i:int=0; i<argCount; i++)
               {
                  var argElement = getFunctionParmByIndex(walk, i);
                  Debug.assert(argElement, "Failed to get function parameter!");

                  // Get argument name - and skip reserved words.
                  var argName = lookupAttributeByName(argElement, "name");
                  if(argName == "var") argName = "value";

                  var rawArgType = lookupAttributeByName(argElement, "type");

                  // Deal with unmappable types.
                  switch(rawArgType)
                  {
                     case "v(...)": skipIt = true; break;
                     case "va_list": skipIt = true; break;
                  }

                  if(!skipIt)
                     skipIt = ignoredTypes.contains(convertNativeToScriptType(rawArgType));

                  // Note type for script...
                  var argType = convertNativeToScriptType(rawArgType);
                  funcArgs.pushSingle(argName.toString() + ":" + argType.toString());

                  // And for C++.
                  var cArgType = convertNativeToNativeType(rawArgType);
                  funcCArgs.pushSingle(cArgType);
               }

               var parmSignature:String = joinVector(funcArgs, ", ");
               var cParmSignature:String = joinVector(funcCArgs, ", ");

               // Also skip if it's a defaultArgs, which SWIG appears to flag for "virtual" entries
               // that are generated to map to things with default args.
               if(lookupAttributeByName(walk, "defaultargs"))
                  skipIt = true;

               // Couple of common method names that are deprecated or irrelevant.
               // This is all Cocos2D specific; you will want to modify for other
               // libraries.
               if(cdeclName == "copyWithZone")
                  skipIt = true;
               if(cdeclName == "node")
                  skipIt = true;
               if(cdeclName == "actionWithAction")
                  skipIt = true;
               if(cdeclName == "transitionWithDuration")
                  skipIt = true;

               // See if the return type is really a pointer.
               var decl:String = lookupAttributeByName(walk, "decl");
               if(decl.substr(decl.length() - 3) == ".p.")
                  cdeclType = "p." + cdeclType;
               if(decl.substr(decl.length() - 3) == ".r.")
                  cdeclType = "r." + cdeclType;

               // Filter by return type.
               if(ignoredTypes.contains(convertNativeToScriptType(cdeclType)))
                  skipIt = true;

               if(skipIt)
               {
                  walk = walk.nextSiblingElement("cdecl");
                  continue;
               }

               if(mode == GenerationMode.GENERATE_SCRIPT)
               {
                  // Script binding are pretty easy.
                  if(cdeclStorage == "static")
                     Console.print("   public native static function " + cdeclName + "(" + parmSignature + "):" + convertNativeToScriptType(cdeclType) + ";");
                  else
                     Console.print("   public native function " + cdeclName + "(" + parmSignature + "):" + convertNativeToScriptType(cdeclType) + ";");                     
               }
               else if(mode == GenerationMode.GENERATE_NATIVE)
               {
                  // Generate a func cast if needed, ie, to disambiguate
                  // an overloaded method.
                  var funcCast = "";
                  if(functionCountMap["__" + cdeclName] > 1)
                  {
                     // C++ function pointer syntax.
                     // (void (cocos2d::CCNode::*)(cocos2d::CCNode *, int, int))

                     if(cdeclStorage == "static")
                        funcCast = "(" + convertNativeToNativeType(cdeclType) + " (*)(" + cParmSignature + "))";
                     else
                        funcCast = "(" + convertNativeToNativeType(cdeclType) + " (" + className + "::*)(" + cParmSignature + "))";
                  }

                  if(cdeclStorage == "static")
                     Console.print("      .addStaticFunction(\"" + cdeclName + "\", " + funcCast + "&" + className + "::" + cdeclName + ")");
                  else
                     Console.print("      .addFunction(\"" + cdeclName + "\", " + funcCast + "&" + className + "::" + cdeclName + ")");
               }
            }
            else if(cdeclKind == "variable")
            {
               // Skip it if it's on the ignore list.
               var convertedVarType = convertNativeToScriptType(cdeclType);
               if(!ignoredTypes.contains(convertedVarType))
               {
                  // Emit a variable binding.
                  if(mode == GenerationMode.GENERATE_SCRIPT)
                     Console.print("   public native var " + cdeclName + ":" + convertedVarType + ";");
                  else if(mode == GenerationMode.GENERATE_NATIVE)
                     Console.print("   .addData(\"" + cdeclName + "\", &" + className + "::" + cdeclName +")");
               }
            }

            // Next cdecl.
            walk = walk.nextSiblingElement("cdecl");
         }

         // Close the definition out.
         if(mode == GenerationMode.GENERATE_NATIVE)
         {
            Console.print("   .endClass()");
            Console.print("");
            Console.print("   .endPackage();");
            Console.print("");
            Console.print("   return 0;");            
            Console.print("");
            Console.print("}");
            Console.print("");
         }
         else
         {
            Console.print("}\n\n");
         }
      }

      public static function scanForClass(node:XMLNode, mode:GenerationMode)
      {
         // If an element, it might be a class tag.
         var elem = node.toElement();
         if(elem && elem.value() == "class")
         {
            handleClass(elem, mode);
            return;
         }

         // Nope - so recursively scan.
         var walk = node.firstChild();
         while(walk)
         {
            scanForClass(walk, mode);
            walk = walk.nextSibling();
         }
      }

      public static function emitPackageInstallationFunction()
      {
         Console.print("void installPackage()");
         Console.print("{");

         // Sort by parent class... Do a simple topological insertion sort so
         // that base classes come first.
         var classList:Vector.<String> = new Vector.<String>();

         var classGoalCount = 0;
         for(var key:String in classNameMap) classGoalCount++;

         // Loop until we're done...
         // TODO: LOOM-607
         for(true;true;true)
         {
            //Console.print("classList = " + classList.length());
            var numFound = 0;

            for(var key:String in classNameMap)
            {
               // Strip it.
               key = stripNativeClass(key);

               // Are we already added? If so skip us.
               if(classList.contains(key))
                  continue;

               // Get the parent class.
               var parentClass = classBaseMap[key];

               //Console.print("Considering " + key + " extends " + parentClass.toString() + "1");

               // Is the parent class emitted yet?
               if(parentClass != null && !classList.contains(parentClass))
                  continue;

               //Console.print("   o Adding");

               // Insert if so.
               Debug.assert(key, "Empty key! (a)");
               classList.pushSingle(key);
               numFound++;
            }

            // If none found, introduce those with unknown parent classes.
            if(numFound == 0)
            {
               for(var key:String in classNameMap)
               {
                  // Strip it.
                  key = stripNativeClass(key);

                  // Are we already added? If so skip us.
                  if(classList.contains(key))
                     continue;

                  // Get the parent class.
                  var parentClass = classBaseMap[key];

                  //Console.print("Considering " + key + " extends " + parentClass.toString() + "2");

                  // Is the parent class present and not yet emitted? We can be more
                  // lenient and allow non-present parents to be ignored.
                  if(parentClass != null && classNameMap[parentClass] != null && !classList.contains(parentClass))
                     continue;

                  //Console.print("   o Adding");

                  // Insert if so.
                  Debug.assert(key, "Empty key! (b)");
                  classList.pushSingle(key);
                  numFound++;
               }
            }

            // Terminate loop when no more are added.
            if(numFound == 0)
            {
               Console.print("Terminating class search due to no more found.");
               break;
            }
         }

         // Now print in order!
         for(var i=0; i<classList.length(); i++)
         {
            Debug.assert(classList[i], "Empty item in class list");
            Debug.assert(classNameMap[classList[i]], "No entry in classNameMap found!");
            Console.print("   NativeInterface::registerManagedNativeType<" + classList[i] + ">(" + classNameMap[classList[i]] + ");");            
         }

         Console.print("}");         
      }

		public static function main()
		{
			Console.print("SwigXMLBindingTool v1.0");

         // Load and parse the XML.
         var xd = new XMLDocument();
         xd.loadFile("/Users/beng/projects/LoomEngine.git/engine/src/cocos2dx/tmp/output.xml");

         // Process the XML.
         Debug.assert(xd.rootElement(), "Document had no root element.");

         // Emit native bindings.
         scanForClass(xd.rootElement(), GenerationMode.GENERATE_NATIVE);
         emitPackageInstallationFunction();

         // Emit script bindings.
         scanForClass(xd.rootElement(), GenerationMode.GENERATE_SCRIPT);

         // All done!
         Process.exit(0);
		}
	}
}