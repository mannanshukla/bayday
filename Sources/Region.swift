import Foundation

// Everything that differs between cities: where the 49 km world is centred, what it is
// called, and the places, routes and starts in it. The flight model, camera, aircraft and
// interface are shared.
struct Neighbourhood {let name:String,latitude:Double,longitude:Double}
struct Region {
 // `name` is shown in the city picker.
 let id:String,name:String,tagline:String
 // Centre of the world, and the length of a degree of latitude there.
 let latitude:Double,longitude:Double,metresPerLatitude:Double
 let sites:[DiscoverySite],routes:[Route],launches:[Place]
 // Used for open water the geocoder does not name.
 let waterName:(_ latitude:Double,_ longitude:Double)->String
 // Where the geocoder names only a larger district (a New York borough), neighbourhood
 // centres for that district, keyed by the name the geocoder gives it.
 var neighbourhoods=[String:[Neighbourhood]]()
 // Character: the name as written locally, a greeting, a flag and a signature tune.
 var localName:String?=nil,country="United States",flag="🇺🇸",greeting:String?=nil,music:String?=nil

 var metresPerLongitude:Double {111320*cos(latitude*Double.pi/180)}
 var places:[Place] {sites.map(\.place)}
 // The nearest neighbourhood centre in the district, if one is within reach.
 func neighbourhood(in district:String,latitude:Double,longitude:Double,within metres:Double=2200)->String? {
  var best:(name:String,distance:Double)?
  for n in neighbourhoods[district] ?? [] {
   let d=hypot((n.latitude-latitude)*metresPerLatitude,(n.longitude-longitude)*metresPerLongitude)
   if d<=metres && d<(best?.distance ?? .infinity) {best=(n.name,d)}
  }
  return best?.name
 }

 // San Francisco and New York are written in code; the other cities are data files.
 static let dataOrder=["london","paris","tokyo","sydney","rome","hongkong","rio","dubai","losangeles","chicago","boston"]
 static let all:[Region]=[sanFrancisco,newYork]+dataOrder.compactMap(load)
 static func named(_ id:String?)->Region? {all.first{$0.id==id}}
 // Tests and tools pick the starting region with the BAYDAY_REGION environment variable;
 // the app starts in the region the player last chose (see FlightGame).
 static var requested:Region? {named(ProcessInfo.processInfo.environment["BAYDAY_REGION"])}
 // Region folders (tests and tools) or the app bundle.
 static var dataFolder:URL? {ProcessInfo.processInfo.environment["BAYDAY_REGIONS_DIR"].map{URL(fileURLWithPath:$0)}}
 static func file(_ kind:String,_ id:String)->URL {
  if let folder=dataFolder {return folder.appendingPathComponent(id).appendingPathComponent(kind=="region" ? "region.json":"\(kind).bin")}
  let bundle=Bundle.main.resourceURL!
  return kind=="region" ? bundle.appendingPathComponent("regions/\(id).json"):bundle.appendingPathComponent("\(kind)-\(id).bin")
 }
}
// A city described by a data file (Resources/regions/<id>/region.json).
private struct RegionFile:Decodable {
 struct Spot:Decodable {let name:String,lat:Float,lon:Float,alt:Float?}
 struct Site:Decodable {let name:String,lat:Float,lon:Float,group:String,fact:String,hint:String,source:String}
 struct Course:Decodable {let name:String,subtitle:String,spawn:Spot,gates:[Spot]}
 let id:String,name:String,localName:String?,country:String,flag:String,greeting:String?,tagline:String
 let latitude:Double,longitude:Double,water:String,music:String?
 let sites:[Site],routes:[Course],launches:[Spot]
}
extension Region {
 static func load(_ id:String)->Region? {
  guard let data=try? Data(contentsOf:file("region",id)),let f=try? JSONDecoder().decode(RegionFile.self,from:data) else{return nil}
  func place(_ s:RegionFile.Spot)->Place {Place(name:s.name,lat:s.lat,lon:s.lon,alt:s.alt ?? 250)}
  let routes=f.routes.map{c->Route in
   // Each route starts facing its first gate.
   let first=c.gates[0],north=Double(first.lat-c.spawn.lat),east=Double(first.lon-c.spawn.lon)*cos(f.latitude*Double.pi/180)
   return Route(name:c.name,subtitle:c.subtitle,spawn:place(c.spawn),yaw:Float(atan2(east,north)),gates:c.gates.map(place))
  }
  let water=f.water
  return Region(id:f.id,name:f.name,tagline:f.tagline,latitude:f.latitude,longitude:f.longitude,
   metresPerLatitude:111132.92-559.82*cos(2*f.latitude*Double.pi/180),
   sites:f.sites.map{DiscoverySite($0.name,$0.lat,$0.lon,220,$0.group,$0.fact,$0.hint,$0.source)},routes:routes,launches:f.launches.map(place),
   waterName:{_,_ in water},localName:f.localName,country:f.country,flag:f.flag,greeting:f.greeting,music:f.music)
 }
}
let appName="Bay Day"
// The region being flown. FlightGame.setRegion changes it; everything below reads it live.
var region=Region.requested ?? .sanFrancisco
var discoverySites:[DiscoverySite] {region.sites}
var sights:[Place] {region.places}
var routes:[Route] {region.routes}
var launches:[Place] {region.launches}
