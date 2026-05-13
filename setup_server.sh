#!/bin/bash

# 1. Cargar variables desde .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo "✅ Archivo .env cargado."
else
    echo "❌ Error: Archivo .env no encontrado. Crea uno basado en .env.example"
    exit 1
fi

# 2. Validación de Password
if [ -z "$KF2_ADMIN_PASSWORD" ]; then
    read -sp "🔑 Introduce la contraseña de Administrador: " KF2_ADMIN_PASSWORD
    echo ""
    export KF2_ADMIN_PASSWORD
fi

# 3. Detección dinámica de IP (Interfaz Bridge enp0s8)
# Intentamos obtener la IP de enp0s8, si no, pedimos input.
if [ -z "$SERVER_IP" ]; then
    DETECTED_IP=$(ip -4 addr show enp0s8 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    if [ ! -z "$DETECTED_IP" ]; then
        SERVER_IP=$DETECTED_IP
        echo "🌐 IP detectada en enp0s8: $SERVER_IP"
    else
        read -p "🌐 No se detectó IP en enp0s8. Introduce la IP de la VM: " SERVER_IP
    fi
fi

# 4. Configuración de Ruteo
GATEWAY_IP=$(ip route show dev enp0s8 | awk '/default/ {print $3}')
if [ ! -z "$GATEWAY_IP" ]; then
    echo "🛤️ Configurando rutas para Gateway: $GATEWAY_IP"
    sudo ip route add default via $GATEWAY_IP dev enp0s8 proto static metric 50 2>/dev/null || \
    sudo ip route change default via $GATEWAY_IP dev enp0s8 proto static metric 50
    sudo ip route change default via 10.0.2.2 dev enp0s3 proto dhcp metric 200
fi

# 5. Desplegar con Docker
echo "🐳 Iniciando contenedores..."
docker compose up -d

# 6. Parche de configuración interna (INI)
echo "🛠️ Aplicando parches a los archivos .ini..."
docker exec -it kf2-server sed -i "s/bEnabled=false/bEnabled=true/g" /data/KFGame/Config/KFWeb.ini
docker exec -it kf2-server sed -i "s/ListenPort=.*/ListenPort=${PORT_WEB}/g" /data/KFGame/Config/KFWeb.ini
docker exec -it kf2-server sed -i "s/AdminPassword=.*/AdminPassword=${KF2_ADMIN_PASSWORD}/g" /data/KFGame/Config/LinuxServer-KFGame.ini

docker compose restart kf2-server

echo "✅ Todo listo."
echo "Servidor: $KF2_SERVER_NAME en http://$SERVER_IP:$PORT_WEB"