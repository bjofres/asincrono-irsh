# README: Servidor HTTP en PowerShell para Ejecución Asíncrona de Comandos

## Descripción
Este script en PowerShell implementa un servidor HTTP que permite la ejecución asíncrona de comandos enviados mediante solicitudes HTTP. Fue desarrollado para integrarse con Azure Data Factory y ejecutarse a través de un Integration Runtime self-hosted como `localhost`.

## Características
- **Ejecución de comandos remotos**: Permite ejecutar comandos en segundo plano a través de solicitudes HTTP.
- **Monitoreo del estado de los trabajos**: Se puede consultar el estado de ejecución de los comandos enviados.
- **Respuestas en formato JSON**: Todas las respuestas del servidor se devuelven en formato JSON.

## Endpoints Disponibles

### 1. `/ping/`  
**Descripción:** Endpoint de prueba para verificar si el servidor está en funcionamiento.  
**Método:** `GET`  
**Respuesta Ejemplo:**
```json
{
    "message": "Solicitud recibida correctamente",
    "timestamp": "2025-02-23 12:34:56"
}
```

### 2. `/execute/`  
**Descripción:** Ejecuta un comando en segundo plano.  
**Método:** `POST`  
**Cuerpo de la solicitud:**
```json
{
    "command": "echo Hello World"
}
```
**Respuesta Ejemplo:**
```json
{
    "jobId": "b3f47a27-5b2e-4d7a-b42f-df9b6cb9f07f",
    "status": "Running"
}
```

### 3. `/status/`  
**Descripción:** Consulta el estado de un trabajo en ejecución.  
**Método:** `GET`  
**Parámetro de la URL:** `jobId` (ID del trabajo previamente generado en `/execute/`)  
**Ejemplo de solicitud:**
```
http://localhost:8080/status/?jobId=b3f47a27-5b2e-4d7a-b42f-df9b6cb9f07f
```
**Respuesta Ejemplo:**
```json
{
    "jobId": "b3f47a27-5b2e-4d7a-b42f-df9b6cb9f07f",
    "status": "Completed",
    "output": "Hello World"
}
```

## Requisitos
- PowerShell (versión 5.1 o superior)
- Permisos para ejecutar `Start-Job` y `New-Object System.Net.HttpListener`

## Instalación y Ejecución
1. Guardar el script en un archivo `Start-HttpServer.ps1`
2. Abrir PowerShell con permisos de administrador
3. Ejecutar el script:
   ```powershell
   .\Start-HttpServer.ps1
   ```
4. El servidor comenzará a escuchar en el puerto 8080.

## Notas Adicionales
- Se recomienda ejecutar este script en un servidor confiable, ya que ejecuta comandos de forma remota.
- Asegurar que el puerto `8080` esté abierto en el firewall.
- Revisar `Get-Job` y `Receive-Job` para gestionar trabajos en segundo plano.
- Los trabajos completados se eliminan después de recuperar su salida para evitar saturación de memoria.

## Seguridad
- **Evita comandos peligrosos**: Filtrar comandos antes de ejecutarlos puede ayudar a prevenir ejecuciones no deseadas.
- **Restringir accesos**: Se recomienda restringir accesos a la red y evitar exponer el puerto de manera pública.
- **Logs**: Agregar un sistema de logs para registrar ejecuciones y posibles errores.

---
**Autor:** Bastián Jofré  
**Fecha:** Septiembre 2024
