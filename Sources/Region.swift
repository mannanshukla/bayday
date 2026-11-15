import Foundation

// Everything that differs between editions of the game: where the 49 km world is centred,
// what it is called, and the places, routes and starts in it. The flight model, camera,
// aircraft and interface are shared.
struct Neighbourhood {let name:String,latitude:Double,longitude:Double}
struct Region {
 let id:String,appName:String,tagline:String
 // Centre of the world, and the length of a degree of latitude there.
 let latitude:Double,longitude:Double,metresPerLatitude:Double
 let sites:[DiscoverySite],routes:[Route],launches:[Place]
 // Used for open water the geocoder does not name.
 let waterName:(_ latitude:Double,_ longitude:Double)->String
 // Where the geocoder names only a larger district (a New York borough), neighbourhood
 // centres for that district, keyed by the name the geocoder gives it.
 var neighbourhoods=[String:[Neighbourhood]]()
 // The nearest neighbourhood centre in the district, if one is within reach.
 func neighbourhood(in district:String,latitude:Double,longitude:Double,within metres:Double=2200)->String? {
  var best:(name:String,distance:Double)?
  for n in neighbourhoods[district] ?? [] {
   let d=hypot((n.latitude-latitude)*metresPerLatitude,(n.longitude-longitude)*metresPerLongitude)
   if d<=metres && d<(best?.distance ?? .infinity) {best=(n.name,d)}
  }
  return best?.name
 }
 var metresPerLongitude:Double {111320*cos(latitude*Double.pi/180)}

 static let all=[sanFrancisco,newYork]
 // The app bundle names its region; tests and tools use the BAYDAY_REGION environment variable.
 static let current:Region={
  let wanted=ProcessInfo.processInfo.environment["BAYDAY_REGION"] ?? Bundle.main.object(forInfoDictionaryKey:"BayDayRegion") as? String
  return all.first{$0.id==wanted} ?? sanFrancisco
 }()
}
let region=Region.current
