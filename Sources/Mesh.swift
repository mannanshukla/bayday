import Foundation
import Metal
import simd

// Vertex layout: position(3) normal(3) colour(3) uv(2) kind(1).
// Kinds: 0 gloss paint, 1 glass, 2 matte, 3 emissive.
struct Mesh {
 let buffer:MTLBuffer
 let count:Int
 init(device:MTLDevice,vertices:[Float]) {
  buffer=device.makeBuffer(bytes:vertices,length:max(1,vertices.count)*4,options:.storageModeShared)!
  count=vertices.count/12
 }
}
typealias Paint=(SIMD3<Float>)->(SIMD3<Float>,Float)
struct MeshBuilder {
 var vertices=[Float]()
 mutating func vertex(_ p:SIMD3<Float>,_ n:SIMD3<Float>,_ c:SIMD3<Float>,_ kind:Float=2) {vertices += [p.x,p.y,p.z,n.x,n.y,n.z,c.x,c.y,c.z,0,0,kind]}
 mutating func quad(_ a:SIMD3<Float>,_ b:SIMD3<Float>,_ c:SIMD3<Float>,_ d:SIMD3<Float>,_ color:SIMD3<Float>,kind:Float=2) {
  let n=normalize(cross(b-a,c-a));for p in [a,b,c,a,c,d]{vertex(p,n,color,kind)}
 }
 mutating func box(_ p:SIMD3<Float>,_ size:SIMD3<Float>,_ c:SIMD3<Float>,kind:Float=2) {
  let a=p-size/2,b=p+size/2
  quad(SIMD3(a.x,a.y,b.z),SIMD3(b.x,a.y,b.z),SIMD3(b.x,b.y,b.z),SIMD3(a.x,b.y,b.z),c,kind:kind)
  quad(SIMD3(b.x,a.y,a.z),SIMD3(a.x,a.y,a.z),SIMD3(a.x,b.y,a.z),SIMD3(b.x,b.y,a.z),c,kind:kind)
  quad(SIMD3(a.x,a.y,a.z),SIMD3(a.x,a.y,b.z),SIMD3(a.x,b.y,b.z),SIMD3(a.x,b.y,a.z),c,kind:kind)
  quad(SIMD3(b.x,a.y,b.z),SIMD3(b.x,a.y,a.z),SIMD3(b.x,b.y,a.z),SIMD3(b.x,b.y,b.z),c,kind:kind)
  quad(SIMD3(a.x,b.y,b.z),SIMD3(b.x,b.y,b.z),SIMD3(b.x,b.y,a.z),SIMD3(a.x,b.y,a.z),c,kind:kind)
  quad(SIMD3(a.x,a.y,a.z),SIMD3(b.x,a.y,a.z),SIMD3(b.x,a.y,b.z),SIMD3(a.x,a.y,b.z),c,kind:kind)
 }
 mutating func ellipsoid(_ p:SIMD3<Float>,_ scale:SIMD3<Float>,_ color:SIMD3<Float>,segments:Int=14,rings:Int=8,kind:Float=2) {
  func point(_ u:Int,_ v:Int)->(SIMD3<Float>,SIMD3<Float>){let a=Float(u)/Float(segments)*2*Float.pi,b=Float(v)/Float(rings)*Float.pi;let n=SIMD3(sin(b)*cos(a),cos(b),sin(b)*sin(a));return(p+n*scale,normalize(n/scale))}
  for j in 0..<rings {for i in 0..<segments {for uv in [(i,j),(i+1,j),(i+1,j+1),(i,j),(i+1,j+1),(i,j+1)] {let q=point(uv.0,uv.1);vertex(q.0,q.1,color,kind)}}}
 }
 // A round strut or tube with smooth normals.
 mutating func beam(_ a:SIMD3<Float>,_ b:SIMD3<Float>,_ radius:Float,_ color:SIMD3<Float>,segments:Int=8,kind:Float=0) {
  let d=normalize(b-a),up:SIMD3<Float>=abs(d.y)>0.9 ? SIMD3(1,0,0):SIMD3(0,1,0),x=normalize(cross(d,up)),y=cross(d,x)
  for i in 0..<segments {
   let t=Float(i)/Float(segments)*2*Float.pi,s=Float(i+1)/Float(segments)*2*Float.pi,n0=x*cos(t)+y*sin(t),n1=x*cos(s)+y*sin(s)
   for (p,n) in [(a+n0*radius,n0),(a+n1*radius,n1),(b+n1*radius,n1),(a+n0*radius,n0),(b+n1*radius,n1),(b+n0*radius,n0)] {vertex(p,n,color,kind)}
  }
 }
 // A smooth skin over a grid of points. Each row is a closed ring; colour and material are
 // chosen per panel from its centre so trim lines and windows keep hard edges.
 mutating func surface(_ grid:[[SIMD3<Float>]],paint:Paint) {
  let rows=grid.count,cols=grid[0].count
  var normals=grid
  for i in 0..<rows {
   let centre=grid[i].reduce(SIMD3<Float>.zero,+)/Float(cols)
   for j in 0..<cols {
    let du=grid[i][(j+1)%cols]-grid[i][(j+cols-1)%cols],dv=grid[min(rows-1,i+1)][j]-grid[max(0,i-1)][j]
    var n=cross(du,dv)
    if length(n)<1e-7 {n=length(dv)>1e-7 ? (i==0 ? -dv:dv):SIMD3(0,1,0)} else if dot(n,grid[i][j]-centre)<0 {n = -n}
    normals[i][j]=normalize(n)
   }
  }
  for i in 0..<rows-1 {for j in 0..<cols {
   let k=(j+1)%cols,(color,kind)=paint((grid[i][j]+grid[i][k]+grid[i+1][k]+grid[i+1][j])/4)
   for (r,c) in [(i,j),(i,k),(i+1,k),(i,j),(i+1,k),(i+1,j)] {vertex(grid[r][c],normals[r][c],color,kind)}
  }}
 }
 func mesh(_ device:MTLDevice)->Mesh {Mesh(device:device,vertices:vertices)}
}

// MARK: Aircraft geometry
// Local axes: nose is -z, up is +y, the right wing is +x. Units are metres.
struct Section {var z:Float,y:Float,rx:Float,ry:Float,power:Float=2.2,x:Float=0}
struct Foil {var le:SIMD3<Float>,chord:Float,thick:Float=0.13,camber:Float=0.02}
struct Hinge {let point:SIMD3<Float>,axis:SIMD3<Float>}

// Rings of a body lofted through cross-sections. `power` squares the section off (2 is an ellipse).
func loft(_ s:[Section],steps:Int=4,segments:Int=28)->[[SIMD3<Float>]] {
 func spline(_ a:Float,_ b:Float,_ c:Float,_ d:Float,_ t:Float)->Float {0.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)}
 var rings=[[SIMD3<Float>]]()
 for k in 0..<s.count-1 {
  let a=s[max(0,k-1)],b=s[k],c=s[k+1],d=s[min(s.count-1,k+2)]
  for step in 0..<(k==s.count-2 ? steps+1:steps) {
   let t=Float(step)/Float(steps),z=b.z+(c.z-b.z)*t,y=spline(a.y,b.y,c.y,d.y,t),x=b.x+(c.x-b.x)*t
   let rx=max(0.004,spline(a.rx,b.rx,c.rx,d.rx,t)),ry=max(0.004,spline(a.ry,b.ry,c.ry,d.ry,t)),e=2/(b.power+(c.power-b.power)*t)
   rings.append((0..<segments).map{j in
    let angle=Float(j)/Float(segments)*2*Float.pi,cs=cos(angle),sn=sin(angle)
    return SIMD3(x+(cs<0 ? -1:1)*pow(abs(cs),e)*rx,y+(sn<0 ? -1:1)*pow(abs(sn),e)*ry,z)
   })
  }
 }
 return rings
}
// Rings of a lifting surface through airfoil sections, optionally only part of the chord
// (so a control surface can be built as its own piece). `axis` is the thickness direction.
func foil(_ sections:[Foil],axis:SIMD3<Float>,from x0:Float=0,to x1:Float=1,points:Int=9)->[[SIMD3<Float>]] {
 sections.map{s in
  func at(_ x:Float,_ side:Float)->SIMD3<Float> {
   let t=s.thick*5*(0.2969*sqrt(x)-0.126*x-0.3516*x*x+0.2843*x*x*x-0.1036*x*x*x*x)
   return s.le+SIMD3(0,0,x*s.chord)+axis*((s.camber*4*x*(1-x)+side*t)*s.chord)
  }
  // Cosine spacing packs points around the leading edge.
  let xs=(0...points).map{x0+(x1-x0)*(1-cos(Float($0)/Float(points)*Float.pi/2))}
  return xs.reversed().map{at($0,1)}+xs.map{at($0,-1)}
 }
}
enum Airframe {
 static let cream=SIMD3<Float>(0.93,0.91,0.84),red=SIMD3<Float>(0.74,0.10,0.07),silver=SIMD3<Float>(0.70,0.72,0.74),dark=SIMD3<Float>(0.05,0.055,0.06),tint=SIMD3<Float>(0.10,0.16,0.20)
 static let propZ:Float = -3.9
 // Bounding half-extents used for ground clearance of a tumbling wreck.
 static let halfSpan:Float=5.75,belly:Float=1.9,halfLength:Float=4.0
 static let wingRoot=Foil(le:SIMD3(0,1.02,-1.5),chord:1.75),wingMid=Foil(le:SIMD3(2.9,1.12,-1.44),chord:1.6),wingOuter=Foil(le:SIMD3(5.5,1.21,-1.36),chord:1.3)
 static let aileronStart:Float=0.72,elevatorStart:Float=0.58,rudderStart:Float=0.6
 static let stabRoot=Foil(le:SIMD3(0,0.42,2.7),chord:1.1,thick:0.09,camber:0),stabTip=Foil(le:SIMD3(1.9,0.42,2.961),chord:0.65,thick:0.09,camber:0)
 static let finRoot=Foil(le:SIMD3(0,0.3,2.35),chord:1.45,thick:0.09,camber:0),finTip=Foil(le:SIMD3(0,1.9,3.15),chord:0.8,thick:0.09,camber:0)
 static func hingePoint(_ f:Foil,_ x:Float)->SIMD3<Float> {f.le+SIMD3(0,0,x*f.chord)}
 static func mirrored(_ p:SIMD3<Float>)->SIMD3<Float> {SIMD3(-p.x,p.y,p.z)}
 // Hinge axes all point toward +x (or up for the rudder) so deflection signs are shared.
 static let aileronRight=Hinge(point:hingePoint(wingMid,aileronStart),axis:normalize(hingePoint(wingOuter,aileronStart)-hingePoint(wingMid,aileronStart)))
 static let aileronLeft=Hinge(point:mirrored(hingePoint(wingMid,aileronStart)),axis:normalize(mirrored(hingePoint(wingMid,aileronStart))-mirrored(hingePoint(wingOuter,aileronStart))))
 static let elevator=Hinge(point:hingePoint(stabRoot,elevatorStart),axis:SIMD3(1,0,0))
 static let rudder=Hinge(point:hingePoint(finRoot,rudderStart),axis:normalize(hingePoint(finTip,rudderStart)-hingePoint(finRoot,rudderStart)))
}
struct AircraftModel {
 let body:Mesh,propeller:Mesh,disc:Mesh,elevator:Mesh,rudder:Mesh,aileronLeft:Mesh,aileronRight:Mesh
 init(_ device:MTLDevice) {
  body=aircraftBody().mesh(device)
  let A=Airframe.self
  func side(_ f:Foil,_ s:Float)->Foil {var g=f;g.le.x *= s;return g}
  func wingPaint(_ p:SIMD3<Float>)->(SIMD3<Float>,Float) {(abs(p.x)>4.75 ? A.red:A.cream,0)}
  var b=MeshBuilder()
  // Ailerons sit just inside the outer panel so they can move without touching it.
  func aileron(_ s:Float)->Mesh {
   var b=MeshBuilder(),inner=A.wingMid,outer=A.wingOuter
   inner.le += (outer.le-inner.le)*0.02;outer.le += (A.wingMid.le-A.wingOuter.le)*0.02
   b.surface(foil([side(inner,s),side(outer,s)],axis:SIMD3(0,1,0),from:A.aileronStart+0.012,to:1,points:5),paint:wingPaint);return b.mesh(device)
  }
  aileronRight=aileron(1);aileronLeft=aileron(-1)
  for s in [-1,1] as [Float] {var inner=A.stabRoot;inner.le.x=0.2;inner.le.z += 0.03;b.surface(foil([side(inner,s),side(A.stabTip,s)],axis:SIMD3(0,1,0),from:A.elevatorStart+0.015,to:1,points:5)){_ in (A.cream,0)}}
  elevator=b.mesh(device)
  b=MeshBuilder();var low=A.finRoot,high=A.finTip
  low.le += (high.le-low.le)*0.04;low.chord += (high.chord-low.chord)*0.04;high.le += (A.finRoot.le-A.finTip.le)*0.03
  b.surface(foil([low,high],axis:SIMD3(1,0,0),from:A.rudderStart+0.015,to:1,points:5)){_ in (A.red,0)};rudder=b.mesh(device)
  // Two twisted blades; the spinner belongs to the body.
  b=MeshBuilder()
  for flip in [1,-1] as [Float] {
   let rings:[[SIMD3<Float>]]=(0...10).map{i in
    let f=Float(i)/10,r=0.16+f*0.98,chord:Float=0.11+0.12*sin(f*Float.pi*0.85)*(1-f*0.35),thick=0.035*(1-f*0.6),twist=(52-f*36)*Float.pi/180
    return (0..<10).map{j in
     let a=Float(j)/10*2*Float.pi,u=cos(a)*chord/2*(i==10 ? 0.3:1),w=sin(a)*thick
     return SIMD3(flip*(u*cos(twist)-w*sin(twist)),flip*r,A.propZ+u*sin(twist)+w*cos(twist))
    }
   }
   b.surface(rings){p in (abs(p.y)>1.02 ? SIMD3(0.92,0.78,0.12):A.dark,2)}
  }
  propeller=b.mesh(device)
  // The blur of a spinning propeller, drawn translucent.
  b=MeshBuilder()
  for i in 0..<40 {
   let a=Float(i)/40*2*Float.pi,c=Float(i+1)/40*2*Float.pi
   for p in [SIMD3<Float>(0,0,A.propZ),SIMD3(cos(a)*1.14,sin(a)*1.14,A.propZ),SIMD3(cos(c)*1.14,sin(c)*1.14,A.propZ)] {b.vertex(p,SIMD3(0,0,-1),SIMD3(0.16,0.16,0.17),3)}
  }
  disc=b.mesh(device)
 }
}
// The fixed airframe: a high-wing single-engine floatplane.
func aircraftBody()->MeshBuilder {
 let A=Airframe.self
 var b=MeshBuilder()
 // Fuselage: round cowl, squarer cabin, tapering tail cone.
 let fuselage=[Section(z:-3.52,y:0,rx:0.46,ry:0.48),Section(z:-3.3,y:0,rx:0.57,ry:0.59),Section(z:-2.5,y:0.02,rx:0.62,ry:0.66),
  Section(z:-2.05,y:0.06,rx:0.64,ry:0.72,power:2.6),Section(z:-1.35,y:0.11,rx:0.66,ry:0.81,power:3),Section(z:-0.4,y:0.11,rx:0.66,ry:0.81,power:3),Section(z:0.6,y:0.1,rx:0.58,ry:0.7,power:2.8),
  Section(z:1.8,y:0.14,rx:0.36,ry:0.45,power:2.4),Section(z:3.0,y:0.22,rx:0.16,ry:0.26),Section(z:3.78,y:0.27,rx:0.03,ry:0.1)]
 b.surface(loft(fuselage,steps:5,segments:32)){p in
  if p.z < -2.5 {return (A.red,0)}
  let side=abs(p.x)>0.38
  if p.z > -2.08 && p.z < -1.42 && p.y>0.44 {return (A.tint,1)}                                  // windscreen
  if side && p.y>0.33 && p.y<0.74 && ((p.z > -1.3 && p.z < -0.5) || (p.z > -0.38 && p.z<0.42)) {return (A.tint,1)}   // cabin windows
  if side && p.y > -0.1 && p.y<0.08 {return (A.red,0)}                                             // cheat line
  return (A.cream,0)
 }
 b.ellipsoid(SIMD3(0,0,-3.5),SIMD3(0.37,0.39,0.05),A.dark)                                        // cowl intake
 b.surface(loft([Section(z:-4.02,y:0,rx:0.01,ry:0.01),Section(z:-3.9,y:0,rx:0.13,ry:0.13),Section(z:-3.7,y:0,rx:0.2,ry:0.2),Section(z:-3.5,y:0,rx:0.22,ry:0.22)],steps:3,segments:16)){_ in (A.silver,0)}
 b.beam(SIMD3(0.42,-0.5,-3.0),SIMD3(0.5,-0.66,-2.3),0.05,A.dark,kind:2)                           // exhaust
 // Wing: tapered, slight dihedral, rounded tips. The outer panel stops at the aileron hinge.
 for s in [-1,1] as [Float] {
  func side(_ f:Foil)->Foil {var g=f;g.le.x *= s;return g}
  let paint:Paint={p in (abs(p.x)>4.75 ? A.red:A.cream,0)}
  b.surface(foil([side(A.wingRoot),side(A.wingMid)],axis:SIMD3(0,1,0)),paint:paint)
  b.surface(foil([side(A.wingMid),side(A.wingOuter)],axis:SIMD3(0,1,0),from:0,to:A.aileronStart),paint:paint)
  b.surface(foil([side(A.wingOuter),side(Foil(le:SIMD3(5.68,1.215,-1.22),chord:1.02,thick:0.1)),side(Foil(le:SIMD3(5.75,1.215,-0.9),chord:0.4,thick:0.05))],axis:SIMD3(0,1,0)),paint:paint)
  // Tailplane ahead of the elevator hinge.
  b.surface(foil([side(A.stabRoot),side(A.stabTip),side(Foil(le:SIMD3(1.96,0.42,3.1),chord:0.3,thick:0.05,camber:0))],axis:SIMD3(0,1,0),from:0,to:A.elevatorStart)){_ in (A.cream,0)}
  // Wing struts, float struts and the float itself.
  b.beam(SIMD3(s*0.6,-0.42,-1.15),SIMD3(s*2.75,1.02,-0.95),0.05,A.silver)
  b.beam(SIMD3(s*0.6,-0.42,-0.2),SIMD3(s*2.75,1.03,-0.45),0.045,A.silver)
  let x=s*1.5
  b.surface(loft([Section(z:-3.25,y:-1.2,rx:0.02,ry:0.02,x:x),Section(z:-2.75,y:-1.4,rx:0.24,ry:0.2,power:2.6,x:x),Section(z:-1.6,y:-1.55,rx:0.36,ry:0.33,power:3,x:x),Section(z:0.15,y:-1.55,rx:0.36,ry:0.33,power:3,x:x),
   Section(z:0.3,y:-1.5,rx:0.33,ry:0.26,power:3,x:x),Section(z:2.2,y:-1.4,rx:0.2,ry:0.16,power:2.6,x:x),Section(z:2.95,y:-1.36,rx:0.02,ry:0.03,x:x)],steps:4,segments:18)){p in (p.y < -1.62 ? A.red:A.silver,0)}
  b.beam(SIMD3(s*0.48,-0.5,-1.55),SIMD3(x,-1.26,-1.5),0.045,A.silver)
  b.beam(SIMD3(s*0.48,-0.48,0.45),SIMD3(x,-1.26,0.5),0.045,A.silver)
  b.beam(SIMD3(s*0.48,-0.5,-1.55),SIMD3(x,-1.26,0.5),0.035,A.silver)
 }
 b.beam(SIMD3(-1.5,-1.28,-1.5),SIMD3(1.5,-1.28,-1.5),0.04,A.silver);b.beam(SIMD3(-1.5,-1.28,0.5),SIMD3(1.5,-1.28,0.5),0.04,A.silver)   // spreader bars
 // Fin ahead of the rudder hinge, with a rounded cap.
 b.surface(foil([A.finRoot,A.finTip,Foil(le:SIMD3(0,1.99,3.42),chord:0.3,thick:0.05,camber:0)],axis:SIMD3(1,0,0),from:0,to:A.rudderStart)){_ in (A.cream,0)}
 // Lights and aerial.
 b.ellipsoid(SIMD3(-5.74,1.215,-0.75),SIMD3(repeating:0.07),SIMD3(1,0.08,0.05),segments:8,rings:5,kind:3)
 b.ellipsoid(SIMD3(5.74,1.215,-0.75),SIMD3(repeating:0.07),SIMD3(0.1,1,0.25),segments:8,rings:5,kind:3)
 b.ellipsoid(SIMD3(0,0.3,3.82),SIMD3(repeating:0.05),SIMD3(1,1,1),segments:8,rings:5,kind:3)
 b.ellipsoid(SIMD3(0,2.02,3.55),SIMD3(repeating:0.06),SIMD3(1,0.1,0.06),segments:8,rings:5,kind:3)
 b.beam(SIMD3(0,1.1,-0.2),SIMD3(0,1.5,0.05),0.012,A.dark,kind:2)
 return b
}
func planeMesh(_ device:MTLDevice)->Mesh {aircraftBody().mesh(device)}
