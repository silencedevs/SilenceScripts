<h1><img src="./assets/silence-logo-round.png" alt="Silence logo" width="40" height="40" align="top"> Silence Scripts</h1>

Silence is a multi-game Roblox script project with automatic game detection and dedicated features for each supported experience.

## Supported Games

- Muscle Legends
- Tap Simulator
- Steal An Egg
  
## Usage

1. Join one of the supported games.
2. Run the following loader in your executor of choice:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/silencedevs/SilenceScripts/main/Loader/Loader.luau"))()
```

3. Enter the key "SOT" when prompted.
4. Select **Execute Silence**. The loader will automatically load the correct script for your game.

## Steal An Egg

`Scripts/stealaneg.luau` uses the custom EleriumV2 library. It includes filtered
egg stealing and delivery, placement, hatching, protected selling, pet equipment,
fusion, upgrades, trails, ESP, player settings, server navigation, and selected
race and event helpers. Automation defaults to off. Selling, fusion, and shop
actions consume items or in-game currency when enabled.

The loader entry becomes available remotely after these files are published to
the repository. For local executor tests, execute `Scripts/stealaneg.luau` directly.
The script downloads EleriumV2 and its modules from this repository's main branch.

## Links

- [Website](https://silencestudios.vercel.app/)
- [Discord](https://discord.gg/9eFf93Kg8D)

## License

This project is licensed under the [MIT License](LICENSE).

## Disclaimer

This project is provided for educational purposes only. Use it responsibly and at your own risk. Silence is not affiliated with, endorsed by, or associated with Roblox Corporation or any of the supported games.
