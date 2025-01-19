#!/bin/bash

set -e

APP_DIR="./go-rest-api-nebo"
DOCKER_DIR="./go-rest-api-nebo/cmd/server/Dockerfile"

# Versión inicial (puedes ajustar esto según sea necesario)
MAJOR=1
MINOR=0
PATCH=0

# Paso 1: Obtener commits relevantes
echo "Buscando commits relevantes en la carpeta $APP_DIR..."
COMMITS=$(git log --oneline -- $APP_DIR)
if [ -z "$COMMITS" ]; then
    echo "No se encontraron commits relevantes en $APP_DIR."
    exit 1
fi

# Paso 2: Analizar los commits y calcular la versión
declare -A VERSIONS_MAP
CURRENT_VERSION="$MAJOR.$MINOR.$PATCH"

while read -r COMMIT; do
    HASH=$(echo "$COMMIT" | awk '{print $1}')
    MESSAGE=$(echo "$COMMIT" | cut -d' ' -f2-)

    # Determinar el tipo de commit
    if echo "$MESSAGE" | grep -q '^feat:'; then
        MINOR=$((MINOR + 1))
        PATCH=0
    elif echo "$MESSAGE" | grep -q '^fix:'; then
        PATCH=$((PATCH + 1))
    elif echo "$MESSAGE" | grep -q 'BREAKING CHANGE'; then
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
    else
        continue
    fi

    # Generar la nueva versión
    CURRENT_VERSION="$MAJOR.$MINOR.$PATCH"
    VERSIONS_MAP["$CURRENT_VERSION"]="$HASH $MESSAGE"
done <<< "$COMMITS"

DOCKER_PASSWORD="asdfsfsdf"
DOCKER_USERNAME="lkhjklhjlhjl"
DOCKER_REPO="$DOCKER_USERNAME/test"
OVERVIEW_FILE="./go-rest-api-nebo/cmd/server/README.md"

# Paso 3: Subir versiones no existentes a Docker Hub
echo "Autenticando en Docker Hub..."
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

for VERSION in "${!VERSIONS_MAP[@]}"; do
    HASH_AND_MESSAGE="${VERSIONS_MAP[$VERSION]}"
    HASH=$(echo "$HASH_AND_MESSAGE" | awk '{print $1}')
    MESSAGE=$(echo "$HASH_AND_MESSAGE" | cut -d' ' -f2-)

    # Verificar si la imagen ya existe en Docker Hub
    if docker manifest inspect "$DOCKER_REPO:$VERSION" >/dev/null 2>&1; then
        echo "La versión $VERSION ya existe en Docker Hub. Omitiendo..."
        continue
    fi

    echo "Creando y subiendo la imagen para la versión $VERSION..."

    # Construir la imagen
    docker build -t "$DOCKER_REPO:$VERSION" -f "$DOCKER_DIR" "$APP_DIR"

    # Etiquetar la imagen con el hash del commit
    docker tag "$DOCKER_REPO:$VERSION" "$DOCKER_REPO:commit-$HASH"

    # Subir la imagen a Docker Hub
    docker push "$DOCKER_REPO:$VERSION"

    # Este README.md file can be use to change the overview of the docker hub repository if build is activated
    echo "Actualizando el archivo $OVERVIEW_FILE..."
        {
            echo "## Versión $VERSION"
            echo "- $HASH_AND_MESSAGE"
            echo "- *Fecha*: $(date)"
            echo ""
        } | cat - $OVERVIEW_FILE > temp && mv temp $OVERVIEW_FILE

done

echo "Todas las versiones han sido procesadas."