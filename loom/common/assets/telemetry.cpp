#include "telemetry.h"

#include "loom/common/utils/fourcc.h"
#include "loom/common/assets/assets.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platformThread.h"

#define LTS_DOCUMENT_ROOT "./www"
#define LTS_PORT "8073"
#define MAIN_URI "/"
#define TICK_URI "/tick"

#define MAX_WS_CLIENTS 5 /* just for the test: a small number that can be reached */
                         /* a real server should use a much higher number here */



lmDefineLogGroup(gTelemetryLogGroup, "lt", true, LoomLogInfo)

utByteArray Telemetry::sendBuffer;

JSON Telemetry::tickValuesJSON;
JSON Telemetry::tickRangesJSON;
JSON Telemetry::tickMetricsJSON;
utString Telemetry::tickMetricsJSONString;

int Telemetry::tickId = 0;

TableValues<TickMetricValue> Telemetry::tickValues;

loom_precision_timer_t Telemetry::tickTimer = loom_startTimer();
utArray<utString> Telemetry::tickTimerStack;
TableValues<TickMetricRange> Telemetry::tickRanges;

int TableValues<TickMetricValue>::sequence;
int TableValues<TickMetricRange>::sequence;

const TableType TableValuesTraits<TickMetricValue>::type = 1;
const int TableValuesTraits<TickMetricValue>::packedItemSize = 4 + 8;

const TableType TableValuesTraits<TickMetricRange>::type = 2;
const int TableValuesTraits<TickMetricRange>::packedItemSize = 4 + 4 * 4 + 2 * 8;

mg_callbacks Telemetry::callbacks;
mg_context* Telemetry::server = NULL;

static MutexHandle jsonMutex = loom_mutex_create();


static int IndexHandler(struct mg_connection *conn, void *cbdata)
{
    mg_printf(conn, "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n");
    return 1;
}

void Telemetry::fileChanged(const char* path)
{
    lmLog(gTelemetryLogGroup, "File changed: %s", path);
}

static int JSONHandler(struct mg_connection *conn, void *cbdata)
{
    JSON* json = (JSON*)cbdata;
    lmAssert(json != NULL, "Invalid JSON object provided to the JSON handler");
    loom_mutex_lock(jsonMutex);
    const char* serialized = json->serialize();
    if (serialized == NULL)
    {
        serialized = "{ \"status\": \"fail\", \"data\": null }";
    }
    mg_printf(conn, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
    mg_write(conn, serialized, strlen(serialized));
    loom_mutex_unlock(jsonMutex);
    return 1;
}

static int JSONStringHandler(struct mg_connection *conn, void *cbdata)
{
    utString* jsonString = (utString*)cbdata;
    lmAssert(jsonString != NULL, "Invalid JSON object provided to the JSON handler");
    loom_mutex_lock(jsonMutex);
    if (jsonString->empty())
    {
        jsonString = &utString("{ \"status\": \"fail\", \"data\": null }");
    }
    mg_printf(conn, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
    mg_write(conn, jsonString->c_str(), jsonString->length());
    loom_mutex_unlock(jsonMutex);
    return 1;
}


static int clientGlobalID = 0;

struct StreamClient {
    int id;
    struct mg_connection * conn;
    int state;
} static streamClients[MAX_WS_CLIENTS];

static unsigned long cnt;


int StreamConnectHandler(const struct mg_connection * conn, void *cbdata)
{
    struct mg_context *ctx = mg_get_context(conn);
    StreamClient *client = NULL;
    int i;

    mg_lock_context(ctx);
    for (i = 0; i < MAX_WS_CLIENTS; i++) {
        if (streamClients[i].conn == NULL) {
            streamClients[i].id = clientGlobalID++;
            streamClients[i].conn = (struct mg_connection *) conn;
            streamClients[i].state = 1;
            mg_set_user_connection_data(conn, (void*)(streamClients + i));
            client = &streamClients[i];
            break;
        }
    }
    mg_unlock_context(ctx);

    if (client == NULL)
    {
        lmLog(gTelemetryLogGroup, "Stream client rejected");
    }
    else
    {
        lmLog(gTelemetryLogGroup, "Stream client #%d accepted", client->id);
    }

    return client == NULL ? 1 : 0;
}

void StreamReadyHandler(struct mg_connection * conn, void *cbdata)
{
    struct StreamClient *client = (StreamClient*)mg_get_user_connection_data(conn);

    //const char * text = "{ \"status\": \"ready\", \"data\": null }";;
    //mg_websocket_write(conn, WEBSOCKET_OPCODE_TEXT, text, strlen(text));

    lmLog(gTelemetryLogGroup, "Stream client #%d ready", client->id);

    lmAssert(client->conn == conn, "Websocket connection mismatch");
    lmAssert(client->state == 1, "Websocket invalid state");

    client->state = 2;
}

int StreamDataHandler(struct mg_connection * conn, int bits, char * data, size_t len, void *cbdata)
{
    struct StreamClient *client = (StreamClient*)mg_get_user_connection_data(conn);
    
    lmAssert(client->conn == conn, "Websocket connection mismatch");
    lmAssert(client->state >= 1, "Websocket invalid state");

    fprintf(stdout, "Websocket got data:\r\n");
    fwrite(data, len, 1, stdout);
    fprintf(stdout, "\r\n\r\n");

    return 1;
}

void StreamCloseHandler(const struct mg_connection * conn, void *cbdata)
{
    struct StreamClient *client = (StreamClient*)mg_get_user_connection_data(conn);
    struct mg_context *ctx = mg_get_context(conn);

    lmAssert(client->conn == conn, "Websocket connection mismatch");
    lmAssert(client->state >= 1, "Websocket invalid state");

    lmLog(gTelemetryLogGroup, "Stream client #%d dropped", client->id);

    mg_lock_context(ctx);
    client->id = -1;
    client->state = 0;
    client->conn = NULL;
    mg_unlock_context(ctx);
}

void StreamSendAll(struct mg_context *ctx, const char *msg)
{
    int i;
    mg_lock_context(ctx);
    for (i = 0; i < MAX_WS_CLIENTS; i++) {
        if (streamClients[i].state == 2) {
            mg_websocket_write(streamClients[i].conn, WEBSOCKET_OPCODE_TEXT, msg, strlen(msg));
        }
    }
    mg_unlock_context(ctx);
}


void Telemetry::startServer()
{
    const char * options[] = {
        "document_root", LTS_DOCUMENT_ROOT,
        "listening_ports", LTS_PORT,
        0
    };

    memset(&callbacks, 0, sizeof(callbacks));
    server = mg_start(&callbacks, 0, options);

    //mg_set_request_handler(server, MAIN_URI, IndexHandler, 0);
    mg_set_request_handler(server, TICK_URI, JSONStringHandler, &Telemetry::tickMetricsJSONString);

    /* WS site for the websocket connection */
    mg_set_websocket_handler(server, "/stream", StreamConnectHandler, StreamReadyHandler, StreamDataHandler, StreamCloseHandler, 0);

}


bool TelemetryListener::handleMessage(int fourcc, AssetProtocolHandler *handler, NetworkBuffer& netBuffer)
{
    switch (fourcc)
    {
    case LOOM_FOURCC('T', 'E', 'L', 'E'):

        utByteArray buffer;
        int curPos = netBuffer.getCurrentPosition();

        buffer.attach((char*)netBuffer.buffer + curPos, netBuffer.length - curPos);

        Telemetry::handleMessage(&buffer);

        return true;

        break;
    }

    return false;
}

void Telemetry::handleMessage(utByteArray *buffer)
{
    TableValues<TickMetricValue> tickValues;
    TableValues<TickMetricRange> tickRanges;

    loom_mutex_lock(jsonMutex);

    while (buffer->bytesAvailable() > 0)
    {
        if (tickValues.read(buffer))
        {
            tickValues.writeJSON(&tickValuesJSON);
        }
        else if (tickRanges.read(buffer))
        {
            tickRanges.writeJSON(&tickRangesJSON);
        }
        else
        {
            lmAssert(false, "Unknown telemetry type: %d", TableValues<TickMetricValue>::readType(buffer));
        }
    }

    updateMetricsJSON();

    loom_mutex_unlock(jsonMutex);
}

void Telemetry::updateMetricsJSON()
{
    JSON jdata;

    tickMetricsJSON.initObject();
    tickMetricsJSON.setString("status", "success");

    jdata.initObject();
    jdata.setArray("values", &tickValuesJSON);
    jdata.setArray("ranges", &tickRangesJSON);
    tickMetricsJSON.setObject("data", &jdata);
    
    const char *serialized = tickMetricsJSON.serialize();
    tickMetricsJSONString = serialized;
    lmFree(NULL, (void*)serialized);

    StreamSendAll(server, tickMetricsJSONString.c_str());
}

void Telemetry::beginTick()
{
    tickValues.reset();
    tickRanges.reset();
    TableValues<TickMetricValue>::sequence = 0;
    TableValues<TickMetricRange>::sequence = 0;
    tickTimerStack.clear();

    loom_resetTimer(tickTimer);

    setTickValue("tickId", tickId);
}

void Telemetry::endTick()
{
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
        snprintf(uniqueName, uniqueLen - 1, "%s.%d", name, stored->duplicates+1);
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
    tickRanges.size += strSize + TableValuesTraits<TickMetricRange>::packedItemSize;
    
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
    //lmLog(gTelemetryLogGroup, "end %s", name);

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
        tickValues.size += strSize + TableValuesTraits<TickMetricValue>::packedItemSize;
    }
    else
    {
        metric = *stored;
        metric.value = value;
    }

    return stored;
}
