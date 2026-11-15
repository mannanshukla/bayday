import SwiftUI
import simd

// The view from the pilot's seat: windscreen pillars, the engine cowl ahead, and a working
// instrument panel. Instruments read the simulation directly every frame.
struct CockpitView:View {
 let game:FlightGame
 let paused:Bool
 static let panelTop:CGFloat=0.70            // fraction of the height where the glareshield starts
 var body:some View {
  TimelineView(.animation(minimumInterval:1.0/60,paused:paused)) {timeline in
   // Reading the date ties the canvas to the timeline so it redraws every frame.
   Canvas {ctx,size in _=timeline.date;draw(&ctx,size)}
  }.ignoresSafeArea().allowsHitTesting(false)
 }
 private func draw(_ ctx:inout GraphicsContext,_ s:CGSize){
  let w=s.width,h=s.height,top=h*Self.panelTop
  // Haze where the far edge of the map meets the sky (see screenHorizon).
  let horizon=screenHorizon(mode:2,roll:game.roll,pitch:game.pitch,aspect:Float(w/max(1,h)),tilt:game.cameraTilt)
  var far=ctx;far.translateBy(x:w/2,y:h/2+CGFloat(horizon.slide)*h);far.rotate(by:.radians(Double(-horizon.angle)))
  let edge = -CGFloat(horizon.cover)*h/2,span=CGFloat(horizon.cover)*w,mist=Color(red:0.74,green:0.87,blue:0.97)
  far.fill(Path(CGRect(x:-span/2,y:edge-2,width:span,height:h*0.16)),with:.linearGradient(Gradient(colors:[mist.opacity(Double(min(1,horizon.slide/0.1))),mist.opacity(0)]),startPoint:CGPoint(x:0,y:edge),endPoint:CGPoint(x:0,y:edge+h*0.16)))
  // Engine cowl and the propeller's blur ahead of the windscreen.
  let disc=CGRect(x:w*0.5-w*0.21,y:top-h*0.30,width:w*0.42,height:h*0.42)
  if !game.crashing {ctx.fill(Path(ellipseIn:disc),with:.radialGradient(Gradient(colors:[.white.opacity(0.02),.white.opacity(0.09),.white.opacity(0)]),center:CGPoint(x:w/2,y:disc.midY),startRadius:disc.width*0.2,endRadius:disc.width*0.5))}
  var cowl=Path();cowl.move(to:CGPoint(x:w*0.27,y:top+h*0.05))
  cowl.addCurve(to:CGPoint(x:w*0.73,y:top+h*0.05),control1:CGPoint(x:w*0.33,y:top-h*0.085),control2:CGPoint(x:w*0.67,y:top-h*0.085));cowl.closeSubpath()
  ctx.fill(cowl,with:.linearGradient(Gradient(colors:[Color(red:0.83,green:0.16,blue:0.11),Color(red:0.42,green:0.05,blue:0.04)]),startPoint:CGPoint(x:0,y:top-h*0.10),endPoint:CGPoint(x:0,y:top+h*0.05)))
  // Windscreen pillars and header.
  let frame=Color(red:0.07,green:0.075,blue:0.085)
  for side in [0,1] as [CGFloat] {
   func x(_ v:CGFloat)->CGFloat {side==0 ? v:w-v}
   var pillar=Path();pillar.move(to:CGPoint(x:x(0),y:0));pillar.addLine(to:CGPoint(x:x(w*0.05),y:0));pillar.addLine(to:CGPoint(x:x(w*0.014),y:top+h*0.03));pillar.addLine(to:CGPoint(x:x(0),y:top+h*0.03));pillar.closeSubpath()
   ctx.fill(pillar,with:.color(frame))
  }
  ctx.fill(Path(CGRect(x:0,y:0,width:w,height:h*0.012)),with:.color(frame))
  // Glareshield and panel.
  var shield=Path();shield.move(to:CGPoint(x:0,y:top+h*0.03))
  shield.addQuadCurve(to:CGPoint(x:w,y:top+h*0.03),control:CGPoint(x:w/2,y:top-h*0.03))
  shield.addLine(to:CGPoint(x:w,y:h));shield.addLine(to:CGPoint(x:0,y:h));shield.closeSubpath()
  ctx.fill(shield,with:.color(frame))
  let face=CGRect(x:w*0.03,y:top+h*0.05,width:w*0.94,height:h-top-h*0.065)
  ctx.fill(Path(roundedRect:face,cornerRadius:14),with:.linearGradient(Gradient(colors:[Color(white:0.20),Color(white:0.13)]),startPoint:CGPoint(x:0,y:face.minY),endPoint:CGPoint(x:0,y:face.maxY)))
  // Five instruments, left of the map that the interface places at the right of the panel.
  let r=min(face.height*0.43,w*0.062),cy=face.midY,spacing=r*2.3,x0=w*0.44-spacing*2
  let motion=game.motion,knots=Double(length(motion))*1.94384,feet=Double(game.position.y)*3.28084
  let heading=(Double(game.yaw)*180/Double.pi).truncatingRemainder(dividingBy:360),climb=Double(motion.y)*196.85
  airspeed(&ctx,CGPoint(x:x0,y:cy),r,knots)
  attitude(&ctx,CGPoint(x:x0+spacing,y:cy),r)
  altimeter(&ctx,CGPoint(x:x0+spacing*2,y:cy),r,feet)
  compass(&ctx,CGPoint(x:x0+spacing*3,y:cy),r,heading<0 ? heading+360:heading)
  vertical(&ctx,CGPoint(x:x0+spacing*4,y:cy),r,climb)
 }
 // Angles are clockwise from straight up.
 private func point(_ c:CGPoint,_ radius:CGFloat,_ degrees:Double)->CGPoint {let a=degrees*Double.pi/180;return CGPoint(x:c.x+radius*CGFloat(sin(a)),y:c.y-radius*CGFloat(cos(a)))}
 private func dial(_ ctx:inout GraphicsContext,_ c:CGPoint,_ r:CGFloat,label:String){
  let rect=CGRect(x:c.x-r,y:c.y-r,width:r*2,height:r*2)
  ctx.fill(Path(ellipseIn:rect.insetBy(dx:-r*0.07,dy:-r*0.07)),with:.color(Color(white:0.32)))
  ctx.fill(Path(ellipseIn:rect),with:.color(Color(white:0.03)))
  ctx.draw(Text(label).font(.system(size:r*0.17,weight:.semibold)).foregroundColor(Color(white:0.6)),at:CGPoint(x:c.x,y:c.y-r*0.42))
 }
 private func ticks(_ ctx:inout GraphicsContext,_ c:CGPoint,_ r:CGFloat,from:Double,sweep:Double,count:Int,labels:(Int)->String?){
  for i in 0...count {
   let a=from+sweep*Double(i)/Double(count),major=labels(i) != nil
   var p=Path();p.move(to:point(c,r*0.96,a));p.addLine(to:point(c,r*(major ? 0.80:0.88),a));ctx.stroke(p,with:.color(.white.opacity(major ? 0.95:0.55)),lineWidth:major ? 1.6:1)
   if let text=labels(i) {ctx.draw(Text(text).font(.system(size:r*0.17,weight:.medium)).foregroundColor(.white),at:point(c,r*0.64,a))}
  }
 }
 private func needle(_ ctx:inout GraphicsContext,_ c:CGPoint,_ r:CGFloat,_ degrees:Double,color:Color = .white){
  var p=Path();p.move(to:point(c,r*0.16,degrees+180));p.addLine(to:point(c,r*0.84,degrees));ctx.stroke(p,with:.color(color),style:StrokeStyle(lineWidth:max(2,r*0.05),lineCap:.round))
  ctx.fill(Path(ellipseIn:CGRect(x:c.x-r*0.07,y:c.y-r*0.07,width:r*0.14,height:r*0.14)),with:.color(Color(white:0.7)))
 }
 private func readout(_ ctx:inout GraphicsContext,_ c:CGPoint,_ r:CGFloat,_ text:String){
  ctx.draw(Text(text).font(.system(size:r*0.24,weight:.semibold,design:.monospaced)).foregroundColor(.white),at:CGPoint(x:c.x,y:c.y+r*0.46))
 }
 private func airspeed(_ ctx:inout GraphicsContext,_ c:CGPoint,_ r:CGFloat,_ knots:Double){
  dial(&ctx,c,r,label:"KNOTS")
  ticks(&ctx,c,r,from:-140,sweep:280,count:25){$0%5==0 ? "\($0*20)":nil}
  readout(&ctx,c,r,String(Int(knots.rounded())))
  needle(&ctx,c,r,-140+280*min(1,max(0,knots/500)))
 }
 private func altimeter(_ ctx:inout GraphicsContext,_ c:CGPoint,_ r:CGFloat,_ feet:Double){
  dial(&ctx,c,r,label:"ALT FT")
  ticks(&ctx,c,r,from:0,sweep:360,count:50){$0%5==0 && $0<50 ? "\($0/5)":nil}
  readout(&ctx,c,r,String(Int(feet.rounded())))
  // Short hand: thousands. Long hand: hundreds.
  var short=Path();short.move(to:c);short.addLine(to:point(c,r*0.5,feet/10000*360));ctx.stroke(short,with:.color(.white),style:StrokeStyle(lineWidth:max(3,r*0.08),lineCap:.round))
  needle(&ctx,c,r,feet.truncatingRemainder(dividingBy:1000)/1000*360)
 }
 private func vertical(_ ctx:inout GraphicsContext,_ c:CGPoint,_ r:CGFloat,_ feetPerMinute:Double){
  dial(&ctx,c,r,label:"CLIMB")
  ticks(&ctx,c,r,from:-240,sweep:300,count:12){$0%2==0 ? "\(abs($0-6))":nil}
  ctx.draw(Text("×1000 FT/MIN").font(.system(size:r*0.12,weight:.medium)).foregroundColor(Color(white:0.6)),at:CGPoint(x:c.x+r*0.2,y:c.y+r*0.42))
  // Zero is at nine o'clock; up is a climb.
  needle(&ctx,c,r,-90+150*min(1,max(-1,feetPerMinute/6000)))
 }
 private func compass(_ ctx:inout GraphicsContext,_ c:CGPoint,_ r:CGFloat,_ heading:Double){
  dial(&ctx,c,r,label:"")
  // The card turns under a fixed marker at the top.
  for i in 0..<36 {
   let a=Double(i*10)-heading,major=i%3==0
   var p=Path();p.move(to:point(c,r*0.96,a));p.addLine(to:point(c,r*(major ? 0.82:0.89),a));ctx.stroke(p,with:.color(.white.opacity(major ? 0.95:0.55)),lineWidth:major ? 1.6:1)
   if i%9==0 {ctx.draw(Text(["N","E","S","W"][i/9]).font(.system(size:r*0.26,weight:.bold)).foregroundColor(i==0 ? .orange:.white),at:point(c,r*0.62,a))}
   else if major {ctx.draw(Text("\(i)").font(.system(size:r*0.15,weight:.medium)).foregroundColor(.white.opacity(0.85)),at:point(c,r*0.66,a))}
  }
  var mark=Path();mark.move(to:point(c,r*0.98,0));mark.addLine(to:CGPoint(x:c.x-r*0.09,y:c.y-r*1.14));mark.addLine(to:CGPoint(x:c.x+r*0.09,y:c.y-r*1.14));mark.closeSubpath();ctx.fill(mark,with:.color(.orange))
  ctx.draw(Text(String(format:"%03d°",Int(heading.rounded())%360)).font(.system(size:r*0.26,weight:.semibold,design:.monospaced)).foregroundColor(.white),at:c)
 }
 private func attitude(_ ctx:inout GraphicsContext,_ c:CGPoint,_ r:CGFloat){
  let rect=CGRect(x:c.x-r,y:c.y-r,width:r*2,height:r*2)
  ctx.fill(Path(ellipseIn:rect.insetBy(dx:-r*0.07,dy:-r*0.07)),with:.color(Color(white:0.32)))
  var ball=ctx;ball.clip(to:Path(ellipseIn:rect))
  // The horizon tilts against the bank and sinks as the nose rises.
  ball.translateBy(x:c.x,y:c.y);ball.rotate(by:.radians(Double(-game.roll)))
  let drop=CGFloat(game.pitch)*r*1.3
  ball.fill(Path(CGRect(x:-r*3,y:-r*3+drop,width:r*6,height:r*3)),with:.color(Color(red:0.20,green:0.52,blue:0.90)))
  ball.fill(Path(CGRect(x:-r*3,y:drop,width:r*6,height:r*3)),with:.color(Color(red:0.50,green:0.33,blue:0.18)))
  ball.fill(Path(CGRect(x:-r*3,y:drop-1,width:r*6,height:2)),with:.color(.white))
  for step in [-2,-1,1,2] {let y=drop-CGFloat(step)*r*0.2269*1.3;ball.fill(Path(CGRect(x:-r*(step%2==0 ? 0.3:0.16),y:y-0.5,width:r*(step%2==0 ? 0.6:0.32),height:1)),with:.color(.white.opacity(0.85)))}
  // Fixed aircraft symbol.
  for sign in [-1,1] as [CGFloat] {var wing=Path();wing.move(to:CGPoint(x:c.x+sign*r*0.62,y:c.y));wing.addLine(to:CGPoint(x:c.x+sign*r*0.22,y:c.y));wing.addLine(to:CGPoint(x:c.x+sign*r*0.22,y:c.y+r*0.1));ctx.stroke(wing,with:.color(.orange),style:StrokeStyle(lineWidth:max(2.5,r*0.06),lineCap:.round,lineJoin:.round))}
  ctx.fill(Path(ellipseIn:CGRect(x:c.x-r*0.05,y:c.y-r*0.05,width:r*0.1,height:r*0.1)),with:.color(.orange))
 }
}

// Haze where the far edge of the slid-down map meets the sky, in the chase views. Drawn
// every frame from the camera's current tilt so it stays on the map's edge (see screenHorizon).
struct HorizonHaze:View {
 let game:FlightGame
 let paused:Bool
 var body:some View {
  TimelineView(.animation(minimumInterval:1.0/60,paused:paused)) {timeline in
   Canvas {ctx,size in
    _=timeline.date
    let slide=CGFloat(screenHorizon(mode:game.cameraMode,roll:0,pitch:0,aspect:1,tilt:game.cameraTilt).slide),mist=Color(red:0.74,green:0.87,blue:0.97),top=size.height*slide-2
    guard slide>0.001 else{return}
    ctx.fill(Path(CGRect(x:0,y:top,width:size.width,height:size.height*0.16)),with:.linearGradient(Gradient(colors:[mist.opacity(Double(min(1,slide/0.1))),mist.opacity(0)]),startPoint:CGPoint(x:0,y:top),endPoint:CGPoint(x:0,y:top+size.height*0.16)))
   }
  }.ignoresSafeArea().allowsHitTesting(false)
 }
}
