#!/bin/bash

# Exit on error
set -e

echo "=== System Information ==="
uname -a
pwd

# Clone the Flutter SDK stable branch if it doesn't exist
if [ ! -d "flutter" ]; then
  echo "=== Cloning Flutter SDK ==="
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable
else
  echo "=== Flutter SDK already exists ==="
fi

# Add Flutter to the PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# Pre-download development binaries and configure web
echo "=== Configuring Flutter ==="
flutter config --enable-web
flutter doctor

# Navigate to the Flutter project folder
cd sampaathi-news

# Get packages and build the web app
echo "=== Fetching Flutter Dependencies ==="
flutter pub get

echo "=== Building Flutter Web Application ==="
if [ -n "$WORDPRESS_API_URL" ]; then
  echo "Using WORDPRESS_API_URL: $WORDPRESS_API_URL"
  flutter build web --release --dart-define=WORDPRESS_API_URL="$WORDPRESS_API_URL"
else
  echo "Using default local URL (WORDPRESS_API_URL environment variable is not set)"
  flutter build web --release
fi

echo "=== Build Complete ==="
