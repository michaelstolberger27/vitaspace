#include "DHT.h"
#include "Air_Quality_Sensor.h"

#include <WiFi.h>
#include <FirebaseClient.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <WebServer.h>

#define DHTTYPE DHT11
#define DHTPIN 4
#define DUSTPIN 6
#define QUALITYPIN 7

unsigned long duration;
unsigned long starttime;
unsigned long sampletime_ms = 30000; // Sample 30s
unsigned long lowpulseoccupancy = 0;
float ratio = 0;
float concentration = 0;

bool isConnected = false;

const char *service_prefix = "VitaSpace_";
char service_name[32];
const char *service_key = NULL;
WebServer server(80);

#define API_KEY "AIzaSyDcrfrDk7JJClDSk4RiP02MXgWBBc_GJjI"
#define DATABASE_URL "https://vitaspace-a88ea-default-rtdb.europe-west1.firebasedatabase.app"

WiFiClientSecure ssl1, ssl2;
DefaultNetwork network;
AsyncClientClass client1(ssl1, getNetwork(network)), client2(ssl2, getNetwork(network));
FirebaseApp app;
RealtimeDatabase Database;
AsyncResult result1, result2, result3;
NoAuth noAuth;
unsigned long ms = 0;

DHT dht11(DHTPIN, DHTTYPE);
AirQualitySensor airQualitySensor(QUALITYPIN);

void handleRoot()
{
    server.send(200, "text/plain", "ESP32 Wi-Fi Provisioning Server");
}

void handleCredentials()
{
    if (server.hasArg("ssid") && server.hasArg("password"))
    {
        String newSSID = server.arg("ssid");
        String newPassword = server.arg("password");

        Serial.print("Received Wi-Fi credentials: SSID=");
        Serial.print(newSSID);
        Serial.print(", Password=");
        Serial.println(newPassword);

        server.send(200, "text/plain", "Received Wi-Fi credentials. Connecting...");
        delay(2000);

        WiFi.softAPdisconnect(true);
        WiFi.mode(WIFI_STA);
        WiFi.begin(newSSID.c_str(), newPassword.c_str());

        Serial.print("Connecting to ");
        Serial.println(newSSID);

        int attempts = 0;
        while (WiFi.status() != WL_CONNECTED && attempts < 20)
        {
            delay(1000);
            Serial.print(".");
            attempts++;
        }

        if (WiFi.status() == WL_CONNECTED)
        {
            Serial.println("\nWi-Fi Connected!");
            Serial.print("ESP32 IP Address: ");
            Serial.println(WiFi.localIP());
            isConnected = true;
            postSetup();
        }
        else
        {
            Serial.println("\nFailed to connect! Restarting SoftAP...");
            setupSoftAP();
        }
    }
    else
    {
        server.send(400, "text/plain", "Missing SSID or Password");
    }
}

void setupSoftAP()
{
    WiFi.mode(WIFI_AP);
    uint32_t chipId = ESP.getEfuseMac() & 0xFFFFFF;
    snprintf(service_name, sizeof(service_name), "%s%06X", service_prefix, chipId);

    bool apStarted = WiFi.softAP(service_name, service_key);
    if (apStarted)
    {
        Serial.print("ESP32 SoftAP Name: ");
        Serial.println(service_name);
        Serial.print("ESP32 SoftAP IP: ");
        Serial.println(WiFi.softAPIP());
    }
    else
    {
        Serial.println("SoftAP failed to start!");
    }

    server.on("/", handleRoot);
    server.on("/prov", handleCredentials);
    server.begin();
}

void postSetup()
{
    Firebase.printf("Firebase Client v%s\n", FIREBASE_CLIENT_VERSION);

    ssl1.setInsecure();
    ssl2.setInsecure();
    initializeApp(client1, app, getAuth(noAuth));
    app.getApp<RealtimeDatabase>(Database);
    Database.url(DATABASE_URL);
    Database.get(client1, "/test/stream", result1, true);
    Firebase.printf("Database initialised");
}

void setup()
{
    Serial.begin(9600);
    Serial.println(F("Setting up ESP32 SoftAP"));
    setupSoftAP();
    dht11.begin();
    pinMode(DUSTPIN, INPUT);
    starttime = millis();
    airQualitySensor.init();
}

void loop()
{
    server.handleClient();

    if (isConnected)
    {
        Database.loop();
        float relHumidity = dht11.readHumidity();
        float tempDegC = dht11.readTemperature();
        duration = pulseIn(DUSTPIN, LOW);
        lowpulseoccupancy += duration;
        if ((millis() - starttime) > sampletime_ms)
        {
            ratio = lowpulseoccupancy / (sampletime_ms * 10.0);
            concentration = 1.1 * pow(ratio, 3) - 3.8 * pow(ratio, 2) + 520 * ratio + 0.62;
            lowpulseoccupancy = 0;
            starttime = millis();
        }

        if (millis() - ms > 20000 || ms == 0)
        {
            JsonWriter writer;
            object_t json, obj1, obj2, obj3, obj4;
            writer.create(obj1, "timestamp", millis());
            writer.create(obj2, "humidity", relHumidity);
            writer.create(obj3, "temperature", tempDegC);
            writer.create(obj4, "dust_concentration", concentration);
            object_t jsonPackage;
            writer.join(jsonPackage, 4, obj1, obj2, obj3, obj4);
            Database.push<object_t>(client2, "/sensor_data", jsonPackage, result2);
            Serial.println("Firebase data push attempt...");
            ms = millis();
        }
    }
}
