# Coordenadas Forever

Player and cursor coordinates for World of Warcraft: Forever, plus waypoints with an arrow and distance.

## Features

- Your coordinates in the bottom left corner of the world map.
- The cursor's coordinates in the bottom right corner while the mouse is over the map.
- A small box on screen with your zone and coordinates. Drag it wherever you like; its position is saved per character.
- Waypoints: `/way 46 74` puts a marker on the map, and the box shows an arrow and the distance until you get there. The waypoint clears itself when you arrive.
- Waypoints in other zones: `/way The Barrens 46 74`. Use the zone name as your client shows it. Case and accents don't matter, and part of the name is enough if it only matches one zone.

The game's own coordinates panel on the world map is hidden while the addon's coordinates are on, so they don't show twice. Turn both of ours off (`/coords map` and `/coords cursor`) and the game's panel comes back.

## Commands

| Command | What it does |
| --- | --- |
| `/way 46 74` | Waypoint in the zone you are in, or the one open on the map |
| `/way 46 74 camp` | Same, with a label |
| `/way The Barrens 46 74` | Waypoint in another zone |
| `/way clear` | Remove the waypoint |
| `/way status` | Print what the addon knows, for bug reports |
| `/coords` | Show or hide the box |
| `/coords lock` | Lock or unlock the box |
| `/coords reset` | Move the box back to the top of the screen |
| `/coords scale 1.5` | Box size, from 0.5 to 3 |
| `/coords map` | Toggle your coordinates on the map |
| `/coords cursor` | Toggle the cursor coordinates on the map |

`/ir` works the same as `/way`, and `/cf` the same as `/coords`.

Commands are in English on every client; only the messages are translated.

If you use TomTom, both addons register `/way` and only one of them will get it.

## Languages

English, Spanish, German, French, Italian, Portuguese, Russian, Korean, and Simplified and Traditional Chinese. Other languages use English.

The output of `/way status` and `/coords pos` is always in English so it can be pasted into bug reports.

## Compatibility

Made for World of Warcraft: Forever 1.60.1 (`Interface: 16001`).

## Installation

1. Extract the `CoordsForever` folder into `World of Warcraft\_classic_beta_\Interface\AddOns\`
2. Restart the game.
3. Check that it's enabled in the AddOns list on the character screen.

## License

MIT
