import Foundation
import simd
let worldHalf:Float = 24640
let worldSize:Float = 49280
let metresLon=Float(region.metresPerLongitude),metresLat=Float(region.metresPerLatitude)
func clamp<T:Comparable>(_ v:T,_ lo:T,_ hi:T)->T { min(hi,max(lo,v)) }
// World metres from the region's centre: x east, -z north.
func geographic(_ lat:Float,_ lon:Float)->SIMD3<Float> {SIMD3(Float((Double(lon)-region.longitude)*region.metresPerLongitude),0,Float(-(Double(lat)-region.latitude)*region.metresPerLatitude))}
func coordinate(_ p:SIMD3<Float>)->(latitude:Double,longitude:Double) {(region.latitude-Double(p.z)/region.metresPerLatitude,region.longitude+Double(p.x)/region.metresPerLongitude)}
func translation(_ p:SIMD3<Float>)->simd_float4x4 { var m=matrix_identity_float4x4;m.columns.3=SIMD4(p,1);return m }
func rotation(_ angle:Float,_ axis:SIMD3<Float>)->simd_float4x4 { simd_float4x4(simd_quatf(angle:angle,axis:axis)) }
func scaling(_ s:Float)->simd_float4x4 { simd_float4x4(diagonal:SIMD4(s,s,s,1)) }
func lookAt(_ eye:SIMD3<Float>,_ target:SIMD3<Float>,up:SIMD3<Float> = SIMD3(0,1,0))->simd_float4x4 {
 let z=normalize(eye-target),x=normalize(cross(up,z)),y=cross(z,x)
 return simd_float4x4(SIMD4(x.x,y.x,z.x,0),SIMD4(x.y,y.y,z.y,0),SIMD4(x.z,y.z,z.z,0),SIMD4(-dot(x,eye),-dot(y,eye),-dot(z,eye),1))
}
// Infinite-far reversed Z: near maps to 1 and distant geometry approaches 0.
// Paired with float depth, .greaterEqual, and a zero clear.
func perspective(_ fov:Float,_ aspect:Float,_ near:Float=1)->simd_float4x4 {
 let s=1/tan(fov/2)
 return simd_float4x4(SIMD4(s/aspect,0,0,0),SIMD4(0,s,0,0),SIMD4(0,0,0,-1),SIMD4(0,0,near,0))
}
struct TerrainData {
 var samples:[Int16]
 init(_ url:URL)throws { let d=try Data(contentsOf:url);guard d.count==1025*1025*2 else{throw NSError(domain:"Terrain",code:1,userInfo:[NSLocalizedDescriptionKey:"Invalid terrain data"])};samples=d.withUnsafeBytes{Array($0.bindMemory(to:Int16.self))} }
 func height(_ x:Float,_ z:Float)->Float {
  let u=clamp((x+worldHalf)/worldSize*1024,0,1023.999),v=clamp((z+worldHalf)/worldSize*1024,0,1023.999),i=Int(u),j=Int(v),a=u-Float(i),b=v-Float(j),k=j*1025+i
  return (Float(samples[k])*(1-a)*(1-b)+Float(samples[k+1])*a*(1-b)+Float(samples[k+1025])*(1-a)*b+Float(samples[k+1026])*a*b)*0.1
 }
 func surface(_ p:SIMD3<Float>)->Float {max(0,height(p.x,p.z))}
}

// MARK: Camera
// The map camera is placed where a real chase (or cockpit) camera would be, so the aircraft
// drawn over the map sits at its true position and height above the scenery.
//
// MapKit limits how far the camera may tilt from straight down, in steps by its distance to
// the point it looks at (measured): 70° within 1 km, 60° within about 2 km, 35° beyond. A
// step would make the view jump, so the tilt is chosen as a continuous function of the
// camera's height that always stays inside those limits.
enum MapCamera {
 static let fieldOfView:Float = .pi/6          // MapKit's vertical field of view
 static let nearLimit:Float=960,midLimit:Float=1850,minimumDistance:Float=114
 static func tilt(height:Float)->Float {
  let h=max(1,height),c70=cos(70*Float.pi/180),c60:Float=0.5,c35=cos(35*Float.pi/180)
  if h<=nearLimit*c70 {return 70}
  if h<nearLimit*c60 {return acos(h/nearLimit)*180/Float.pi}
  if h<=midLimit*c60 {return 60}
  if h<midLimit*c35 {return acos(h/midLimit)*180/Float.pi}
  return 35
 }
 // The tilt MapKit will actually honour at a given distance.
 static func allowedTilt(distance:Float)->Float {distance<=1000 ? 70:distance<=2000 ? 60:35}
 // Camera position in the aircraft's heading frame (x right, y up, -z ahead) for a tilt in degrees.
 // Modes: 0 chase, 1 far chase, 2 cockpit (the pilot's eye).
 static func eye(_ mode:Int,tilt:Float)->SIMD3<Float> {
  if mode==2 {return SIMD3(0,0.8,-0.9)}
  // Behind the aircraft along the line of sight, raised a little in the camera's own up
  // direction so the aircraft sits just below the centre of the view at every tilt.
  let r=tilt*Float.pi/180,distance:Float=mode==1 ? 95:46,raise:Float=mode==1 ? 5:2.5
  return SIMD3(0,cos(r),sin(r))*distance+SIMD3(0,sin(r),-cos(r))*raise
 }
 static func view(tilt:Float)->SIMD3<Float> {let r=tilt*Float.pi/180;return SIMD3(0,-cos(r),-sin(r))}
}
// Projection for the aircraft layer from a camera position in the aircraft's heading frame.
func aircraftOverlayProjection(eye:SIMD3<Float>,tilt:Float,_ aspect:Float)->simd_float4x4 {
 perspective(MapCamera.fieldOfView,aspect,0.5)*lookAt(eye,eye+MapCamera.view(tilt:tilt))
}
func aircraftOverlayProjection(_ mode:Int,_ aspect:Float,tilt:Float=70)->simd_float4x4 {aircraftOverlayProjection(eye:MapCamera.eye(mode,tilt:tilt),tilt:tilt,aspect)}
// MapKit cannot roll or look above its tilt limit. In the cockpit the map picture itself is
// turned against the bank and slid down as the nose rises, with sky behind it, so its far
// edge reads as the horizon. Returns the rotation (radians, counter-clockwise), the downward
// slide as a fraction of the view height, and the scale that keeps the corners covered.
func cockpitHorizon(roll:Float,pitch:Float,aspect:Float)->(angle:Float,slide:Float,cover:Float) {
 let angle=roll*0.6,slide=0.2+clamp(pitch,-0.5,1)*0.3
 return (angle,slide,cos(abs(angle))+max(aspect,1/aspect)*sin(abs(angle)))
}
// One camera for both layers. `eye` is where the camera really is after every adjustment,
// and `local` is that position in the aircraft's heading frame; the map and the aircraft
// layer are both drawn from it, so they cannot disagree.
// The cockpit's screen-space turn and slide of the map (cockpitHorizon), as a transform of
// clip space, so effects drawn by the aircraft layer stay registered with the scenery.
func cockpitClipTransform(roll:Float,pitch:Float,aspect:Float)->simd_float4x4 {
 let h=cockpitHorizon(roll:roll,pitch:pitch,aspect:aspect)
 let stretch=simd_float4x4(diagonal:SIMD4(aspect,1,1,1)),squeeze=simd_float4x4(diagonal:SIMD4(1/aspect,1,1,1)),cover=simd_float4x4(diagonal:SIMD4(h.cover,h.cover,1,1))
 return translation(SIMD3(0,-2*h.slide,0))*squeeze*rotation(h.angle,SIMD3(0,0,1))*stretch*cover
}
struct CameraSolution {var eye:SIMD3<Float>,local:SIMD3<Float>,centre:SIMD3<Float>,distance:Float,tilt:Float}
extension CameraSolution {
 // Acceptable to MapKit at its solved distance, and clear of the terrain.
 func usable(_ terrain:TerrainData)->Bool {tilt<=MapCamera.allowedTilt(distance:distance) && eye.y>=terrain.surface(eye)+2}
}
// The camera for one given tilt: where it is, and the ground point on its line of sight
// that MapKit is asked to look at.
func cameraSolution(position:SIMD3<Float>,yaw:Float,mode:Int,terrain:TerrainData,tilt:Float)->CameraSolution {
 let ahead=SIMD3<Float>(sin(yaw),0,-cos(yaw))
 let nominal=MapCamera.eye(mode,tilt:tilt),r=tilt*Float.pi/180
 var eye=position+SIMD3(0,nominal.y,0)-ahead*nominal.z
 eye.y=max(eye.y,terrain.surface(eye)+2)                // never inside a hillside behind the aircraft
 let ray=ahead*sin(r)+SIMD3(0,-cos(r),0)
 var near:Float=0,far:Float=0
 while far<20000 {far += 40;let q=eye+ray*far;if q.y<=terrain.surface(q){break};near=far}
 for _ in 0..<10 {let mid=(near+far)/2,q=eye+ray*mid;if q.y<=terrain.surface(q){far=mid}else{near=mid}}
 let centre=eye+ray*far
 // MapKit will not come closer than its minimum distance: back the camera up along its line of sight.
 if far<MapCamera.minimumDistance {far=MapCamera.minimumDistance;eye=centre-ray*far}
 let offset=eye-position
 return CameraSolution(eye:eye,local:SIMD3(0,offset.y,-dot(offset,ahead)),centre:centre,distance:far,tilt:tilt)
}
// The tilt actually used glides toward the solved one. Rough ground can move the solved
// tilt abruptly from one metre to the next; easing turns that into a short, smooth change.
func easedTilt(current:Float,target:Float,elapsed:Float)->Float {current+clamp(target-current,-30*elapsed,30*elapsed)}
// The preferred camera for the aircraft's position: the shallowest tilt MapKit allows.
func solveMapCamera(position:SIMD3<Float>,yaw:Float,mode:Int,terrain:TerrainData)->CameraSolution {
 func solve(_ tilt:Float)->CameraSolution {cameraSolution(position:position,yaw:yaw,mode:mode,terrain:terrain,tilt:tilt)}
 // Use the shallowest tilt MapKit will honour at the distance that tilt produces. A steeper
 // tilt always shortens the distance, so each band is searched for the point where the
 // distance reaches its limit; the result changes smoothly as the aircraft climbs.
 func settle(from steep:Float,to shallow:Float,limit:Float)->CameraSolution? {
  var best=solve(steep)
  guard best.distance<=limit else{return nil}
  let top=solve(shallow)
  if top.distance<=limit {return top}
  var lo=steep,hi=shallow
  for _ in 0..<9 {let mid=(lo+hi)/2,m=solve(mid);if m.distance<=limit{lo=mid;best=m}else{hi=mid}}
  return best
 }
 var s=settle(from:60,to:70,limit:MapCamera.nearLimit) ?? settle(from:35,to:60,limit:MapCamera.midLimit) ?? solve(35)
 // On a very low pass beside a slope the backed-up camera can end inside the hill; look down more steeply until it is clear.
 for tilt:Float in [60,50,42,35] where s.tilt>tilt && s.eye.y<terrain.surface(s.eye)+2 {s=solve(tilt)}
 return s
}
