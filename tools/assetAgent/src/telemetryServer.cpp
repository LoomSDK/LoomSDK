#include "telemetryServer.h"

#include "loom/common/core/telemetry.h"
#include "loom/common/utils/fourcc.h"
#include "loom/common/platform/platformThread.h"

#define LTS_DOCUMENT_ROOT "./www"
#define LTS_PORT "8073"
#define LTS_MAX_CLIENTS 5
#define LTS_TICK_URI "/tick"
#define LTS_STREAM_URI "/stream"
#define LTS_SDK_SUBDIR "/telemetry/www/"

lmDefineLogGroup(gTelemetryServerLogGroup, "lts", true, LoomLogInfo)

static MutexHandle jsonMutex = loom_mutex_create();
static int clientGlobalID = 0;


utString TelemetryListener::tickMetricsJSONString;

mg_callbacks TelemetryServer::callbacks;
mg_context* TelemetryServer::server = NULL;
utString TelemetryServer::clientRoot;



struct StreamClient {
    int id;
    struct mg_connection * conn;
    int state;
} static streamClients[LTS_MAX_CLIENTS];



static int StreamConnectHandler(const struct mg_connection * conn, void *cbdata)
{
    struct mg_context *ctx = mg_get_context(conn);
    StreamClient *client = NULL;
    int i;

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
        lmLog(gTelemetryServerLogGroup, "Stream client rejected");
    }
    else
    {
        lmLog(gTelemetryServerLogGroup, "Stream client #%d accepted", client->id);
    }

    return client == NULL ? 1 : 0;
}

void StreamReadyHandler(struct mg_connection * conn, void *cbdata)
{
    struct StreamClient *client = (StreamClient*)mg_get_user_connection_data(conn);

    lmLog(gTelemetryServerLogGroup, "Stream client #%d ready", client->id);

    lmAssert(client->conn == conn, "Websocket connection mismatch");
    lmAssert(client->state == 1, "Websocket invalid state");

    client->state = 2;
}

int StreamDataHandler(struct mg_connection * conn, int bits, char * data, size_t len, void *cbdata)
{
    struct StreamClient *client = (StreamClient*)mg_get_user_connection_data(conn);

    lmAssert(client->conn == conn, "Websocket connection mismatch");
    lmAssert(client->state >= 1, "Websocket invalid state");

    if (strcmp(data, "ping") != 0) {
        const char* pong = "{ \"status\": \"pong\", \"data\": null }";
        mg_websocket_write(conn, WEBSOCKET_OPCODE_TEXT, pong, strlen(pong));
        return 1;
    }

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

    lmLog(gTelemetryServerLogGroup, "Stream client #%d dropped", client->id);

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
    for (i = 0; i < LTS_MAX_CLIENTS; i++) {
        if (streamClients[i].state == 2) {
            mg_websocket_write(streamClients[i].conn, WEBSOCKET_OPCODE_TEXT, msg, strlen(msg));
        }
    }
    mg_unlock_context(ctx);
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

    mg_set_request_handler(server, LTS_TICK_URI, JSONStringHandler, &TelemetryListener::tickMetricsJSONString);
    mg_set_websocket_handler(server, LTS_STREAM_URI, StreamConnectHandler, StreamReadyHandler, StreamDataHandler, StreamCloseHandler, NULL);

    lmLog(gTelemetryServerLogGroup, "Loom Telemetry server listening on port %s", mg_get_option(server, "listening_ports"));
    lmLog(gTelemetryServerLogGroup, "\tServing client from %s", mg_get_option(server, "document_root"));
}

void TelemetryServer::stop()
{
    if (server == NULL) return;

    mg_stop(server);
    server = NULL;

    lmLog(gTelemetryServerLogGroup, "Loom Telemetry server shut down");
}

bool TelemetryServer::isRunning()
{
    return server != NULL;
}

void TelemetryServer::sendAll(const char *msg)
{
    if (server == NULL) return;

    StreamSendAll(server, msg);
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
        buffer.attach((char*)netBuffer.buffer + curPos, netBuffer.length - curPos);

        TableValues<TickMetricValue> tickValues;
        TableValues<TickMetricRange> tickRanges;

        loom_mutex_lock(jsonMutex);

        while (buffer.bytesAvailable() > 0)
        {
            if (tickValues.read(&buffer))
            {
                tickValues.writeJSONObject(&tickValuesJSON);
            }
            else if (tickRanges.read(&buffer))
            {
                tickRanges.writeJSONArray(&tickRangesJSON);
            }
            else
            {
                lmAssert(false, "Unknown telemetry type: %d", TableValues<TickMetricValue>::readType(&buffer));
            }
        }

        updateMetricsJSON();

        loom_mutex_unlock(jsonMutex);


        return true;

        break;
    }

    return false;
}

void TelemetryListener::updateMetricsJSON()
{
    JSON jdata;

    tickMetricsJSON.initObject();
    tickMetricsJSON.setString("status", "success");

    jdata.initObject();
    jdata.setObject("values", &tickValuesJSON);
    jdata.setArray("ranges", &tickRangesJSON);
    tickMetricsJSON.setObject("data", &jdata);

    const char *serialized = tickMetricsJSON.serialize();
    tickMetricsJSONString = serialized;
    lmFree(NULL, (void*)serialized);

    TelemetryServer::sendAll(tickMetricsJSONString.c_str());
}

void TelemetryServer::fileChanged(const char* path)
{
    lmLog(gTelemetryServerLogGroup, "File changed: %s", path);
}
