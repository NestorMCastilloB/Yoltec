#!/bin/bash
# Compilar y publicar nueva versión de la app en GitHub Releases
# Uso: ./release.sh v1.3 "Descripción del release"

VERSION=${1:-""}
DESCRIPCION=${2:-"Nueva versión"}

if [ -z "$VERSION" ]; then
  echo "Uso: ./release.sh v1.3 \"Descripción\""
  exit 1
fi

echo "Compilando APK release..."
flutter build apk --release

if [ $? -ne 0 ]; then
  echo "Error al compilar el APK"
  exit 1
fi

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

echo "Publicando $VERSION en GitHub Releases..."
gh release create "$VERSION" "$APK_PATH" \
  --title "Yoltec $VERSION" \
  --notes "$DESCRIPCION"

echo "Release publicado: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/$VERSION"
