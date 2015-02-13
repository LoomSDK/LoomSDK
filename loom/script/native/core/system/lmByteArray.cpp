/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#include "loom/script/loomscript.h"
#include "loom/common/utils/utByteArray.h"

static int registerSystemByteArray(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<utByteArray> ("ByteArray")

       .addConstructor<void (*)(void)>()
       .addMethod("clear", &utByteArray::clear)
       .addProperty("position", &utByteArray::getPosition, &utByteArray::setPosition)
       .addProperty("bytesAvailable", &utByteArray::bytesAvailable)
       .addMethod("toString", &utByteArray::toString)
       .addMethod("setPosition", &utByteArray::setPosition)
       .addMethod("readInt", &utByteArray::readInt)
       .addMethod("writeInt", &utByteArray::writeInt)
       .addMethod("readUnsignedInt", &utByteArray::readUnsignedInt)
       .addMethod("writeUnsignedInt", &utByteArray::writeUnsignedInt)
       .addMethod("readShort", &utByteArray::readShort)
       .addMethod("writeShort", &utByteArray::writeShort)
       .addMethod("readUnsignedShort", &utByteArray::readUnsignedShort)
       .addMethod("writeUnsignedShort", &utByteArray::writeUnsignedShort)
       .addMethod("readFloat", &utByteArray::readFloat)
       .addMethod("writeFloat", &utByteArray::writeFloat)
       .addMethod("readDouble", &utByteArray::readDouble)
       .addMethod("writeDouble", &utByteArray::writeDouble)
       .addMethod("readString", &utByteArray::readString)
       .addMethod("writeString", &utByteArray::writeString)
       .addMethod("readBoolean", &utByteArray::readBoolean)
       .addMethod("writeBoolean", &utByteArray::writeBoolean)
       .addMethod("readByte", &utByteArray::readByte)
       .addMethod("writeByte", &utByteArray::writeByte)
       .addMethod("readUnsignedByte", &utByteArray::readUnsignedByte)
       .addMethod("writeUnsignedByte", &utByteArray::writeUnsignedByte)
       .addMethod("readBytes", &utByteArray::readBytes)
       .addMethod("writeBytes", &utByteArray::writeBytes)
       .addMethod("reserve", &utByteArray::reserve)
       .addMethod("compress", &utByteArray::compress)
       .addMethod("uncompress", &utByteArray::uncompress)
       .addVarAccessor("length", &utByteArray::getSize, &utByteArray::resize)

       .endClass()

       .endPackage();

    return 0;
}


void installSystemByteArray()
{
    NativeInterface::registerNativeType<utByteArray>(registerSystemByteArray);
}
