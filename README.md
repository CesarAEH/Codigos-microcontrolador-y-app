# Contenidos del repositorio
Para la realización del proyecto se usaron codigos para el microcontrolador y para el desarrollo de la aplicación, acontinuación una breve descripción de lo que encontrará en cada carpeta.
## Features

1. **WiFi Configuration**:
   - Starts in AP mode if no WiFi credentials are stored.
   - Web interface allows users to configure WiFi credentials.
   - Credentials are saved in non-volatile memory for future use.

2. **Sensor Integration**:
   - **VL53L5CX**: Measures distances in a 4x4 grid (16 values).
   - **BME280**: Measures temperature and humidity.

3. **Data Upload to Firebase**:
   - Distance data is sent to Firebase in JSON format.
   - Temperature and humidity data are sent to a separate Firebase endpoint.

4. **Local Web Server**:
   - Provides a web interface for WiFi configuration.
   - Handles redirection and HTTP requests.

5. **DNS Redirection**:
   - Redirects all requests to the ESP32's web server during AP mode.

## How It Works
