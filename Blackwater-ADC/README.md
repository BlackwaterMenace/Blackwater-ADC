# Blackwater-ADC
Accessorize with Detached Cosmetics (ADC) is a Random Access Mayhem mod that allows you to add cosmetic alterations to the game that can carry over to any skin.

This mod is designed as a framework for other mods.

# Introduction
Sometimes, a skin mod consists of slight changes to a preexisting skin. Examples of such changes may include:
  * Sunglasses
  * Top hats
  * Human hands
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
  1. Draw your accessories on a new layer (most artists will likely already do this!) for, at the very least, the skin selection portrait and the actual spritesheet that will be used in the game.
  2. When you're done, delete the layer containing the original, vanilla game's spritesheet you were drawing over.
  3. Export the result, which now consists only of transparency and your own unique content, and give it a distinctive name.
  4. TODO: finish these instructions as soon as you figure out how each mod should change the Progression.gd with the appropriate data.
  5. Make sure that your mod lists this framework as a dependency.

As a mod user:
  1. Install the mod as you would with any other mod.
  2. Install whatever mods you want to that use this framework as a dependency.
  3. When on the character/difficulty/skin selection menu, there should now be two buttons, one above the other, in every place there is normally a skin change button. The top buttons change the skin, and the bottom buttons change the accessories. Just as changing the skin before a run updates the skin selection portrait, changing the accessories should display the accessories over the skin.
  4. When starting the run, you should now see the accessories on top of the skin.

# Some final notes
If you're still reading this, you are likely either interested in this mod or are reading this in some form of highly esoteric RAM mods GitHub repo README.txt -based cringe compilation.
If your case is the former, then I can't help but feel obligated to ensure you are aware of the following:
  * As a framework, this mod does not add anything of particular importance on its own. It is meant to pave the way for sprite modders to make their own accessories, which can be used with most skins.
  * This framework is meant for small changes. If your mod's new sprites cover up most of the vanilla sprite's area, then it is likely best installed as a proper skin mod rather than an accessory.
  * This mod works by overlaying sprites over the skin that you are using in your run. As such, it cannot remove parts of the underlying sprite. If you're making a mod that, for example, turns Router into Sonic the Hedgehog, this is not the mod for you. Indeed, any skin mods that involve removing anything from the silhouette* of the bot from what it is in vanilla should not be converted into accessories and used with this framework. If your skin mod keeps the same silhouette* or adds onto the silhouette*, however, then this framework may be for you.
  * Silhouette in German is "Umriss."

If your case is the latter, then the following information may also be of use to you:
  * Silhouette in German is "Umriss."
