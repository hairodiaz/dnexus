#!/bin/bash
# Build script for Vercel deployment

echo "🔧 Installing Flutter dependencies..."
flutter pub get

echo "🏗️ Building Flutter web application..."
flutter build web --release --base-href "/" --no-tree-shake-icons

echo "✅ Build completed successfully!"
echo "📦 Web files are ready in build/web/"