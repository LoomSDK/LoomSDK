#ifndef _ASSETS_TELEMETRY_H_
#define _ASSETS_TELEMETRY_H_

#include "loom/common/platform/platformTime.h"
#include "loom/common/assets/assetProtocol.h"
#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utByteArray.h"
#include "loom/common/utils/json.h"
#include "loom/common/core/performance.h"

// Type alias for metric IDs
typedef int TickMetricID;

// Event types are packed into the lower bits of the address. This controls
// how much alignment
static const int TICK_EVENT_ALIGN = 4;
static const int TICK_EVENT_ALIGN_MASK = TICK_EVENT_ALIGN - 1;
static const int TICK_EVENT_BEGIN = 1;
static const int TICK_EVENT_END   = 2;

static const unsigned char TICK_PROFILER_TYPE = 3;

// Base struct for different kinds of metrics
struct TickMetricBase
{
    TickMetricID id;
    
    // Write the metric as binary values
    // This should be called and extended in subclasses
    // for the values that they add
    void write(utByteArray *buffer)
    {
        buffer->writeInt(id);
    }

    // Write the metric as a JSON property
    // This should be called and extended in subclasses
    // for the values that they add
    void writeJSON(JSON *json)
    {
        json->setInteger("id", id);
    }

    // Read the metric from a binary buffer
    // This should be called and extended in subclasses
    // for the values that they add
    void read(utByteArray *buffer)
    {
        id = buffer->readInt();
    }
};

// Metric type containing a single floating point value
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

// Type alias for the table type ID
typedef unsigned char TableType;

// Generic class for handling key-value tables with different values/metrics and their serialization
template <class TableValue>
struct TableValues
{
    static const unsigned int HEADER_SIZE = 1 + 4; // Table type + size bytes
    static const TableType type; // Should be set to a unique value for every specialized struct (i.e. for every type used)
    static const int packedItemSize; // Should be set to the expected packed byte size of a written TableValue item

    // A sequence number useful for assigning items table-unique ids
    int sequence;

    // The hash table holding the key-value pairs
    utHashTable<utHashedString, TableValue> table;

    // Size of the table in bytes
    size_t size;

    // Reset and clear the table
    void reset()
    {
        table.clear();
        size = HEADER_SIZE;
        sequence = 0;
    }

    // Write the table to a buffer including the type, size and actual key-value pairs
    void write(utByteArray *buffer)
    {
        writeType(buffer);
        writeSize(buffer);
        writeHashTable(buffer);
    }

    // Write just the table type to a buffer
    void writeType(utByteArray *buffer)
    {
        buffer->writeUnsignedByte(TableValues<TableValue>::type);
    }

    // Write just the table size to a buffer
    void writeSize(utByteArray *buffer)
    {
        buffer->writeUnsignedInt((unsigned int)size);
    }

    // Write just the key-value pairs to a buffer
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

    // Write the table as a JSON array
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

    // Write the table as a JSON object
    void writeJSONObject(JSON *json)
    {
        json->initObject();
        for (UTsize i = 0; i < table.size(); i++)
        {
            TableValue value = table.at(i);
            value.writeJSONProperty(json, table.keyAt(i).str().c_str());
        }
    }

    // Read the table from the buffer, returns false if the table type doesn't match, true if the table was read successfully
    bool read(utByteArray *buffer)
    {
        TableType type = readType(buffer);
        if (type != TableValues<TableValue>::type)
        {
            buffer->setPosition(buffer->getPosition() - 1);
            return false;
        }
        size = readSize(buffer);
        readHashTable(buffer);
        return true;
    }

    // Read just the table size
    int readSize(utByteArray *buffer) const
    {
        return buffer->readUnsignedInt();
    }

    // Read just the table type
    static TableType readType(utByteArray *buffer)
    {
        return buffer->readUnsignedByte();
    }

    // Read just the table key-value pairs
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

// App level Telemetry API for setting values / metrics and configuring the behavior
class Telemetry
{
protected:
    // true if telemetry is enabled (this can take up to a tick to update once you toggle state)
    static bool enabled;
    // The desired state of telemetry, this is the externally visible state and takes effect on tick begin
    // Until then `enabled` reflects the current state of the system
    static bool pendingEnabled;

    // Temporary buffer used while sending the tick
    static utByteArray sendBuffer;

    // Stored values of the current tick
    static TableValues<TickMetricValue> tickValues;

    // Timer used for timing tick ranges
    static loom_precision_timer_t tickTimer;
    
    // The number of unique roots visited in the current tick
    static int tickProfilerRootsVisited;

    // Position of the start of the profiler event stream
    static size_t eventsStartPos;

    // `true` if the profiler is active and capturing events, `false` otherwise
    static bool tickProfilerActive;

    // ID of the thread where the tick started
    static int tickThreadId;

    // Current tick ID
    static int tickId;

public:

    // Enable telemetry functionality
    // This will take effect when the next tick begins
    static void enable();

    // Disable telemetry functionality
    // This will take effect when the next tick begins
    static void disable();
    
    // Returns whether the telemetry is enabled or disabled
    // Note that this can return true while the system is still
    // transitioning states and not active yet
    inline static bool isEnabled()
    {
        return pendingEnabled;
    }

    // Call at the beginning of the tick
    static void beginTick();

    // Call at the end of the tick
    static void endTick();

    // Begin a timer range using the specified profiler root
    static void beginTickTimer(LoomProfilerRoot* root);

    // End the timer range previously began with the specified profiler root
    static void endTickTimer(LoomProfilerRoot* root);

    // Set an arbitrary floating point value associated with the current tick and name
    // Previously set values of the same name get overwritten
    // To avoid name conflicts it is suggested to use namespaced names (e.g. gc.cycle.update.count)
    static TickMetricValue* setTickValue(const char *name, double value);

    // Read and process tick events from the provided buffer and save them as JSON
    // ranges and additional metadata into the provided objects.
    static bool readTickProfiler(utByteArray& buffer, JSON& tickRange, JSON& meta);

};

#endif