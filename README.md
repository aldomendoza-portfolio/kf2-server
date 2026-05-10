# 🧟 Killing Floor 2 Containerized Server (Multipass + Docker)

Este proyecto automatiza el despliegue de un servidor dedicado de Killing Floor 2 en un entorno de microservicios. Está diseñado para correr sobre una VM de Multipass configurada en modo Bridge, permitiendo visibilidad directa en la red local y acceso externo a través de una IP pública.

---

## 🏗️ Arquitectura de Red
El despliegue utiliza una configuración de doble interfaz para balancear la gestión interna de Multipass y el tráfico de alto rendimiento del juego.

- enp0s3 (NAT): Gestión interna de la VM.
- enp0s8 (Bridge): Tráfico de producción y acceso externo (IP fija en red local).
- Storage: Volúmenes de Docker persistentes para preservar mapas, configuraciones y progreso de perks.

---

## 🚀 Instalación Rápida

1. Clonar y Preparar el Entorno

Primero, prepara tu archivo de configuración sensible:

``` Bash
git clone https://github.com/aldomendoza-portfolio/kf2-server.git
cd kf2-server
cp .env.example .env
```
2. Configurar Variables

Edita el archivo .env con tus credenciales y preferencias. No compartas este archivo.

```
KF2_SERVER_NAME=Aldo-KF2-Server
KF2_ADMIN_PASSWORD=TuPasswordSeguro
KF2_MAP=KF-BioticsLab
SERVER_IP=192.168.1.81  # IP de la VM en modo Bridge
```
3. Ejecutar el Script

Este script `setup_server.sh` se encarga de todo: 

- Corregir el ruteo asimétrico del kernel de Linux.
- Levantar el stack de Docker Compose.
- Inyectar parches de configuración en los archivos .ini del motor Unreal.

``` Bash
chmod +x setup_server.sh
./setup_server.sh
```

## 🌐 Configuración del Router (Port Forwarding)

Para que los jugadores puedan unirse desde internet, asegúrate de tener estas reglas en tu router (IP Destino: `192.168.1.81`):

| Puerto | Protocolo | Descripción |
|--------|-----------|-------------|
| 7777 | UDP | Tráfico del juego |
| 27015 | UDP | Query Port (Steam Browser) |
| 20660 | UDP | Master Server Communication |
| 8080 | TCP | Web Admin Interface |

## 🛠️ Administración y Mantenimiento

### Acceso al Portal Web

El WebAdmin permite cambiar mapas, dificultad y expulsar jugadores en tiempo real.

- URL: http://[IP_ADDRESS]
- Usuario: admin
- Contraseña: La que definiste en `KF2_ADMIN_PASSWORD` en el `.env`.

### Comandos Útiles

- Actualiza el servidor: `docker compose pull && docker compose up -d`
- Reinicia el servidor: `docker compose restart kf2-server`
- Ver Logs: `docker logs -f kf2-server`
- Entrar a la Shell: `docker exec -it kf2-server bash`

--- 

# ⚠️ Troubleshooting (Lecciones Aprendidas)

1. Ruteo Asimétrico: Si el servidor responde localmente pero no externamente, verifica que la ruta por defecto (`default gateway`) apunte a la interfaz Bridge (`enp0s8`). El script de setup maneja esto automáticamente.

2. WebAdmin Port: El motor del juego a veces intenta usar el puerto `80`. El script fuerza el puerto `8080` en el archivo `KFWeb.ini`.

3. Persistencia: Todos los archivos de configuración residen en el volumen `kf2_data`. Para resetear el servidor a estado de fábrica, elimina el volumen: `docker volume rm kf2-server_kf2_data`.

---

# 📝 Licencia

Este proyecto es de uso personal y educativo. Killing Floor 2 es propiedad de Tripwire Interactive.