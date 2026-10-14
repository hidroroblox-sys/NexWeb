#!/usr/bin/env bash
# Monta o jogo com o Rojo e envia direto para a sua experiência no Roblox (Open Cloud).
#
# Precisa destas variáveis de ambiente (configure nas variáveis do ambiente, nunca no código):
#   ROBLOX_API_KEY      chave Open Cloud com permissão "universe-places: write" nesta experiência
#   ROBLOX_UNIVERSE_ID  ID da experiência (Creator Hub > ... > Copiar ID do universo)
#   ROBLOX_PLACE_ID     ID do lugar inicial (Creator Hub > ... > Copiar ID do lugar inicial)
#
# Uso:
#   scripts/publish-to-roblox.sh            -> salva uma versão (aparece ao abrir no Studio)
#   scripts/publish-to-roblox.sh Published  -> publica para os jogadores
set -euo pipefail

: "${ROBLOX_API_KEY:?Defina ROBLOX_API_KEY}"
: "${ROBLOX_UNIVERSE_ID:?Defina ROBLOX_UNIVERSE_ID}"
: "${ROBLOX_PLACE_ID:?Defina ROBLOX_PLACE_ID}"

VERSION_TYPE="${1:-Saved}"
if [[ "$VERSION_TYPE" != "Saved" && "$VERSION_TYPE" != "Published" ]]; then
	echo "Use Saved ou Published" >&2
	exit 1
fi

cd "$(dirname "$0")/.."
mkdir -p build
rojo build default.project.json -o build/FujaDoTsunamiPorOvos.rbxl

curl --fail-with-body -sS -X POST \
	"https://apis.roblox.com/universes/v1/${ROBLOX_UNIVERSE_ID}/places/${ROBLOX_PLACE_ID}/versions?versionType=${VERSION_TYPE}" \
	-H "x-api-key: ${ROBLOX_API_KEY}" \
	-H "Content-Type: application/octet-stream" \
	--data-binary @build/FujaDoTsunamiPorOvos.rbxl
echo
echo "Enviado como ${VERSION_TYPE}."
