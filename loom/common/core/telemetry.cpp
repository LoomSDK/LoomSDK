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

template<> const TableType TableValues<TickMetricValue>::type = 1;
template<> const int TableValues<TickMetricValue>::packedItemSize = 4 + 8;

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

    setTickValue("tickId", tickId);
}

void Telemetry::endTick()
{
    if (!enabled) return;

    lmAssert(tickTimerStack.size() == 0, "Tick timer end call missing");

    int sendSize = 3 * 4 + tickValues.size + tickRanges.size;
    sendBuffer.resize(sendSize);
    sendBuffer.setPosition(0);
    sendBuffer.writeInt(sendSize);
    sendBuffer.writeInt(0xDEADBEEF);
    sendBuffer.writeInt(LOOM_FOURCC('T', 'E', 'L', 'E'));

    //lmLog(gTelemetryLogGroup, "endTick %d", sendSize);

    tickValues.write(&sendBuffer);
    tickRanges.write(&sendBuffer);

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

    if (stored != NULL)
    {
        stored->duplicates++;
        stored->duplicatesOnStack++;
        //sscanf_s(stored->n, "%s.%d", uniqueName, dup);
        snprintf(uniqueName, uniqueLen - 1, "%s #%d", name, stored->duplicates+1);
        uniqueName[uniqueLen - 1] = 0;

        key = utHashedString(uniqueName);
    }
    //lmAssert(stored == NULL, "Tick timer missing end call for %s (begin call called twice in a row)", name);

    utString parentName = tickTimerStack.size() > 0 ? tickTimerStack.back() : NULL;
    TickMetricRange *parent = tickRanges.table.get(utHashedString(parentName));

    TickMetricRange metric;
    metric.id = tickRanges.sequence++;
    lmAssert(metric.id >= 0, "Invalid id");
    metric.parent = parent ? parent->id : -1;
    metric.level = parent ? parent->level + 1 : 0;
    metric.children = 0;
    metric.sibling = parent ? parent->children : 0;
    metric.duplicates = 0;
    metric.duplicatesOnStack = 0;
    //metric.name = strdup(name);
    //metric.unique = strdup(uniqueName);
    if (parent) parent->children++;

    bool inserted = tickRanges.table.insert(key, metric);
    lmAssert(inserted, "Tick timer insertion error");

    int strSize = 2 + strlen(key.str().c_str());
    tickRanges.size += strSize + TableValues<TickMetricRange>::packedItemSize;
    
    stored = tickRanges.table.get(key);
    tickTimerStack.push_back(key.str());

    double tickNano = loom_readTimerNano(tickTimer);
    stored->a = tickNano;
    
    /*
    lmAssert(stored->id >= 0, "Invalid id");
    //lmLog(gTelemetryLogGroup, "begin %s", name);
    for (unsigned int i = 0; i < tickRanges.table.size(); i++) {
        TickMetricRange *t = &tickRanges.table.at(i);
        //lmLog(gTelemetryLogGroup, "id %d level %d parent %d dup %d dups %d", t->id, t->level, t->parent, t->duplicates, t->duplicatesOnStack);
        lmAssert(t->id >= 0, "Invalid id");
    }
    //lmLog(gTelemetryLogGroup, "---");
    for (unsigned int i = 0; i < tickTimerStack.size(); i++) {
        utString tname = tickTimerStack.at(i);
        TickMetricRange *t = tickRanges.table.get(utHashedString(tname));
        //lmLog(gTelemetryLogGroup, "id %d %s level %d parent %d dup %d dups %d", tname, t->id, t->level, t->parent, t->duplicates, t->duplicatesOnStack);
        lmAssert(t->id >= 0, "Invalid id");
    }
    */
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
    
    if (stored->id != stacked->id) {
        stored->duplicatesOnStack--;
        lmAssert(stored->duplicatesOnStack >= 0, "Tick metric mismatched begin/end calls");
    }

    tickTimerStack.pop_back();
    
    stacked->b = tickNano;
}

TickMetricValue* Telemetry::setTickValue(const char *name, double value)
{
    if (!enabled) return NULL;

    utHashedString key = utHashedString(name);
    TickMetricValue *stored = tickValues.table.get(key);
    TickMetricValue metric;
    if (stored == NULL) {
        metric.id = tickValues.sequence++;
        metric.value = value;

        bool inserted = tickValues.table.insert(key, metric);
        lmAssert(inserted, "Tick metric should be able to be inserted or retrieved");

        stored = &tickValues.table.at(tickValues.table.size() - 1);

        int strSize = 2 + strlen(name);
        tickValues.size += strSize + TableValues<TickMetricValue>::packedItemSize;
    }
    else
    {
        metric = *stored;
        metric.value = value;
    }

    return stored;
}
