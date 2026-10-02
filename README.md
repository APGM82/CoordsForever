# Coordenadas Forever

Player and cursor coordinates for World of Warcraft: Forever, plus waypoints with an arrow and distance.

The in-game text is in Spanish.

## Features

- Your coordinates in the bottom left corner of the world map.
- The cursor's coordinates in the bottom right corner while the mouse is over the map.
- A small box on screen with your zone and coordinates. Drag it wherever you like; its position is saved per character.
- Waypoints: `/way 46 74` puts a marker on the map, and the box shows an arrow and the distance until you get there.
- Waypoints in other zones: `/way Los Baldíos 46 74`. Case and accents don't matter, and part of the name is enough if it only matches one zone.

## Commands

| Command | What it does |
| --- | --- |
| `/way 46 74` | Waypoint in the zone you are in, or the one open on the map |
| `/way 46 74 tower` | Same, with a label |
| `/way Los Baldíos 46 74` | Waypoint in another zone |
| `/way borrar` | Remove the waypoint |
| `/way estado` | Print what the addon knows, for bug reports |
| `/coords` | Show or hide the box |
| `/coords lock` | Lock or unlock the box |
| `/coords reset` | Move the box back to the top of the screen |
| `/coords scale 1.5` | Box size, from 0.5 to 3 |
| `/coords map` | Toggle your coordinates on the map |
| `/coords cursor` | Toggle the cursor coordinates on the map |

`/ir` works the same as `/way`, and `/cf` the same as `/coords`.

If you use TomTom, both addons register `/way` and only one of them will get it.

## Compatibility

Made for World of Warcraft: Forever 1.60.1 (`Interface: 16001`).

## Installation

1. Extract the `CoordsForever` folder into `World of Warcraft\_classic_beta_\Interface\AddOns\`
2. Restart the game.
3. Check that it's enabled in the AddOns list on the character screen.

## License

MIT
