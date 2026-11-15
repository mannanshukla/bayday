import CoreLocation
import Foundation
import simd

// What the aircraft is flying over. Names come from Apple's reverse geocoder: the
// neighbourhood where it has one, otherwise a named place or the town.
struct PlaceLabel:Equatable {
 var name="",detail=""
}
// One geocoder answer, reduced to what the label needs.
struct PlaceAnswer:Codable,Equatable {
 var sub:String?,named:String?,locality:String?,county:String?,water:String?
 // Over water the geocoder answers with the nearest address on shore, so the caller says
 // whether the aircraft is over open water and the shore name becomes "near …".
 func label(overWater:Bool,latitude:Double,longitude:Double)->PlaceLabel {
  var land=sub ?? named ?? locality,parent=locality
  // A district with its own neighbourhood table: show the neighbourhood, with the district as the note.
  if let sub,region.neighbourhoods[sub] != nil {parent=sub;land=region.neighbourhood(in:sub,latitude:latitude,longitude:longitude) ?? sub;if land==sub{parent=locality}}
  if overWater || water != nil {
   return PlaceLabel(name:water ?? PlaceAnswer.waterName(latitude:latitude,longitude:longitude),detail:land.map{"near \($0)"} ?? "")
  }
  guard let land else{return PlaceLabel()}
  return PlaceLabel(name:land,detail:land==locality ? (county ?? ""):(parent ?? county ?? ""))
 }
 // Used when the geocoder does not name the water itself.
 static func waterName(latitude:Double,longitude:Double)->String {region.waterName(latitude,longitude)}
}
final class PlaceLocator {
 typealias Lookup=(_ latitude:Double,_ longitude:Double,_ done:@escaping(PlaceAnswer?)->Void)->Void
 static let cell:Float=300,interval:Double=3
 // Answers are keyed by world square, so each region keeps its own.
 let storeKey=region.id=="sf" ? "BayDayNative.places":"BayDayNative.places."+region.id
 private let lookup:Lookup,store:UserDefaults?
 private var busy=false,nextTime:Double=0,retry:Double=10
 // Answers are kept per 300 m square and saved, so ground already flown over needs no request.
 private(set) var answers=[String:PlaceAnswer]()
 private(set) var requests=0
 init(store:UserDefaults?=nil,lookup:Lookup?=nil){
  self.store=store;self.lookup=lookup ?? PlaceLocator.geocode
  if let data=store?.data(forKey:storeKey),let saved=try? JSONDecoder().decode([String:PlaceAnswer].self,from:data){answers=saved}
 }
 static func key(_ p:SIMD3<Float>)->String {"\(Int(floorf(p.x/cell))),\(Int(floorf(p.z/cell)))"}
 // Asks about the square the aircraft is in, at most once every few seconds, and waits
 // longer each time the service refuses or is unreachable.
 func update(position:SIMD3<Float>,now:Double,done:@escaping()->Void){
  let key=PlaceLocator.key(position)
  guard answers[key] == nil,!busy,now>=nextTime else{return}
  busy=true;requests+=1
  let c=coordinate(position)
  lookup(c.latitude,c.longitude){[weak self] answer in
   guard let self else{return}
   self.busy=false
   guard let answer else{self.nextTime=now+self.retry;self.retry=min(120,self.retry*2);return}
   self.retry=10;self.nextTime=now+PlaceLocator.interval;self.answers[key]=answer
   if self.answers.count>6000 {self.answers.removeAll();self.answers[key]=answer}
   if self.answers.count%8==0,let data=try? JSONEncoder().encode(self.answers){self.store?.set(data,forKey:self.storeKey)}
   done()
  }
 }
 // The answer for this square, or a neighbouring one while this square's is on its way.
 // Nothing is shown when no answer is close, so a new start never shows the last flight's place.
 func label(position:SIMD3<Float>,overWater:Bool)->PlaceLabel {
  let c=coordinate(position)
  var answer=answers[PlaceLocator.key(position)]
  if answer == nil {for dx in [-1,1,0,0] as [Float] {for dz in [0,0,-1,1] as [Float] where answer == nil && (dx==0) != (dz==0) {answer=answers[PlaceLocator.key(position+SIMD3(dx,0,dz)*PlaceLocator.cell)]}}}
  return answer?.label(overWater:overWater,latitude:c.latitude,longitude:c.longitude) ?? PlaceLabel()
 }
 private static let geocoder=CLGeocoder()
 static func geocode(_ latitude:Double,_ longitude:Double,_ done:@escaping(PlaceAnswer?)->Void){
  geocoder.reverseGeocodeLocation(CLLocation(latitude:latitude,longitude:longitude)){places,error in
   DispatchQueue.main.async {
    guard let p=places?.first,error == nil else{done(nil);return}
    // A name is only useful if it is a place, not a street address.
    let named=p.name.flatMap{name in (p.areasOfInterest ?? []).contains(name) ? name:nil}
    done(PlaceAnswer(sub:p.subLocality,named:named,locality:p.locality,county:p.subAdministrativeArea,water:p.inlandWater ?? p.ocean))
   }
  }
 }
}
