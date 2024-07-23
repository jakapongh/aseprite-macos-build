#!/bin/bash
#  What does it do?
#    1. Build the latest development version of Aseprite from source for macOS
#    2. Bundle it to an executable Aseprite.app
#    3. Cleans up all the source files after building
#  
#  Does it work?
#    - Last updated and tested on 22 Jul 2024.
#    - Tested to work with macOS 15.0 Sequoia Beta 3, Apple M2.
#    - This is a Universal build for Intel-based and M-series (arm64) Macs.
#    - It should work on both.
#  
#  How do I use it?
#    1. Install Homebrew (from https://brew.sh)
#    2. Install Xcode (from App Store)
#    3. Copy and paste the contents of this script into Terminal (Command + C, Command + V)
#    4. Press enter to run the script and start the build process
#    5. Wait
#    5. At some point, you will be prompted to agree to the license. Press Q to continue.
#    6. Done! You'll get your .app file.
#        By default, you will find it in ~/Developer/Aseprite/
#        Then you can copy it to your ~/Applications/ folder.
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



# Where the build will occur, and where the compiled .app file will be stored
WORKING_DIRECTORY="$HOME/Developer/Aseprite"

# URLs for source files and dmg files required for build
ASEPRITE_SOURCE_GIT_REPO_URL="https://github.com/aseprite/aseprite.git"
ASEPRITE_TRIAL_DMG_URL="https://www.aseprite.org/downloads/trial/Aseprite-v1.3.6-trial-macOS.dmg"
SKIA_M102_URL="https://github.com/aseprite/skia/releases/download/m102-861e4743af/Skia-macOS-Release-arm64.zip"

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

  echo "\033[0;32m[${CURRENT_STEP}/${TOTAL_STEPS}] Build script finished\!\n"
  echo "---------------- BUILD FINISHED ----------------"
  echo " Find your Aseprite.app at:"
  echo " $WORKING_DIRECTORY"
  echo "------------------------------------------------"
  echo -e "\033[0m"
}

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
  rm -rf "{$WORKING_DIRECTORY}"
fi

cd "$WORKING_DIRECTORY"

# Download Skia-m102, a required 2D graphics library
script_echo "Downloading skia_m102"
curl -# -o skia_m102.zip -L "$SKIA_M102_URL"

# Unzip Skia and delete original Skia zip
unzip skia_m102.zip -d skia_m102
if $DELETE_SOURCE_AFTER_COMPILATION; then
  rm skia_m102.zip
fi

# Clone latest Aseprite source from repository
script_echo "Cloning Aseprite source repository. This may take a while."
git clone --recursive "$ASEPRITE_SOURCE_GIT_REPO_URL" ./repo

# Compile Aseprite now that we have downloaded Skia-m102 and latest source
script_echo "Compiling Aseprite from source. This may take a while."
mkdir build
cd build
cmake \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$DCMAKE_OSX_DEPLOYMENT_TARGET" \
  -DCMAKE_OSX_SYSROOT="$DCMAKE_OSX_SYSROOT_PATH" \
  -DLAF_BACKEND=skia \
  -DSKIA_DIR=../skia_m102 \
  -DSKIA_LIBRARY_DIR=../skia_m102/out/Release-arm64 \
  -DSKIA_LIBRARY=../skia_m102/out/Release-arm64/libskia.a \
  -DPNG_ARM_NEON:STRING=on \
  -G Ninja \
  ../repo
ninja aseprite
cd ../

# Delete Skia and source repository after build finishes
if $DELETE_SOURCE_AFTER_COMPILATION; then
  rm -rf ./skia_m102 ./repo
fi

# Bundle our build files into the trial .app
# Extract .app from trial .dmg
script_echo "Downloading Aseprite original trial .dmg"
mkdir ./bundle
curl -# -o ./bundle/aseprite_trial.dmg -J "$ASEPRITE_TRIAL_DMG_URL"
script_echo "Mounting original trial .dmg"
mkdir ./bundle/mount
yes qy | hdiutil attach -quiet -nobrowse -noverify -noautoopen -mountpoint ./bundle/mount ./bundle/aseprite_trial.dmg
script_echo "Copying original trial .app"

# Copy trial .app into working directory
cp -rf ./bundle/mount/Aseprite.app .
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

show_build_finised_message
