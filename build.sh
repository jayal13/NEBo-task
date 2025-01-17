#!/bin/bash

set -e

# Crear un directorio temporal
TEMP_DIR=$(mktemp -d)

echo "Creando carpeta temporal: $TEMP_DIR"

# Instalar las dependencias en la carpeta temporal
echo "Instalando las dependencias en la carpeta temporal"
npm install --prefix $TEMP_DIR semantic-release @semantic-release/commit-analyzer @semantic-release/release-notes-generator @semantic-release/changelog @semantic-release/git

# Generar una nueva versión con Semantic Release
echo "Generando nueva versión..."
VERSION=$($TEMP_DIR/node_modules/.bin/semantic-release --dry-run --branches=main \
  --plugins=@semantic-release/commit-analyzer,@semantic-release/release-notes-generator,@semantic-release/changelog,@semantic-release/git \
  | grep 'next release version' | awk '{print $5}')
echo $VERSION
if [ -z "$VERSION" ]; then
    echo "Error: No se pudo generar la versión."
    rm -rf $TEMP_DIR
    exit 1
fi
echo "Nueva versión: $VERSION"

# Construir la imagen Docker usando el Dockerfile existente
echo "Construyendo imagen Docker..."
docker build -t go-rest-api:$VERSION .

# Etiquetar y (opcional) subir al registro
echo "Etiquetando imagen..."
docker tag go-rest-api:$VERSION myrepo/go-rest-api:$VERSION
# docker push myrepo/go-rest-api:$VERSION

echo "Imagen versionada como $VERSION."

# limpiar la carpeta temporal
echo "Limpiando carpeta temporal"
rm -rf $TEMP_DIR

# 4. Opcional: Crear un rollback a una versión específica
# echo "Para rollback, usa: docker run -d -p 8080:8080 myrepo/go-rest-api:<versión-anterior>"