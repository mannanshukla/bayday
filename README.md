# Bay Day

**[mannan.dev/bayday](https://mannan.dev/bayday/)** · [Download for Mac](https://github.com/mannanshukla/bayday/releases/latest/download/BayDay.zip)

A native Apple Silicon Mac flying game over San Francisco, Marin, the Peninsula and the East Bay. A floatplane flies over Apple Maps scenery, with 24 information points to collect and three timed gate routes. Requires macOS 14 or newer and an internet connection. The interface is Liquid Glass on macOS 26 and later, with a material fallback on macOS 14 and 15.

## Play

Open **build/Bay Day.app**, choose a start, and press **Start flight** (or Return).

- **Satellite** uses Apple's photographic Flyover imagery; **Apple Maps 3D** uses Apple's city models. T switches between them, and the choice is saved.
- **Explore**: pass within 140 m of a blue marker, at any altitude, to collect it. The flight record (J) lists every point, its fact and source, and can set a course to one you have not found.
- **Gate challenge**: three routes, 21 gates. Gates are numbered markers on the map; pass within 140 m of the next one. Each gate is worth 1,000 points; a bounce costs 50 and a crash 250.

| Action | Keys |
| --- | --- |
| Steer | Arrow keys / A D |
| Climb / dive | Down or S / Up or W |
| Boost / brake | Shift or E / Space or Q |
| Camera (chase, far, cockpit) | C |
| Map / flight record | M / J |
| Hide interface | H |
| Music on-off / next track | K / N |
| Restart / pause | R / P or Escape |

A gamepad's left stick steers; the right trigger boosts and the left trigger brakes. Losing window focus pauses the game.

## Flight and crash model

`Sources/Physics.swift` holds the flight model. Speed comes from thrust, drag and gravity along the flight path, so dives gain airspeed and climbs and hard turns lose it. Turn rate follows bank angle and falls with speed, so braking tightens turns. Braking in a steep climb stalls the wing until the nose comes down. The steepest possible climb eases to level flight over the last 500 m below the 2,400 m service ceiling.

Contact with terrain and water is checked along the path each frame, using the bundled elevation grid. A shallow touch bounces; a steep impact is a crash. The wreck tumbles and bounces with debris, then the flight restarts above the crash site, high enough to clear the terrain ahead. Apple's buildings are not collision objects.

## Camera and drawing

MapKit renders the scenery. A transparent Metal layer above it draws the aircraft and its effects.

The map camera is placed where a real chase camera would be: 46 m behind the aircraft (95 m in the far view) along the line of sight, looking at the ground point on that line. The Metal layer uses the same position and MapKit's 30° field of view, so the aircraft appears at its true position and height over the scenery. Where the camera has to move (MapKit will not come closer than about 114 m to the point it looks at, and the camera is kept out of hillsides), one solved position is used for both layers. The speed, altitude and height-above-ground readouts are the simulation's own values.

MapKit limits how far its camera may tilt from straight down, in steps by distance to the point it looks at: 70° within 1 km, 60° within about 2 km, 35° beyond (measured). A step would make the view jump, so the tilt is a continuous function of camera height that stays inside those limits (`MapCamera.tilt`). The consequence is that the view looks more steeply down the higher you fly, and the horizon is never in a chase view.

The cockpit view puts the camera at the pilot's eye. MapKit cannot roll or look up, so the map picture itself is rotated against the bank and slid down as the nose rises, with a sky behind it; its far edge reads as the horizon. The panel (`Sources/Cockpit.swift`) has working airspeed, attitude, altimeter, compass and climb instruments.

The aircraft does not share Apple's depth buffer, so buildings never hide it. Apple's attribution stays visible on the in-flight map, and Apple's models are never extracted or stored.

The aircraft (`Sources/Mesh.swift`) is built in code: a lofted fuselage, airfoil-section wings and tail, floats and struts, glass, and separate ailerons, elevator and rudder that follow the controls. The propeller blurs with engine speed and stops in a crash.

## Build and test

Swift, AppKit, SwiftUI, MetalKit, MapKit, AVFoundation and GameController. Apple Command Line Tools are enough.

```sh
./build.sh
./test.sh
./build/Bay\ Day.app/Contents/MacOS/BayDay --qa "$PWD/build/qa"
```

`build.sh` builds and ad-hoc signs the app. `test.sh` runs 97 checks of the flight model, crashes, the ceiling, the camera, gates, collection, pause and map transitions, saved settings and aircraft framing; test runs never touch saved progress. `--qa` saves transparent PNGs of the aircraft (four flight attitudes and a close-up) and quits. `swift scripts/make-icon.swift <aircraft-hero.png> Resources`, followed by `iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns`, rebuilds the app icon from that close-up.

`--fly <camera> <turn> <climb> <start>` starts a flight immediately with a steady control input, for checking a view without the keyboard (for example `--fly 2 0.4 0 1` for the cockpit in a right turn over downtown).

The website is the static page in `docs/`, served by GitHub Pages.

The renderer targets 60 fps and skips three of four redraws while paused. Scenery loading speed and coverage depend on Apple and the connection.

## Sources and licenses

- Scenery: Apple Maps, through the system MapKit API with its attribution.
- Elevation: [Mapzen / AWS Terrain Tiles](https://registry.opendata.aws/terrain-tiles/), including USGS sources.
- Music: "Bossa Antigua", "Backbay Lounge" and "Carefree" by Kevin MacLeod (incompetech.com), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), transcoded. The chime and crash sound are synthesized.
- Sources for the information points are linked in the flight record and recorded in `Sources/Discoveries.swift`.

The app is ad-hoc signed; public distribution would need Developer ID signing and notarization.
