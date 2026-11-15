import Foundation
struct DiscoverySite {
 let place:Place
 let region:String
 let fact:String
 let hint:String
 let source:String
 init(_ name:String,_ lat:Float,_ lon:Float,_ alt:Float,_ region:String,_ fact:String,_ hint:String,_ source:String){place=Place(name:name,lat:lat,lon:lon,alt:alt);self.region=region;self.fact=fact;self.hint=hint;self.source=source}
}
