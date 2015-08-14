<h1 align="center">
	<img src="http://i.imgur.com/dP8aoOw.png" alt="Scratch-Detector">
</h1>

### Overview
Scratch Detector is a program that reads all tracks on Equibase and Racing-Channel; looking for any coupled entries that have been scratched. Any coupled entry changes are then presented to the user. This information can be used to complete the normal Coupled Entry Scratch Process.

The \data directory contains \temp, while the NAS contains \data\archive. Both are non-essential and can be cleared or deleted at any time.

This program works like a screen scraping machine for Racing Channel; but for Equibase, it reads a XML file located http://www.equibase.com/premium/eqbLateChangeXMLDownload.cfm


### Example Use
Run and be informed of all current Coupled Entry scratches.

After entering a coupled entry scratch on All DDS platforms; doubleclick on both the horses of that entry. Any horses doubleclicked will be added to a database that is only used for the current day. Horses in that database will not be highlighted in orange. DB are saved in ..\data\archive\DBs

This database is shared across all of us so when Morning shift scratches horses on the system in the morning, they won’t appear when MidDay runs the program.

This also helps when there are a lot of scratches, it won’t be as hard to decipher what is new.


### Functions & Features
Pressing F1 on the keyboard is a shortcut for pressing the "Update" button.

Scratched Runners will be highlighted in orange until double-clicked and refreshed.

Double-clicking the Trackname will clear your clipboard and replace it with Shift Notes formatted scratches.   Example: 4-(1,1A,1X)  6-(2B)


### Settings
**Auto-Update:** Cannot be smaller than 10mins. Starts a repeating timer when checkbox is clicked. Every time the timer expires; the update button is pressed internally.


### Troubleshooting
Racing-Channel keeps some kind of cookie to keep track of if you have logged in recently. A message will be displayed next to the mouse cursor in the event that Equibase or Racing-Channel data could not be pulled.


### Warnings
When Racing-Channel scratches a Runner but it is not confirmed by Equibase. It is recommended to watch the live video and confirm the scratch. These scratches are not counted in effected entries.


### Technical Details
Latest version is 0.29.2 (05.17.15)
