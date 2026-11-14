// Builds Resources/AppIcon.icns from a transparent render of the aircraft.
// Usage: swift scripts/make-icon.swift <aircraft-hero.png> <Resources folder>
import AppKit
import CoreGraphics

let args=CommandLine.arguments
guard args.count==3,let plane=NSImage(contentsOfFile:args[1])?.cgImage(forProposedRect:nil,context:nil,hints:nil) else{fatalError("usage: make-icon.swift <aircraft.png> <Resources>")}
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
 // Water with a soft reflection band.
 c.drawLinearGradient(gradient([(0x2b86c9,0),(0x145a9e,1)]),start:CGPoint(x:0,y:345),end:CGPoint(x:0,y:100),options:[.drawsAfterEndLocation])
 c.setFillColor(rgb(0xffffff,0.12));for (y,w,x) in [(300,220,560),(262,150,640),(226,260,300),(182,180,520)] as [(CGFloat,CGFloat,CGFloat)] {c.fill(CGRect(x:x,y:y,width:w,height:5))}
 c.setFillColor(orange.copy(alpha:0.25)!);for x in towers {c.fill(CGRect(x:x-21,y:300,width:42,height:44))}
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
