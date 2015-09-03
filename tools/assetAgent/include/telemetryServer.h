#ifndef _ASSETS_TELEMETRYSERVER_H_
#define _ASSETS_TELEMETRYSERVER_H_

#include "loom/vendor/civetweb/include/civetweb.h"
#include "loom/common/utils/json.h"
#include "loom/common/assets/assetProtocol.h"

class TelemetryListener : public AssetProtocolMessageListener
{
public:
    virtual bool handleMessage(int fourcc, AssetProtocolHandler *handler, NetworkBuffer& buffer);

    JSON tickValuesJSON;
    JSON tickRangesJSON;
    JSON tickMetricsJSON;

    static utString tickMetricsJSONString;

    void updateMetricsJSON();
};

class TelemetryServer
{
    static struct mg_callbacks callbacks;
    static struct mg_context *server;

    static utString clientRoot;

public:
    static void setClientRootFromSDK(const char *root);
    static void setClientRoot(const char *root);

    static void start();
    static void stop();
    static bool isRunning();

    static void fileChanged(const char* path);

    static void sendAll(const char* msg);

};


#endif