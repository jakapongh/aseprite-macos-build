#!/bin/bash
#  This script will:
#    1. Build the latest development version of Aseprite from source for macOS
#    2. Bundle it to an executable Aseprite.app
#    3. Cleans up all the source files after building
#  
#  Support:
#    Last updated and tested on 22 Jul 2024.
#    Tested to work with macOS 15.0 Sequoia Beta 3, Apple M2.
#    This is a Universal build for Intel-based and M-series (arm64) Macs.
#    It should work on both.
#  
#  Instructions:
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
#   Credits:
#    This is a modification of furashcka's script, which itself was a modification
#    of allangarcia's script.
#    https://gist.github.com/allangarcia/938b052a7d55d1652052e4259364260b
#
#   Disclaimer:
#     THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
#     BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
#     PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#     HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
#     OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE
#     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#  

WORKING_DIRECTORY=$HOME/Developer
ASEPRITE_SOURCE_GIT_REPO_URL=https://github.com/aseprite/aseprite.git
ASEPRITE_TRIAL_DMG_URL=https://www.aseprite.org/downloads/trial/Aseprite-v1.3.6-trial-macOS.dmg
SKIA_M102_URL=https://github.com/aseprite/skia/releases/download/m102-861e4743af/Skia-macOS-Release-arm64.zip
DCMAKE_OSX_SYSROOT_PATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
DCMAKE_OSX_DEPLOYMENT_TARGET=11.0

# For stylised status text
script_echo() {
  echo -e "\033[33m${1}\033[0m"
}

show_build_finised_message() {
  # Remove build files after replacing original .app with build
  rm -rf ./build

  echo "\033[0;32m[12/12] Build script finished\!\n"
  echo "---------------- BUILD FINISHED ----------------"
  echo " Find your Aseprite.app at:"
  echo " $HOME/Developer/Aseprite/"
  echo "------------------------------------------------"
  echo -e "\033[0m"
}

# This is for tools required: cmake & ninja
script_echo "[01/12] Updating brew and installing cmake & ninja"
brew update
brew install cmake
brew install ninja

# Create the default root directory
cd $WORKING_DIRECTORY
script_echo "[02/12] Changed directory to ${WORKING_DIRECTORY}"
if [ -d "./Aseprite" ]; then
    script_echo "[02/12] ${WORKING_DIRECTORY}/Aseprite already exists. Deleting it."
    rm -rf "./Aseprite"
else
    script_echo "[02/12] ${WORKING_DIRECTORY}/Aseprite doesn't exist. Creating it."
fi

mkdir Aseprite
cd Aseprite

# Download skia m102
script_echo "[03/12] Downloading skia_m102"
curl -# -o skia_m102.zip -L $SKIA_M102_URL

# Unzip skia and delete original zip
unzip skia_m102.zip -d skia_m102 && rm skia_m102.zip

# This is the project itself
script_echo "[04/12] Cloning Aseprite source repository. This may take a while."
git clone --recursive $ASEPRITE_SOURCE_GIT_REPO_URL ./repo

# Compiling aseprite
script_echo "[05/12] Compiling Aseprite from source. This may take a while."
mkdir build
cd build
cmake \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=$DCMAKE_OSX_DEPLOYMENT_TARGET \
  -DCMAKE_OSX_SYSROOT=$DCMAKE_OSX_SYSROOT_PATH \
  -DLAF_BACKEND=skia \
  -DSKIA_DIR=../skia_m102 \
  -DSKIA_LIBRARY_DIR=../skia_m102/out/Release-arm64 \
  -DSKIA_LIBRARY=../skia_m102/out/Release-arm64/libskia.a \
  -DPNG_ARM_NEON:STRING=on \
  -G Ninja \
  ../repo
ninja aseprite
cd ../

# Delete skia and source repo after build
rm -rf ./skia_m102 ./repo

# Bundle app from trial
# Extract .app from .dmg
script_echo "[06/12] Downloading Aseprite original trial .dmg"
mkdir ./bundle
curl -# -o ./bundle/aseprite_trial.dmg -J $ASEPRITE_TRIAL_DMG_URL
script_echo "[07/12] Mounting original trial dmg"
mkdir ./bundle/mount
yes qy | hdiutil attach -quiet -nobrowse -noverify -noautoopen -mountpoint ./bundle/mount ./bundle/aseprite_trial.dmg
script_echo "[08/12] Copying original trial app"
cp -r ./bundle/mount/Aseprite.app .
script_echo "[09/12] Unmounting dmg"
hdiutil detach ./bundle/mount -quiet

# Removed original app file after copying
rm -rf ./bundle

# Replace original contents of .app with our build
script_echo "[10/12] Removing original trial app contents"
rm -rf Aseprite.app/Contents/MacOS/aseprite
rm -rf Aseprite.app/Contents/Resources/data
script_echo "[11/12] Copying build files to app contents"
cp -r ./build/bin/aseprite Aseprite.app/Contents/MacOS/aseprite
cp -r ./build/bin/data Aseprite.app/Contents/Resources/data

show_build_finised_message
