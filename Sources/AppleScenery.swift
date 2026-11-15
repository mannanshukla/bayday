import AppKit
import MapKit
import SwiftUI
import simd
final class DiscoveryAnnotation:NSObject,MKAnnotation {
 let index:Int
 var coordinate:CLLocationCoordinate2D
 var title:String? {sights[index].name}
 init(_ index:Int){self.index=index;let p=sights[index];coordinate=CLLocationCoordinate2D(latitude:Double(p.lat),longitude:Double(p.lon));super.init()}
}
final class GateAnnotation:NSObject,MKAnnotation {
 let number:Int,next:Bool
 var coordinate:CLLocationCoordinate2D
 init(_ place:Place,number:Int,next:Bool){self.number=number;self.next=next;coordinate=CLLocationCoordinate2D(latitude:Double(place.lat),longitude:Double(place.lon));super.init()}
}
// A numbered gate on the map. The next gate is larger and filled.
struct GateBadge:View {
 let number:Int,next:Bool
 var body:some View {
  let size:CGFloat=next ? 52:34
  ZStack {
   Circle().fill(next ? AnyShapeStyle(Color.orange.gradient):AnyShapeStyle(Color.black.opacity(0.35)))
   Circle().strokeBorder(next ? Color.white:Color.orange,lineWidth:next ? 3:2.5)
   Text("\(number)").font(.system(size:size*0.42,weight:.bold)).foregroundStyle(.white)
  }.frame(width:size,height:size).shadow(color:.black.opacity(0.3),radius:3,y:2)
 }
}
final class MapGateView:MKAnnotationView {
 var host:NSHostingView<GateBadge>?
 func set(_ a:GateAnnotation){
  let badge=GateBadge(number:a.number,next:a.next),side:CGFloat=a.next ? 60:42
  if let host {host.rootView=badge;host.frame=NSRect(x:0,y:0,width:side,height:side)}else{let h=NSHostingView(rootView:badge);h.frame=NSRect(x:0,y:0,width:side,height:side);addSubview(h);host=h}
  frame=NSRect(x:0,y:0,width:side,height:side);centerOffset=NSPoint(x:0,y:-side/2);canShowCallout=false;displayPriority = .required;zPriority = a.next ? .max:.defaultUnselected
 }
}
final class MapDiscoveryView:MKAnnotationView {
 var host:NSHostingView<InfoOrb>?
 var collected=false
 func setCollected(_ value:Bool){guard host==nil || collected != value else{return};collected=value
  if let host {host.rootView=InfoOrb(collected:value,size:43)}else{let h=NSHostingView(rootView:InfoOrb(collected:value,size:43));h.frame=NSRect(x:0,y:0,width:52,height:52);addSubview(h);host=h;frame=NSRect(x:0,y:0,width:52,height:52);centerOffset=NSPoint(x:0,y:-30);canShowCallout=false;displayPriority = .required}
 }
}
struct AppleScenery:NSViewRepresentable {
 @ObservedObject var game:FlightGame
 // The map is drawn wider than the window so scenery to either side is already loaded when the aircraft turns.
 static let overscan:CGFloat=CGFloat(Double(ProcessInfo.processInfo.environment["BAYDAY_OVERSCAN"] ?? "") ?? 1.3)
 func makeCoordinator()->Coordinator {Coordinator(game)}
 func makeNSView(context:Context)->MKMapView {
  let map=MKMapView(frame:.zero);map.delegate=context.coordinator;map.showsBuildings=true;map.showsCompass=false;map.showsScale=false;map.isZoomEnabled=false;map.isScrollEnabled=false;map.isRotateEnabled=false;map.isPitchEnabled=false
  map.register(MapDiscoveryView.self,forAnnotationViewWithReuseIdentifier:"info");map.register(MapGateView.self,forAnnotationViewWithReuseIdentifier:"gate");map.addAnnotations(sights.indices.map{DiscoveryAnnotation($0)})
  game.appleMap=map;game.mapSceneryMode = -1;context.coordinator.mode=game.scenery;configure(map);return map
 }
 func updateNSView(_ map:MKMapView,context:Context){
  if context.coordinator.mode != game.scenery {configure(map);context.coordinator.mode=game.scenery}
  // A different region has different points.
  if context.coordinator.regionID != game.regionID {
   context.coordinator.regionID=game.regionID;context.coordinator.gateKey = -2
   map.removeAnnotations(map.annotations.filter{$0 is DiscoveryAnnotation});map.addAnnotations(sights.indices.map{DiscoveryAnnotation($0)})
  }
  // Remaining gates of the current route; rebuilt only when the route or the next gate changes.
  let gateKey=game.challenge && !game.routeFinished ? game.routeIndex*1000+game.nextGate:-1
  if context.coordinator.gateKey != gateKey {
   context.coordinator.gateKey=gateKey
   map.removeAnnotations(map.annotations.filter{$0 is GateAnnotation})
   if gateKey>=0 {let gates=routes[game.routeIndex].gates;map.addAnnotations((game.nextGate..<gates.count).map{GateAnnotation(gates[$0],number:$0+1,next:$0==game.nextGate)})}
  }
  for annotation in map.annotations where annotation is GateAnnotation {map.view(for:annotation)?.isHidden=game.photoMode}
  for annotation in map.annotations {if let a=annotation as? DiscoveryAnnotation,let view=map.view(for:a) as? MapDiscoveryView{view.setCollected(game.discovered.contains(a.index));view.isHidden=game.photoMode}}
 }
 func configure(_ map:MKMapView){
  if game.scenery==2 {map.preferredConfiguration=MKImageryMapConfiguration(elevationStyle:.realistic);map.mapType = .satelliteFlyover}
  else {let config=MKStandardMapConfiguration(elevationStyle:.realistic,emphasisStyle:.default);config.pointOfInterestFilter = .excludingAll;map.preferredConfiguration=config}
 }
 class Coordinator:NSObject,MKMapViewDelegate {
  let game:FlightGame;var mode = -1,gateKey = -1,regionID=region.id
  init(_ game:FlightGame){self.game=game}
  func mapView(_ mapView:MKMapView,viewFor annotation:any MKAnnotation)->MKAnnotationView? {
   if let gate=annotation as? GateAnnotation {let v=mapView.dequeueReusableAnnotationView(withIdentifier:"gate",for:annotation) as! MapGateView;v.set(gate);v.isHidden=game.photoMode;return v}
   guard let a=annotation as? DiscoveryAnnotation else{return nil};let v=mapView.dequeueReusableAnnotationView(withIdentifier:"info",for:annotation) as! MapDiscoveryView;v.setCollected(game.discovered.contains(a.index));v.isHidden=game.photoMode;return v
  }
  func mapView(_ mapView:MKMapView,didAdd views:[MKAnnotationView]){for view in views where view is MapDiscoveryView{view.isHidden=game.photoMode}}
  func mapView(_ mapView:MKMapView,didFailLoadingMapWithError error:Error){game.mapNotice="Apple Maps could not load. Check the internet connection."}
  func mapViewDidFinishRenderingMap(_ mapView:MKMapView,fullyRendered:Bool){if fullyRendered && !game.mapNotice.isEmpty{game.mapNotice=""}}
 }
}
extension FlightGame {
 func updateAppleCamera(){
  guard let map=appleMap,let terrain else{return}
  let changed=simd_distance(position,mapCameraPosition)>0.05 || abs(yaw-mapCameraYaw)>0.0001 || abs(pitch-mapCameraPitch)>0.0001 || abs(roll-mapCameraRoll)>0.0001 || cameraMode != mapCameraMode || scenery != mapSceneryMode || map.bounds.size != mapCameraSize
  guard changed else{return}
  // A new flight, a recovery, a camera switch or a long gap takes the solved camera at once.
  let now=CFAbsoluteTimeGetCurrent(),elapsed=Float(now-mapCameraClock),fresh=mapCameraPosition.x.isInfinite || cameraMode != mapCameraMode || elapsed>0.25
  // Runs once per drawn frame, so the map and the aircraft layer always move together.
  mapCameraClock=now;mapCameraPosition=position;mapCameraYaw=yaw;mapCameraPitch=pitch;mapCameraRoll=roll;mapCameraMode=cameraMode;mapSceneryMode=scenery;mapCameraSize=map.bounds.size
  var s=solveMapCamera(position:position,yaw:yaw,mode:cameraMode,terrain:terrain)
  if !fresh && abs(s.tilt-cameraTilt)>0.05 {
   let eased=cameraSolution(position:position,yaw:yaw,mode:cameraMode,terrain:terrain,tilt:easedTilt(current:cameraTilt,target:s.tilt,elapsed:elapsed))
   if eased.usable(terrain) {s=eased}
  }
  cameraTilt=s.tilt;cameraEye=s.local
  let at=coordinate(s.centre),coord=CLLocationCoordinate2D(latitude:at.latitude,longitude:at.longitude)
  map.setCamera(MKMapCamera(lookingAtCenter:coord,fromDistance:Double(s.distance),pitch:Double(s.tilt),heading:Double(yaw)*180/Double.pi),animated:false)
  // Slide (and in the cockpit, turn) the map picture on screen; see screenHorizon. The map
  // view is wider than the window, so the turn is measured against the window's shape.
  guard let layer=map.layer else{return}
  let size=map.bounds.size,h=screenHorizon(mode:cameraMode,roll:roll,pitch:pitch,aspect:Float(size.width/AppleScenery.overscan/max(1,size.height)),tilt:s.tilt)
  layer.setAffineTransform(CGAffineTransform(translationX:size.width/2,y:size.height/2-CGFloat(h.slide)*size.height).rotated(by:CGFloat(h.angle)).scaledBy(x:CGFloat(h.cover),y:CGFloat(h.cover)).translatedBy(x:-size.width/2,y:-size.height/2))
  // A second, smaller map looks a few seconds ahead so that scenery is already loading
  // when the aircraft gets there.
  if let ahead=prefetchMap,now-prefetchClock>0.25,ProcessInfo.processInfo.environment["BAYDAY_NO_PREFETCH"] == nil {
   prefetchClock=now
   let lead=SIMD3<Float>(sin(yaw),0,-cos(yaw))*max(600,speed*6),there=coordinate(s.centre+lead)
   ahead.setCamera(MKMapCamera(lookingAtCenter:CLLocationCoordinate2D(latitude:there.latitude,longitude:there.longitude),fromDistance:Double(s.distance),pitch:Double(s.tilt),heading:Double(yaw)*180/Double.pi),animated:false)
  }
 }
}

// Loads scenery ahead of the aircraft. It sits behind the main map and is never seen.
struct SceneryPrefetch:NSViewRepresentable {
 @ObservedObject var game:FlightGame
 func makeNSView(context:Context)->MKMapView {
  let map=MKMapView(frame:.zero);map.showsBuildings=true;map.showsCompass=false;map.showsScale=false;map.isZoomEnabled=false;map.isScrollEnabled=false;map.isRotateEnabled=false;map.isPitchEnabled=false
  configure(map);game.prefetchMap=map;return map
 }
 func updateNSView(_ map:MKMapView,context:Context){if context.coordinator.mode != game.scenery {context.coordinator.mode=game.scenery;configure(map)}}
 func configure(_ map:MKMapView){
  if game.scenery==2 {map.preferredConfiguration=MKImageryMapConfiguration(elevationStyle:.realistic);map.mapType = .satelliteFlyover}
  else {let config=MKStandardMapConfiguration(elevationStyle:.realistic,emphasisStyle:.default);config.pointOfInterestFilter = .excludingAll;map.preferredConfiguration=config}
 }
 func makeCoordinator()->Coordinator {Coordinator()}
 class Coordinator {var mode = -1}
}
