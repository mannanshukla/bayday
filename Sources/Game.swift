import Foundation
import SwiftUI
import AVFoundation
import GameController
import MapKit
import simd
struct Place {
 let name:String,lat:Float,lon:Float,alt:Float
 var position:SIMD3<Float> {var p=geographic(lat,lon);p.y=alt;return p}
}
struct Route {
 let name:String,subtitle:String,spawn:Place,yaw:Float,gates:[Place]
}
let routes=region.routes
let launches=region.launches

class FlightGame:ObservableObject {
 static let collectRadius:Float=140
 @Published var ready=false
 @Published var loading="Loading…"
 @Published var error:String?=nil
 @Published var paused=true
 @Published var launched=false
 @Published var launchIndex=0
 @Published var routeIndex=0
 @Published var challenge=false
 @Published var selectedChallenge=false
 @Published var selectedRouteIndex=0
 @Published var nextGate=0
 @Published var routeFinished=false
 @Published var points=0
 @Published var elapsed:Float=0
 @Published var speedReadout=0
 @Published var altitude=0
 @Published var height=0
 @Published var heading=0
 @Published var fps=0
 @Published var toast=""
 @Published var nearest="Golden Gate"
 @Published var distanceText=""
 @Published var courseBearing:Float=0
 @Published var boostReadout:Float=1
 @Published var photoMode=false
 @Published var showHelp=false
 @Published var showMap=false
 @Published var showCredits=false
 @Published var showPassport=false
 @Published var musicOn=true
 @Published private(set) var preferredScenery=2
 // 1 is Apple Maps 3D, 2 is satellite Flyover.
 @Published var scenery=2 {didSet{if scenery != oldValue{mapNotice="Loading scenery…"}}}
 @Published var mapNotice="Loading scenery…"
 private let preferences:UserDefaults
 private var mapReturnToFlight=false
 var mapReturnsToFlight:Bool{mapReturnToFlight}
 weak var appleMap:MKMapView?
 var mapCameraPosition=SIMD3<Float>(repeating:.infinity)
 var mapCameraYaw:Float=0,mapCameraPitch:Float=0,mapCameraRoll:Float=0,mapCameraMode = -1,mapSceneryMode = -1
 @Published var discovered=Set<Int>()
 @Published var activeDiscovery:Int?=nil
 @Published var selectedDiscovery=0
 @Published var trackedDiscovery:Int?=nil
 @Published var sessionFinds=0
 var collectionPulse:Float=0
 var discoveryTime:Float=0
 var chime:AVAudioPlayer?
 var burstPosition=SIMD3<Float>.zero
 var burstTime:Float = -100
 var isTesting:Bool
 var targetDiscovery:Int? {if let i=trackedDiscovery,!discovered.contains(i){return i};return sights.indices.filter{!discovered.contains($0)}.min{discoveryDistance(sights[$0])<discoveryDistance(sights[$1])}}
 func discoveryDistance(_ place:Place)->Float {let d=place.position-position;return hypot(d.x,d.z)}
 func rangeLabel(_ metres:Float)->String {metres<1000 ? "\(Int(metres)) m":String(format:"%.1f km",metres/1000)}
 func collect(_ i:Int){
  guard sights.indices.contains(i),!discovered.contains(i) else{return}
  discovered.insert(i);sessionFinds+=1;activeDiscovery=i;selectedDiscovery=i;discoveryTime=time;collectionPulse=1;burstPosition=sights[i].position;burstTime=time
  if !isTesting {preferences.set(Array(discovered),forKey:"BayDayNative.discoveries")}
  if trackedDiscovery==i{trackedDiscovery=nil}
  chime?.currentTime=0;chime?.play()
  if discovered.count==sights.count{notify("All \(sights.count) points found")}
 }
 func setCourse(_ i:Int){
  guard sights.indices.contains(i) else{return}
  // A discovery course replaces the gate route so the compass actually points to it.
  if challenge{challenge=false;selectedChallenge=false}
  trackedDiscovery=i;selectedDiscovery=i;resume();publishHUD();notify("Course set: \(sights[i].name)")
 }

 var renderer:FlightRenderer?
 var terrain:TerrainData?
 var position=routes[0].spawn.position
 var previous=routes[0].spawn.position
 var forward=SIMD3<Float>(0,0,-1)
 var yaw:Float=0,pitch:Float=0,roll:Float=0,speed:Float=Aero.cruise,boost:Float=1
 @Published var cameraMode=0
 var keys=Set<UInt16>(),shift=false
 // Current camera, shared by the map and the aircraft layer (see solveMapCamera).
 var cameraTilt:Float=70,cameraEye=MapCamera.eye(0,tilt:70),mapCameraSize=CGSize.zero,mapCameraClock:Double=0
 var demoInput=SIMD2<Float>.zero           // steady test input from --fly
 var turnInput:Float=0,pitchInput:Float=0
 var flightElapsed:Float=0
 var time:Float=0,lastToast:Float=0,collideCooldown:Float=0,publishTimer:Float=0
 var audio:AVAudioPlayer?
 var audioIndex=0
 let musicFiles=["bossa-antigua","backbay-lounge","carefree"]
 // Flight dynamics and crash state (see Physics.swift).
 var velocityDir=SIMD3<Float>(0,0,-1),rollRate:Float=0,pitchRate:Float=0,loadFactor:Float=1,stallAmount:Float=0,thrust:Float=Aero.cruiseThrust
 var crashTime:Float = -1,crashVelocity=SIMD3<Float>.zero,crashStart=SIMD3<Float>.zero,crashWater=false,tumble=SIMD3<Float>.zero,tumbleRate=SIMD3<Float>.zero
 var shake:Float=0,smokeTimer:Float=0,particles=[Particle](),thud:AVAudioPlayer?
 @Published var crashed=false
 @Published var stalling=false
 @Published var atCeiling=false
 @Published var place=PlaceLabel()
 lazy var locator=PlaceLocator(store:preferences)
 @Published var impactFlash=0
 init(preferences:UserDefaults = .standard,testing:Bool=CommandLine.arguments.contains("--qa")) {
  self.preferences=preferences;isTesting=testing
  if !testing {
   if let a=preferences.array(forKey:"BayDayNative.discoveries") as? [Int]{discovered=Set(a.filter{sights.indices.contains($0)})}
   if let saved=preferences.object(forKey:"BayDayNative.scenery") as? Int,(1...2).contains(saved){preferredScenery=saved;scenery=saved}
  }
 }
 func chooseScenery(_ value:Int){
  guard (1...2).contains(value) else{return}
  preferredScenery=value;scenery=value
  if !isTesting{preferences.set(value,forKey:"BayDayNative.scenery")}
 }
 func toggleSceneryStyle(){chooseScenery(scenery==1 ? 2:1)}
 func togglePause(){if paused{launched ? resume():begin()}else{pause()}}
 func toggleMap(){
  guard ready else{return}
  if showMap{closeMap();return}
  mapReturnToFlight = !paused;pause();showHelp=false;showCredits=false;showPassport=false;showMap=true
 }
 func openPassport(){pause();showMap=false;mapReturnToFlight=false;showHelp=false;showCredits=false;showPassport=true}
 func openHelp(){pause();showMap=false;mapReturnToFlight=false;showPassport=false;showCredits=false;showHelp=true}
 func openCredits(){pause();showMap=false;mapReturnToFlight=false;showPassport=false;showHelp=false;showCredits=true}
 func closeMap(){let returnToFlight=mapReturnToFlight;showMap=false;mapReturnToFlight=false;if returnToFlight{resume()}}

 func resource(_ name:String)->URL {Bundle.main.resourceURL!.appendingPathComponent(name)}
 func notify(_ message:String){toast=message;lastToast=time}
 func setupAudio(){if thud == nil {thud=try? AVAudioPlayer(contentsOf:resource("crash.wav"));thud?.prepareToPlay()};if chime == nil {chime=try? AVAudioPlayer(contentsOf:resource("collect.wav"));chime?.volume=0.55;chime?.prepareToPlay()};do{audio=try AVAudioPlayer(contentsOf:resource("music/\(musicFiles[audioIndex]).mp3"));audio?.volume=0.25;audio?.numberOfLoops = -1;audio?.prepareToPlay();if !paused && musicOn{audio?.play()}}catch{notify("Music unavailable")}}
 func toggleMusic(){musicOn.toggle();if musicOn && !paused{audio?.play()}else{audio?.pause()}}
 func nextMusic(){audioIndex=(audioIndex+1)%musicFiles.count;setupAudio();notify("Now playing: \(musicFiles[audioIndex].replacingOccurrences(of:"-",with:" "))")}
 func clearInput(){keys.removeAll();shift=false;turnInput=0;pitchInput=0}
 func pause(){paused=true;photoMode=false;clearInput();audio?.pause()}
 func resume(){guard ready else{return};paused=false;launched=true;showHelp=false;showCredits=false;showPassport=false;showMap=false;mapReturnToFlight=false;if musicOn{audio?.play()}}
 func begin(){guard ready else{return};challenge=selectedChallenge;routeIndex=selectedRouteIndex;reset();resume()}
 func reset(){
  let p=challenge ? routes[routeIndex].spawn:launches[launchIndex];position=p.position;yaw=challenge ? routes[routeIndex].yaw:0
  position.y=max(position.y,(terrain?.surface(position) ?? 0)+100);previous=position;pitch=0;roll=0;speed=Aero.cruise;boost=1;time=0;flightElapsed=0;elapsed=0;nextGate=0;points=0;routeFinished=false;sessionFinds=0;activeDiscovery=nil;trackedDiscovery=nil;burstTime = -100;forward=SIMD3(sin(yaw),0,-cos(yaw));resetDynamics();mapCameraPosition=SIMD3(repeating:.infinity);clearInput();publishHUD();notify(challenge ? "Fly through the gates in order":"")
 }
 func key(_ code:UInt16,down:Bool,repeatKey:Bool=false){
  if down{keys.insert(code)}else{keys.remove(code);return};if repeatKey{return}
  switch code {
  case 53,35:if showMap{closeMap()}else if showHelp||showCredits||showPassport {showHelp=false;showCredits=false;showPassport=false}else{togglePause()}
  case 8:cameraMode=(cameraMode+1)%3;notify(["Chase camera","Far camera","Cockpit"][cameraMode])
  case 17:toggleSceneryStyle()
  case 40:toggleMusic()
  case 45:nextMusic()
  case 15:reset()
  case 46:toggleMap()
  case 4:if !paused{photoMode.toggle()}
  case 38:openPassport()
  case 44:openHelp()
  case 1,125,13,126,0,123,2,124,49,14,12:break
  case 36:if paused{launched ? resume():begin()}
  default:break
  }
 }
 var nextTarget:Place? {challenge && nextGate<routes[routeIndex].gates.count ? routes[routeIndex].gates[nextGate]:nil}
 func update(_ dt:Float){
  guard !paused,terrain != nil else{return};previous=position;time += dt;if !routeFinished {flightElapsed += dt};collideCooldown=max(0,collideCooldown-dt)
  shake=max(0,shake-dt*1.7);updateParticles(dt)
  if crashing {updateCrash(dt)} else {
   var turn:Float=(keys.contains(2)||keys.contains(124) ? 1:0)-(keys.contains(0)||keys.contains(123) ? 1:0)
   var climb:Float=(keys.contains(1)||keys.contains(125) ? 1:0)-(keys.contains(13)||keys.contains(126) ? 1:0)
   var boosting=shift||keys.contains(14),braking=keys.contains(49)||keys.contains(12)
   if let pad=GCController.controllers().first?.extendedGamepad {turn += pad.leftThumbstick.xAxis.value;climb -= pad.leftThumbstick.yAxis.value;boosting = boosting || pad.rightTrigger.value>0.3;braking = braking || pad.leftTrigger.value>0.3}
   fly(dt,turn:clamp(turn+demoInput.x,-1,1),climb:clamp(climb+demoInput.y,-1,1),boosting:boosting,braking:braking)
   let edge=max(abs(position.x),abs(position.z))
   if edge>worldHalf-3000 {let desired=atan2(-position.x,position.z),diff=atan2(sin(desired-yaw),cos(desired-yaw));yaw += clamp(diff,-1,1)*dt*min(2,(edge-worldHalf+3000)/600);if edge>worldHalf-200{position.x=clamp(position.x,-worldHalf+200,worldHalf-200);position.z=clamp(position.z,-worldHalf+200,worldHalf-200)}}
   if let (p,c)=sweptContact(from:previous,to:position) {position=p;impact(c)}
  }
  // Gates and points are markers on the map: passing within 140 m counts at any altitude.
  func passes(_ place:Place)->Bool {
   var a=previous,b=position,target=place.position;a.y=0;b.y=0;target.y=0
   let ab=b-a,t=clamp(dot(target-a,ab)/max(0.001,dot(ab,ab)),0,1)
   return distance(a+ab*t,target)<FlightGame.collectRadius
  }
  if !crashing,let target=nextTarget,passes(target) {
   nextGate+=1;points+=1000;burstTime=time;chime?.currentTime=0;chime?.play();notify("\(target.name) · +1,000")
   if nextGate==routes[routeIndex].gates.count {routeFinished=true;notify("Route complete · \(points) points · \(Int(flightElapsed)) s");let key="BayDayNative.best.\(routeIndex)",best=preferences.float(forKey:key);if !isTesting && (best==0||flightElapsed<best){preferences.set(flightElapsed,forKey:key)}}
  }
  if !crashing {for (i,p) in sights.enumerated() where !discovered.contains(i) && passes(p) {collect(i)}}
  if activeDiscovery != nil && time-discoveryTime>12 {activeDiscovery=nil};collectionPulse=max(0,collectionPulse-dt*0.7)

  if time-lastToast>5 && !toast.isEmpty{toast=""}
  publishTimer += dt
  if publishTimer>0.1 {publishTimer=0;publishHUD()}
 }
 // The label for the ground below. Water is decided from the elevation grid every time, so
 // the name changes as soon as the aircraft crosses the shore.
 func refreshPlace(){
  guard !isTesting,let terrain else{return}
  locator.update(position:position,now:CFAbsoluteTimeGetCurrent()){[weak self] in self?.refreshPlace()}
  let label=locator.label(position:position,overWater:terrain.height(position.x,position.z)<=0.5)
  if label != place{place=label}
 }
 func publishHUD(){
   refreshPlace()
   elapsed=flightElapsed;speedReadout=Int(length(motion)*1.94384);altitude=Int(position.y*3.28084);height=Int(max(0,position.y-Aero.clearance-(terrain?.surface(position) ?? 0))*3.28084);heading=(Int(yaw*180/Float.pi)%360+360)%360;boostReadout=boost;if stalling != (stallAmount>0.35){stalling=stallAmount>0.35};let high=position.y>Aero.ceiling-200 && pitchInput>0.3;if atCeiling != high{atCeiling=high}
   if let p=nextTarget{nearest=p.name;let delta=p.position-position;distanceText=rangeLabel(hypot(delta.x,delta.z));courseBearing=atan2(delta.x,-delta.z)-yaw}
   else if let i=targetDiscovery {let p=sights[i];nearest=p.name;distanceText=rangeLabel(discoveryDistance(p));let d=p.position-position;courseBearing=atan2(d.x,-d.z)-yaw}else{nearest="All points found";distanceText="";courseBearing=0}
 }
}
