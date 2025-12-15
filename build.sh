#!/bin/bash
#
#  What does it do?
#    1. Build the development version of Aseprite v1.3.16 from source for macOS
#    2. Bundle it to an executable Aseprite.app
#    3. Cleans up all the source files after building
#  
# - Last updated and tested on 15 Dec 2025 on macOS Tahoe 26.2.
# - This is a Universal build for Intel and M-series (arm64) Macs.
#  
#  How do I use it?
#  1. Install Homebrew (from https://brew.sh)
#  2. Install Xcode (from App Store)
#  3. Save this script to a file (e.g., build.sh)
#  4. Open Terminal and navigate to where you saved the file
#  5. Run: chmod +x build.sh && ./build.sh
#  5. At some point, you will be prompted to agree to the license. Press Q to continue.
#  6. Wait (compilation takes a while)
#  7. Done! You'll get your .app file.  
#     By default, you will find it in ~/Developer/Aseprite/  
#     Then you can copy it to your ~/Applications/ folder. 
#   
#  Credits
#    This is a modification of furashcka's script, which itself was a modification
#    of allangarcia's script.
#    https://gist.github.com/allangarcia/938b052a7d55d1652052e4259364260b
#
#  Disclaimer:
#     This software is provided "as is" without warranty of any kind, express or implied.
#     
#     The script enables users to compile Aseprite from source for personal use and to
#     create commercial art/assets, but it does not authorize the redistribution of
#     compiled versions of Aseprite.
#     
#     Aseprite has been open source since 2001, but from August 2016, the EULA was updated
#     to prohibit the redistribution of compiled versions of Aseprite. You can download
#     the source code, compile it, and use it for personal purposes or to create commercial
#     art/assets, but you cannot share or sell compiled versions.
#     
#     Users must comply with the Aseprite End User License Agreement (EULA). The authors
#     of this script are not responsible for any legal or financial consequences resulting
#     from the use or misuse of this script.
#     
#     This script is intended for educational purposes only. Users should review and adhere
#     to all relevant licensing terms and conditions.
#     
#

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Where the build will occur, and where the compiled .app file will be stored
WORKING_DIRECTORY="$HOME/Developer/Aseprite"

# URLs for source files and dmg files required for build
ASEPRITE_SOURCE_GIT_REPO_URL="https://github.com/aseprite/aseprite.git"
ASEPRITE_TRIAL_DMG_URL="https://www.aseprite.org/downloads/trial/Aseprite-v1.3.16-trial-macOS.dmg"
SKIA_M102_URL="https://github.com/aseprite/skia/releases/download/m124-08a5439a6b/Skia-macOS-Release-arm64.zip"

# Delete source files after compilation
# (default: true)
DELETE_SOURCE_AFTER_COMPILATION=true

# Xcode SDK location for CMake
DCMAKE_OSX_SYSROOT_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"

# Minimum version of macOS that should be supported
# (default: macOS 11.0 Big Sur or later versions is supported)
DCMAKE_OSX_DEPLOYMENT_TARGET="11.0"

CURRENT_STEP=1
TOTAL_STEPS=12

# Cleanup function for errors
cleanup_on_error() {
  echo -e "\033[0;31m"
  echo "================================================"
  echo "ERROR: Build failed at step ${CURRENT_STEP}"
  echo "================================================"
  echo -e "\033[0m"
  
  echo "Cleaning up partial build..."
  cd "$HOME"
  
  # Unmount DMG if it's mounted
  if [ -d "$WORKING_DIRECTORY/bundle/mount" ]; then
    echo "Unmounting DMG..."
    hdiutil detach "$WORKING_DIRECTORY/bundle/mount" -quiet -force 2>/dev/null || true
  fi
  
  # Clean up build and bundle directories
  if [ -d "$WORKING_DIRECTORY/build" ]; then
    rm -rf "$WORKING_DIRECTORY/build"
  fi
  if [ -d "$WORKING_DIRECTORY/bundle" ]; then
    rm -rf "$WORKING_DIRECTORY/bundle"
  fi
  
  exit 1
}

# Set up error trap
trap cleanup_on_error ERR

# For stylised status text
script_echo() {
  echo -e "\033[33m[${CURRENT_STEP}/${TOTAL_STEPS}] ${1}\033[0m"
  ((CURRENT_STEP++))
}

show_build_finised_message() {
  # Remove build files after replacing original .app with build
  if $DELETE_SOURCE_AFTER_COMPILATION; then
    rm -rf ./build
  fi

  echo -e "\033[0;32m[${CURRENT_STEP}/${TOTAL_STEPS}] Build script finished!"
  echo ""
  echo "---------------- BUILD FINISHED ----------------"
  echo " Find your Aseprite.app at:"
  echo " $WORKING_DIRECTORY"
  echo "------------------------------------------------"
  echo -e "\033[0m"
}

# Check prerequisites
check_prerequisites() {
  echo "Checking prerequisites..."
  
  if ! command -v brew >/dev/null 2>&1; then
    echo "Error: Homebrew not found. Please install from https://brew.sh"
    exit 1
  fi
  
  if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "Error: Xcode not found. Please install from the App Store"
    exit 1
  fi
  
  if [ ! -d "$DCMAKE_OSX_SYSROOT_PATH" ]; then
    echo "Error: Xcode SDK not found at $DCMAKE_OSX_SYSROOT_PATH"
    echo "Please ensure Xcode is properly installed and run: sudo xcode-select --switch /Applications/Xcode.app"
    exit 1
  fi
  
  echo "All prerequisites satisfied."
}

# Run prerequisite checks
check_prerequisites

# Install tools required with brew: cmake & ninja
script_echo "Updating brew and installing cmake & ninja"
brew update
brew install cmake
brew install ninja

# Create the working directory if it doesn't exist
if [ ! -d "$WORKING_DIRECTORY" ]; then
  script_echo "${WORKING_DIRECTORY} doesn't exist. Creating it."
  mkdir -p "$WORKING_DIRECTORY"
else
  cd "$HOME"
  script_echo "${WORKING_DIRECTORY} already exists. Deleting it."
  
  # Check if there's a mounted DMG and unmount it first
  if [ -d "$WORKING_DIRECTORY/bundle/mount" ]; then
    echo "Found mounted DMG from previous run. Unmounting..."
    hdiutil detach "$WORKING_DIRECTORY/bundle/mount" -quiet -force 2>/dev/null || true
    # Give it a moment to fully unmount
    sleep 1
  fi
  
  rm -rf "$WORKING_DIRECTORY"
  mkdir -p "$WORKING_DIRECTORY"
fi

cd "$WORKING_DIRECTORY"

# Download Skia-m102, a required 2D graphics library
script_echo "Downloading skia_m102"
curl -# -o skia_m102.zip -L "$SKIA_M102_URL"

# Verify download
if [ ! -f "skia_m102.zip" ]; then
  echo "Error: Skia download file not found"
  exit 1
fi

# Unzip Skia and delete original Skia zip
unzip skia_m102.zip -d skia_m102

if $DELETE_SOURCE_AFTER_COMPILATION; then
  rm skia_m102.zip
fi

# Clone latest Aseprite source from repository
script_echo "Cloning Aseprite source repository. This may take a while."
git clone --recursive "$ASEPRITE_SOURCE_GIT_REPO_URL" ./repo

# Verify clone
if [ ! -d "./repo" ]; then
  echo "Error: Aseprite repository directory not found"
  exit 1
fi

# Compile Aseprite now that we have downloaded Skia-m102 and latest source
script_echo "Compiling Aseprite from source. This may take a while."
mkdir build
cd build

# Get absolute paths to avoid CMake relative path errors
SKIA_ABS_PATH="$(cd ../skia_m102 && pwd)"
REPO_ABS_PATH="$(cd ../repo && pwd)"

cmake \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$DCMAKE_OSX_DEPLOYMENT_TARGET" \
  -DCMAKE_OSX_SYSROOT="$DCMAKE_OSX_SYSROOT_PATH" \
  -DLAF_BACKEND=skia \
  -DSKIA_DIR="$SKIA_ABS_PATH" \
  -DSKIA_LIBRARY_DIR="$SKIA_ABS_PATH/out/Release-arm64" \
  -DSKIA_LIBRARY="$SKIA_ABS_PATH/out/Release-arm64/libskia.a" \
  -DPNG_ARM_NEON:STRING=on \
  -G Ninja \
  "$REPO_ABS_PATH"

ninja aseprite

cd ../

# Verify build output
if [ ! -f "./build/bin/aseprite" ]; then
  echo "Error: Build succeeded but aseprite binary not found"
  exit 1
fi

# Delete Skia and source repository after build finishes
if $DELETE_SOURCE_AFTER_COMPILATION; then
  rm -rf ./skia_m102 ./repo
fi

# Bundle our build files into the trial .app
# Extract .app from trial .dmg
script_echo "Downloading Aseprite original trial .dmg"
mkdir ./bundle

curl -# -o ./bundle/aseprite_trial.dmg -J "$ASEPRITE_TRIAL_DMG_URL"

# Verify download
if [ ! -f "./bundle/aseprite_trial.dmg" ]; then
  echo "Error: Trial .dmg file not found"
  exit 1
fi

script_echo "Mounting original trial .dmg"
mkdir ./bundle/mount

hdiutil attach -nobrowse -noverify -noautoopen -mountpoint ./bundle/mount ./bundle/aseprite_trial.dmg

ls -la ./bundle/mount/ || echo "Mount directory is empty or inaccessible"
if [ ! -d "./bundle/mount/Aseprite.app" ]; then
  echo "Error: Aseprite.app not found in mounted DMG"
  exit 1
fi

script_echo "Copying original trial .app"

# Copy trial .app into working directory
cp -rf ./bundle/mount/Aseprite.app .

# Verify copy succeeded
if [ ! -d "./Aseprite.app" ]; then
  echo "Error: Failed to copy Aseprite.app"
  exit 1
fi

script_echo "Unmounting .dmg"
hdiutil detach ./bundle/mount -quiet

# Remove original trial .app file after copying .app
if $DELETE_SOURCE_AFTER_COMPILATION; then
  rm -rf ./bundle
fi

# Replace original contents of trial .app with our build
script_echo "Removing original trial .app contents"
rm -rf Aseprite.app/Contents/MacOS/aseprite
rm -rf Aseprite.app/Contents/Resources/data

script_echo "Copying build files to .app contents"
cp -r ./build/bin/aseprite Aseprite.app/Contents/MacOS/aseprite
cp -r ./build/bin/data Aseprite.app/Contents/Resources/data

# Verify final .app
if [ ! -f "Aseprite.app/Contents/MacOS/aseprite" ]; then
  echo "Error: Final .app bundle is incomplete"
  exit 1
fi

show_build_finised_message
