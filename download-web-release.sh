#!/bin/bash

# Pocket ID Web Release Downloader
# This script downloads the latest web release from GitHub and unpacks it into the 'web-dist' folder.

REPO="NtWriteCode/pocket-id"
TARGET_DIR="web-dist"

echo "🔍 Finding latest release for $REPO..."

# Get the latest release JSON from GitHub API
RELEASE_DATA=$(curl -s https://api.github.com/repos/$REPO/releases/latest)

# Extract the download URL for the web zip asset
# It looks for an asset containing "-web.zip"
DOWNLOAD_URL=$(echo "$RELEASE_DATA" | grep -oP '"browser_download_url": "\K[^"]*?-web\.zip(?=")')

if [ -z "$DOWNLOAD_URL" ]; then
    echo "❌ Error: Could not find a web release asset (-web.zip) in the latest release."
    exit 1
fi

VERSION=$(echo "$RELEASE_DATA" | grep -oP '"tag_name": "\K[^"]*(?=")')
echo "📦 Latest version found: $VERSION"
echo "📥 Downloading from: $DOWNLOAD_URL"

# Create target directory and temporary file
mkdir -p "$TARGET_DIR"
TEMP_ZIP="latest-web.zip"

# Download the file
curl -L "$DOWNLOAD_URL" -o "$TEMP_ZIP"

if [ $? -eq 0 ]; then
    echo "✅ Download complete. Unpacking to '$TARGET_DIR'..."
    
    # Unpack the zip into the target directory
    unzip -o "$TEMP_ZIP" -d "$TARGET_DIR"
    
    # Clean up
    rm "$TEMP_ZIP"
    
    echo "🚀 Done! You can now host the content of the '$TARGET_DIR' folder."
    echo "💡 Example: python3 -m http.server 8080 --directory $TARGET_DIR"
else
    echo "❌ Error: Download failed."
    rm -f "$TEMP_ZIP"
    exit 1
fi
