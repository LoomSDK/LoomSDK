#include "telemetryServer.h"

#include "loom/common/core/telemetry.h"
#include "loom/common/core/log.h"
#include "loom/common/utils/fourcc.h"
#include "loom/common/platform/platformThread.h"

#define LTS_DOCUMENT_ROOT "./www"
#define LTS_PORT "8073"
#define LTS_MAX_CLIENTS 5
#define LTS_TICK_URI "/tick"
#define LTS_STREAM_URI "/stream"
#define LTS_SDK_SUBDIR "/telemetry/www/"

lmDefineLogGroup(gTelemetryServerLogGroup, "lts", true, LoomLogInfo)

// Server might be multithreaded, so lock our data to be sure
static MutexHandle jsonMutex = loom_mutex_create();

// This holds the current tick as serialized json string bytes ready to be sent
utByteArray TelemetryListener::tickMetricsJSONBytes;

mg_callbacks TelemetryServer::callbacks;
mg_context* TelemetryServer::server = NULL;
utString TelemetryServer::clientRoot;

static const char* failJSON = "{ \"status\": \"fail\", \"data\": null }";
static size_t failJSONSize = strlen(failJSON);

// Used to assign clients a unique id
static int clientGlobalID = 0;

// Represents a single connected websockets stream client
struct StreamClient {
    int id;
    struct mg_connection * conn;
    int state;
} static streamClients[LTS_MAX_CLIENTS];

// Called on a new connection
static int StreamConnectHandler(const struct mg_connection * conn, void *cbdata)
{
    struct mg_context *ctx = mg_get_context(conn);
    StreamClient *client = NULL;
    int i;
    
    // Find a free client
    mg_lock_context(ctx);
    for (i = 0; i < LTS_MAX_CLIENTS; i++) {
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
        lmLogWarn(gTelemetryServerLogGroup, "Stream client rejected");
    }
    else
    {
        lmLogDebug(gTelemetryServerLogGroup, "Stream client #%d accepted", client->id);
    }

    return client == NULL ? 1 : 0;
}

// Called when the stream client is connected and ready
void StreamReadyHandler(struct mg_connection * conn, void *cbdata)
{
    struct StreamClient *client = (StreamClient*)mg_get_user_connection_data(conn);

    lmLog(gTelemetryServerLogGroup, "Stream client #%d ready", client->id);

    lmAssert(client->conn == conn, "Websocket connection mismatch");
    lmAssert(client->state == 1, "Websocket invalid state");

    client->state = 2;
}

// Called on new incoming data (this can be much nicer)
int StreamDataHandler(struct mg_connection * conn, int bits, char * data, size_t len, void *cbdata)
{
    struct StreamClient *client = (StreamClient*)mg_get_user_connection_data(conn);

    lmAssert(client->conn == conn, "Websocket connection mismatch");
    lmAssert(client->state >= 1, "Websocket invalid state");

    // For now only a "ping" non-json command is supported
    if (strstr(data, "ping") != NULL) {
        const char* pong = "{ \"status\": \"pong\", \"data\": null }";
        mg_websocket_write(conn, WEBSOCKET_OPCODE_TEXT, pong, strlen(pong));
        return 1;
    }

    // Otherwise it just prints what it got
    fprintf(stdout, "Websocket got data:\r\n");
    fwrite(data, len, 1, stdout);
    fprintf(stdout, "\r\n\r\n");

    return 1;
}

// Called on connection termination marking the client as free
void StreamCloseHandler(const struct mg_connection * conn, void *cbdata)
{
    struct StreamClient *client = (StreamClient*)mg_get_user_connection_data(conn);
    struct mg_context *ctx = mg_get_context(conn);

    lmAssert(client->conn == conn, "Websocket connection mismatch");
    lmAssert(client->state >= 1, "Websocket invalid state");

    lmLog(gTelemetryServerLogGroup, "Stream client #%d dropped", client->id);

    mg_lock_context(ctx);
    client->id = -1;
    client->state = 0;
    client->conn = NULL;
    mg_unlock_context(ctx);
}

// Send the provided message to all connected clients
void StreamSendAll(struct mg_context *ctx, const char *msg, size_t len = -1)
{
    int i;
    mg_lock_context(ctx);
    for (i = 0; i < LTS_MAX_CLIENTS; i++) {
        if (streamClients[i].state == 2) {
            mg_websocket_write(streamClients[i].conn, WEBSOCKET_OPCODE_TEXT, msg, len == -1 ? strlen(msg) : len);
        }
    }
    mg_unlock_context(ctx);
}



// Replies with the provided custom data JSON string (or replies with failure status if the string is empty)
static int JSONStringHandler(struct mg_connection *conn, void *cbdata)
{
    utString* jsonString = (utString*)cbdata;
    const char* buf;
    size_t len;
    lmAssert(jsonString != NULL, "Invalid JSON object provided to the JSON handler");
    loom_mutex_lock(jsonMutex);
    if (!jsonString->empty())
    {
        buf = jsonString->c_str();
        len = jsonString->length();
    }
    else
    {
        buf = failJSON;
        len = failJSONSize;
    }
    mg_printf(conn, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
    mg_write(conn, buf, len);
    loom_mutex_unlock(jsonMutex);
    return 1;
}

// Replies with the provided custom data JSON bytes (or replies with failure status if the bytes are empty)
static int JSONBytesHandler(struct mg_connection *conn, void *cbdata)
{
    utByteArray* jsonBytes = (utByteArray*)cbdata;
    const char* buf;
    size_t len;
    lmAssert(jsonBytes != NULL, "Invalid JSON object provided to the JSON handler");
    loom_mutex_lock(jsonMutex);
    if (jsonBytes->getSize() > 0)
    {
        buf = reinterpret_cast<const char*>(jsonBytes->getDataPtr());
        len = jsonBytes->getSize();
    }
    else
    {
        buf = failJSON;
        len = failJSONSize;
    }
    mg_printf(conn, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
    mg_write(conn, buf, len);
    loom_mutex_unlock(jsonMutex);
    return 1;
}

void TelemetryServer::start()
{
    if (server != NULL) return;

    const char * options[] = {
        "document_root", clientRoot.length() == 0 ? LTS_DOCUMENT_ROOT : clientRoot.c_str(),
        "listening_ports", LTS_PORT,
        0
    };

    memset(&callbacks, 0, sizeof(callbacks));

    server = mg_start(&callbacks, NULL, options);

    // Set /tick as a handler that returns the main JSON string
    mg_set_request_handler(server, LTS_TICK_URI, JSONBytesHandler, &TelemetryListener::tickMetricsJSONBytes);

    // Set /stream as the websocket connection that streams all the ticks
    mg_set_websocket_handler(server, LTS_STREAM_URI, StreamConnectHandler, StreamReadyHandler, StreamDataHandler, StreamCloseHandler, NULL);

    lmLog(gTelemetryServerLogGroup, "Loom Telemetry interface available at http://localhost:%s/", mg_get_option(server, "listening_ports"));
    lmLog(gTelemetryServerLogGroup, "\tServing client from %s", mg_get_option(server, "document_root"));
}

void TelemetryServer::stop()
{
    if (server == NULL) return;

    mg_stop(server);
    server = NULL;

    lmLog(gTelemetryServerLogGroup, "Loom Telemetry shut down");
}

bool TelemetryServer::isRunning()
{
    return server != NULL;
}

void TelemetryServer::sendAll(const char *msg, size_t len)
{
    if (server == NULL) return;

    StreamSendAll(server, msg, len);
}

void TelemetryServer::setClientRootFromSDK(const char *root)
{
    if (root == NULL) return;
    clientRoot = utString(root) + LTS_SDK_SUBDIR;
}

void TelemetryServer::setClientRoot(const char *root)
{
    if (root == NULL) return;
    clientRoot = utString(root);
}

bool TelemetryListener::handleMessage(int fourcc, AssetProtocolHandler *handler, NetworkBuffer& netBuffer)
{
    switch (fourcc)
    {
    case LOOM_FOURCC('T', 'E', 'L', 'E'):

        utByteArray buffer;
        int curPos = netBuffer.getCurrentPosition();

        // Attach with a utByteArray for easier reads and writes
        buffer.attach((char*)netBuffer.buffer + curPos, netBuffer.length - curPos);

        TableValues<TickMetricValue> tickValues;

        loom_mutex_lock(jsonMutex);

        // Read the tick profiler events and roots first
        Telemetry::readTickProfiler(buffer, tickRangesJSON, tickRangeMetaJSON);

        while (buffer.bytesAvailable() > 0)
        {
            // Try reading tables in succession (each table knows how to read itself and returns false if it can't)
            if (tickValues.read(&buffer))
            {
                tickValues.writeJSONObject(&tickValuesJSON);
            }
            else
            {
                lmAssert(false, "Unknown telemetry type: %d", TableValues<TickMetricValue>::readType(&buffer));
            }
        }

        updateMetricsJSON();

        loom_mutex_unlock(jsonMutex);

        // We have detected our telemetry message and can report it as handled
        return true;

        break;
    }

    return false;
}

// Update the main JSON object from the individual parts and serialize it
// as a cached string ready for transmission
void TelemetryListener::updateMetricsJSON()
{
    JSON jdata;

    JSON tickMetricsJSON;
    tickMetricsJSON.initObject();
    tickMetricsJSON.setString("status", "success");

    // Put together metrics data JSON
    jdata.initObject();
    jdata.setObject("values", &tickValuesJSON);
    jdata.setArray("ranges", &tickRangesJSON);
    jdata.setObject("rangeInfo", &tickRangeMetaJSON);
    tickMetricsJSON.setObject("data", &jdata);

    // Write tick metrics JSON to the byte array
    tickMetricsJSONBytes.clear(true);
    tickMetricsJSON.serializeToBuffer(&tickMetricsJSONBytes);
    tickMetricsJSONBytes.resize(tickMetricsJSONBytes.getPosition());

    // Send the newly serialized json to all clients automatically
    TelemetryServer::sendAll(static_cast<const char*>(tickMetricsJSONBytes.getDataPtr()), tickMetricsJSONBytes.getSize());
}
