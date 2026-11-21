import SwiftUI
import MapKit
import simd

// After a landing, the player can look around from the street nearest the aircraft, in
// Apple's Look Around. A scene request only answers for a point on or beside a street, and
// a landed floatplane is on the water, so the search widens in rings until one answers.

enum LookAroundState:Equatable {
 case closed,searching
 case open(MKLookAroundScene,metres:Int)
 static func==(a:LookAroundState,b:LookAroundState)->Bool {
  switch (a,b) {
  case (.closed,.closed),(.searching,.searching):return true
  case let (.open(x,m),.open(y,n)):return x===y && m==n
  default:return false
  }
 }
}

extension FlightGame {
 static let lookAroundRadius:Double=500
 func openLookAround(){
  guard canLookAround else{return}
  lookAroundState = .searching;clearInput();lookAroundTicket += 1
  let here=coordinate(position),ticket=lookAroundTicket
  Task {@MainActor [weak self] in
   let found=await FlightGame.nearestScene(latitude:here.latitude,longitude:here.longitude)
   guard let self,self.lookAroundTicket==ticket,self.lookAroundState == .searching else{return}
   if let found {self.lookAroundState = .open(found.scene,metres:found.metres)}
   else{self.lookAroundState = .closed;self.notify("No Look Around within \(Int(FlightGame.lookAroundRadius)) m of here")}
  }
 }
 func closeLookAround(){lookAroundTicket += 1;lookAroundState = .closed;clearInput()}

 // Rings of points around the aircraft, nearest first; the first ring with any scene wins.
 // About 30 requests at most, inside MapKit's request allowance.
 static func nearestScene(latitude:Double,longitude:Double) async->(scene:MKLookAroundScene,metres:Int)? {
  let perLatitude=111132.92,perLongitude=111320*cos(latitude * .pi/180)
  for ring in [0.0,100,200,350,lookAroundRadius] {
   let bearings=ring==0 ? [0.0]:stride(from:0.0,to:360,by:45).map{$0}
   let hit=await withTaskGroup(of:MKLookAroundScene?.self) {group->MKLookAroundScene? in
    for b in bearings {
     let a=b * .pi/180,at=CLLocationCoordinate2D(latitude:latitude+ring*cos(a)/perLatitude,longitude:longitude+ring*sin(a)/perLongitude)
     group.addTask {try? await MKLookAroundSceneRequest(coordinate:at).scene}
    }
    for await scene in group {if let scene {group.cancelAll();return scene}}
    return nil
   }
   if let hit {return (hit,Int(ring))}
  }
  return nil
 }
}

// The Look Around picture over the whole window, with the way back to the aircraft.
struct LookAroundOverlay:View {
 @ObservedObject var game:FlightGame
 var body:some View {
  switch game.lookAroundState {
  case .closed:EmptyView()
  case .searching:
   ZStack {
    Color.black.opacity(0.35).ignoresSafeArea()
    Label("Finding the nearest street…",systemImage:"binoculars.fill").font(.system(size:14,weight:.semibold)).padding(.horizontal,18).padding(.vertical,10).aeroCapsule()
   }.transition(.opacity)
  case let .open(scene,metres):
   ZStack(alignment:.top) {
    LookAroundPreview(initialScene:scene,allowsNavigation:true,showsRoadLabels:true).ignoresSafeArea()
    HStack(alignment:.top) {
     Button(action:game.closeLookAround){Label("Back to the aircraft",systemImage:"xmark")}.buttonStyle(AeroButtonStyle(compact:true)).help("Back to the aircraft (L or Esc)")
     Spacer()
     Text(metres<50 ? "Look Around · right here":"Look Around · about \(metres) m from the aircraft").font(.system(size:12,weight:.semibold)).padding(.horizontal,14).padding(.vertical,8).aeroCapsule()
    }.padding(.horizontal,22).padding(.top,36)
   }.transition(.opacity)
  }
 }
}
