# Build Aseprite from Source on macOS

### What does it do?
1. Build the latest [development version of Aseprite](https://github.com/aseprite/aseprite) from source for macOS
2. Bundle it to an executable Asperite.app
3. Cleans up all the source files after building

### Does it work?
- Last updated and tested on 22 Jul 2024
- Tested to work with macOS 15.0 Sequoia Beta 3, Apple M2
- This is a Universal build for Intel-based and M-series (arm64) Macs
- It should work on both Intel and M-series Macs

### How do I use it?
1. Install Homebrew (from https://brew.sh)
2. Install Xcode (from App Store)
3. Copy and paste the contents of this script into Terminal (Command + C, Command + V)
4. Press enter to run the script and start the build process
5. Wait
5. At some point, you will be prompted to agree to the license. Press Q to continue.
6. Done! You'll get your .app file.  
   By default, you will find it in ~/Developer/Aseprite/  
   Then you can copy it to your ~/Applications/ folder. 

### Credits
This is a modification of furashcka's script, which itself was a modification
of allangarcia's script.
https://gist.github.com/allangarcia/938b052a7d55d1652052e4259364260b

### Disclaimer
```
This software is provided "as is" without warranty of any kind, express or implied.  

The script enables users to compile Aseprite from source for personal use and to  
create commercial art/assets, but it does not authorize the redistribution of  
compiled versions of Aseprite.  

Aseprite has been open source since 2001, but from August 2016, the EULA was updated  
to prohibit the redistribution of compiled versions of Aseprite. You can download  
the source code, compile it, and use it for personal purposes or to create commercial  
art/assets, but you cannot share or sell compiled versions.  

Users must comply with the Aseprite End User License Agreement (EULA). The authors  
of this script are not responsible for any legal or financial consequences resulting  
from the use or misuse of this script.  

This script is intended for educational purposes only. Users should review and adhere  
to all relevant licensing terms and conditions.
```
  
