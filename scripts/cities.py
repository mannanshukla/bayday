#!/usr/bin/env python3
"""Writes Resources/regions/<id>/region.json for the cities described below.

Each site is (name, latitude, longitude, group, fact, hint, Wikipedia title). Routes are
(name, subtitle, spawn (name, lat, lon, alt), [gate names or (name, lat, lon)]); a gate named
after a site takes that site's position. Run: python3 scripts/cities.py
"""
import json, os, sys

W = "https://en.wikipedia.org/wiki/"
CITIES = [
 dict(id="london", name="London", country="United Kingdom", flag="🇬🇧", greeting="Hello", tagline="The Thames", latitude=51.505, longitude=-0.11, water="River Thames", music="george-street-shuffle",
  sites=[
   ("Tower Bridge",51.5055,-0.0754,"THE RIVER","Opened in 1894. The roadway splits into two bascules that lift to let tall ships through, around 800 times a year.","The bridge with two stone towers, just east of the Tower of London.","Tower_Bridge"),
   ("Big Ben",51.5007,-0.1246,"WESTMINSTER","Big Ben is the nickname of the great bell, not the tower. The tower itself was renamed the Elizabeth Tower in 2012.","The clock tower at the north end of the Houses of Parliament, beside Westminster Bridge.","Big_Ben"),
   ("London Eye",51.5033,-0.1196,"THE RIVER","A 135-metre observation wheel opened in 2000. One turn takes about half an hour.","The big wheel on the south bank, across the river from Westminster.","London_Eye"),
   ("St Paul's Cathedral",51.5138,-0.0984,"THE CITY","Christopher Wren's cathedral was completed in 1710, after the Great Fire of 1666 destroyed the one before it. Its dome is 111 metres high.","The great dome in the City, north of the Millennium Bridge.","St_Paul%27s_Cathedral"),
   ("The Shard",51.5045,-0.0865,"THE RIVER","At 310 metres, the tallest building in the United Kingdom. It was completed in 2012.","The glass spike beside London Bridge station, south of the river.","The_Shard"),
   ("Buckingham Palace",51.5014,-0.1419,"WESTMINSTER","The monarch's London home since 1837. It has 775 rooms.","At the end of the Mall, between Green Park and St James's Park.","Buckingham_Palace"),
   ("Tower of London",51.5081,-0.0759,"THE CITY","William the Conqueror began the White Tower in the 1070s. The Crown Jewels are kept here.","The castle on the north bank beside Tower Bridge.","Tower_of_London"),
   ("Hyde Park",51.5073,-0.1657,"WEST LONDON","350 acres, open to the public since 1637. The Serpentine lake was made in the 1730s.","The large park west of Mayfair, with a long curved lake.","Hyde_Park,_London"),
   ("Canary Wharf",51.5054,-0.0235,"DOCKLANDS","A financial district built on the old West India Docks from the late 1980s. One Canada Square was Britain's tallest building until the Shard.","The cluster of towers inside the big loop of the river to the east.","Canary_Wharf"),
   ("Royal Observatory",51.4769,-0.0005,"GREENWICH","The prime meridian, zero degrees longitude, runs through this hilltop observatory, founded in 1675.","On the hill in Greenwich Park, south of the river bend.","Royal_Observatory,_Greenwich"),
   ("Wembley Stadium",51.5560,-0.2796,"NORTH WEST","England's national football stadium, rebuilt and reopened in 2007. Its arch is 133 metres high.","Look for the white arch, far to the north-west.","Wembley_Stadium"),
   ("Battersea Power Station",51.4821,-0.1445,"THE RIVER","A coal-fired power station with four chimneys, built between 1929 and 1955. After decades empty it reopened in 2022 with shops, offices and homes.","Four white chimneys on the south bank, upstream of Westminster.","Battersea_Power_Station"),
  ],
  routes=[("Along the Thames","Battersea to Canary Wharf · 6 gates",("Chelsea",51.4850,-0.1750,280),["Battersea Power Station","Big Ben","London Eye","St Paul's Cathedral","Tower Bridge","Canary Wharf"]),
          ("Parks and palaces","Hyde Park to the Tower · 5 gates",("Paddington",51.5200,-0.1950,320),["Hyde Park","Buckingham Palace","Big Ben","The Shard","Tower of London"])],
  launches=[("Westminster",51.495,-0.140,300),("The City",51.510,-0.100,350),("Canary Wharf",51.500,-0.040,300),("Greenwich",51.470,-0.010,260),("Wembley",51.550,-0.260,300)]),
 dict(id="paris", name="Paris", country="France", flag="🇫🇷", greeting="Bonjour", tagline="The Seine", latitude=48.858, longitude=2.33, water="the Seine", music="parisian",
  sites=[
   ("Eiffel Tower",48.8584,2.2945,"LEFT BANK","Built for the 1889 World's Fair and meant to stand for only 20 years. It was the tallest structure in the world until 1930, and with its antennas it now reaches 330 metres.","The iron tower beside the Seine, at the end of the Champ de Mars.","Eiffel_Tower"),
   ("Arc de Triomphe",48.8738,2.2950,"RIGHT BANK","Ordered by Napoleon in 1806 and finished in 1836. Twelve avenues meet at its roundabout.","At the top of the Champs-Élysées, in the middle of a star of avenues.","Arc_de_Triomphe"),
   ("Louvre",48.8606,2.3376,"RIGHT BANK","A royal palace that became a museum in 1793. The glass pyramid in its courtyard was added in 1989.","The long palace on the right bank, with a glass pyramid in its courtyard.","Louvre"),
   ("Notre-Dame",48.8530,2.3499,"THE ISLANDS","Begun in 1163 on an island in the Seine. It reopened in December 2024 after the fire of 2019.","On the Île de la Cité, the larger of the two islands in the river.","Notre-Dame_de_Paris"),
   ("Sacré-Cœur",48.8867,2.3431,"MONTMARTRE","A white basilica on the hill of Montmartre, the highest point in Paris. It was completed in 1914.","The white domes on the hill in the north of the city.","Sacr%C3%A9-C%C5%93ur,_Paris"),
   ("Les Invalides",48.8566,2.3125,"LEFT BANK","Founded by Louis XIV in 1670 as a home for old soldiers. Napoleon's tomb lies under the golden dome.","The golden dome south of the river, east of the Eiffel Tower.","Les_Invalides"),
   ("Panthéon",48.8462,2.3464,"LEFT BANK","Finished in 1790 as a church and soon made a resting place for great French citizens, among them Voltaire, Victor Hugo and Marie Curie.","The dome on the hill of the Latin Quarter, south of Notre-Dame.","Panth%C3%A9on"),
   ("Montparnasse Tower",48.8421,2.3220,"LEFT BANK","A 210-metre office tower completed in 1973. It was so unpopular that the city banned tall buildings in the centre soon after.","The lone dark tower south-west of the Luxembourg Garden.","Tour_Montparnasse"),
   ("La Défense",48.8925,2.2360,"WEST","The business district west of the city. The Grande Arche, opened in 1989, lines up with the Arc de Triomphe and the Louvre.","The cluster of towers west of the Arc de Triomphe, across the river.","La_D%C3%A9fense"),
   ("Place de la Concorde",48.8656,2.3212,"RIGHT BANK","The largest square in Paris. Its Egyptian obelisk, about 3,300 years old, came from Luxor in the 1830s.","The open square at the foot of the Champs-Élysées, by the river.","Place_de_la_Concorde"),
   ("Stade de France",48.9245,2.3601,"NORTH","The national stadium, built for the 1998 World Cup, with room for about 80,000.","The white ring of a stadium in Saint-Denis, north of the city.","Stade_de_France"),
   ("Bois de Boulogne",48.8620,2.2490,"WEST","A royal hunting ground turned into a park in the 1850s. It is about two and a half times the size of New York's Central Park.","The big wood along the western edge of the city.","Bois_de_Boulogne"),
  ],
  routes=[("Along the Seine","Notre-Dame to the Bois de Boulogne · 6 gates",("Bercy",48.8350,2.3850,300),["Notre-Dame","Louvre","Place de la Concorde","Les Invalides","Eiffel Tower","Bois de Boulogne"]),
          ("The grand axis","The Louvre to La Défense, then Montmartre · 5 gates",("Bastille",48.8530,2.3700,320),["Louvre","Place de la Concorde","Arc de Triomphe","La Défense","Sacré-Cœur"])],
  launches=[("Eiffel Tower",48.845,2.290,350),("Île de la Cité",48.842,2.350,300),("Montmartre",48.875,2.340,400),("La Défense",48.885,2.215,350)]),
 dict(id="tokyo", name="Tokyo", localName="東京", country="Japan", flag="🇯🇵", greeting="こんにちは", tagline="Tokyo Bay", latitude=35.66, longitude=139.76, water="Tokyo Bay", music="ishikari-lore",
  sites=[
   ("Tokyo Tower",35.6586,139.7454,"MINATO","Completed in 1958 and 333 metres tall. It is painted white and international orange for air safety.","The orange and white lattice tower south of the Imperial Palace.","Tokyo_Tower"),
   ("Tokyo Skytree",35.7101,139.8107,"SUMIDA","At 634 metres, the tallest tower in the world. It opened in 2012.","The very tall pale tower east of the Sumida River.","Tokyo_Skytree"),
   ("Imperial Palace",35.6852,139.7528,"CHIYODA","The home of the Emperor, on the site of Edo Castle. The castle's moats and stone walls remain.","The green island of trees and moats in the middle of the city.","Tokyo_Imperial_Palace"),
   ("Shibuya Crossing",35.6595,139.7005,"SHIBUYA","Often called the busiest pedestrian crossing in the world. Traffic stops in every direction at once and people cross all ways.","Outside Shibuya Station, in the west of the city.","Shibuya_Crossing"),
   ("Sensō-ji",35.7148,139.7967,"ASAKUSA","Tokyo's oldest temple, founded in 645 according to tradition. A giant red lantern hangs in its Thunder Gate.","In Asakusa, near the Sumida River, a little west of the Skytree.","Sens%C5%8D-ji"),
   ("Tokyo Station",35.6812,139.7671,"CHIYODA","The red-brick station building opened in 1914. Shinkansen bullet trains leave from here.","Just east of the Imperial Palace gardens.","Tokyo_Station"),
   ("Shinjuku",35.6896,139.6917,"SHINJUKU","The twin-towered Tokyo Metropolitan Government Building opened in 1991. Shinjuku Station nearby is the busiest railway station in the world.","The cluster of skyscrapers in the west, north of Shibuya.","Tokyo_Metropolitan_Government_Building"),
   ("Rainbow Bridge",35.6365,139.7633,"THE BAY","A suspension bridge across the northern part of Tokyo Bay, opened in 1993. It links the city to the man-made island of Odaiba.","The white suspension bridge over the harbour, south of Tokyo Tower.","Rainbow_Bridge_(Tokyo)"),
   ("Meiji Shrine",35.6764,139.6993,"SHIBUYA","A Shinto shrine to Emperor Meiji, completed in 1920. The forest around it was planted with about 100,000 donated trees.","The dense forest between Shibuya and Shinjuku.","Meiji_Shrine"),
   ("Haneda Airport",35.5494,139.7798,"THE BAY","Tokyo's main domestic airport and one of the busiest in the world, built on reclaimed land at the edge of the bay.","On the bay shore, well south of the city centre.","Haneda_Airport"),
   ("Ueno Park",35.7148,139.7734,"TAITO","One of Japan's first public parks, established in 1873. It is known for its museums and its cherry blossom.","The park with a pond, north-east of the Imperial Palace.","Ueno_Park"),
   ("Tokyo Dome",35.7056,139.7519,"BUNKYO","A stadium opened in 1988, home of the Yomiuri Giants baseball team. Its white roof is held up by air pressure.","The white dome north of the Imperial Palace.","Tokyo_Dome"),
  ],
  routes=[("Bay to temple","Rainbow Bridge to Asakusa · 6 gates",("Tokyo Bay",35.6050,139.7900,280),["Rainbow Bridge","Tokyo Tower","Imperial Palace","Tokyo Station","Tokyo Skytree","Sensō-ji"]),
          ("West side","Shibuya to Ueno · 5 gates",("Meguro",35.6300,139.7050,350),["Shibuya Crossing","Meiji Shrine","Shinjuku","Tokyo Dome","Ueno Park"])],
  launches=[("Tokyo Bay",35.610,139.800,250),("Shibuya",35.645,139.700,380),("Asakusa",35.700,139.800,350),("Haneda",35.560,139.810,250)]),
 dict(id="sydney", name="Sydney", country="Australia", flag="🇦🇺", greeting="G'day", tagline="Sydney Harbour", latitude=-33.86, longitude=151.21, water="Sydney Harbour", music="easy-lemon",
  sites=[
   ("Sydney Opera House",-33.8568,151.2153,"THE HARBOUR","Designed by Jørn Utzon and opened in 1973, ten years later than planned. Its shells are covered in more than a million tiles.","The white sails on the point east of the Harbour Bridge.","Sydney_Opera_House"),
   ("Sydney Harbour Bridge",-33.8523,151.2108,"THE HARBOUR","Opened in 1932. Locals call the steel arch the Coathanger; its top is 134 metres above the water.","The steel arch across the harbour, beside the Opera House.","Sydney_Harbour_Bridge"),
   ("Bondi Beach",-33.8908,151.2743,"THE COAST","About a kilometre of sand on the Pacific. Its surf lifesaving club, founded in 1907, is among the oldest in the world.","The crescent beach on the ocean, east of the city.","Bondi_Beach"),
   ("Sydney Tower",-33.8704,151.2093,"THE CITY","At 309 metres, the tallest structure in Sydney. It opened to the public in 1981.","The golden turret on a thin shaft in the middle of the city.","Sydney_Tower"),
   ("Darling Harbour",-33.8748,151.2009,"THE CITY","Once a busy cargo port, rebuilt as a waterfront of museums, parks and promenades for Australia's bicentenary in 1988.","The narrow inlet on the western side of the city centre.","Darling_Harbour"),
   ("Taronga Zoo",-33.8433,151.2411,"THE HARBOUR","Opened in 1916 on the north shore of the harbour. Many visitors arrive by ferry.","On the wooded north shore, across the water from the Opera House.","Taronga_Zoo_Sydney"),
   ("Manly",-33.7969,151.2885,"THE COAST","A beach suburb on a neck of land between the harbour and the ocean, half an hour by ferry from the city.","Near North Head, at the northern side of the harbour entrance.","Manly,_New_South_Wales"),
   ("Royal Botanic Garden",-33.8642,151.2166,"THE HARBOUR","Established in 1816, which makes it the oldest scientific institution in Australia.","The gardens around the bay just east of the Opera House.","Royal_Botanic_Garden,_Sydney"),
   ("Sydney Cricket Ground",-33.8917,151.2247,"THE CITY","Cricket has been played on this ground since the middle of the 1800s.","The stadiums in Moore Park, south-east of the centre.","Sydney_Cricket_Ground"),
   ("Sydney Airport",-33.9399,151.1753,"BOTANY BAY","In use since 1920, one of the oldest continuously operating commercial airports in the world. Two of its runways reach out into Botany Bay.","On the north shore of Botany Bay, south of the city.","Sydney_Airport"),
   ("South Head",-33.8335,151.2810,"THE HARBOUR","The southern headland of the harbour entrance. The red and white Hornby Lighthouse has guided ships in since 1858.","The tip of the peninsula past Watsons Bay, facing North Head.","South_Head_(Sydney)"),
   ("Sydney Olympic Park",-33.8474,151.0677,"WEST","Built for the 2000 Olympic Games on former industrial land beside the Parramatta River.","Far up the Parramatta River, west of the city.","Sydney_Olympic_Park"),
  ],
  routes=[("Harbour run","Darling Harbour to Manly · 6 gates",("Glebe",-33.8850,151.1850,280),["Darling Harbour","Sydney Harbour Bridge","Sydney Opera House","Taronga Zoo","South Head","Manly"]),
          ("City to surf","The Botanic Garden to Bondi · 5 gates",("North Sydney",-33.8400,151.2080,320),["Royal Botanic Garden","Sydney Tower","Sydney Cricket Ground","Bondi Beach","South Head"])],
  launches=[("Sydney Harbour",-33.845,151.225,250),("The city",-33.885,151.205,350),("Bondi",-33.900,151.260,260),("Manly",-33.810,151.290,260)]),
 dict(id="rome", name="Rome", localName="Roma", country="Italy", flag="🇮🇹", greeting="Ciao", tagline="The Tiber", latitude=41.90, longitude=12.48, water="the Tiber", music="laid-back-guitars",
  sites=[
   ("Colosseum",41.8902,12.4922,"ANCIENT ROME","Opened in AD 80. It held around 50,000 spectators and is still the largest amphitheatre ever built.","The great oval ruin east of the Forum.","Colosseum"),
   ("St. Peter's Basilica",41.9022,12.4539,"VATICAN","The dome, designed by Michelangelo, rises about 136 metres. The present church was completed in 1626.","The huge dome west of the Tiber, behind an oval square.","St._Peter%27s_Basilica"),
   ("Pantheon",41.8986,12.4769,"CENTRE","Completed around AD 126. Its dome is still the largest unreinforced concrete dome in the world, open to the sky at the top.","A low grey dome in the old centre, east of Piazza Navona.","Pantheon,_Rome"),
   ("Trevi Fountain",41.9009,12.4833,"CENTRE","Finished in 1762. Tradition says a coin thrown over your shoulder means you will return to Rome.","In a small square in the old centre, east of the Pantheon.","Trevi_Fountain"),
   ("Roman Forum",41.8925,12.4853,"ANCIENT ROME","The centre of public life in ancient Rome: markets, temples, courts and speeches, for about a thousand years.","The field of ruins between the Colosseum and the white Vittoriano.","Roman_Forum"),
   ("Circus Maximus",41.8861,12.4851,"ANCIENT ROME","A chariot-racing track about 600 metres long that could hold some 150,000 people.","The long grassy hollow south of the Palatine Hill.","Circus_Maximus"),
   ("Castel Sant'Angelo",41.9031,12.4663,"VATICAN","Built as the tomb of the emperor Hadrian, finished in AD 139, and later used by the popes as a fortress.","The round fortress on the Tiber, east of St. Peter's.","Castel_Sant%27Angelo"),
   ("Piazza Navona",41.8992,12.4731,"CENTRE","The long oval follows a stadium built by the emperor Domitian. Bernini's Fountain of the Four Rivers stands in the middle.","A long narrow square west of the Pantheon.","Piazza_Navona"),
   ("Spanish Steps",41.9060,12.4828,"CENTRE","135 steps, built in the 1720s to link the square below with the church above.","Below a twin-towered church, north of the Trevi Fountain.","Spanish_Steps"),
   ("Villa Borghese",41.9142,12.4853,"NORTH","A landscape park of about 80 hectares, laid out in the 1600s around the Borghese family's villa.","The big park north of the Spanish Steps.","Villa_Borghese_gardens"),
   ("Vittoriano",41.8946,12.4831,"CENTRE","A white marble monument to Victor Emmanuel II, the first king of united Italy, completed in 1935. Romans nicknamed it the typewriter.","The very white monument at the north end of the Forum.","Victor_Emmanuel_II_Monument"),
   ("Stadio Olimpico",41.9341,12.4547,"NORTH","Rome's main stadium, home to both Roma and Lazio. It hosted the 1960 Olympic Games.","Beside a bend of the Tiber in the north of the city.","Stadio_Olimpico"),
  ],
  routes=[("Ancient Rome","Circus Maximus to Piazza Navona · 6 gates",("Aventine",41.8720,12.4860,280),["Circus Maximus","Colosseum","Roman Forum","Vittoriano","Pantheon","Piazza Navona"]),
          ("To the Vatican","Villa Borghese to St. Peter's · 5 gates",("Parioli",41.9280,12.4950,300),["Villa Borghese","Spanish Steps","Trevi Fountain","Castel Sant'Angelo","St. Peter's Basilica"])],
  launches=[("Colosseum",41.878,12.500,300),("Vatican",41.890,12.440,300),("Villa Borghese",41.922,12.490,300),("The Tiber",41.868,12.470,260)]),
 dict(id="hongkong", name="Hong Kong", localName="香港", country="Hong Kong", flag="🇭🇰", greeting="你好", tagline="Victoria Harbour", latitude=22.30, longitude=114.17, water="Victoria Harbour", music="dragon-and-toast",
  sites=[
   ("Victoria Peak",22.2759,114.1455,"HONG KONG ISLAND","The highest hill on Hong Kong Island at 552 metres. The Peak Tram has climbed it since 1888.","The wooded mountain behind the towers of Central.","Victoria_Peak"),
   ("International Commerce Centre",22.3033,114.1602,"KOWLOON","At 484 metres, the tallest building in Hong Kong. It was completed in 2010.","The tallest tower on the Kowloon side, on the western waterfront.","International_Commerce_Centre"),
   ("Star Ferry Pier",22.2937,114.1687,"KOWLOON","The Star Ferry has crossed the harbour between Kowloon and Hong Kong Island since 1888.","At the tip of Kowloon, beside an old clock tower.","Star_Ferry"),
   ("Bank of China Tower",22.2793,114.1616,"HONG KONG ISLAND","I. M. Pei's tower of glass triangles, completed in 1990. It was the first building outside the United States to rise above 305 metres.","The sharp-edged tower with white diagonal lines, in Central.","Bank_of_China_Tower_(Hong_Kong)"),
   ("Two International Finance Centre",22.2855,114.1588,"HONG KONG ISLAND","A tower more than 410 metres tall on the Central waterfront, completed in 2003.","The tallest tower on the island side, at the water's edge.","International_Finance_Centre_(Hong_Kong)"),
   ("Happy Valley Racecourse",22.2726,114.1830,"HONG KONG ISLAND","Horses have raced in this valley since 1846. Tower blocks now look down on the track.","An oval track ringed by apartment towers, east of Central.","Happy_Valley_Racecourse"),
   ("Kai Tak",22.3070,114.2130,"KOWLOON","Until 1998 this was Hong Kong's airport, famous for a low turn over the rooftops of Kowloon on the way in. The runway is now a cruise terminal.","The long finger of land pointing into the harbour from east Kowloon.","Kai_Tak_Airport"),
   ("Tsing Ma Bridge",22.3515,114.0740,"NEW TERRITORIES","Opened in 1997 with a main span of 1,377 metres, the longest in the world carrying both road and rail.","The big suspension bridge in the north-west, beyond Tsing Yi island.","Tsing_Ma_Bridge"),
   ("Lion Rock",22.3523,114.1870,"KOWLOON","A 495-metre peak shaped like a crouching lion. It has become a symbol of Hong Kong's spirit.","The rocky summit on the ridge north of Kowloon.","Lion_Rock"),
   ("Stonecutters Bridge",22.3260,114.1180,"KOWLOON","A cable-stayed bridge over the container port, opened in 2009, with towers 298 metres tall.","The bridge with two tall single towers, by the container terminals.","Stonecutters_Bridge"),
   ("Ocean Park",22.2467,114.1757,"HONG KONG ISLAND","A marine and amusement park opened in 1977 on the south side of the island, with a cable car between its two halves.","On a headland on the south coast of Hong Kong Island.","Ocean_Park_Hong_Kong"),
   ("Sha Tin Racecourse",22.4000,114.2030,"NEW TERRITORIES","Opened in 1978 on land reclaimed from the sea. It holds about 85,000 people.","Beside the river in Sha Tin, north of the Kowloon hills.","Sha_Tin_Racecourse"),
  ],
  routes=[("Harbour dash","Kai Tak to Happy Valley · 6 gates",("Lei Yue Mun",22.2900,114.2350,300),["Kai Tak","Star Ferry Pier","International Commerce Centre","Two International Finance Centre","Bank of China Tower","Happy Valley Racecourse"]),
          ("Bridges and peaks","Stonecutters to Sha Tin · 4 gates",("West Kowloon",22.3000,114.1400,350),["Stonecutters Bridge","Tsing Ma Bridge","Lion Rock","Sha Tin Racecourse"])],
  launches=[("Victoria Harbour",22.290,114.190,260),("Kowloon",22.320,114.170,450),("The Peak",22.265,114.150,750),("Tsing Yi",22.340,114.100,500)]),
 dict(id="rio", name="Rio de Janeiro", country="Brazil", flag="🇧🇷", greeting="Olá", tagline="Guanabara Bay", latitude=-22.93, longitude=-43.21, water="Guanabara Bay", music="samba-isobel",
  sites=[
   ("Christ the Redeemer",-22.9519,-43.2105,"THE HILLS","A 30-metre statue on top of Corcovado, 700 metres above the city. It was completed in 1931.","On the sharp summit in the middle of the city: climb to reach it.","Christ_the_Redeemer_(statue)"),
   ("Sugarloaf Mountain",-22.9492,-43.1545,"THE BAY","A 396-metre granite peak at the mouth of the bay. A cable car has run to the top since 1912.","The bare rock dome at the entrance to the bay.","Sugarloaf_Mountain"),
   ("Copacabana Beach",-22.9711,-43.1822,"THE BEACHES","Four kilometres of sand in a long curve. The wave pattern in the pavement beside it is a design from Portugal.","The long curved beach south of Sugarloaf.","Copacabana,_Rio_de_Janeiro"),
   ("Ipanema Beach",-22.9868,-43.2050,"THE BEACHES","The beach that gave the song its name. The twin peaks of Dois Irmãos stand at its western end.","The straight beach west of Copacabana, in front of the lagoon.","Ipanema"),
   ("Maracanã Stadium",-22.9121,-43.2302,"NORTH","Opened for the 1950 World Cup, whose final drew a crowd of almost 200,000, a record for football.","The big oval stadium north-west of the centre.","Maracan%C3%A3_Stadium"),
   ("Sambadrome",-22.9118,-43.1968,"CENTRE","A 700-metre parade avenue with stands on both sides, designed by Oscar Niemeyer and opened in 1984 for the Carnival samba parades.","A straight strip lined with grandstands, west of the centre.","Sambadrome_Marqu%C3%AAs_de_Sapuca%C3%AD"),
   ("Rodrigo de Freitas Lagoon",-22.9730,-43.2110,"THE BEACHES","A saltwater lagoon linked to the sea by a canal, with a path about 7.5 kilometres long around it.","The lagoon behind Ipanema, under Corcovado.","Rodrigo_de_Freitas_Lagoon"),
   ("Santos Dumont Airport",-22.9105,-43.1631,"THE BAY","The city airport, on land reclaimed from the bay and named for Brazil's aviation pioneer. Its runway is only about 1,300 metres long.","The short runway sticking into the bay beside the centre.","Santos_Dumont_Airport"),
   ("Rio–Niterói Bridge",-22.8707,-43.1670,"THE BAY","More than 13 kilometres long, it crosses Guanabara Bay. It opened in 1974.","The long bridge across the bay, north of the centre.","Rio%E2%80%93Niter%C3%B3i_Bridge"),
   ("Tijuca Forest",-22.9425,-43.2850,"THE HILLS","One of the largest urban forests in the world, replanted by hand from the 1860s after coffee farming had stripped the hills.","The forested mountains west of Corcovado.","Tijuca_Forest"),
   ("Pedra da Gávea",-22.9977,-43.2848,"THE BEACHES","A granite mountain 844 metres high that rises almost straight from the ocean.","The flat-topped rock above the coast, west of Ipanema.","Pedra_da_G%C3%A1vea"),
   ("Niterói Contemporary Art Museum",-22.9078,-43.1259,"NITERÓI","Oscar Niemeyer's saucer-shaped museum, opened in 1996 on a cliff across the bay from Rio.","On a point on the far side of the bay, east of the city airport.","Niter%C3%B3i_Contemporary_Art_Museum"),
  ],
  routes=[("Bay and beaches","Santos Dumont to Corcovado · 6 gates",("Guanabara Bay",-22.8900,-43.1450,320),["Santos Dumont Airport","Sugarloaf Mountain","Copacabana Beach","Ipanema Beach","Rodrigo de Freitas Lagoon","Christ the Redeemer"]),
          ("Across the bay","The Sambadrome to Niterói · 4 gates",("Glória",-22.9250,-43.1800,350),["Sambadrome","Maracanã Stadium","Rio–Niterói Bridge","Niterói Contemporary Art Museum"])],
  launches=[("Guanabara Bay",-22.900,-43.150,300),("Copacabana",-22.980,-43.170,300),("Corcovado",-22.935,-43.200,950),("São Conrado",-23.005,-43.260,400)]),
 dict(id="dubai", name="Dubai", localName="دبي", country="United Arab Emirates", flag="🇦🇪", greeting="مرحبا", tagline="The Gulf coast", latitude=25.16, longitude=55.24, water="the Persian Gulf", music="desert-city",
  sites=[
   ("Burj Khalifa",25.1972,55.2744,"DOWNTOWN","The tallest building in the world at 828 metres. It opened in 2010.","The needle that stands far above everything else downtown.","Burj_Khalifa"),
   ("Palm Jumeirah",25.1124,55.1390,"THE COAST","An artificial island in the shape of a palm tree, built in the early 2000s from sand dredged from the sea floor.","The palm-shaped island off the coast, south-west of the centre.","Palm_Jumeirah"),
   ("Burj Al Arab",25.1412,55.1853,"THE COAST","A hotel shaped like a sail, 321 metres tall, on its own small island. It opened in 1999.","The white sail just off the beach, between the Palm and downtown.","Burj_Al_Arab"),
   ("Dubai Marina",25.0805,55.1403,"THE COAST","A canal city about three kilometres long, cut inland from the sea and lined with residential towers.","The winding waterway among towers, south of the Palm.","Dubai_Marina"),
   ("Dubai Frame",25.2355,55.3003,"OLD DUBAI","A 150-metre picture frame with a glass-floored bridge across the top, opened in 2018. One side looks to old Dubai and the other to new.","A golden rectangle standing in a park, north-east of downtown.","Dubai_Frame"),
   ("Dubai Creek",25.2637,55.3075,"OLD DUBAI","The saltwater inlet where the city began as a trading and pearl-diving port. Wooden abra boats still ferry people across.","The winding inlet through the old town in the north-east.","Dubai_Creek"),
   ("Museum of the Future",25.2192,55.2820,"DOWNTOWN","A ring-shaped building covered in Arabic calligraphy, opened in 2022.","A silver ring beside the main highway, north of the Burj Khalifa.","Museum_of_the_Future"),
   ("Ain Dubai",25.0799,55.1237,"THE COAST","The tallest observation wheel in the world, about 250 metres high, on Bluewaters Island.","The giant wheel on a small island off the Marina.","Ain_Dubai"),
   ("Dubai International Airport",25.2532,55.3657,"OLD DUBAI","One of the busiest airports in the world for international passengers.","East of the creek, at the north-east corner of the city.","Dubai_International_Airport"),
   ("The World Islands",25.2200,55.1700,"THE COAST","About 300 artificial islands arranged as a map of the world, four kilometres off the coast. Most remain undeveloped.","A scatter of sandy islands out at sea, north-west of downtown.","The_World_(archipelago)"),
   ("Jumeirah Mosque",25.2338,55.2655,"OLD DUBAI","Built of white stone in 1979 in a style inspired by Fatimid Egypt, and open to visitors of all faiths.","Near the coast, north of downtown.","Jumeirah_Mosque"),
   ("Atlantis The Palm",25.1304,55.1171,"THE COAST","The resort at the outer edge of the Palm's crescent, opened in 2008.","The pink building with a great arch, at the far tip of the Palm.","Atlantis,_The_Palm"),
  ],
  routes=[("Coast run","Ain Dubai to the World Islands · 6 gates",("Jebel Ali",25.0550,55.1050,300),["Ain Dubai","Dubai Marina","Atlantis The Palm","Palm Jumeirah","Burj Al Arab","The World Islands"]),
          ("Downtown and the creek","Burj Khalifa to Dubai Creek · 5 gates",("Business Bay",25.1700,55.2500,500),["Burj Khalifa","Museum of the Future","Jumeirah Mosque","Dubai Frame","Dubai Creek"])],
  launches=[("Downtown",25.180,55.255,550),("The Palm",25.100,55.115,300),("Dubai Creek",25.245,55.300,300),("Dubai Marina",25.065,55.130,400)]),
 dict(id="losangeles", name="Los Angeles", country="United States", flag="🇺🇸", greeting=None, tagline="Santa Monica Bay", latitude=34.03, longitude=-118.36, water="the Pacific Ocean", music="cool-vibes",
  sites=[
   ("Hollywood Sign",34.1341,-118.3215,"HOLLYWOOD","Put up in 1923 as an advertisement that read Hollywoodland. The last four letters came down in 1949.","White letters on the hillside above Hollywood: climb to reach them.","Hollywood_Sign"),
   ("Griffith Observatory",34.1184,-118.3004,"HOLLYWOOD","Opened in 1935 on the slope of Mount Hollywood. Admission has been free ever since.","The white domed building on the hill east of the Hollywood Sign.","Griffith_Observatory"),
   ("Santa Monica Pier",34.0086,-118.4986,"THE COAST","Opened in 1909. A sign on the pier marks the western end of Route 66.","The pier with a Ferris wheel, where the city meets the ocean.","Santa_Monica_Pier"),
   ("Downtown Los Angeles",34.0500,-118.2600,"DOWNTOWN","With its spire, the Wilshire Grand Center reaches 335 metres, the tallest building in Los Angeles.","The cluster of towers at the eastern end of the basin.","Wilshire_Grand_Center"),
   ("Dodger Stadium",34.0739,-118.2400,"DOWNTOWN","Opened in 1962 in Chavez Ravine. It is the third-oldest ballpark in Major League Baseball.","In the hills just north of downtown, ringed by car parks.","Dodger_Stadium"),
   ("Los Angeles Airport",33.9416,-118.4085,"THE COAST","The Theme Building at its centre, shaped like a landed flying saucer, dates from 1961.","Four long runways running to the ocean, south of Venice.","Los_Angeles_International_Airport"),
   ("Venice Beach",33.9850,-118.4695,"THE COAST","Founded in 1905 as a seaside resort with canals copied from Venice in Italy. A few of the canals remain.","The wide beach south of Santa Monica.","Venice,_Los_Angeles"),
   ("Getty Center",34.0780,-118.4741,"WESTSIDE","An art museum on a hilltop in the Santa Monica Mountains, opened in 1997. Visitors ride up by tram.","The pale stone buildings on a ridge above the freeway, north of Santa Monica.","Getty_Center"),
   ("SoFi Stadium",33.9535,-118.3392,"SOUTH","Opened in 2020 in Inglewood, home to both the Rams and the Chargers.","The huge curved roof east of the airport.","SoFi_Stadium"),
   ("Beverly Hills",34.0736,-118.4004,"WESTSIDE","A separate city of under six square miles, surrounded by Los Angeles.","Between Hollywood and the coast, at the foot of the hills.","Beverly_Hills,_California"),
   ("La Brea Tar Pits",34.0638,-118.3554,"MID-CITY","Natural asphalt has seeped to the surface here for tens of thousands of years, trapping mammoths, sabre-toothed cats and dire wolves.","In a park on Wilshire Boulevard, halfway between downtown and the coast.","La_Brea_Tar_Pits"),
   ("Memorial Coliseum",34.0141,-118.2879,"SOUTH","Opened in 1923. It hosted the Olympic Games in 1932 and 1984, and will again in 2028.","The big oval stadium south-west of downtown.","Los_Angeles_Memorial_Coliseum"),
  ],
  routes=[("Coast to downtown","Venice to Dodger Stadium · 6 gates",("Marina del Rey",33.9600,-118.4750,300),["Venice Beach","Santa Monica Pier","Beverly Hills","La Brea Tar Pits","Downtown Los Angeles","Dodger Stadium"]),
          ("Hills and stadiums","The Hollywood Sign to SoFi · 5 gates",("West Hollywood",34.0850,-118.3500,500),["Hollywood Sign","Griffith Observatory","Dodger Stadium","Memorial Coliseum","SoFi Stadium"])],
  launches=[("Santa Monica Bay",33.990,-118.520,260),("Hollywood",34.090,-118.330,550),("Downtown",34.030,-118.250,450),("The airport",33.940,-118.460,300)]),
 dict(id="chicago", name="Chicago", country="United States", flag="🇺🇸", greeting=None, tagline="Lake Michigan", latitude=41.88, longitude=-87.66, water="Lake Michigan", music="bass-walker",
  sites=[
   ("Willis Tower",41.8789,-87.6359,"THE LOOP","Completed in 1973 as the Sears Tower. At 442 metres it was the tallest building in the world for 25 years.","The dark stepped tower with two white antennas, west of the Loop.","Willis_Tower"),
   ("Cloud Gate",41.8827,-87.6233,"THE LOOP","A polished steel sculpture in Millennium Park, nicknamed the Bean. It weighs about 110 tons.","In Millennium Park, between the towers and the lake.","Cloud_Gate"),
   ("Navy Pier",41.8917,-87.6005,"THE LAKEFRONT","A pier more than 3,000 feet long, opened in 1916. Its Ferris wheel recalls the very first one, built in Chicago for the 1893 World's Fair.","The long pier into the lake, just north of the river mouth.","Navy_Pier"),
   ("Wrigley Field",41.9484,-87.6553,"NORTH SIDE","Home of the Cubs since 1916 and the second-oldest ballpark in the major leagues. Ivy covers the outfield wall.","A ballpark among houses on the North Side.","Wrigley_Field"),
   ("Soldier Field",41.8623,-87.6167,"THE LAKEFRONT","Opened in 1924 as a memorial to American soldiers. The Bears have played here since 1971.","The stadium with classical colonnades on the lakefront, south of the Loop.","Soldier_Field"),
   ("875 North Michigan Avenue",41.8988,-87.6229,"NEAR NORTH","Completed in 1969 and long known as the John Hancock Center. The X-shaped braces on its outside help hold it up.","The dark tapering tower with crossed braces, north of the river.","875_North_Michigan_Avenue"),
   ("Lincoln Park Zoo",41.9211,-87.6340,"NORTH SIDE","Founded in 1868 and still free to enter, one of the oldest zoos in North America.","In the long lakefront park north of downtown.","Lincoln_Park_Zoo"),
   ("Adler Planetarium",41.8663,-87.6068,"THE LAKEFRONT","The first planetarium in the Western Hemisphere, opened in 1930 at the tip of a peninsula in the lake.","At the end of the spit of land east of Soldier Field.","Adler_Planetarium"),
   ("University of Chicago",41.7886,-87.5987,"SOUTH SIDE","Founded in 1890. The first controlled nuclear chain reaction took place here in 1942, under the stands of a football field.","Grey stone quadrangles in Hyde Park, on the South Side.","University_of_Chicago"),
   ("Midway Airport",41.7868,-87.7522,"SOUTH SIDE","Until O'Hare opened to airlines in 1955, this one square mile was the busiest airport in the world.","A square airfield hemmed in by houses, south-west of the Loop.","Midway_International_Airport"),
   ("United Center",41.8807,-87.6742,"WEST SIDE","Home of the Bulls and the Blackhawks since 1994. A statue of Michael Jordan stands inside.","The big arena west of the Loop.","United_Center"),
   ("Wolf Point",41.8870,-87.6370,"THE LOOP","Where the branches of the Chicago River meet. Engineers reversed the river in 1900 so that it flows away from Lake Michigan, the city's drinking water.","Where the river splits in three, at the north-west corner of the Loop.","Wolf_Point,_Chicago"),
  ],
  routes=[("Lakefront","Soldier Field to Wrigley Field · 6 gates",("Burnham Harbor",41.8350,-87.6000,300),["Soldier Field","Adler Planetarium","Navy Pier","875 North Michigan Avenue","Lincoln Park Zoo","Wrigley Field"]),
          ("The Loop and west","Cloud Gate to Midway · 5 gates",("Grant Park",41.8650,-87.6000,450),["Cloud Gate","Willis Tower","Wolf Point","United Center","Midway Airport"])],
  launches=[("Lake Michigan",41.870,-87.590,260),("The Loop",41.858,-87.630,550),("North Side",41.930,-87.640,350),("Midway",41.800,-87.740,350)]),
]

root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Resources", "regions")
overrides = {}
if len(sys.argv) > 1:            # verified coordinates: {"city id": {"site name": [lat, lon]}}
    overrides = json.load(open(sys.argv[1]))
for c in CITIES:
    fix = overrides.get(c["id"], {})
    sites = {}
    for name, lat, lon, group, fact, hint, title in c["sites"]:
        lat, lon = fix.get(name, (lat, lon))
        sites[name] = dict(name=name, lat=round(lat, 5), lon=round(lon, 5), group=group, fact=fact, hint=hint, source=W + title)
    def spot(g, alt=250):
        if isinstance(g, str): return dict(name=g, lat=sites[g]["lat"], lon=sites[g]["lon"], alt=alt)
        return dict(name=g[0], lat=g[1], lon=g[2], alt=g[3] if len(g) > 3 else alt)
    out = {k: c[k] for k in ("id", "name", "country", "flag", "tagline", "latitude", "longitude", "water", "music")}
    for k in ("localName", "greeting"):
        if c.get(k): out[k] = c[k]
    out["sites"] = list(sites.values())
    out["routes"] = [dict(name=n, subtitle=s, spawn=spot(sp), gates=[spot(g) for g in gates]) for n, s, sp, gates in c["routes"]]
    out["launches"] = [spot(l) for l in c["launches"]]
    os.makedirs(os.path.join(root, c["id"]), exist_ok=True)
    with open(os.path.join(root, c["id"], "region.json"), "w") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print(c["id"], len(out["sites"]), "sites", len(out["routes"]), "routes", len(out["launches"]), "starts")
