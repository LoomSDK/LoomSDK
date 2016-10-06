#include "loom/common/core/telemetry.h"

#include "loom/common/assets/assets.h"
#include "loom/common/core/log.h"
#include "loom/common/utils/fourcc.h"
#include "loom/common/utils/utEndian.h"
#include "loom/common/platform/platformThread.h"

lmDefineLogGroup(gTelemetryLogGroup, "lt", true, LoomLogInfo)

bool Telemetry::enabled = false;
bool Telemetry::pendingEnabled = false;

utByteArray Telemetry::sendBuffer;

int Telemetry::tickId = 0;

TableValues<TickMetricValue> Telemetry::tickValues;

loom_precision_timer_t Telemetry::tickTimer = loom_startTimer();

int Telemetry::tickProfilerRootsVisited;
size_t Telemetry::eventsStartPos;
bool Telemetry::tickProfilerActive = false;
int Telemetry::tickThreadId = -1;

// Initialize specialized constants for every type used
// TickMetricValue
template<> const TableType TableValues<TickMetricValue>::type = 1;
template<> const int TableValues<TickMetricValue>::packedItemSize = 4 + 8;

static const int EVENT_BYTE_SIZE = 16;
static const size_t EVENTS_MIN_SIZE = EVENT_BYTE_SIZE*128;

void Telemetry::enable()
{
    pendingEnabled = true;
}

void Telemetry::disable()
{
    pendingEnabled = false;
}

void Telemetry::beginTick()
{
    if (enabled != pendingEnabled) {
        if (pendingEnabled) tickThreadId = platform_getCurrentThreadId();
        enabled = pendingEnabled;
        lmLog(gTelemetryLogGroup, "Telemetry %s", enabled ? "enabled" : "disabled");
    }
    if (!enabled) return;

    tickValues.reset();
    tickProfilerRootsVisited = 0;

    loom_resetTimer(tickTimer);

    // Customized asset protocol message (3 ints + telemetry + other tables)
    sendBuffer.setPosition(0);

    // Size of the whole message, late write
    sendBuffer.writeUnsignedInt(-1);
    sendBuffer.writeInt(0xDEADBEEF);
    sendBuffer.writeInt(LOOM_FOURCC('T', 'E', 'L', 'E'));

    // Size of telemetry events, late write
    sendBuffer.writeUnsignedInt(-1); 

    // Endianness of the device for more efficient recording
    sendBuffer.writeUnsignedInt(UT_ENDIAN);

    // Event stream starting point for later use
    eventsStartPos = sendBuffer.getPosition();

    // Add the tick id as a default tick value
    setTickValue("tick.id", tickId);

    tickProfilerActive = true;
}

// Used to build up a telemetry root structure while reading.
struct TickProfilerRoot {
    utString name;
    int count;
};

bool Telemetry::readTickProfiler(utByteArray& buffer, JSON& ranges, JSON& meta)
{
    loom_resetTimer(tickTimer);

    size_t eventsSize = buffer.readUnsignedInt();
    unsigned int eventEndianness = buffer.readUnsignedInt();
    size_t eventsPos = buffer.getPosition();
    
    // Skip to the profiler root tree
    buffer.setPosition(eventsPos + eventsSize);

    size_t rootsWritten = buffer.readUnsignedInt();

    utHashTable<utUInt64HashKey, TickProfilerRoot> addrToName;
    addrToName.reserve(rootsWritten);

    // Read the profiler roots and save them as a lookup table into `addrToName`
    UTuint64 addr = -1;
    while ((addr = buffer.readUnsignedInt64()) != 0) {
        TickProfilerRoot root;
        root.name = buffer.readString();
        root.count = 0;
        addrToName.insert(utUInt64HashKey(addr), root);
    }
    // Overhead while writing the lookup table in-app
    UTuint64 writeOverhead = buffer.readUnsignedInt64();

    // Remember the end of the tick profiling data
    size_t endPos = buffer.getPosition();

    // Skip back to telemetry events
    buffer.setPosition(eventsPos);

    ranges.initArray();

    UTuint64 addrWithType;
    int sequence = 0;

    utArray<int> ancestors;
    // Reserving space for at least 64 makes it almost never allocate, except
    // for very deep tree depths, at which point it's ok.
    ancestors.reserve(64);
    ancestors.push_back(-1);

    // Read, process and write events as JSON
    while ((addrWithType = buffer.readUnsignedInt64()) != 0) {
        UTint64 nanoTime = buffer.readUnsignedInt64();

        // Convert endianness if necessary
        if (eventEndianness == UT_ENDIAN_BIG)
        {
            addrWithType = convertBEndianToHost(addrWithType);
            nanoTime = convertBEndianToHost(nanoTime);
        }
        else
        {
            addrWithType = convertLEndianToHost(addrWithType);
            nanoTime = convertLEndianToHost(nanoTime);
        }

        // Grab address and type from the combined addrWithType
        UTuint64 addr = addrWithType & ~TICK_EVENT_ALIGN_MASK;
        unsigned char type = addrWithType & TICK_EVENT_ALIGN_MASK;

        TickProfilerRoot* rootPtr = addrToName.get(addr);
        lmAssert(rootPtr, "Unable to find event profiler root in lookup table: %llx", addr);
        TickProfilerRoot& root = *rootPtr;

        switch (type)
        {
        case TICK_EVENT_BEGIN:
        {
            int id = sequence++;
            int parent = ancestors.back();
            int sibling = root.count++;

            // Increment children count in parent if there is one
            if (parent != -1) {
                JSON jparent = ranges.getArrayObject(parent);
                jparent.setInteger("children", jparent.getInteger("children") + 1);
            }

            JSON jrange;
            jrange.initObject();
            jrange.setInteger("id", id);
            jrange.setString("name", root.name.c_str());
            jrange.setInteger("parent", parent);
            jrange.setInteger("level", ancestors.size() - 1);
            jrange.setInteger("children", 0); // Children increment themselves
            jrange.setInteger("sibling", sibling);
            jrange.setNumber("a", nanoTime);
            jrange.setNumber("b", 0); // Set at TICK_EVENT_END
            jrange.setNumber("overhead", 0);
            ranges.setArrayObject(id, &jrange);

            ancestors.push_back(id);
        }
        break;

        case TICK_EVENT_END:
        {
            // Set end time in the previously started event
            int id = ancestors.back();
            JSON jrange = ranges.getArrayObject(id);
            jrange.setNumber("b", nanoTime);

            lmAssert(ancestors.size() > 1, "Unable to end event for %s, not enough begin events", root.name.c_str());
            ancestors.pop_back();
        }
        break;

        default: lmAssert(false, "Unknown telemetry profiler type: %d", type);
        }

    }

    lmAssert(buffer.getPosition() - eventsPos == eventsSize, "Telemetry tick profiler read size inconsistency, expected %d read %d", eventsSize, buffer.getPosition() - eventsPos);

    // Skip to end of profiler data
    buffer.setPosition(endPos);

    JSON metaOverhead;
    metaOverhead.initObject();
    meta.initObject();

    UTint64 readOverhead = loom_readTimerNano(tickTimer);

    // Write out metadata (write / read overhead)
    metaOverhead.setNumber("write", writeOverhead);
    metaOverhead.setNumber("read", readOverhead);
    meta.setObject("overhead", &metaOverhead);

    return true;
}

void Telemetry::endTick()
{
    if (!enabled) return;

    tickProfilerActive = false;

    // End events with a zero int64
    sendBuffer.writeUnsignedInt64(0);

    // Go back and write the correct size of the events
    size_t eventsAfterPos = sendBuffer.getPosition();
    sendBuffer.setPosition(eventsStartPos - 4*2);
    size_t eventsSize = eventsAfterPos - eventsStartPos;
    sendBuffer.writeUnsignedInt(eventsSize);
    sendBuffer.setPosition(eventsAfterPos);

    // Size of telemetry events, late write
    size_t rootsSizePos = sendBuffer.getPosition();
    sendBuffer.writeUnsignedInt(-1); 
    
    // Write out all the relevant profiler roots
    size_t rootsWalked = 0;
    size_t rootsWritten = 0;
    UTint64 rootWalkTime = loom_readTimerNano(tickTimer);
    for (LoomProfilerRoot *walk = LoomProfilerRoot::sRootList; walk; walk = walk->mNextRoot)
    {
        rootsWalked++;
        if (!walk->mTelemetryVisited) continue;

        walk->mTelemetryVisited = false;

        sendBuffer.writeUnsignedInt64(reinterpret_cast<UTuint64>(walk));
        sendBuffer.writeString(walk->mName);
        rootsWritten++;
    }

    // End with a zero int64
    sendBuffer.writeUnsignedInt64(0);

    // Go back and write the correct size of the events
    size_t rootsAfterPos = sendBuffer.getPosition();
    sendBuffer.setPosition(rootsSizePos);
    sendBuffer.writeUnsignedInt(rootsWritten);
    sendBuffer.setPosition(rootsAfterPos);

    // Record the write overhead
    rootWalkTime = loom_readTimerNano(tickTimer) - rootWalkTime;
    sendBuffer.writeUnsignedInt64(rootWalkTime);

    // Write out the values table
    tickValues.write(&sendBuffer);

    // Fix message size to be the actual written size
    size_t sendSize = sendBuffer.getPosition();
    sendBuffer.setPosition(0);
    sendBuffer.writeUnsignedInt(sendSize);
    sendBuffer.setPosition(sendSize);

    // Send the tick over the asset protocol
    loom_asset_custom(sendBuffer.getDataPtr(), sendSize);

    tickId++;
}

// Ensure that the message buffer contains enough space for at least
// one more event.
static void ensureEventBuffer(utByteArray &buffer, size_t startPos)
{
    size_t size = buffer.getSize();
    if (buffer.getPosition() + EVENT_BYTE_SIZE > size) {
        size_t newEventsSize = utMax((size - startPos)*2, EVENTS_MIN_SIZE);
        buffer.resize(size + newEventsSize);
    }
}

// Begins the profiling range of the provided root.
void Telemetry::beginTickTimer(LoomProfilerRoot* root)
{
    if (!enabled) return;
    
    // Ignore all events that are not on the main thread for now
    if (platform_getCurrentThreadId() != tickThreadId) return;

    // Uncomment to identify profiler events out of the usual tick range
    //lmAssert(tickProfilerActive, "Began tick timer while inactive at %s", root->mName);
    if (!tickProfilerActive) return;

    if (!root->mTelemetryVisited) {
        ++tickProfilerRootsVisited;
        root->mTelemetryVisited = true;
    }

    ensureEventBuffer(sendBuffer, eventsStartPos);

    // Write out the event message directly in system endianness
    UTuint64* buf = reinterpret_cast<UTuint64*>(static_cast<unsigned char*>(sendBuffer.getDataPtr()) + sendBuffer.getPosition());
    buf[0] = reinterpret_cast<UTuint64>(root) | TICK_EVENT_BEGIN;
    buf[1] = loom_readTimerNano(tickTimer);
    sendBuffer.setPosition(sendBuffer.getPosition() + EVENT_BYTE_SIZE);
}

// Ends the timing range of the provided root. See `beginTickTimer`.
void Telemetry::endTickTimer(LoomProfilerRoot* root)
{
    if (!enabled) return;
    if (platform_getCurrentThreadId() != tickThreadId) return;
    if (!tickProfilerActive) return;

    ensureEventBuffer(sendBuffer, eventsStartPos);

    UTuint64* buf = reinterpret_cast<UTuint64*>(static_cast<unsigned char*>(sendBuffer.getDataPtr()) + sendBuffer.getPosition());
    buf[0] = reinterpret_cast<UTuint64>(root) | TICK_EVENT_END;
    buf[1] = loom_readTimerNano(tickTimer);
    sendBuffer.setPosition(sendBuffer.getPosition() + EVENT_BYTE_SIZE);
}

TickMetricValue* Telemetry::setTickValue(const char *name, double value)
{
    if (!enabled) return NULL;

    utHashedString key = utHashedString(name);
    TickMetricValue *stored = tickValues.table.get(key);
    TickMetricValue metric;

    // This is a new value, insert it and update the table size
    if (stored == NULL) {
        metric.id = tickValues.sequence++;
        metric.value = value;

        bool inserted = tickValues.table.insert(key, metric);
        lmAssert(inserted, "Tick metric should be able to be inserted or retrieved");

        stored = &tickValues.table.at(tickValues.table.size() - 1);

        size_t strSize = 2 + strlen(name);
        tickValues.size += strSize + TableValues<TickMetricValue>::packedItemSize;
    }
    else
    {
        // It was inserted before, just update the value
        metric = *stored;
        metric.value = value;
    }

    return stored;
}
