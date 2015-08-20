#ifndef _ASSETS_TELEMETRY_H_
#define _ASSETS_TELEMETRY_H_

#include "loom/common/platform/platformTime.h"
#include "loom/common/assets/assetProtocol.h"
#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utByteArray.h"

#include "loom/vendor/civetweb/include/civetweb.h"
#include "loom/script/native/core/system/lmJSON.h"

class TelemetryListener : public AssetProtocolMessageListener
{
public:
    virtual bool handleMessage(int fourcc, AssetProtocolHandler *handler, NetworkBuffer& buffer);
};

typedef int TickMetricID;

struct TickMetricBase
{
    TickMetricID id;
    void write(utByteArray *buffer)
    {
        buffer->writeInt(id);
    }
    void writeJSON(JSON *json)
    {
        json->setInteger("id", id);
    }
    void read(utByteArray *buffer)
    {
        id = buffer->readInt();
    }
};

struct TickMetricValue : TickMetricBase
{
    double value;
    void write(utByteArray *buffer)
    {
        TickMetricBase::write(buffer);
        buffer->writeDouble(value);
    }
    void writeJSON(JSON *json)
    {
        TickMetricBase::writeJSON(json);
        json->setNumber("value", value);
    }
    void writeJSONProperty(JSON *json, const char *name)
    {
        json->setNumber(name, value);
    }
    void read(utByteArray *buffer)
    {
        TickMetricBase::read(buffer);
        value = buffer->readDouble();
    }
};

struct TickMetricRange : TickMetricBase
{
    TickMetricID parent;
    int level;
    int children;
    int sibling;
    double a;
    double b;

    int duplicates;
    int duplicatesOnStack;
    //const char *name;
    //const char *unique;

    void write(utByteArray *buffer)
    {
        TickMetricBase::write(buffer);
        buffer->writeInt(parent);
        buffer->writeInt(level);
        buffer->writeInt(children);
        buffer->writeInt(sibling);
        buffer->writeDouble(a);
        buffer->writeDouble(b);
    }
    void writeJSON(JSON *json)
    {
        TickMetricBase::writeJSON(json);
        json->setInteger("parent", parent);
        json->setInteger("level", level);
        json->setInteger("children", children);
        json->setInteger("sibling", sibling);
        json->setNumber("a", a);
        json->setNumber("b", b);
    }
    void read(utByteArray *buffer)
    {
        TickMetricBase::read(buffer);
        parent = buffer->readInt();
        level = buffer->readInt();
        children = buffer->readInt();
        sibling = buffer->readInt();
        a = buffer->readDouble();
        b = buffer->readDouble();
    }
};


typedef unsigned char TableType;

template <class T>
struct TableValuesTraits
{
    static const TableType type;
    static const int packedItemSize;
};

template <>
struct TableValuesTraits<TickMetricValue>
{
    static const TableType type;
    static const int packedItemSize;
};


template <class TableValue>
struct TableValues
{
    static const unsigned int HEADER_SIZE = 1 + 4; // Table type + size bytes

    static int sequence;

    TableType getType() { return TableValuesTraits<TableValue>::type; }
    utHashTable<utHashedString, TableValue> table;
    unsigned int size;

    void reset()
    {
        table.clear();
        size = HEADER_SIZE;
        sequence = 0;
    }

    void write(utByteArray *buffer)
    {
        writeType(buffer);
        writeSize(buffer);
        writeHashTable(buffer);
    }
    void writeType(utByteArray *buffer)
    {
        buffer->writeUnsignedByte(TableValuesTraits<TableValue>::type);
    }
    void writeSize(utByteArray *buffer)
    {
        buffer->writeUnsignedInt(size);
    }
    void writeHashTable(utByteArray *buffer)
    {
        int startPos = buffer->getPosition() - HEADER_SIZE;
        int len = table.size();
        for (int i = 0; i < len; i++)
        {
            utHashedString key = table.keyAt(i);
            TableValue *value = table.get(key);
            lmAssert(value != NULL, "Internal hash table error, value should not be null");
            buffer->writeUTF(key.str().c_str());
            value->write(buffer);
        }
        lmAssert(size == -1 || size == buffer->getPosition() - startPos, "Internal hash table size inconsistency: %d - %d != %d", buffer->getPosition(), startPos, size);
    }

    void writeJSONArray(JSON *json)
    {
        json->initArray();
        for (UTsize i = 0; i < table.size(); i++)
        {
            TableValue value = table.at(i);
            JSON jvalue;
            jvalue.initObject();
            jvalue.setString("name", table.keyAt(i).str().c_str());
            value.writeJSON(&jvalue);
            json->setArrayObject(value.id, &jvalue);
        }
    }

    void writeJSONObject(JSON *json)
    {
        json->initObject();
        for (UTsize i = 0; i < table.size(); i++)
        {
            TableValue value = table.at(i);
            value.writeJSONProperty(json, table.keyAt(i).str().c_str());
        }
    }

    bool read(utByteArray *buffer)
    {
        TableType type = readType(buffer);
        if (type != TableValuesTraits<TableValue>::type)
        {
            buffer->setPosition(buffer->getPosition() - 1);
            return false;
        }
        size = readSize(buffer);
        readHashTable(buffer);
        return true;
    }

    int readSize(utByteArray *buffer) const
    {
        return buffer->readUnsignedInt();
    }

    static TableType readType(utByteArray *buffer)
    {
        return buffer->readUnsignedByte();
    }

    int readHashTable(utByteArray *buffer)
    {
        int insertedItems = 0;
        unsigned int startPos = buffer->getPosition() - HEADER_SIZE;
        while (buffer->getPosition() - startPos < size)
        {
            const char* name = buffer->readUTF();
            TableValue value;
            value.read(buffer);
            bool inserted = table.insert(utHashedString(name), value);
            if (inserted) insertedItems++;
        }
        lmAssert(buffer->getPosition() - startPos == size, "Internal hash table read size mismatch");
        return insertedItems;
    }


};

class Telemetry
{
protected:
    static utByteArray sendBuffer;

    static TableValues<TickMetricValue> tickValues;

    static loom_precision_timer_t tickTimer;
    static utArray<utString> tickTimerStack;
    static TableValues<TickMetricRange> tickRanges;

    static int tickId;

    static struct mg_callbacks callbacks;
    static struct mg_context *server;

    static JSON tickValuesJSON;
    static JSON tickRangesJSON;
    static JSON tickMetricsJSON;
    static utString tickMetricsJSONString;

    static void updateMetricsJSON();


public:
    static void handleMessage(utByteArray *buffer);

    static void beginTick();
    static void endTick();

    static void beginTickTimer(const char *name);
    static void endTickTimer(const char *name);

    static TickMetricValue* setTickValue(const char *name, double value);

    static void startServer();
    static void fileChanged(const char* path);

};

#endif