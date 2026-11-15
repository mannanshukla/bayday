import Foundation

// San Francisco Bay: the city, Marin, the Peninsula and the East Bay.
extension Region {
 static let sanFrancisco=Region(id:"sf",name:"San Francisco",tagline:"San Francisco Bay",latitude:37.76,longitude:-122.38,metresPerLatitude:110990,sites:sfSites,routes:sfRoutes,launches:sfLaunches,waterName:sfWater,music:"bossa-antigua")
 private static let sfSites:[DiscoverySite]={
  var s=[DiscoverySite]()
  s.append(DiscoverySite("Golden Gate Bridge",37.8199,-122.4783,180,"THE GOLDEN GATE","That famous color is International Orange. The bridge connects San Francisco to Marin across the narrow entrance between the Pacific and the bay.","Follow the orange towers north from the Presidio.","https://www.goldengate.org/bridge/history-research/"))
  s.append(DiscoverySite("Alcatraz",37.8267,-122.423,160,"ISLAND HOPPING","A fortress, a prison, and a place of Native American activism: this small island has many layers of history. Its cellhouse and lighthouse make an unmistakable silhouette.","Look for the rocky island between the city and Angel Island.","https://www.nps.gov/alca/learn/historyculture/index.htm"))
  s.append(DiscoverySite("Coit Tower",37.8024,-122.4058,220,"SAN FRANCISCO","The pale tower on Telegraph Hill has watched over the waterfront since 1933. Inside, murals tell stories of California life during the Depression.","Find the white column on the hill above the northeast waterfront.","https://www.sfrecpark.org/684/Points-of-Interest"))
  s.append(DiscoverySite("Transamerica Pyramid",37.7952,-122.4028,300,"SAN FRANCISCO","A sharp point among the city’s flat rooftops! The Transamerica Pyramid is one of San Francisco’s most recognizable buildings, with a grove of redwoods at its base.","Search for the pointed tower south of Coit Tower.","https://www.thepyramid.com/"))
  s.append(DiscoverySite("Salesforce Tower",37.7897,-122.3966,380,"SAN FRANCISCO","The rounded crown belongs to San Francisco’s tallest tower. Nearby, Salesforce Park is an elevated garden stretching across the roof of the transit center.","Climb above the tallest rounded tower in the downtown skyline.","https://salesforcetransitcenter.com/salesforce-park/"))
  s.append(DiscoverySite("Palace of Fine Arts",37.8029,-122.4484,150,"SAN FRANCISCO","This rotunda began as part of the 1915 Panama-Pacific exhibition. Its classical columns and lagoon make a surprisingly quiet corner of the Marina.","Look just inland from the waterfront, east of the Presidio.","https://www.sfrecpark.org/684/Points-of-Interest"))
  s.append(DiscoverySite("Golden Gate Park",37.7694,-122.4862,220,"SAN FRANCISCO","A huge green rectangle reaches almost to the ocean. Golden Gate Park holds gardens, lakes, museums, and winding paths inside the city’s street grid.","Follow the long green park west toward the Pacific.","https://www.sfrecpark.org/684/Points-of-Interest"))
  s.append(DiscoverySite("Twin Peaks",37.7544,-122.4477,430,"SAN FRANCISCO","Two neighboring summits rise above the center of San Francisco. From here the street grid fans out toward downtown, the bay, and the Pacific.","Climb over the two bare hills south of Golden Gate Park.","https://sfrecpark.org/Facilities/Facility/Details/Twin-Peaks-384"))
  s.append(DiscoverySite("Bay Bridge",37.798,-122.377,200,"ACROSS THE BAY","This crossing is really a sequence of bridges joined at Yerba Buena Island. The western suspension spans and the eastern span have distinctly different shapes.","Fly east from the downtown waterfront toward Yerba Buena Island.","https://www.bayareafastrak.org/en/bridges/san-francisco-oakland-bridge.shtml"))
  s.append(DiscoverySite("Sausalito",37.859,-122.485,180,"MARIN","Hillside homes face a sheltered waterfront in this Marin town. The bay is calmer here than at the ocean-facing cliffs just over the ridge.","Follow the Marin shoreline north from the Golden Gate.","https://www.discoversausalito.com/"))
  s.append(DiscoverySite("Mount Tamalpais",37.9235,-122.5965,900,"MARIN","Mount Tam rises above Marin’s ridges and forests. On clear days, its high slopes reveal the bay on one side and the Pacific on the other.","Head northwest and climb toward Marin’s tallest ridge.","https://www.parks.ca.gov/?page_id=471"))
  s.append(DiscoverySite("Oakland",37.8044,-122.2712,240,"EAST BAY","Oakland’s waterfront, downtown, and hillside neighborhoods share the sunny side of the bay. The port’s container cranes stand along the western shoreline.","Cross the Bay Bridge and continue southeast toward downtown Oakland.","https://www.visitoakland.com/"))
  s.append(DiscoverySite("Berkeley",37.8715,-122.273,260,"EAST BAY","From the waterfront, Berkeley climbs toward its university campus and the East Bay hills. Its rectangular street grid is easy to trace from above.","Follow the East Bay shoreline north from Oakland.","https://www.visitberkeley.com/"))
  s.append(DiscoverySite("San Francisco Airport",37.6213,-122.379,200,"THE PENINSULA","SFO’s long runways project into the bay. From the air, the runway pairs and their surrounding taxiways form a distinctive geometric pattern.","Look along the eastern Peninsula shoreline, south of the city.","https://www.flysfo.com/"))
  s.append(DiscoverySite("San Mateo Bridge",37.596,-122.25,180,"SOUTH BAY","A long, low causeway links the Peninsula with the East Bay. Compared with the Golden Gate, much of this crossing sits close to the water.","Look southeast of SFO for the long crossing over open water.","https://www.bayareafastrak.org/en/bridges/san-mateo-hayward-bridge.shtml"))
  s.append(DiscoverySite("Angel Island",37.86,-122.432,420,"ISLAND HOPPING","This island is a state park with a complicated past. Its immigration station processed and detained immigrants, particularly from Asia; preserved buildings tell their stories.","Climb over the large hilly island north of Alcatraz.","https://www.parks.ca.gov/?page_id=1309"))
  s.append(DiscoverySite("Crissy Field",37.803,-122.466,140,"THE GOLDEN GATE","Before it became a waterfront park, Crissy Field was an Army airfield. A fitting place for a little sightseeing flight to begin!​","Find the open shoreline on the city side of the Golden Gate.","https://www.nps.gov/prsf/learn/historyculture/crissy-field.htm"))
  s.append(DiscoverySite("Ferry Building",37.7955,-122.3937,160,"SAN FRANCISCO","The waterfront clock tower marks the foot of Market Street. Ferries still connect this landmark with communities around the bay.","Follow the downtown shoreline to the clock tower.","https://www.ferrybuildingmarketplace.com/"))
  s.append(DiscoverySite("City Hall",37.7793,-122.4192,220,"SAN FRANCISCO","A grand dome crowns San Francisco’s Civic Center. Its broad courtyards and formal street layout stand out from the surrounding neighborhoods.","Look southwest of downtown for the large civic dome.","https://www.sf.gov/location/san-francisco-city-hall"))
  s.append(DiscoverySite("Sutro Tower",37.7552,-122.4528,670,"SAN FRANCISCO","Three tall legs and red-and-white antenna masts make Sutro Tower a local landmark. It helps broadcast television and radio across the region.","Climb west of Twin Peaks toward the three-legged tower.","https://sutrotower.com/"))
  s.append(DiscoverySite("Ocean Beach",37.759,-122.510,140,"PACIFIC COAST","The city ends in a long sweep of sand facing the Pacific. This open coast is a very different world from the sheltered water inside the bay.","Follow the western edge of San Francisco south from the park.","https://www.nps.gov/goga/planyourvisit/oceanbeach.htm"))
  s.append(DiscoverySite("Lands End",37.782,-122.506,200,"PACIFIC COAST","Rocky bluffs turn from the ocean toward the Golden Gate. Coastal trails here wind past cypress trees, headlands, and views of the bridge.","Follow the coast around San Francisco’s northwest corner.","https://www.nps.gov/goga/planyourvisit/landsend.htm"))
  s.append(DiscoverySite("Oracle Park",37.7786,-122.3893,180,"SAN FRANCISCO","The Giants’ ballpark sits right against the water. Beyond the right-field wall, McCovey Cove is famous for boats waiting for splash-hit home runs.","Look for the waterfront baseball diamond south of the Bay Bridge.","https://www.mlb.com/giants/ballpark"))
  s.append(DiscoverySite("Presidio",37.798,-122.455,210,"THE GOLDEN GATE","Once a military post, the Presidio is now part of the national park landscape. Forest, historic buildings, and open spaces fill the city’s northwest corner.","Explore the wooded land behind Crissy Field.","https://presidio.gov/about/history"))
  return s
 }()
 private static let sfRoutes:[Route]={
  var r=[Route]()
  do {
   var g=[Place]()
   g.append(Place(name:"Presidio shoreline",lat:37.806,lon:-122.480,alt:180))
   g.append(Place(name:"Golden Gate",lat:37.820,lon:-122.479,alt:125))
   g.append(Place(name:"Marin Headlands",lat:37.834,lon:-122.481,alt:280))
   g.append(Place(name:"Sausalito",lat:37.849,lon:-122.478,alt:220))
   g.append(Place(name:"Angel Island",lat:37.850,lon:-122.444,alt:300))
   g.append(Place(name:"Alcatraz",lat:37.827,lon:-122.423,alt:200))
   g.append(Place(name:"Fisherman’s Wharf",lat:37.810,lon:-122.416,alt:190))
   g.append(Place(name:"Palace of Fine Arts",lat:37.803,lon:-122.448,alt:210))
   r.append(Route(name:"Golden Gate circuit",subtitle:"Bridge, headlands & island hopping · 8 gates",spawn:Place(name:"Golden Gate",lat:37.794,lon:-122.480,alt:200),yaw:0,gates:g))
  }
  do {
   var g=[Place]()
   g.append(Place(name:"Salesforce Tower",lat:37.7897,lon:-122.394,alt:410))
   g.append(Place(name:"Coit Tower",lat:37.8024,lon:-122.4058,alt:260))
   g.append(Place(name:"City Hall",lat:37.7793,lon:-122.4192,alt:240))
   g.append(Place(name:"Twin Peaks",lat:37.7544,lon:-122.4477,alt:440))
   g.append(Place(name:"Golden Gate Park",lat:37.7694,lon:-122.4862,alt:250))
   g.append(Place(name:"Ocean Beach",lat:37.770,lon:-122.513,alt:180))
   g.append(Place(name:"Lands End",lat:37.782,lon:-122.506,alt:220))
   r.append(Route(name:"City & coast",subtitle:"Skyline, Twin Peaks & Ocean Beach · 7 gates",spawn:Place(name:"Downtown",lat:37.775,lon:-122.391,alt:440),yaw:0,gates:g))
  }
  do {
   var g=[Place]()
   g.append(Place(name:"Western span",lat:37.799,lon:-122.375,alt:220))
   g.append(Place(name:"Yerba Buena Island",lat:37.811,lon:-122.363,alt:230))
   g.append(Place(name:"Eastern span",lat:37.819,lon:-122.340,alt:190))
   g.append(Place(name:"Oakland",lat:37.8044,lon:-122.2712,alt:300))
   g.append(Place(name:"Berkeley",lat:37.867,lon:-122.282,alt:320))
   g.append(Place(name:"Treasure Island",lat:37.825,lon:-122.370,alt:230))
   r.append(Route(name:"Across the bay",subtitle:"Bay Bridge, Oakland & Berkeley · 6 gates",spawn:Place(name:"Bay Bridge",lat:37.782,lon:-122.383,alt:240),yaw:0.45,gates:g))
  }
  return r
 }()
 private static let sfLaunches:[Place]={
  var l=[Place]()
  l.append(Place(name:"Golden Gate",lat:37.811,lon:-122.478,alt:180))
  l.append(Place(name:"Downtown",lat:37.775,lon:-122.391,alt:440))
  l.append(Place(name:"Marin Headlands",lat:37.842,lon:-122.514,alt:560))
  l.append(Place(name:"Oakland",lat:37.790,lon:-122.290,alt:330))
  l.append(Place(name:"SFO & Peninsula",lat:37.605,lon:-122.370,alt:250))
  l.append(Place(name:"Mount Tamalpais",lat:37.916,lon:-122.59,alt:1000))
  l.append(Place(name:"Oracle Park",lat:37.7747,lon:-122.3893,alt:200))
  return l
 }()
 private static func sfWater(_ latitude:Double,_ longitude:Double)->String {
   if longitude < -122.53 || (longitude < -122.505 && latitude<37.80) {return "Pacific Ocean"}
   if latitude>37.80 && latitude<37.835 && longitude < -122.47 {return "Golden Gate"}
   return "San Francisco Bay"
 }
}
