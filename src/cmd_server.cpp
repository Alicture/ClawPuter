#include "cmd_server.h"
#include <WiFiServer.h>
#include <WiFiClient.h>
#include <WiFiUdp.h>
#include <ArduinoJson.h>

static WiFiServer tcpServer(CmdServer::CMD_PORT);
static WiFiUDP cmdUdp;

void CmdServer::begin() {
    if (started) return;
    tcpServer.begin();
    tcpServer.setNoDelay(true);
    cmdUdp.begin(CMD_UDP_PORT);
    started = true;
    Serial.printf("[CMD] TCP %d + UDP %d ready\n", CMD_PORT, CMD_UDP_PORT);
}

void CmdServer::tick() {
    if (!started) return;
    tickTCP();
    tickUDP();
}

void CmdServer::tickTCP() {
    WiFiClient client = tcpServer.available();
    if (!client) return;

    // Read one line (JSON command) — non-blocking with timeout
    char buf[BUF_SIZE];
    int len = 0;
    unsigned long deadline = millis() + 2000;  // 2s timeout

    while (client.connected() && millis() < deadline) {
        if (!client.available()) { delay(1); continue; }
        char c = client.read();
        if (c == '\n') break;
        if (len < BUF_SIZE - 1) buf[len++] = c;
    }
    buf[len] = '\0';

    if (len > 0) {
        Serial.printf("[CMD/TCP] Received: %s\n", buf);

        char response[512];
        processCommand(buf, response, sizeof(response));

        client.print(response);
        client.print('\n');
    }

    client.stop();
}

void CmdServer::tickUDP() {
    int packetSize = cmdUdp.parsePacket();
    if (packetSize <= 0) return;

    char buf[BUF_SIZE];
    int len = cmdUdp.read(buf, sizeof(buf) - 1);
    if (len <= 0) return;
    buf[len] = '\0';

    // Strip trailing newline/CR
    while (len > 0 && (buf[len - 1] == '\n' || buf[len - 1] == '\r'))
        buf[--len] = '\0';

    if (len == 0) return;

    Serial.printf("[CMD/UDP] Received: %s\n", buf);

    char response[512];
    processCommand(buf, response, sizeof(response));

    // Send response back to sender
    cmdUdp.beginPacket(cmdUdp.remoteIP(), cmdUdp.remotePort());
    cmdUdp.write((const uint8_t*)response, strlen(response));
    cmdUdp.endPacket();
}

void CmdServer::processCommand(const char* json, char* responseBuf, int responseBufSize) {
    // Default response
    snprintf(responseBuf, responseBufSize, "{\"ok\":true}");

    // Parse JSON using stack-only approach (no JsonDocument in hot path)
    // Simple key extraction for small commands

    // Find "cmd" field
    const char* cmdKey = strstr(json, "\"cmd\":\"");
    if (!cmdKey) {
        snprintf(responseBuf, responseBufSize, "{\"ok\":false,\"error\":\"no cmd\"}");
        return;
    }
    const char* cmdStart = cmdKey + 7;
    const char* cmdEnd = strchr(cmdStart, '"');
    if (!cmdEnd) return;

    int cmdLen = cmdEnd - cmdStart;
    char cmd[16];
    if (cmdLen >= (int)sizeof(cmd)) cmdLen = sizeof(cmd) - 1;
    memcpy(cmd, cmdStart, cmdLen);
    cmd[cmdLen] = '\0';

    if (strcmp(cmd, "animate") == 0) {
        // {"cmd":"animate","state":"happy"}
        const char* stateKey = strstr(json, "\"state\":\"");
        if (stateKey && animateCb) {
            const char* stStart = stateKey + 9;
            const char* stEnd = strchr(stStart, '"');
            if (stEnd) {
                char state[16];
                int stLen = stEnd - stStart;
                if (stLen >= (int)sizeof(state)) stLen = sizeof(state) - 1;
                memcpy(state, stStart, stLen);
                state[stLen] = '\0';
                animateCb(state);
            }
        }
    } else if (strcmp(cmd, "text") == 0 || strcmp(cmd, "say") == 0) {
        // {"cmd":"text","msg":"Hello"} or {"cmd":"say","msg":"Hello"}
        bool autoSend = (strcmp(cmd, "say") == 0);
        const char* msgKey = strstr(json, "\"msg\":\"");
        if (msgKey && textCb) {
            const char* msgStart = msgKey + 7;
            // Find closing quote (handle escaped quotes)
            const char* p = msgStart;
            char msgBuf[128];
            int mi = 0;
            while (*p && *p != '"' && mi < (int)sizeof(msgBuf) - 1) {
                if (*p == '\\' && p[1]) {
                    switch (p[1]) {
                        case '"':  msgBuf[mi++] = '"';  p += 2; break;
                        case '\\': msgBuf[mi++] = '\\'; p += 2; break;
                        case 'n':  msgBuf[mi++] = '\n'; p += 2; break;
                        default:   p += 2; break;
                    }
                } else {
                    msgBuf[mi++] = *p++;
                }
            }
            msgBuf[mi] = '\0';
            textCb(msgBuf, autoSend);
        }
    } else if (strcmp(cmd, "notify") == 0) {
        // {"cmd":"notify","app":"Messages","title":"Mom","body":"Dinner?"}
        if (notifyCb) {
            // Use ArduinoJson for complex notification parsing
            JsonDocument doc;
            if (deserializeJson(doc, json) == DeserializationError::Ok) {
                const char* app = doc["app"] | "";
                const char* title = doc["title"] | "";
                const char* body = doc["body"] | "";
                notifyCb(app, title, body);
            }
        }
    } else if (strcmp(cmd, "history") == 0) {
        // {"cmd":"history"} — return chat history
        if (historyCb) {
            String history = historyCb();
            snprintf(responseBuf, responseBufSize, "%s", history.c_str());
        }
    } else {
        snprintf(responseBuf, responseBufSize, "{\"ok\":false,\"error\":\"unknown cmd\"}");
    }
}
