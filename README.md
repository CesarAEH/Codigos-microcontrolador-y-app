# Contenidos del repositorio
Para la realización del proyecto se usaron codigos para el microcontrolador y para el desarrollo de la aplicación, acontinuación una breve descripción de lo que encontrará en cada carpeta.

## Descripción codigo microcontrolador

El archivo codigoesp.ino, que se encuentra en la carpeta llamada microcontrolador, está diseñado para recopilar datos de sensores (distancia, temperatura y humedad), enviarlos a Firebase, y permitir una configuración flexible de la red WiFi mediante una interfaz web. Este código realiza las siguientes funciones principales:

1 . **Configuración de WiFi con Modo AP y Memoria Persistente**:

El ESP32 inicia en modo de punto de acceso (AP) si no encuentra credenciales WiFi guardadas, permitiendo configurar la red a través de una interfaz web.
Las credenciales ingresadas son almacenadas en memoria no volátil (Preferences) para conectarse automáticamente en el futuro.

2. **Lectura de Sensores**:
   
Utiliza un sensor láser VL53L5CX para medir distancias en una matriz de 4x4.
Utiliza un sensor BME280 para medir la temperatura y la humedad ambiental.

3. **Envío de Datos a Firebase**:
   
Los datos del sensor láser se envían a una base de datos Firebase en formato JSON, filtrando valores fuera de rango.
Los datos de temperatura y humedad también se envían a otra ubicación en Firebase.

4. **Servidor Web Local**:
   
Un servidor web local en el puerto 80 permite a los usuarios configurar las credenciales WiFi a través de un formulario HTML.
Maneja redirecciones y solicitudes HTTP para la configuración del WiFi.

5. **Flujo Principal**:
   
En el bucle principal (loop), verifica si el ESP32 está conectado a WiFi:
Si está conectado, obtiene datos de los sensores y los envía a Firebase.
Si no está conectado, permanece en modo AP para configuración.
