# Changelog

## 1.11

- New look shared with the other Forever addons: the options window is dark glass with bronze lines, buttons have relief and a gold edge under the mouse, and ticks are gold. The on-screen box has a bronze edge.
- The waypoint on the world map and the minimap is a gold dot with a ring pulsing out of it, instead of the diamond.
- The arrow next to the waypoint distance can be bigger or smaller, from 12 to 48, in the options or with `/coords arrow 24`.

## 1.10

- The waypoint now shows on the minimap too. If it's too far to fit, an arrow on the edge points towards it. Works with the rotating minimap and with square minimaps from other addons.
- Hover the minimap marker to see the label, zone and distance.
- New options window (`/coords options`) with the box, world map and minimap settings. It has a button to centre the box horizontally and the list of commands on the side.
- Minimap button: left click opens the options, right click shows or hides the box. Drag it to move it around the minimap. Hide it from the options or with `/coords button`, which also brings it back.
- `/coords minimap` turns the waypoint on the minimap on or off.

## 1.09

- English zone names work with `/way` on every client, so waypoints from English guides work in any language.
- `/way` accepts the map number format copied from Wowhead: `/way #1413 46.1 74.9`.
- Brackets and parentheses around the coordinates are ignored: `/way [46.1, 74.9]`.

## 1.08

- Translated into all ten WoW client languages, with English as the default.
- Commands are now English on every client: `/way clear` and `/way status`.
- Zone names in Russian, Korean and Chinese now work with `/way`.
- The game's own coordinates panel on the world map is hidden while the addon's coordinates are on, so they no longer show twice.
- The waypoint clears itself when you arrive.

## 1.07

First public release.

- Player and cursor coordinates on the world map.
- Movable on-screen box with zone and coordinates, saved per character.
- Waypoints with arrow and distance: `/way 46 74`.
- Waypoints in other zones: `/way Los Baldíos 46 74`.
