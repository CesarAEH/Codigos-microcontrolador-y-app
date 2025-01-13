/*
 * Este código utiliza dependencias bajo las siguientes licencias de código abierto:
 * 
 * - Licencia MIT (WiFi, HTTPClient): Permite el uso, modificación y distribución con restricciones mínimas.
 * - Licencia BSD (Wire): Permite el uso, modificación y distribución, siempre que se mantenga la licencia original.
 * - Licencia Apache 2.0 (Adafruit_Sensor): Permite el uso, distribución y modificación con ciertas condiciones como la atribución.
 * - Licencia SparkFun para VL53L5CX y BME280: Permite el uso para proyectos educativos y personales con atribución.
 * 
 * Por favor, consulta los términos específicos de cada licencia para más detalles:
 * - WiFi, HTTPClient: https://github.com/espressif/arduino-esp32/blob/master/LICENSE
 * - Wire: https://github.com/arduino/ArduinoCore-avr/blob/master/LICENSE
 * - Adafruit_Sensor: https://github.com/adafruit/Adafruit_Sensor/blob/master/LICENSE
 * - SparkFun VL53L5CX: https://github.com/sparkfun/SparkFun_VL53L5CX_Arduino_Library/blob/main/LICENSE.md
 * - SparkFun BME280: https://github.com/sparkfun/SparkFun_BME280_Arduino_Library/blob/main/LICENSE.md
 * 
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <SparkFun_VL53L5CX_Library.h>
#include "SparkFunBME280.h"
#include <WebServer.h>
#include <DNSServer.h>
#include <Preferences.h>  

// Configuración del servidor web y DNS
const byte DNS_PORT = 53;
DNSServer dnsServer;
WebServer server(80);  // Servidor web en el puerto 80

Preferences preferences;  // Instancia para manejo de memoria no volátil

// Variables de configuración WiFi
String ssid = "";
String password = "";

// Variables para Firebase
const char* firebaseUrl = "https://esp32v1-c5c01-default-rtdb.firebaseio.com/sensors.json";
const char* environmentDataUrl = "https://esp32v1-c5c01-default-rtdb.firebaseio.com/TempyHum.json";

// Sensores
BME280 mySensor;
SparkFun_VL53L5CX myImager;
VL53L5CX_ResultsData measurementData;

// Declaración de funciones 
void sendSensorDataToFirebase();
void sendEnvironmentDataToFirebase();
void initializeSensors();
void startAPMode();
void connectToWiFi();

// Función para mostrar el formulario HTML
void handleRoot() {
  String html = "<html>\
    <body>\
    <h1>Configuración WiFi ESP32</h1>\
    <form action='/wifi' method='POST'>\
      <label for='ssid'>SSID del WiFi:</label><br>\
      <input type='text' id='ssid' name='ssid'><br><br>\
      <label for='password'>Password:</label><br>\
      <input type='password' id='password' name='password'><br><br>\
      <input type='submit' value='Enviar'>\
    </form>\
    <p>Si no aparece, acceda manualmente a 192.168.4.1 en su navegador.</p>\
    </body>\
    </html>";
  server.send(200, "text/html", html);
}

// Función para manejar la configuración del WiFi
void handleWifiConfig() {
  ssid = server.arg("ssid");
  password = server.arg("password");

  Serial.println("Recibido:");
  Serial.println("SSID: " + ssid);
  Serial.println("Password: " + password);

  // Guardar el SSID y la contraseña en la memoria no volátil
  preferences.begin("wifi-config", false);
  preferences.putString("ssid", ssid);
  preferences.putString("password", password);
  preferences.end();

  WiFi.begin(ssid.c_str(), password.c_str());

  int timeout = 30; // 30 segundos para intentar conectarse
  while (WiFi.status() != WL_CONNECTED && timeout > 0) {
    delay(1000);
    timeout--;
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nConectado al WiFi");
    Serial.println("Dirección IP: ");
    Serial.println(WiFi.localIP());
    server.send(200, "text/html", "Conexión exitosa. IP: " + WiFi.localIP().toString());
    WiFi.softAPdisconnect(true); // Apagar el AP una vez conectado a la red WiFi
    initializeSensors();  // Inicializar los sensores después de la conexión WiFi
  } else {
    Serial.println("\nNo se pudo conectar al WiFi");
    server.send(200, "text/html", "Error al conectar al WiFi.");
  }
}

// Función para redirigir las peticiones no encontradas a la IP del AP
void handleNotFound() {
  server.sendHeader("Location", "http://192.168.4.1", true);  // Redirigir a la IP del AP
  server.send(302, "text/plain", "");
}

void initializeSensors() {
  Wire.begin(); // Iniciar I2C
  Wire.setClock(400000); 

  // Inicializar el sensor VL53L5CX
  if (!myImager.begin()) {
    Serial.println("Sensor VL53L5CX no encontrado - revisa la conexión.");
    while (1);
  }

 
  myImager.setResolution(4 * 4);             // Reducir resolución a 4x4
  myImager.setIntegrationTime(100);          
  myImager.setRangingFrequency(5);           
  myImager.startRanging();

  // Inicializar el sensor BME280
  if (!mySensor.beginI2C()) {
    Serial.println("El sensor BME280 no respondió. Revisa la conexión.");
    while (1);
  }
}


void setup() {
  Serial.begin(115200);

  // Recuperar SSID y contraseña guardados
  preferences.begin("wifi-config", true);
  ssid = preferences.getString("ssid", "");
  password = preferences.getString("password", "");
  preferences.end();

  if (ssid != "" && password != "") {
    // Intentar conectarse a la red WiFi almacenada
    connectToWiFi();
  } else {
    // No hay configuración previa, iniciar en modo AP
    startAPMode();
  }
}




void loop() {
  dnsServer.processNextRequest();
  server.handleClient();

  // Verificar si está conectado a WiFi
  if (WiFi.status() == WL_CONNECTED) {
    // Leer datos del sensor láser VL53L5CX
    if (myImager.isDataReady()) {
      Serial.println("Datos del sensor VL53L5CX listos para enviar.");
      if (myImager.getRangingData(&measurementData)) {
        // Filtrar datos inconsistentes
        for (int i = 0; i < 16; i++) {
          if (measurementData.distance_mm[i] < 30 || measurementData.distance_mm[i] > 4000) {
            measurementData.distance_mm[i] = 0; // Ignorar datos fuera de rango
          }
        }
        sendSensorDataToFirebase(); // Enviar datos del sensor VL53L5CX
      } else {
        Serial.println("Error al obtener datos del sensor VL53L5CX.");
      }
    } else {
      Serial.println("Datos del sensor VL53L5CX no listos.");
    }

    // Leer datos del sensor BME280
    sendEnvironmentDataToFirebase(); // Enviar datos del sensor BME280

   
    delay(5000);
  }
}



// Conectar al WiFi usando las credenciales almacenadas
void connectToWiFi() {
  Serial.println("Intentando conectar a la red WiFi guardada...");
  WiFi.begin(ssid.c_str(), password.c_str());

  int timeout = 30; // 30 segundos para intentar conectarse
  while (WiFi.status() != WL_CONNECTED && timeout > 0) {
    delay(1000);
    timeout--;
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nConectado al WiFi");
    Serial.println("Dirección IP: ");
    Serial.println(WiFi.localIP());
    initializeSensors();  // Inicializar los sensores después de la conexión WiFi
  } else {
    Serial.println("\nNo se pudo conectar a la red guardada. Iniciando modo AP.");
    startAPMode();  // Iniciar modo AP si falla la conexión
  }
}

// Iniciar en modo AP para configuración
void startAPMode() {
  WiFi.softAP("ESP32_WIFI", "12345678");

  Serial.println("Punto de acceso iniciado");
  Serial.println("Dirección IP del AP: ");
  Serial.println(WiFi.softAPIP());

  // Iniciar el DNS Server para redirigir todo al ESP32
  dnsServer.start(DNS_PORT, "*", WiFi.softAPIP());

  // Configurar las rutas del servidor web
  server.on("/", handleRoot);
  server.on("/wifi", HTTP_POST, handleWifiConfig);
  server.onNotFound(handleNotFound);

  server.begin();
  Serial.println("Servidor web iniciado");
}
//Manda datos del sensor distancia a firebase
void sendSensorDataToFirebase() {
  HTTPClient http;
  http.begin(firebaseUrl);
  http.addHeader("Content-Type", "application/json");

  String jsonData = "{";
  for (int i = 0; i < 16; i++) {
    // Filtrar valores fuera del rango típico 
    int distance = measurementData.distance_mm[i];
    if (distance < 5 || distance > 4000) {
      distance = 0; // Ignorar datos fuera de rango
    }
    jsonData += "\"distance" + String(i) + "\":" + String(distance);
    if (i < 15) jsonData += ", ";
  }
  jsonData += "}";

  int httpResponseCode = http.PUT(jsonData);
  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.println(response);
  } else {
    Serial.println("Error al enviar datos: " + http.errorToString(httpResponseCode));
  }
  http.end();
}


// Definición de la función para enviar datos del sensor BME280 a Firebase
void sendEnvironmentDataToFirebase() {
  HTTPClient http;
  http.begin(environmentDataUrl);
  http.addHeader("Content-Type", "application/json");

  float humidity = mySensor.readFloatHumidity();
  float temperature = mySensor.readTempC();

  String jsonData = "{";
  jsonData += "\"humidity\": " + String(humidity);
  jsonData += ", \"temperature\": " + String(temperature);
  jsonData += "}";

  Serial.println("Enviando datos de ambiente a Firebase: ");
  Serial.println(jsonData);

  int httpResponseCode = http.PUT(jsonData);
  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.println("Código de respuesta HTTP: " + String(httpResponseCode));
    Serial.println("Respuesta: " + response);
  } else {
    Serial.println("Error al enviar la solicitud PUT: " + String(httpResponseCode));
    Serial.println(http.errorToString(httpResponseCode));
  }
  http.end();
}