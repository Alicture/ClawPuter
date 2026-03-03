#include "state_broadcast.h"
#include <WiFiUdp.h>
#include <ArduinoJson.h>
#include "utils.h"

static WiFiUDP udp;
static Timer broadcastTimer{200}; // 5Hz

static constexpr uint16_t BROADCAST_PORT = 19820;

void stateBroadcastBegin() {
    udp.begin(BROADCAST_PORT);
}

void stateBroadcastTick(int state, int frame, const char* mode) {
    if (!broadcastTimer.tick()) return;

    JsonDocument doc;
    doc["s"] = state;
    doc["f"] = frame;
    doc["m"] = mode;

    char buf[64];
    size_t len = serializeJson(doc, buf, sizeof(buf));

    udp.beginPacket("255.255.255.255", BROADCAST_PORT);
    udp.write((const uint8_t*)buf, len);
    udp.endPacket();
}
