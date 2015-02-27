/*
 * Copyright (C) 2006 Claus Wahlers and Max Herkender
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

package deng.fzip
{
    import loom2d.events.Event;
    import loom2d.events.EventDispatcher;
	/**
	 * Dispatched when a file contained in a ZIP archive has 
	 * loaded successfully.
	 *
	 * @eventType deng.fzip.FZipEvent.FILE_LOADED
	 */
	[Event(name="fileLoaded", type="deng.fzip.FZipEvent")]

	/**
	 * Dispatched when an error is encountered while parsing a 
	 * ZIP Archive.
	 *
	 * @eventType deng.fzip.FZipErrorEvent.PARSE_ERROR
	 */
	[Event(name="parseError", type="deng.fzip.FZipErrorEvent")]

	/**
	 * Dispatched when data has loaded successfully. 
	 *
	 * @eventType flash.events.Event.COMPLETE 
	 */
	[Event(name="complete", type="flash.events.Event")]

	/**
	 * Dispatched if a call to FZip.load() attempts to access data 
	 * over HTTP, and the current Flash Player is able to detect 
	 * and return the status code for the request. (Some browser 
	 * environments may not be able to provide this information.) 
	 * Note that the httpStatus (if any) will be sent before (and 
	 * in addition to) any complete or error event
	 *
	 * @eventType flash.events.HTTPStatusEvent.HTTP_STATUS 
	 */
	[Event(name="httpStatus", type="flash.events.HTTPStatusEvent")]

	/**
	 * Dispatched when an input/output error occurs that causes a 
	 * load operation to fail. 
	 *
	 * @eventType flash.events.IOErrorEvent.IO_ERROR
	 */
	[Event(name="ioError", type="flash.events.IOErrorEvent")]

	/**
	 * Dispatched when a load operation starts.
	 *
	 * @eventType flash.events.Event.OPEN
	 */
	 
	[Event(name="open", type="flash.events.Event")]

	/**
	 * Dispatched when data is received as the download operation 
	 * progresses.
	 *
	 * @eventType flash.events.ProgressEvent.PROGRESS
	 */
	[Event(name="progress", type="flash.events.ProgressEvent")]

	/**
	 * Dispatched if a call to FZip.load() attempts to load data 
	 * from a server outside the security sandbox. 
	 * 
	 * @eventType flash.events.SecurityErrorEvent.SECURITY_ERROR
	 */
	[Event(name="securityError", type="flash.events.SecurityErrorEvent")]


	/**
	 * Loads and parses ZIP archives.
	 * 
	 * <p>FZip is able to process, create and modify standard ZIP archives as described in the
	 * <a href="http://www.pkware.com/business_and_developers/developer/popups/appnote.txt">PKZIP file format documentation</a>.</p>
	 * 
	 * <p>Limitations:</p>
	 * <ul>
	 * <li>ZIP feature versions &gt; 2.0 are not supported</li>
	 * <li>ZIP archives containing data descriptor records are not supported.</li>
	 * <li>If running in the Flash Player browser plugin, FZip requires ZIPs to be 
	 * patched (Adler32 checksums need to be added). This is not required if
	 * FZip runs in the Adobe AIR runtime or if files contained in the ZIP 
	 * are not compressed.</li>
	 * </ul>
	 */		
	public class FZip extends EventDispatcher
	{
		protected var filesList:Vector.<Object>;
		protected var filesDict:Dictionary;

		//protected var urlStream:URLStream;
		protected var charEncoding:String;
		protected var parseFunc:Function;
		protected var currentFile:FZipFile;
		
		protected var ddBuffer:ByteArray;
		protected var ddSignature:uint;
		protected var ddCompressedSize:uint;

		// PKZIP record signatures
		public static const SIG_CENTRAL_FILE_HEADER:uint = 0x02014b50;
		public static const SIG_SPANNING_MARKER:uint = 0x30304b50;
		public static const SIG_LOCAL_FILE_HEADER:uint = 0x04034b50;
		public static const SIG_DIGITAL_SIGNATURE:uint = 0x05054b50;
		public static const SIG_END_OF_CENTRAL_DIRECTORY:uint = 0x06054b50;
		public static const SIG_ZIP64_END_OF_CENTRAL_DIRECTORY:uint = 0x06064b50;
		public static const SIG_ZIP64_END_OF_CENTRAL_DIRECTORY_LOCATOR:uint = 0x07064b50;
		public static const SIG_DATA_DESCRIPTOR:uint = 0x08074b50;
		public static const SIG_ARCHIVE_EXTRA_DATA:uint = 0x08064b50;
		public static const SIG_SPANNING:uint = 0x08074b50;

		/**
		 * Constructor
		 * 
		 * @param filenameEncoding The character encoding used for filenames
		 * contained in the zip. If unspecified, unicode ("utf-8") is used.
		 * Older zips commonly use encoding "IBM437" (aka "cp437"),
		 * while other European countries use "ibm850".
		 * @see http://livedocs.adobe.com/labs/as3preview/langref/charset-codes.html
		 */		
		public function FZip(filenameEncoding:String = "utf-8") {
			super();
			charEncoding = filenameEncoding;
			parseFunc = parseIdle;
		}

		/**
		 * Indicates whether a file is currently being processed or not.
		 */		
		public function get active():Boolean {
			return (parseFunc != parseIdle);
		}

		/**
		 * Begins downloading the ZIP archive specified by the request
		 * parameter.
		 * 
		 * @param request A URLRequest object specifying the URL of a ZIP archive
		 * to download. 
		 * If the value of this parameter or the URLRequest.url property 
		 * of the URLRequest object passed are null, Flash Player throws 
		 * a null pointer error.
		 */		
		/*
		public function load(request:URLRequest):void {
			if(!urlStream && parseFunc == parseIdle) {
				urlStream = new URLStream();
				urlStream.endian = Endian.LITTLE_ENDIAN;
				addEventHandlers();
				filesList = [];
				filesDict = new Dictionary();
				parseFunc = parseSignature;
				urlStream.load(request);
			}
		}
		*/
		
		/**
		 * Loads a ZIP archive from a ByteArray.
		 *
		 * @param bytes The ByteArray containing the ZIP archive
		 */
		public function loadBytes(bytes:ByteArray):void {
			//if (!urlStream && parseFunc == parseIdle) {
            Debug.assert(bytes != null);
			if (parseFunc == parseIdle) {
				filesList = [];
				filesDict = new Dictionary();
				bytes.position = 0;
				//bytes.endian = Endian.LITTLE_ENDIAN;
				parseFunc = parseSignature;
				if (parse(bytes)) {
					parseFunc = parseIdle;
					dispatchEvent(new Event(Event.COMPLETE));
				} else {
					dispatchEvent(new FZipErrorEvent(FZipErrorEvent.PARSE_ERROR, "EOF"));
				}
			}
		}

		/**
		 * Immediately closes the stream and cancels the download operation.
		 * Files contained in the ZIP archive being loaded stay accessible
		 * through the getFileAt() and getFileByName() methods.
		 */		
		public function close():void {
			/*
			if(urlStream) {
				parseFunc = parseIdle;
				removeEventHandlers();
				urlStream.close();
				urlStream = null;
			}
			*/
		}

		/**
		 * Serializes this zip archive into an ByteArray stream (such as 
		 * ByteArray or FileStream) according to PKZIP APPNOTE.TXT
		 * 
		 * @param stream The stream to serialize the zip file into.
		 * @param includeAdler32 To decompress compressed files, FZip needs Adler32
		 * 		checksums to be injected into the zipped files. FZip will do that 
		 * 		automatically if includeAdler32 is set to true. Note that if the
		 * 		ZIP contains a lot of files, or big files, the calculation of the
		 * 		checksums may take a while.
		 */		
		public function serialize(stream:ByteArray, includeAdler32:Boolean = false):void {
			if(stream != null && filesList.length > 0) {
				//var endian:String = stream.endian;
				var ba:ByteArray = new ByteArray();
				//stream.endian = ba.endian = Endian.LITTLE_ENDIAN;
				var offset:uint = 0;
				var files:uint = 0;
				for(var i:int = 0; i < filesList.length; i++) {
					var file:FZipFile = filesList[i] as FZipFile;
					if(file != null) {
						// first serialize the central directory item
						// into our temporary ByteArray
						file.serialize(ba, includeAdler32, true, offset);
						// then serialize the file itself into the stream
						// and update the offset
						offset += file.serialize(stream, includeAdler32);
						// keep track of how many files we have written
						files++;
					}
				}
				if(ba.length > 0) {
					// Write the central directory items
					stream.writeBytes(ba);
				}
				// Write end of central directory:
				// Write signature
				stream.writeUnsignedInt(SIG_END_OF_CENTRAL_DIRECTORY);
				// Write number of this disk (always 0)
				stream.writeShort(0);
				// Write number of this disk with the start of the central directory (always 0)
				stream.writeShort(0);
				// Write total number of entries on this disk
				stream.writeShort(files);
				// Write total number of entries
				stream.writeShort(files);
				// Write size
				stream.writeUnsignedInt(ba.length);
				// Write offset of start of central directory with respect to the starting disk number
				stream.writeUnsignedInt(offset);
				// Write zip file comment length (always 0)
				stream.writeShort(0);
				// Reset endian of stream
				//stream.endian = endian;
			}
		}

		/**
		 * Gets the number of accessible files in the ZIP archive.
		 * 
		 * @return The number of files
		 */				
		public function getFileCount():uint {
			return filesList ? filesList.length : 0;
		}

		/**
		 * Retrieves a file contained in the ZIP archive, by index.
		 * 
		 * @param index The index of the file to retrieve
		 * @return A reference to a FZipFile object
		 */				
		public function getFileAt(index:uint):FZipFile {
			return filesList ? filesList[index] as FZipFile : null;
		}

		/**
		 * Retrieves a file contained in the ZIP archive, by filename.
		 * 
		 * @param name The filename of the file to retrieve
		 * @return A reference to a FZipFile object
		 */				
		public function getFileByName(name:String):FZipFile {
			return filesDict[name] ? filesDict[name] as FZipFile : null;
		}

		/**
		 * Adds a file to the ZIP archive.
		 * 
		 * @param name The filename
		 * @param content The ByteArray containing the uncompressed data (pass <code>null</code> to add a folder)
		 * @param doCompress Compress the data after adding.
		 * 
		 * @return A reference to the newly created FZipFile object
		 */				
		public function addFile(name:String, content:ByteArray = null, doCompress:Boolean = true):FZipFile {
			return addFileAt(filesList ? filesList.length : 0, name, content, doCompress);
		}

		/**
		 * Adds a file from a String to the ZIP archive.
		 * 
		 * @param name The filename
		 * @param content The String
		 * @param charset The character set
		 * @param doCompress Compress the string after adding.
		 * 
		 * @return A reference to the newly created FZipFile object
		 */				
		public function addFileFromString(name:String, content:String, charset:String = "utf-8", doCompress:Boolean = true):FZipFile {
			return addFileFromStringAt(filesList ? filesList.length : 0, name, content, charset, doCompress);
		}

		/**
		 * Adds a file to the ZIP archive, at a specified index.
		 * 
		 * @param index The index
		 * @param name The filename
		 * @param content The ByteArray containing the uncompressed data (pass <code>null</code> to add a folder)
		 * @param doCompress Compress the data after adding.
		 * 
		 * @return A reference to the newly created FZipFile object
		 */				
		public function addFileAt(index:uint, name:String, content:ByteArray = null, doCompress:Boolean = true):FZipFile {
			if(filesList == null) {
				filesList = [];
			}
			if(filesDict == null) {
				filesDict = new Dictionary();
			} else if(filesDict[name]) {
				Debug.assert("File already exists: " + name + ". Please remove first.");
			}
			var file:FZipFile = new FZipFile();
			file.filename = name;
			file.setContent(content, doCompress);
			if(index >= filesList.length) {
				filesList.push(file);
			} else {
				filesList.splice(index, 0, file);
			}
			filesDict[name] = file;
			return file;
		}

		/**
		 * Adds a file from a String to the ZIP archive, at a specified index.
		 * 
		 * @param index The index
		 * @param name The filename
		 * @param content The String
		 * @param charset The character set
		 * @param doCompress Compress the string after adding.
		 * 
		 * @return A reference to the newly created FZipFile object
		 */				
		public function addFileFromStringAt(index:uint, name:String, content:String, charset:String = "utf-8", doCompress:Boolean = true):FZipFile {
			if(filesList == null) {
				filesList = [];
			}
			if(filesDict == null) {
				filesDict = new Dictionary();
			} else if(filesDict[name]) {
				Debug.assert("File already exists: " + name + ". Please remove first.");
			}
			var file:FZipFile = new FZipFile();
			file.filename = name;
			file.setContentAsString(content, charset, doCompress);
			if(index >= filesList.length) {
				filesList.push(file);
			} else {
				filesList.splice(index, 0, file);
			}
			filesDict[name] = file;
			return file;
		}

		/**
		 * Removes a file at a specified index from the ZIP archive.
		 * 
		 * @param index The index
		 * @return A reference to the removed FZipFile object
		 */				
		public function removeFileAt(index:uint):FZipFile {
			if(filesList != null && filesDict != null && index < filesList.length) {
				var file:FZipFile = filesList[index] as FZipFile;
				if(file != null) {
					filesList.splice(index, 1);
                    filesDict.deleteKey(file.filename);
					return file;
				}
			}
			return null;
		}

		/**
		 * @private
		 */		
		protected function parse(stream:ByteArray):Boolean {
			while (parseFunc(stream)) {}
			return (parseFunc == parseIdle);
		}

		/**
		 * @private
		 */		
		protected function parseIdle(stream:ByteArray):Boolean {
			return false;
		}
		
		/**
		 * @private
		 */		
		protected function parseSignature(stream:ByteArray):Boolean {
			if(stream.bytesAvailable >= 4) {
				var sig:uint = stream.readUnsignedInt();
                //trace(String.format("%d %08x", stream.bytesAvailable, sig));
				switch(sig) {
					case SIG_LOCAL_FILE_HEADER:
						parseFunc = parseLocalfile;
						currentFile = new FZipFile(charEncoding);
						break;
					case SIG_CENTRAL_FILE_HEADER:
					case SIG_END_OF_CENTRAL_DIRECTORY:
					case SIG_SPANNING_MARKER:
					case SIG_DIGITAL_SIGNATURE:
					case SIG_ZIP64_END_OF_CENTRAL_DIRECTORY:
					case SIG_ZIP64_END_OF_CENTRAL_DIRECTORY_LOCATOR:
					case SIG_DATA_DESCRIPTOR:
					case SIG_ARCHIVE_EXTRA_DATA:
					case SIG_SPANNING:
						parseFunc = parseIdle;
						break;
					default:
						Debug.assert("Unknown record signature: " + sig);
						break;
				}
				return true;
			}
			return false;
		}

		/**
		 * @private
		 */		
		protected function parseLocalfile(stream:ByteArray):Boolean {
			if(currentFile.parse(stream)) {
				if(currentFile.hasDataDescriptor) {
					
					// This file uses a data descriptor:
					
					// "[A data] descriptor exists only if bit 3 of the
					// general purpose bit flag is set.  It is byte aligned
					// and immediately follows the last byte of compressed data.
					// This descriptor is used only when it was not possible to
					// seek in the output .ZIP file, e.g., when the output .ZIP file
					// was standard output or a non-seekable device" (APPNOTE.TXT).
					
					// The file parser stops parsing after the file header.
					// We need to figure out the compressed size of the file's
					// payload (by searching ahead for the data descriptor
					// signature). See findDataDescriptor() below.
					
					parseFunc = findDataDescriptor;
					ddBuffer = new ByteArray();
					ddSignature = 0;
					ddCompressedSize = 0;
					return true;
				} else {
					// No data descriptor: We're done.
					// Register file and dispatch FILE_LOADED event
					onFileLoaded();
					// TODO [CW] why do we check for parseIdle here?
					if (parseFunc != parseIdle) {
						parseFunc = parseSignature;
						return true;
					}
				}
			}
			return false;
		}

		/**
		 * @private
		 */		
		protected function findDataDescriptor(stream:ByteArray):Boolean {
			while(stream.bytesAvailable > 0) {
				var c:uint = stream.readUnsignedByte();
				ddSignature = (ddSignature >> 8) | (c << 24);
				if(ddSignature == SIG_DATA_DESCRIPTOR) {
					// Data descriptor signature found
					// Remove last three (signature-) bytes from buffer
					ddBuffer.length -= 3;
					parseFunc = validateDataDescriptor;
					return true;
				}
				ddBuffer.writeByte(c);
			}
			return false;
		}

		/**
		 * @private
		 */		
		protected function validateDataDescriptor(stream:ByteArray):Boolean {
			// TODO [CW]
			// In case validation fails, we should reexamine the 
			// alleged sig/crc32/size bytes (minus the first byte)
			if (stream.bytesAvailable >= 12) {
				// Get data from descriptor
				var ddCRC32:uint = stream.readUnsignedInt();
				var ddSizeCompressed:uint = stream.readUnsignedInt();
				var ddSizeUncompressed:uint = stream.readUnsignedInt();
				// If the compressed size from the descriptor matches the buffer length,
				// we can be reasonably sure that this really is the descriptor.
				if(ddBuffer.length == ddSizeCompressed) {
					ddBuffer.position = 0;
					// Inject the descriptor data into current file
					currentFile._crc32 = ddCRC32;
					currentFile._sizeCompressed = ddSizeCompressed;
					currentFile._sizeUncompressed = ddSizeUncompressed;
					// Copy buffer into current file
					currentFile.parseContent(ddBuffer);
					// Register file and dispatch FILE_LOADED event
					onFileLoaded();
					// Continue with next file
					parseFunc = parseSignature;
				} else {
					// TODO [CW] check endianness (i think it's big endian, gotta set that on buffer)
					ddBuffer.writeUnsignedInt(ddCRC32);
					ddBuffer.writeUnsignedInt(ddSizeCompressed);
					ddBuffer.writeUnsignedInt(ddSizeUncompressed);
					parseFunc = findDataDescriptor;
				}
				return true;
			}
			return false;
		}
		
		/**
		 * @private
		 */		
		protected function onFileLoaded():void {
			filesList.push(currentFile);
			if (currentFile.filename) {
				filesDict[currentFile.filename] = currentFile;
			}
			dispatchEvent(new FZipEvent(FZipEvent.FILE_LOADED, currentFile));
			currentFile = null;
		}
		
		/**
		 * @private
		 */		
		/*
		protected function progressHandler(evt:Event):void {
			dispatchEvent(evt.clone());
			try {
				if(parse(urlStream)) {
					close();
					dispatchEvent(new Event(Event.COMPLETE));
				}
			} catch(e:Error) {
				close();
				if(hasEventListener(FZipErrorEvent.PARSE_ERROR)) {
					dispatchEvent(new FZipErrorEvent(FZipErrorEvent.PARSE_ERROR, e.message));
				} else {
					throw(e);
				}
			}
		}
		*/
		
		/**
		 * @private
		 */		
		protected function defaultHandler(evt:Event):void {
			dispatchEvent(evt.clone());
		}
		
		/**
		 * @private
		 */		
		protected function defaultErrorHandler(evt:Event):void {
			close();
			dispatchEvent(evt.clone());
		}
		
		/**
		 * @private
		 */		
		/*
		protected function addEventHandlers():void {
			urlStream.addEventListener(Event.COMPLETE, defaultHandler);
			urlStream.addEventListener(Event.OPEN, defaultHandler);
			urlStream.addEventListener(HTTPStatusEvent.HTTP_STATUS, defaultHandler);
			urlStream.addEventListener(IOErrorEvent.IO_ERROR, defaultErrorHandler);
			urlStream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, defaultErrorHandler);
			urlStream.addEventListener(ProgressEvent.PROGRESS, progressHandler);
		}
		*/
		
		/**
		 * @private
		 */		
		/*
		protected function removeEventHandlers():void {
			urlStream.removeEventListener(Event.COMPLETE, defaultHandler);
			urlStream.removeEventListener(Event.OPEN, defaultHandler);
			urlStream.removeEventListener(HTTPStatusEvent.HTTP_STATUS, defaultHandler);
			urlStream.removeEventListener(IOErrorEvent.IO_ERROR, defaultErrorHandler);
			urlStream.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, defaultErrorHandler);
			urlStream.removeEventListener(ProgressEvent.PROGRESS, progressHandler);
		}
		*/
	}
}