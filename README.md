## The build.sh script will
   1. Build the latest development version of Aseprite from source for macOS
   2. Bundle it to an executable Asperite.app
   3. Cleans up all the source files after building

## Support
  Last updated and tested on 22 Jul 2024.  
  Tested to work with macOS 15.0 Sequoia Beta 3, Apple M2.  
  This is a Universal build for Intel-based and M-series (arm64) Macs.  
  It should work on both.  

## Instructions
   1. Install Homebrew (from https://brew.sh)
   2. Install Xcode (from App Store)
   3. Copy and paste the contents of this script into Terminal (Command + C, Command + V)
   4. Press enter to run the script and start the build process
   5. Wait
   5. At some point, you will be prompted to agree to the license. Press Q to continue.
   6. Done! You'll get your .app file.
      By default, you will find it in ~/Developer/Aseprite/
      Then you can copy it to your ~/Applications/ folder.
 
 ## Credits
   This is a modification of furashcka's script, which itself was a modification
   of allangarcia's script.
   https://gist.github.com/allangarcia/938b052a7d55d1652052e4259364260b

## Disclaimer
  THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
  BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
