#!/bin/bash

# Nazwa obrazu buildera przekazana jako argument
BUILD_IMAGE=$1

echo "------------------------------------------"
echo "Starting Publish process..."

# 1. Wyciągamy skompilowane pliki z obrazu buildera do bieżącego folderu
# Używamy tymczasowego kontenera, żeby skopiować folder dist i package.json
docker run --rm -v $(pwd):/out $BUILD_IMAGE cp -r /app/package.json /app/dist /out/

# 2. Pakujemy pliki używając oficjalnego kontenera Node (izolacja środowiska)
# To tworzy plik .tgz bez instalowania czegokolwiek na Jenkinsie
docker run --rm -v $(pwd):/out -w /out node:20-alpine npm pack

echo "Package created successfully."
echo "------------------------------------------"