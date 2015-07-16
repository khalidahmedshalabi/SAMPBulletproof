# Bulletproof-Gamemode
Bulletproof Gamemode is a SA-MP gamemode which is believed to take A/D and TDM to a new level.

### Website
http://www.infinite-gaming.ml/khk/bulletproofgm/

### Guidelines (pull requests)

- [x] You're welcome to contribute, make changes and add your touch to our gamemode, however you have to listen to a few things...
- Keep whatever you write organized in modules/libraries and don't get the main gamemode pawn file messy. Also don't overdo it.
- Try to always use iterators (y_iterate) when possible and BE WARE of Iter_Remove and Iter_SafeRemove.
- PLEASE, use 'Allman' indent style when writing codes!
- Always research and make your code the most efficient. You must do this when you provide a code that is going to be executed more frequently (e.g code under OnPlayerTakeDamge or OnPlayerUpdate)
- Do not give random sizes for strings! If your string could barely hit 70 characters, why randomly give it 128 or any random size? There are tons of online tools for this purpose, use one!
- Document whatever you write with comments. This makes it easier for us to merge and for others to understand.

### Little advice for while writing code for Bulletproof

I personally do this so it's a preference yet I think it's the easiest way to go. If you haven't noticed there are 3 major types of files: *bulletproof.pwn, modules\src\ and modules\header*. What I do is open up *bulletproof.pwn* normally in PAWNO and have 2 Notepad++ windows open; one for src files and the other for header files. This is how it goes, I make changes to header/src files, hit CTRL+SHIFT+S in Notepad++ to save all changes and finally compile with PAWNO.
