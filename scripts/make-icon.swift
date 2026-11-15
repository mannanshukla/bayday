// Builds Resources/AppIcon.icns from a transparent render of the aircraft.
// Usage: swift scripts/make-icon.swift <aircraft-hero.png> <output folder> [sf|nyc]
import AppKit
import CoreGraphics

let args=CommandLine.arguments
guard args.count>=3,let plane=NSImage(contentsOfFile:args[1])?.cgImage(forProposedRect:nil,context:nil,hints:nil) else{fatalError("usage: make-icon.swift <aircraft.png> <Resources>")}
let style=args.count>3 ? args[3]:"sf"
let space=CGColorSpace(name:CGColorSpace.sRGB)!
func rgb(_ hex:UInt32,_ a:CGFloat=1)->CGColor {CGColor(colorSpace:space,components:[CGFloat((hex>>16)&255)/255,CGFloat((hex>>8)&255)/255,CGFloat(hex&255)/255,a])!}
func gradient(_ stops:[(UInt32,CGFloat)])->CGGradient {CGGradient(colorsSpace:space,colors:stops.map{rgb($0.0)} as CFArray,locations:stops.map{$0.1})!}

// Crop the render to its opaque pixels.
func opaqueBounds(_ image:CGImage)->CGRect {
 let w=image.width,h=image.height
 var pixels=[UInt8](repeating:0,count:w*h*4)
 let c=CGContext(data:&pixels,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:space,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 c.draw(image,in:CGRect(x:0,y:0,width:w,height:h))
 var x0=w,x1=0,y0=h,y1=0
 for y in 0..<h {for x in 0..<w where pixels[(y*w+x)*4+3]>8 {x0=min(x0,x);x1=max(x1,x);y0=min(y0,y);y1=max(y1,y)}}
 return CGRect(x:x0,y:y0,width:x1-x0+1,height:y1-y0+1)   // rows run top-down, matching CGImage.cropping
}
let aircraft=plane.cropping(to:opaqueBounds(plane))!

// San Francisco: headlands and the Golden Gate Bridge.
func goldenGate(_ c:CGContext){
 // Headlands.
 c.setFillColor(rgb(0x3f6f86));c.move(to:CGPoint(x:100,y:330));c.addCurve(to:CGPoint(x:420,y:330),control1:CGPoint(x:170,y:470),control2:CGPoint(x:330,y:420));c.closePath();c.fillPath()
 c.setFillColor(rgb(0x4f8196));c.move(to:CGPoint(x:640,y:330));c.addCurve(to:CGPoint(x:924,y:420),control1:CGPoint(x:740,y:400),control2:CGPoint(x:850,y:380));c.addLine(to:CGPoint(x:924,y:330));c.closePath();c.fillPath()
 // Bridge: deck, two towers, main cables and suspenders.
 let orange=rgb(0xd9482b),deck:CGFloat=372,top:CGFloat=560,towers:[CGFloat]=[330,694]
 c.setStrokeColor(orange);c.setLineCap(.round)
 func cable(_ x:CGFloat)->CGFloat {
  if x<towers[0] {let t=(x-100)/(towers[0]-100);return deck+14+(top-deck-14)*t*t}
  if x>towers[1] {let t=(924-x)/(924-towers[1]);return deck+14+(top-deck-14)*t*t}
  let t=(x-512)/((towers[1]-towers[0])/2);return deck+22+(top-deck-22)*t*t
 }
 c.setLineWidth(3);for x in stride(from:CGFloat(112),through:912,by:16) {c.move(to:CGPoint(x:x,y:deck));c.addLine(to:CGPoint(x:x,y:cable(x)))};c.strokePath()
 c.setLineWidth(7);c.move(to:CGPoint(x:100,y:cable(100)));for x in stride(from:CGFloat(104),through:924,by:4) {c.addLine(to:CGPoint(x:x,y:cable(x)))};c.strokePath()
 c.setFillColor(orange);c.fill(CGRect(x:100,y:deck-9,width:824,height:18))
 for x in towers {
  c.fill(CGRect(x:x-21,y:300,width:13,height:top-290));c.fill(CGRect(x:x+8,y:300,width:13,height:top-290))
  for y in [deck+50,deck+105,deck+155,top-6] as [CGFloat] {c.fill(CGRect(x:x-21,y:y,width:42,height:11))}
 }
 c.setFillColor(orange.copy(alpha:0.25)!);for x in towers {c.fill(CGRect(x:x-21,y:300,width:42,height:44))}
}
// New York: a skyline with the Brooklyn Bridge in front.
func skyline(_ c:CGContext){
 let far=rgb(0x5f86a8),near=rgb(0x3f6386),base:CGFloat=330
 func tower(_ x:CGFloat,_ w:CGFloat,_ h:CGFloat,_ color:CGColor,spire:CGFloat=0,steps:Int=0){
  c.setFillColor(color);c.fill(CGRect(x:x,y:base,width:w,height:h))
  var width=w,top=base+h
  for _ in 0..<steps {width*=0.62;c.fill(CGRect(x:x+(w-width)/2,y:top,width:width,height:h*0.09));top+=h*0.09}
  if spire>0 {c.move(to:CGPoint(x:x+w/2-max(3,width*0.16),y:top));c.addLine(to:CGPoint(x:x+w/2,y:top+spire));c.addLine(to:CGPoint(x:x+w/2+max(3,width*0.16),y:top));c.closePath();c.fillPath()}
 }
 // Distant blocks, then the recognisable towers.
 for (x,w,h) in [(110,46,96),(150,38,140),(196,52,110),(250,40,170),(300,58,128),(366,44,188),(418,50,150),(520,46,176),(574,54,132),(636,42,196),(684,56,150),(748,44,118),(798,52,160),(856,60,104)] as [(CGFloat,CGFloat,CGFloat)] {tower(x,w,h,far)}
 tower(214,54,236,near,spire:92)                       // One World Trade Center
 c.setFillColor(near);c.move(to:CGPoint(x:214,y:base+236));c.addLine(to:CGPoint(x:241,y:base+300));c.addLine(to:CGPoint(x:268,y:base+236));c.closePath();c.fillPath()
 tower(470,58,228,near,spire:78,steps:3)               // Empire State Building
 tower(604,40,214,near,spire:96,steps:2)               // Chrysler Building
 tower(760,48,206,near,steps:1)
 // Brooklyn Bridge: stone towers with pointed arches, main cables and diagonal stays.
 let stone=rgb(0xb8956a),shade=rgb(0x8c6c48),deck:CGFloat=372,top:CGFloat=560,towers:[CGFloat]=[330,694]
 func cable(_ x:CGFloat)->CGFloat {
  if x<towers[0] {let t=(x-100)/(towers[0]-100);return deck+10+(top-deck-24)*t*t}
  if x>towers[1] {let t=(924-x)/(924-towers[1]);return deck+10+(top-deck-24)*t*t}
  let t=(x-512)/((towers[1]-towers[0])/2);return deck+18+(top-deck-32)*t*t
 }
 c.setStrokeColor(rgb(0x3b4654));c.setLineCap(.round);c.setLineWidth(2)
 for x in stride(from:CGFloat(112),through:912,by:14) {c.move(to:CGPoint(x:x,y:deck));c.addLine(to:CGPoint(x:x,y:cable(x)))};c.strokePath()
 for tx in towers {for k in 1...6 {for side in [-1,1] as [CGFloat] {c.move(to:CGPoint(x:tx,y:top-18));c.addLine(to:CGPoint(x:tx+side*CGFloat(k)*26,y:deck))}}};c.strokePath()
 c.setLineWidth(6);c.move(to:CGPoint(x:100,y:cable(100)));for x in stride(from:CGFloat(104),through:924,by:4) {c.addLine(to:CGPoint(x:x,y:cable(x)))};c.strokePath()
 c.setFillColor(rgb(0x4a5563));c.fill(CGRect(x:100,y:deck-8,width:824,height:16))
 for tx in towers {
  c.setFillColor(stone);c.fill(CGRect(x:tx-40,y:300,width:80,height:top-296))
  c.setFillColor(shade);c.fill(CGRect(x:tx-46,y:top-2,width:92,height:12));c.fill(CGRect(x:tx-44,y:deck+8,width:88,height:8))
  // Two pointed arches above the deck show the sky through the tower.
  for ax in [tx-19,tx+19] as [CGFloat] {
   c.setFillColor(rgb(0x7fb6e6));c.move(to:CGPoint(x:ax-11,y:deck+20));c.addLine(to:CGPoint(x:ax-11,y:deck+108))
   c.addQuadCurve(to:CGPoint(x:ax,y:deck+146),control:CGPoint(x:ax-10,y:deck+132));c.addQuadCurve(to:CGPoint(x:ax+11,y:deck+108),control:CGPoint(x:ax+10,y:deck+132))
   c.addLine(to:CGPoint(x:ax+11,y:deck+20));c.closePath();c.fillPath()
  }
 }
}
func icon(_ size:Int)->CGImage {
 let c=CGContext(data:nil,width:size,height:size,bitsPerComponent:8,bytesPerRow:0,space:space,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 c.scaleBy(x:CGFloat(size)/1024,y:CGFloat(size)/1024)
 // macOS icon grid: an 824-point rounded square centred on a 1024 canvas.
 let tile=CGRect(x:100,y:100,width:824,height:824),shape=CGPath(roundedRect:tile,cornerWidth:186,cornerHeight:186,transform:nil)
 c.saveGState();c.setShadow(offset:CGSize(width:0,height:-10),blur:24,color:rgb(0x000000,0.3));c.addPath(shape);c.setFillColor(rgb(0x2a7fd6));c.fillPath();c.restoreGState()
 c.saveGState();c.addPath(shape);c.clip()
 // Sky, low sun and haze.
 c.drawLinearGradient(gradient([(0x1f6fd0,0),(0x4aa3ee,0.45),(0xbfe4fb,0.78),(0xffe9c4,1)]),start:CGPoint(x:0,y:924),end:CGPoint(x:0,y:330),options:[])
 c.drawRadialGradient(CGGradient(colorsSpace:space,colors:[rgb(0xfff6d8,0.95),rgb(0xfff0c0,0)] as CFArray,locations:[0,1])!,startCenter:CGPoint(x:760,y:520),startRadius:0,endCenter:CGPoint(x:760,y:520),endRadius:330,options:[])
 if style=="nyc" {skyline(c)} else {goldenGate(c)}
 // Water with a soft reflection band.
 c.drawLinearGradient(gradient([(0x2b86c9,0),(0x145a9e,1)]),start:CGPoint(x:0,y:345),end:CGPoint(x:0,y:100),options:[.drawsAfterEndLocation])
 c.setFillColor(rgb(0xffffff,0.12));for (y,w,x) in [(300,220,560),(262,150,640),(226,260,300),(182,180,520)] as [(CGFloat,CGFloat,CGFloat)] {c.fill(CGRect(x:x,y:y,width:w,height:5))}
 // The aircraft, large and slightly overlapping the bridge.
 let width:CGFloat=760,height=width*CGFloat(aircraft.height)/CGFloat(aircraft.width)
 c.setShadow(offset:CGSize(width:0,height:-22),blur:34,color:rgb(0x062a52,0.42))
 c.draw(aircraft,in:CGRect(x:512-width/2+6,y:486-height/2,width:width,height:height))
 c.restoreGState()
 // Glass edge highlight.
 c.addPath(CGPath(roundedRect:tile.insetBy(dx:3,dy:3),cornerWidth:183,cornerHeight:183,transform:nil));c.setStrokeColor(rgb(0xffffff,0.35));c.setLineWidth(5);c.strokePath()
 return c.makeImage()!
}
let resources=URL(fileURLWithPath:args[2]),set=resources.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at:set);try! FileManager.default.createDirectory(at:set,withIntermediateDirectories:true)
func write(_ image:CGImage,_ url:URL){try! NSBitmapImageRep(cgImage:image).representation(using:.png,properties:[:])!.write(to:url)}
for (points,scale) in [(16,1),(16,2),(32,1),(32,2),(128,1),(128,2),(256,1),(256,2),(512,1),(512,2)] {
 write(icon(points*scale),set.appendingPathComponent("icon_\(points)x\(points)\(scale==2 ? "@2x":"").png"))
}
print(set.path)
