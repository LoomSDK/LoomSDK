#include "loom/common/core/telemetry.h"

#include "loom/common/assets/assets.h"
#include "loom/common/core/log.h"
#include "loom/common/core/performance.h"
#include "loom/common/utils/fourcc.h"

lmDefineLogGroup(gTelemetryLogGroup, "lt", true, LoomLogInfo)

bool Telemetry::enabled = false;
bool Telemetry::pendingEnabled = false;

utByteArray Telemetry::sendBuffer;

int Telemetry::tickId = 0;

TableValues<TickMetricValue> Telemetry::tickValues;

loom_precision_timer_t Telemetry::tickTimer = loom_startTimer();
utArray<utString> Telemetry::tickTimerStack;
TableValues<TickMetricRange> Telemetry::tickRanges;

// Initialize specialized constants for every type used
// TickMetricValue
template<> const TableType TableValues<TickMetricValue>::type = 1;
template<> const int TableValues<TickMetricValue>::packedItemSize = 4 + 8;
// TickMetricRange
template<> const TableType TableValues<TickMetricRange>::type = 2;
template<> const int TableValues<TickMetricRange>::packedItemSize = 4 + 4 * 4 + 2 * 8;


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
        enabled = pendingEnabled;
        lmLog(gTelemetryLogGroup, "Telemetry %s", enabled ? "enabled" : "disabled");
    }
    if (!enabled) return;

    tickValues.reset();
    tickRanges.reset();
    tickTimerStack.clear();

    loom_resetTimer(tickTimer);

    // Add the tick id as a default tick value
    setTickValue("tick.id", tickId);
}

void Telemetry::endTick()
{
    if (!enabled) return;

    lmAssert(tickTimerStack.size() == 0, "Tick timer end call missing");

    // Customized asset protocol message (3 ints + tables)
    int sendSize = (int)(3 * 4 + tickValues.size + tickRanges.size);
    sendBuffer.resize(sendSize);
    sendBuffer.setPosition(0);
    sendBuffer.writeInt(sendSize);
    sendBuffer.writeInt(0xDEADBEEF);
    sendBuffer.writeInt(LOOM_FOURCC('T', 'E', 'L', 'E'));

    tickValues.write(&sendBuffer);
    tickRanges.write(&sendBuffer);

    // Send the tick over the asset protocol
    loom_asset_custom(sendBuffer.getDataPtr(), sendBuffer.getSize());

    tickId++;
}

void Telemetry::beginTickTimer(const char *name)
{
    if (!enabled) return;

    utHashedString key = utHashedString(name);

    TickMetricRange *stored = tickRanges.table.get(key);

    const int uniqueLen = 128;
    static char uniqueName[uniqueLen];
    int dup = 0;

    // A range with the specified name already exists,
    // mark this one as a duplicate and append the sequential duplicate number at the end
    if (stored != NULL)
    {
        stored->duplicates++;
        stored->duplicatesOnStack++;
        snprintf(uniqueName, uniqueLen - 1, "%s #%d", name, stored->duplicates+1);
        uniqueName[uniqueLen - 1] = 0;

        key = utHashedString(uniqueName);
    }

    utString parentName = tickTimerStack.size() > 0 ? tickTimerStack.back() : NULL;
    TickMetricRange *parent = tickRanges.table.get(utHashedString(parentName));

    // Init values of the new metric based on its parent and siblings
    TickMetricRange metric;
    metric.id = tickRanges.sequence++;
    lmAssert(metric.id >= 0, "Invalid id");
    metric.parent = parent ? parent->id : -1;
    metric.level = parent ? parent->level + 1 : 0;
    metric.children = 0;
    metric.sibling = parent ? parent->children : 0;
    metric.duplicates = 0;
    metric.duplicatesOnStack = 0;
    if (parent) parent->children++;

    // Insert it into the table
    bool inserted = tickRanges.table.insert(key, metric);
    lmAssert(inserted, "Tick timer insertion error");

    // String written size is short length + data
    int strSize = (int)(2 + strlen(key.str().c_str()));
    tickRanges.size += strSize + TableValues<TickMetricRange>::packedItemSize;
    
    // This should be fairly quick as the last inserted value should be cached
    stored = tickRanges.table.get(key);
    tickTimerStack.push_back(key.str());

    double tickNano = loom_readTimerNano(tickTimer);
    
    // Set the start time at the very end
    // TODO measure overhead of the code above and include that in the metrics
    stored->a = tickNano;
}

void Telemetry::endTickTimer(const char *name)
{
    if (!enabled) return;

    double tickNano = loom_readTimerNano(tickTimer);

    utHashedString key = utHashedString(name);

    lmAssert(tickTimerStack.size() > 0, "Tick timer %s begin call missing (stack empty)");

    TickMetricRange *stored = tickRanges.table.get(key);
    utString stackedName = tickTimerStack.back();
    TickMetricRange *stacked = tickRanges.table.get(utHashedString(stackedName));

    lmAssert(stored->id >= 0 && stacked->id >= 0, "Invalid id");
    lmAssert(stored != NULL && stacked != NULL, "Tick timer %s begin call missing");
    
    // If the stack and stored ids don't match
    // it means the stack metric was a modified duplicate
    // with a different unique name, so we can decrement the
    // number of duplicates on stack of the originally named stored metric
    if (stored->id != stacked->id) {
        stored->duplicatesOnStack--;
        lmAssert(stored->duplicatesOnStack >= 0, "Tick metric mismatched begin/end calls");
    }

    tickTimerStack.pop_back();
    
    // Set the end time of the tick on the stack taken from the enter time of the function
    // TODO measure overhead as with begin
    stacked->b = tickNano;
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
