#pragma once
#include <Arduino.h>

namespace Config {
    // Load saved config from NVS. Returns true if WiFi credentials exist.
    bool load();

    // Save current config to NVS.
    void save();

    // Clear all saved config.
    void reset();

    // Getters
    const String& getSSID();
    const String& getPassword();
    const String& getApiKey();
    const String& getGatewayHost();
    const String& getGatewayPort();
    const String& getGatewayToken();
    const String& getSttHost();
    const String& getSttPort();
    const String& getSSID2();
    const String& getPassword2();
    const String& getGatewayHost2();

    // Setters
    void setSSID(const String& ssid);
    void setPassword(const String& password);
    void setApiKey(const String& key);
    void setGatewayHost(const String& host);
    void setGatewayPort(const String& port);
    void setGatewayToken(const String& token);
    void setSttHost(const String& host);
    void setSttPort(const String& port);
    void setSSID2(const String& ssid);
    void setPassword2(const String& password);
    void setGatewayHost2(const String& host);

    // Check if config is valid (has WiFi credentials)
    bool isValid();
}
