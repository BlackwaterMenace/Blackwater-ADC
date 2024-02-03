# Blackwater-ADC
Accessorize with Detached Cosmetics (ADC) is a Random Access Mayhem mod that allows you to add cosmetic alterations to the game that can carry over to any skin.

This mod is designed as a framework for other mods.
Included is the ADCTest mod, which offers high-visibility overlays that fit perfectly over the skins to verify alignment, animation synchronization, and (most importantly) demonstrate how compatible mods should go about adding overlays.
Also, please note that the Modloader currently does not support extensions of certain classes. The Blackwater-ADC folder includes a Scripts folder that should be dragged and dropped into the game root folder to replace those scripts with the modded version. The Scripts folder will be removed when extending those scripts is possible.

# Introduction
Sometimes, a skin mod consists of slight changes to a preexisting skin. Examples of such changes may include:
  * Sunglasses
  * Top hats
  * Photorealistic human hands
  * One or more of the following: cat ears, cat tails, cat paws, cat collars, catching mitts

Usually, these mods are made by drawing these new details (typically some form of fashion accessory) on top of the bot's default skin.
While this is perfectly functional, it does have some slight drawbacks. What if the end user prefers to use the Carbon skin for Aphid, and doesn't want to have to choose between a cool, hard-earned skin that is seen nowhere else in the game and the equally cool bow tie mod skin? What if another mod adds a really really awesome recolor that would look great with a monocle, but the monocle mod only covers vanilla skins?
There has to be a better way, right?
Introducing, Accessorize with Detached Cosmetics (ADC)!

# Premise
How does it work? Simple!
By isolating the changes that a mod makes to the base spritesheet, then overlaying those changes over any skin you want, you can easily have the mod's changes applied to ALL skins for that bot - even ones that are added by other mods! This is very simple to do during the process of the mod's creation, and with a bit of know-how and/or a bit of patience, even an existing skin mod can be changed into a cosmetic accessory that is detached from the rest of the skin.

# How do I use this mod?
As a mod creator:

  Part A: Creating your art assets

    1. Draw your accessories on a new layer (most artists will likely already do this!) for, at the very least, the skin selection portrait and the actual spritesheet that will be used in the game.
    2. When you're done, delete the layer containing the original, vanilla game's spritesheet you were drawing over.
    3. Export the result, which now consists only of transparency and your own unique content, and give it a distinctive name.*
    
  Part B: Setting up the mod
	
    1. Make a mod with your overlay sprites(heets) in the "Art/Characters/{host's internal name}RAM/Overlays" folder.
    2. In the mod_main.gd file, in either the \_ready() method or a helper method called from there, call the following method for every overlay your mod will add (you can add any number of overlays for different bots in a single mod): Progression.add_{host's internal name}_overlay(AUTHORNAME_MODNAME_DIR, "{name of the overlay}").*
    3. Make sure that your mod lists this framework as a dependency.

As a mod user:
  1. Install the mod as you would with any other mod.
  2. Install whatever mods you want to that use this framework as a dependency.
  3. When on the character/difficulty/skin selection menu, there should now be two buttons, one above the other, in every place there is normally a skin change button. The top buttons change the skin, and the bottom buttons change the accessories. Just as changing the skin before a run updates the skin selection portrait, changing the accessories should display the accessories over the skin.
  4. When starting the run, you should now see the accessories on top of the skin.

# Some final notes
If you're still reading this, you are likely either interested in this mod or are reading this in some form of highly esoteric RAM mods GitHub repo README.txt -based cringe compilation.
If your case is the former, then I can't help but feel obligated to ensure you are aware of the following:
  * As a framework, this mod does not add anything of particular importance on its own. It is meant to pave the way for sprite modders to make their own accessories, which can be used with most skins.
  * This framework is meant for small changes. If you're making a mod that, for example, turns Router into Sonic the Hedgehog, this is not the mod for you. Generally, your mod should keep the same silhouette\* as the OG skins or add only slight details to it. If the silhouette\* will be radically changed or most of the OG skin will be obscured, just make it into a new skin.
  * Silhouette in German is "Umriss."

If your case is the latter, then the following information may also be of use to you:
  * Silhouette in German is "Umriss."

# Notes:
This framework enforces certain style choices. The sprites must be named as such:

*{Bot actual name (capitalized)}{Name of overlay}{Type of sprite}.png*

With {Type of sprite} being one of the following:
* OSP:	  (All bots) Overlay Selection Portrait, which is used for seeing what overlay you're selecting on the skin/overlay selection menu.
* Main:	  (All bots) Used for the main body.
* Arm:	  (Deadlift, Router) Used for Deadlift's and Router's arms, as they are animated seperately from the rest of their bodies. Many overlays will not need this.
* Shaped: (Router) Used for Router's Shaped Charges arm. Many overlays will not need this.

For examples, see the included "Blackwater-ADCTest" mod structure, which provides a template of how your files should be set up.
