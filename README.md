#Ingamium

Ingamium is a plugin for the free chat client Adium. It allows you to receive messages and reply to them while playing a game without leaving fullscreen mode or quitting the game. You'll simply see the chat messages as overlay on top of your game. Works with all chat protocols Adium supports.

### Features
* Install the plugin with a simple double click – thereafter it's perfectly integrated to Adium, without any further configuration!
* No matter whether you use ICQ, MSN, Aim, Google Talk or any other protocol – Ingamium supports them all!
* Chat with your friends without closing your game
* Ingamium supports about 80 native Mac OS X games, but you can add custom ones with a few clicks
* Configure Ingamium to fit your needs: e.g. Position, color and the behavior of the chat window are customizable
* Use the build-in function to send new games to the developer – they'll be officially included in the next release!

### Requirements
* Adium 1.4
* Mac OS X 10.6 - 10.9
* Admin password at first launch
* NOTE: If you're using OS X 10.9 Mavericks, you'll have to go to "Security & Privacy" in your System Preferences, open the tab "Privacy", select "Accessibility" from the list and drag'n'drop Adium into the list of trusted applications. Otherwise, you won't be able to answer incoming chat messages, because Adium doesn't have the permission to access your keyboard by default. This might be automated in any future version if I find the time to look at it.

### TODO
* ~~Test it on 10.9 Mavericks~~
* More architectures: x86_64 and PPC (OSX 10.5)
* Remove deprecated API calls
* Add more games!

### Changelog:
#### Version 1.4
* Overall code and project cleanup (changeover to SMJobBless-API)
* Update to latest mach_inject and mach_override
* Support for OS X 10.8 Mountain Lion

#### Version 1.3
* Support for Sandbox-Apps from MAS
* Performance-Fix for Call of Duty 4
* Improved compatibility and stability
* Upgrade to most recent mach_star
* More games!

#### Version 1.2
* Improved Lion compatibility

#### Version 1.1
* Fixed 10.6.8-related crashs
* Greatly improved performance in Source-Engine games

#### Version 1.0
* Initial release

### Credits
* Lead development: Florian Bethke
* Application icon: Keyes
* Homepage (currently not online): Felix Wandler
* [mach_inject](https://github.com/rentzsch/mach_inject) and [mach_override](https://github.com/rentzsch/mach_override) by Jonathan Rentzsch
* [SMJobBless](https://github.com/erwanb/MachInjectSample) demo code: Erwan Barrier


### Screenshots
![Ingame Message](https://raw.github.com/Fl0ri4n/Ingamium/master/Resources/screenshot1.png)
![Ingame Message2](https://raw.github.com/Fl0ri4n/Ingamium/master/Resources/screenshot2.tiff)
