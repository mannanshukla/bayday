import AppKit
import MapKit
import SwiftUI

// A separate, flat satellite chart avoids the no-data rectangles in the offline
// imagery atlas. Its extent stays fixed; only the aircraft and discovery dots move.
final class NavigationAnnotation:NSObject,MKAnnotation {
 // -1 is the aircraft, 0..<gateBase a discovery point, gateBase+n a route gate.
 static let gateBase=1000
 let index:Int
 @objc dynamic var coordinate:CLLocationCoordinate2D
 init(index:Int,coordinate:CLLocationCoordinate2D){self.index=index;self.coordinate=coordinate;super.init()}
}
final class NavigationMarker:MKAnnotationView {
 var aircraft=false,found=false,tracked=false,gate=false,nextGate=false
 var heading:Float=0
 override func draw(_ dirtyRect:NSRect){
  NSGraphicsContext.saveGraphicsState()
  let transform=AffineTransform(translationByX:bounds.midX,byY:bounds.midY)
  (transform as NSAffineTransform).concat()
  // Draw in y-up coordinates whichever way MapKit flips the view, so north is always up.
  if isFlipped {let flip=NSAffineTransform();flip.scaleX(by:1,yBy:-1);flip.concat()}
  if aircraft {
   // Heading is clockwise from north; a clockwise turn is a negative rotation with y up.
   let turn=NSAffineTransform();turn.rotate(byRadians:-CGFloat(heading));turn.concat()
   let p=NSBezierPath();p.move(to:NSPoint(x:0,y:10));p.line(to:NSPoint(x:-7,y:-7));p.line(to:NSPoint(x:0,y:-3));p.line(to:NSPoint(x:7,y:-7));p.close()
   NSColor.systemBlue.setFill();p.fill();NSColor.white.setStroke();p.lineWidth=1.8;p.lineJoinStyle = .round;p.stroke()
  }else if gate {
   let r:CGFloat=nextGate ? 5.5:3.5,p=NSBezierPath(ovalIn:NSRect(x:-r,y:-r,width:r*2,height:r*2));NSColor.systemOrange.setFill();p.fill();NSColor.white.setStroke();p.lineWidth=nextGate ? 2:1;p.stroke()
  }else{
   let p=NSBezierPath(ovalIn:NSRect(x:-3,y:-3,width:6,height:6));(found ? NSColor.systemGreen:NSColor.systemCyan).setFill();p.fill();NSColor.white.setStroke();p.lineWidth=1;p.stroke()
   if tracked{let ring=NSBezierPath(ovalIn:NSRect(x:-6,y:-6,width:12,height:12));NSColor.systemYellow.setStroke();ring.lineWidth=2;ring.stroke()}
  }
  NSGraphicsContext.restoreGraphicsState()
 }
}
struct LiveFlightMap:NSViewRepresentable {
 @ObservedObject var game:FlightGame
 let size:CGFloat
 func makeCoordinator()->Coordinator {Coordinator(game)}
 func makeNSView(context:Context)->MKMapView {
  let map=MKMapView(frame:NSRect(x:0,y:0,width:size,height:size))
  map.preferredConfiguration=MKImageryMapConfiguration(elevationStyle:.flat)
  map.showsBuildings=false;map.showsCompass=false;map.showsScale=false
  map.isZoomEnabled=false;map.isScrollEnabled=false;map.isRotateEnabled=false;map.isPitchEnabled=false
  map.delegate=context.coordinator
  map.register(NavigationMarker.self,forAnnotationViewWithReuseIdentifier:"navigation")
  map.addAnnotations(sights.indices.map{NavigationAnnotation(index:$0,coordinate:CLLocationCoordinate2D(latitude:Double(sights[$0].lat),longitude:Double(sights[$0].lon)))})
  map.addAnnotation(context.coordinator.aircraft)
  if !follows{setExtent(map)};context.coordinator.size=size
  return map
 }
 func setExtent(_ map:MKMapView){map.setRegion(MKCoordinateRegion(center:CLLocationCoordinate2D(latitude:37.76,longitude:-122.38),latitudinalMeters:Double(worldSize),longitudinalMeters:Double(worldSize)),animated:false)}
 // The small in-flight map follows the aircraft; the large map shows the whole region.
 var follows:Bool {size<300}
 func updateNSView(_ map:MKMapView,context:Context){
  let p=game.position,c=CLLocationCoordinate2D(latitude:37.76-Double(p.z)/110990,longitude:-122.38+Double(p.x/metresLon))
  if context.coordinator.size != size {context.coordinator.size=size;context.coordinator.centre=nil;if !follows{setExtent(map)}}
  if follows {
   let last=context.coordinator.centre
   if last == nil || abs(last!.latitude-c.latitude)>0.0004 || abs(last!.longitude-c.longitude)>0.0005 {
    context.coordinator.centre=c;map.setRegion(MKCoordinateRegion(center:c,latitudinalMeters:12000,longitudinalMeters:12000),animated:false)
   }
  }
  let aircraft=context.coordinator.aircraft
  if abs(c.latitude-aircraft.coordinate.latitude)>0.000001 || abs(c.longitude-aircraft.coordinate.longitude)>0.000001{aircraft.coordinate=c}
  let gateKey=game.challenge && !game.routeFinished ? game.routeIndex*1000+game.nextGate:-1
  if context.coordinator.gateKey != gateKey {
   context.coordinator.gateKey=gateKey
   map.removeAnnotations(map.annotations.filter{($0 as? NavigationAnnotation).map{$0.index>=NavigationAnnotation.gateBase} ?? false})
   if gateKey>=0 {let gates=routes[game.routeIndex].gates;map.addAnnotations((game.nextGate..<gates.count).map{NavigationAnnotation(index:NavigationAnnotation.gateBase+$0,coordinate:CLLocationCoordinate2D(latitude:Double(gates[$0].lat),longitude:Double(gates[$0].lon)))})}
  }
  for a in map.annotations{if let marker=map.view(for:a) as? NavigationMarker,let a=a as? NavigationAnnotation{context.coordinator.configure(marker,a)}}
 }
 class Coordinator:NSObject,MKMapViewDelegate {
  let game:FlightGame
  var size:CGFloat=0,gateKey = -1
  var centre:CLLocationCoordinate2D?
  let aircraft=NavigationAnnotation(index:-1,coordinate:CLLocationCoordinate2D(latitude:37.76,longitude:-122.38))
  init(_ game:FlightGame){self.game=game}
  func configure(_ view:NavigationMarker,_ a:NavigationAnnotation){
   view.aircraft=a.index == -1;view.gate=a.index>=NavigationAnnotation.gateBase;view.nextGate=a.index-NavigationAnnotation.gateBase==game.nextGate;view.found=game.discovered.contains(a.index);view.tracked=game.trackedDiscovery==a.index;view.heading=game.yaw;view.needsDisplay=true
   view.displayPriority = .required;view.canShowCallout=false;let side:CGFloat=view.aircraft ? 26:18;if view.frame.size != NSSize(width:side,height:side){view.setFrameSize(NSSize(width:side,height:side))};if view.aircraft{view.zPriority = .max}
   view.setAccessibilityLabel(view.aircraft ? "Your aircraft":view.gate ? "Gate \(a.index-NavigationAnnotation.gateBase+1)":sights[a.index].name)
  }
  func mapView(_ mapView:MKMapView,viewFor annotation:any MKAnnotation)->MKAnnotationView?{
   guard let a=annotation as? NavigationAnnotation else{return nil}
   let v=mapView.dequeueReusableAnnotationView(withIdentifier:"navigation",for:annotation) as! NavigationMarker
   configure(v,a);return v
  }
 }
}
