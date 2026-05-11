#!/bin/bash


# 1. Cargar variables desde .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo "✅ Archivo .env cargado."
else
    echo "❌ Error: Archivo .env no encontrado. Crea uno basado en .env.example"
    exit 1
fi

# 2. Validar variables mínimas
if [ -z "$API_KEY" ] || [ -z "$STEAM_ID" ] || [ -z "$APP_ID" ]; then
    echo "❌ Error: API_KEY, STEAM_ID o APP_ID no están definidos en el .env"
    exit 1
fi

echo "🔍 Buscando logros pendientes para KF2..."

# 1. Obtenemos el esquema de nombres (Cacheamos para no saturar la API)
curl -s "https://api.steampowered.com/ISteamUserStats/GetSchemaForGame/v0002/?key=${API_KEY}&appid=${APP_ID}&l=spanish" > schema.json

# 2. Obtenemos tus logros
curl -s "https://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/?appid=${APP_ID}&key=${API_KEY}&steamid=${STEAM_ID}" > player.json

# 3. Cruzamos datos con jq
jq -r --slurpfile schema schema.json '
  .playerstats.achievements[] 
  | select(.achieved == 0) 
  | .apiname as $id 
  | $schema[0].game.availableGameStats.achievements[] 
  | select(.name == $id) 
  | "- \(.displayName): \(.description)"
' player.json | sort