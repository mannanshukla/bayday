import Foundation

// New York Harbor: Manhattan, Brooklyn, Queens, the Bronx, Staten Island, Jersey City and Newark.
extension Region {
 static let newYork=Region(id:"nyc",appName:"Harbor Day",tagline:"New York Harbor",latitude:40.715,longitude:-73.985,metresPerLatitude:111049.5,sites:nycSites,routes:nycRoutes,launches:nycLaunches,waterName:nycWater,neighbourhoods:nycNeighbourhoods)
 private static let nycSites:[DiscoverySite]={
  var s=[DiscoverySite]()
  s.append(DiscoverySite("Statue of Liberty",40.6892,-74.0445,150,"THE HARBOR","A gift from the people of France, dedicated in 1886. The copper skin has weathered to green, and the torch stands about 305 feet above the ground.","On a small island in the Upper Bay, southwest of the tip of Manhattan.","https://www.nps.gov/stli/"))
  s.append(DiscoverySite("Ellis Island",40.6995,-74.0396,150,"THE HARBOR","About 12 million immigrants were processed here between 1892 and 1954. The main building is now a museum of immigration.","Just north of the Statue of Liberty, close to the New Jersey shore.","https://www.nps.gov/elis/"))
  s.append(DiscoverySite("Governors Island",40.6895,-74.0168,160,"THE HARBOR","A military post for about two centuries, first for the Army and then the Coast Guard. It has been open to the public as a park since the 2000s.","The island half a mile south of Manhattan, east of the Statue of Liberty.","https://en.wikipedia.org/wiki/Governors_Island"))
  s.append(DiscoverySite("Brooklyn Bridge",40.7061,-73.9969,200,"EAST RIVER","Opened in 1883, it was the first fixed crossing of the East River and the longest suspension bridge in the world at the time. Its towers are granite and limestone.","The southernmost East River bridge, with two stone towers and pointed arches.","https://en.wikipedia.org/wiki/Brooklyn_Bridge"))
  s.append(DiscoverySite("One World Trade Center",40.7127,-74.0134,560,"LOWER MANHATTAN","The tallest building in the Western Hemisphere. Its spire reaches 1,776 feet, a reference to the year of the Declaration of Independence.","The tallest tower at the southern end of Manhattan, near the Hudson.","https://en.wikipedia.org/wiki/One_World_Trade_Center"))
  s.append(DiscoverySite("Flatiron Building",40.7411,-73.9897,220,"MIDTOWN","A steel-framed triangle completed in 1902 where Broadway crosses Fifth Avenue. It is only about six and a half feet wide at its narrow end.","Where Broadway and Fifth Avenue cross at 23rd Street, beside Madison Square Park.","https://en.wikipedia.org/wiki/Flatiron_Building"))
  s.append(DiscoverySite("Empire State Building",40.7484,-73.9857,460,"MIDTOWN","Completed in 1931 after about 13 months of construction. It was the tallest building in the world for nearly 40 years.","On Fifth Avenue at 34th Street: the stepped tower with a tall mast.","https://en.wikipedia.org/wiki/Empire_State_Building"))
  s.append(DiscoverySite("Chrysler Building",40.7516,-73.9755,340,"MIDTOWN","An Art Deco tower finished in 1930. Its stainless steel crown and eagle ornaments echo Chrysler cars of the time, and for 11 months it was the tallest building in the world.","East of Grand Central on 42nd Street: look for the silver crown of arches.","https://en.wikipedia.org/wiki/Chrysler_Building"))
  s.append(DiscoverySite("Times Square",40.7580,-73.9855,250,"MIDTOWN","Named for The New York Times, which moved here in 1904. A ball has dropped here on New Year's Eve since 1907.","Where Broadway crosses Seventh Avenue, between 42nd and 47th Streets.","https://en.wikipedia.org/wiki/Times_Square"))
  s.append(DiscoverySite("United Nations",40.7489,-73.9680,220,"MIDTOWN","The headquarters of the United Nations since the early 1950s. The 39-story Secretariat tower stands beside the East River.","A thin glass slab on the East River shore at 42nd Street.","https://en.wikipedia.org/wiki/Headquarters_of_the_United_Nations"))
  s.append(DiscoverySite("Hudson Yards",40.7538,-74.0010,320,"MIDTOWN","A district built on a platform over a working rail yard. Its first tower opened in 2016, and the public plaza and shops in 2019.","A cluster of new towers on the far west side, near the Hudson at 33rd Street.","https://en.wikipedia.org/wiki/Hudson_Yards_(development)"))
  s.append(DiscoverySite("Central Park",40.7812,-73.9665,250,"UPTOWN","843 acres in the middle of Manhattan, designed by Frederick Law Olmsted and Calvert Vaux. It opened in stages from 1858.","The long green rectangle from 59th Street to 110th Street.","https://en.wikipedia.org/wiki/Central_Park"))
  s.append(DiscoverySite("Roosevelt Island",40.7620,-73.9500,200,"EAST RIVER","A narrow island two miles long in the East River. An aerial tramway has connected it to Manhattan since 1976.","The thin island under the Queensboro Bridge.","https://en.wikipedia.org/wiki/Roosevelt_Island"))
  s.append(DiscoverySite("George Washington Bridge",40.8517,-73.9527,250,"UPTOWN","Opened in 1931 with a main span of 3,500 feet, nearly double the previous record. A lower deck was added in 1962, and it is one of the busiest bridges in the world.","The big suspension bridge over the Hudson, far uptown.","https://en.wikipedia.org/wiki/George_Washington_Bridge"))
  s.append(DiscoverySite("Yankee Stadium",40.8296,-73.9262,200,"THE BRONX","The current stadium opened in 2009, across the street from the site of the original 1923 ballpark.","In the Bronx, just east of the Harlem River.","https://en.wikipedia.org/wiki/Yankee_Stadium"))
  s.append(DiscoverySite("Unisphere",40.7464,-73.8448,200,"QUEENS","A steel globe 140 feet high, built for the 1964 New York World's Fair. The park around it also hosts the US Open tennis tournament.","In Flushing Meadows, the large park south of LaGuardia Airport.","https://en.wikipedia.org/wiki/Unisphere"))
  s.append(DiscoverySite("LaGuardia Airport",40.7769,-73.8740,200,"QUEENS","Opened in 1939 and named for Mayor Fiorello La Guardia. Its two runways are each about 7,000 feet long, and parts of them stand on decks over the water.","On the north shore of Queens, facing Rikers Island.","https://en.wikipedia.org/wiki/LaGuardia_Airport"))
  s.append(DiscoverySite("Kennedy Airport",40.6413,-73.7781,220,"QUEENS","Opened in 1948 as Idlewild Airport and renamed for President John F. Kennedy in 1963. It is the busiest international passenger gateway in the United States.","On the north shore of Jamaica Bay, at the south-east corner of the map.","https://en.wikipedia.org/wiki/John_F._Kennedy_International_Airport"))
  s.append(DiscoverySite("Prospect Park",40.6602,-73.9690,220,"BROOKLYN","Brooklyn's 526-acre park, by the designers of Central Park. It opened in 1867.","The large park in the middle of Brooklyn, with a lake at its southern end.","https://en.wikipedia.org/wiki/Prospect_Park_(Brooklyn)"))
  s.append(DiscoverySite("Coney Island",40.5749,-73.9786,160,"BROOKLYN","Beach, boardwalk and amusement rides at the southern edge of Brooklyn. The wooden Cyclone roller coaster has run since 1927.","On the Atlantic shore at the bottom of Brooklyn: look for the Ferris wheel.","https://en.wikipedia.org/wiki/Coney_Island"))
  s.append(DiscoverySite("Verrazzano-Narrows Bridge",40.6066,-74.0447,260,"THE HARBOR","It links Brooklyn and Staten Island across the Narrows. When it opened in 1964 its 4,260-foot main span was the longest in the world.","The suspension bridge at the mouth of the harbor, south of the Statue of Liberty.","https://en.wikipedia.org/wiki/Verrazzano-Narrows_Bridge"))
  s.append(DiscoverySite("St. George",40.6437,-74.0736,180,"STATEN ISLAND","The Staten Island Ferry lands here after a five-mile crossing from Manhattan. The ferry has been free since 1997.","The ferry terminal at the north-east tip of Staten Island.","https://en.wikipedia.org/wiki/St._George_Terminal"))
  s.append(DiscoverySite("Jersey City",40.7163,-74.0336,300,"NEW JERSEY","Across the Hudson from Lower Manhattan, former rail yards and docks became a district of offices and apartments. Its towers include 99 Hudson Street, the tallest building in New Jersey.","The cluster of towers on the west bank of the Hudson, opposite the World Trade Center.","https://en.wikipedia.org/wiki/Jersey_City,_New_Jersey"))
  s.append(DiscoverySite("Newark Airport",40.6895,-74.1745,220,"NEW JERSEY","Opened in 1928, it was the first major airport serving the New York area, and in the 1930s it was the busiest airport in the world.","West of Newark Bay, beside the container port.","https://en.wikipedia.org/wiki/Newark_Liberty_International_Airport"))
  return s
 }()
 private static let nycRoutes:[Route]={
  var r=[Route]()
  do {
   var g=[Place]()
   g.append(Place(name:"Governors Island",lat:40.6895,lon:-74.0168,alt:160))
   g.append(Place(name:"Statue of Liberty",lat:40.6892,lon:-74.0445,alt:150))
   g.append(Place(name:"Ellis Island",lat:40.6995,lon:-74.0396,alt:150))
   g.append(Place(name:"Jersey City",lat:40.7163,lon:-74.0336,alt:300))
   g.append(Place(name:"World Trade Center",lat:40.7127,lon:-74.0134,alt:560))
   g.append(Place(name:"The Battery",lat:40.7033,lon:-74.0170,alt:200))
   g.append(Place(name:"Brooklyn Bridge",lat:40.7061,lon:-73.9969,alt:200))
   g.append(Place(name:"Manhattan Bridge",lat:40.7075,lon:-73.9908,alt:200))
   r.append(Route(name:"Harbor loop",subtitle:"Statue of Liberty, Jersey City & the Brooklyn Bridge · 8 gates",spawn:Place(name:"The Battery",lat:40.700,lon:-74.005,alt:220),yaw:-2.45,gates:g))
  }
  do {
   var g=[Place]()
   g.append(Place(name:"Flatiron Building",lat:40.7411,lon:-73.9897,alt:300))
   g.append(Place(name:"Empire State Building",lat:40.7484,lon:-73.9857,alt:480))
   g.append(Place(name:"Times Square",lat:40.7580,lon:-73.9855,alt:350))
   g.append(Place(name:"Chrysler Building",lat:40.7516,lon:-73.9755,alt:380))
   g.append(Place(name:"United Nations",lat:40.7489,lon:-73.9680,alt:260))
   g.append(Place(name:"Roosevelt Island",lat:40.7620,lon:-73.9500,alt:220))
   g.append(Place(name:"Central Park",lat:40.7812,lon:-73.9665,alt:300))
   r.append(Route(name:"Up the avenues",subtitle:"Midtown towers, the East River & Central Park · 7 gates",spawn:Place(name:"Union Square",lat:40.730,lon:-73.991,alt:450),yaw:0.1,gates:g))
  }
  do {
   var g=[Place]()
   g.append(Place(name:"Williamsburg Bridge",lat:40.7135,lon:-73.9725,alt:220))
   g.append(Place(name:"Long Island City",lat:40.7447,lon:-73.9485,alt:300))
   g.append(Place(name:"Queensboro Bridge",lat:40.7570,lon:-73.9545,alt:240))
   g.append(Place(name:"Randalls Island",lat:40.7800,lon:-73.9270,alt:220))
   g.append(Place(name:"Yankee Stadium",lat:40.8296,lon:-73.9262,alt:220))
   g.append(Place(name:"George Washington Bridge",lat:40.8517,lon:-73.9527,alt:260))
   r.append(Route(name:"Bridges and boroughs",subtitle:"East River bridges, the Bronx & the George Washington Bridge · 6 gates",spawn:Place(name:"Brooklyn Navy Yard",lat:40.700,lon:-73.975,alt:240),yaw:0.14,gates:g))
  }
  return r
 }()
 private static let nycLaunches:[Place]={
  var l=[Place]()
  l.append(Place(name:"New York Harbor",lat:40.680,lon:-74.030,alt:180))
  l.append(Place(name:"Midtown",lat:40.742,lon:-73.992,alt:450))
  l.append(Place(name:"Brooklyn",lat:40.690,lon:-73.985,alt:300))
  l.append(Place(name:"Queens",lat:40.742,lon:-73.940,alt:300))
  l.append(Place(name:"Jersey City",lat:40.720,lon:-74.050,alt:300))
  l.append(Place(name:"George Washington Bridge",lat:40.838,lon:-73.955,alt:260))
  l.append(Place(name:"Kennedy Airport & Jamaica Bay",lat:40.620,lon:-73.820,alt:250))
  l.append(Place(name:"Coney Island",lat:40.565,lon:-73.985,alt:200))
  return l
 }()
 private static func nycWater(_ latitude:Double,_ longitude:Double)->String {
   // Rough areas, used only where the geocoder gives no name.
   // The Atlantic shore runs east-north-east along Coney Island and the Rockaway peninsula.
   if latitude<40.545 || (longitude > -74.0 && latitude<40.572+max(0,longitude+73.93)*0.237) {return "Atlantic Ocean"}
   if latitude<40.60 {return longitude > -73.93 ? "Jamaica Bay":"Lower New York Bay"}
   if latitude<40.665 && longitude > -73.93 && longitude < -73.75 {return "Jamaica Bay"}
   if longitude < -74.09 {return latitude<40.65 ? "Kill Van Kull":"Newark Bay"}
   if latitude<40.70 {return "Upper New York Bay"}
   let hudson = -74.02+(latitude-40.70)*0.5          // the Hudson's centre line runs north-north-east
   if longitude<hudson+0.012 {return "Hudson River"}
   if latitude>40.805 && longitude < -73.905 {return "Harlem River"}
   if longitude > -73.80 && latitude>40.78 {return "Long Island Sound"}
   return "East River"
 }
}
