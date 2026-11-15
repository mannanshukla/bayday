import AppKit
import Foundation
import MetalKit
import simd

struct Uniforms {
 var vp=matrix_identity_float4x4
 var model=matrix_identity_float4x4
 var eyeTime=SIMD4<Float>(0,0,0,0)
 var sun=SIMD4<Float>(-0.6,0.75,0.35,0)
 var options=SIMD4<Float>(1,0,0,0)
}
// Draws the aircraft, its control surfaces and crash effects in a transparent layer over
// the map. The map itself is Apple's; this view never draws scenery.
class FlightRenderer:NSObject,MTKViewDelegate {
 let device:MTLDevice,queue:MTLCommandQueue,game:FlightGame
 weak var view:MTKView?
 var pipeline:MTLRenderPipelineState!,solidDepth:MTLDepthStencilState!,blendDepth:MTLDepthStencilState!
 var aircraft:AircraftModel!,sparkle:Mesh!,debris:Mesh!,puff:Mesh!,spray:Mesh!
 var lastTime=CFAbsoluteTimeGetCurrent(),clock:Float=0
 var propAngle:Float=0,propSpeed:Float=48
 var fpsFrames=0,fpsStart=CFAbsoluteTimeGetCurrent()
 let inFlight=DispatchSemaphore(value:3)
 var qaFrame=0,qaHero=false
 let qaPath:String?
 var initialized=false
 var pausedFrame=0
 init(view:MTKView,game:FlightGame)throws {
  guard let d=MTLCreateSystemDefaultDevice(),let q=d.makeCommandQueue() else{throw NSError(domain:"Metal",code:1,userInfo:[NSLocalizedDescriptionKey:"Metal is unavailable on this Mac"])}
  self.device=d;queue=q;self.game=game;self.view=view
  let args=CommandLine.arguments;if let i=args.firstIndex(of:"--qa"),i+1<args.count{qaPath=args[i+1]}else{qaPath=nil}
  super.init();view.device=d;view.colorPixelFormat = .bgra8Unorm;view.depthStencilPixelFormat = .depth32Float;view.clearDepth=0;view.sampleCount=4;view.preferredFramesPerSecond=60;view.framebufferOnly=false;view.clearColor=MTLClearColorMake(0,0,0,0);view.layer?.isOpaque=false;view.autoResizeDrawable=false;view.enableSetNeedsDisplay=false;view.isPaused=true
  let source=try String(contentsOf:game.resource("Shaders.metal"),encoding:.utf8),library=try device.makeLibrary(source:source,options:nil)
  let p=MTLRenderPipelineDescriptor();p.vertexFunction=library.makeFunction(name:"worldVertex");p.fragmentFunction=library.makeFunction(name:"worldFragment")
  p.depthAttachmentPixelFormat = .depth32Float;p.rasterSampleCount=4
  // The shader outputs premultiplied, sRGB-encoded colour, which is what the layer composites.
  let c=p.colorAttachments[0]!;c.pixelFormat=view.colorPixelFormat;c.isBlendingEnabled=true
  c.sourceRGBBlendFactor = .one;c.destinationRGBBlendFactor = .oneMinusSourceAlpha;c.sourceAlphaBlendFactor = .one;c.destinationAlphaBlendFactor = .oneMinusSourceAlpha
  pipeline=try device.makeRenderPipelineState(descriptor:p)
  let dd=MTLDepthStencilDescriptor();dd.depthCompareFunction = .greaterEqual;dd.isDepthWriteEnabled=true;solidDepth=device.makeDepthStencilState(descriptor:dd)
  dd.isDepthWriteEnabled=false;blendDepth=device.makeDepthStencilState(descriptor:dd)
  game.renderer=self;view.delegate=self
 }
 func load()throws {
  guard let grid=game.terrainLoader(region) else{throw NSError(domain:"Terrain",code:2,userInfo:[NSLocalizedDescriptionKey:"The elevation data for \(region.name) is missing"])}
  game.terrain=grid
  aircraft=AircraftModel(device)
  var b=MeshBuilder();b.ellipsoid(.zero,SIMD3(repeating:0.5),SIMD3(1,0.85,0.25),segments:8,rings:6,kind:3);sparkle=b.mesh(device)
  b=MeshBuilder();b.box(.zero,SIMD3(1.5,0.16,0.9),Airframe.cream,kind:0);b.box(SIMD3(0,0.2,0),SIMD3(0.5,0.2,1.1),Airframe.red,kind:0);debris=b.mesh(device)
  b=MeshBuilder();b.ellipsoid(.zero,SIMD3(repeating:1),SIMD3(0.62,0.6,0.57),segments:20,rings:12);puff=b.mesh(device)
  b=MeshBuilder();b.ellipsoid(.zero,SIMD3(repeating:1),SIMD3(0.9,0.96,1),segments:6,rings:4,kind:3);spray=b.mesh(device)
  game.reset();game.setupAudio();game.ready=true;game.loading="";initialized=true;lastTime=CFAbsoluteTimeGetCurrent();fpsStart=lastTime;view?.isPaused=false
 }
 func mtkView(_ view:MTKView,drawableSizeWillChange size:CGSize){}
 func resize(_ view:MTKView){let factor=min(2,2560/max(1,view.bounds.width));let s=CGSize(width:max(1,view.bounds.width*factor),height:max(1,view.bounds.height*factor));if view.drawableSize != s{view.drawableSize=s}}
 func draw(in view:MTKView) {
  guard initialized else{return}
  // Keep display-link pacing fixed and skip idle redraws rather than
  // renegotiating the display refresh rate when pausing or resuming.
  if game.paused && qaPath == nil{pausedFrame+=1;if pausedFrame % 4 != 0{return}}else{pausedFrame=0}
  resize(view)
  let now=CFAbsoluteTimeGetCurrent();let dt=Float(clamp(now-lastTime,0,0.05));lastTime=now;clock+=dt
  if qaPath != nil {qaStep()}
  game.update(dt);game.updateAppleCamera()
  guard inFlight.wait(timeout:.now()) == .success else{return}
  guard let pass=view.currentRenderPassDescriptor,let drawable=view.currentDrawable,let command=queue.makeCommandBuffer(),let enc=command.makeRenderCommandEncoder(descriptor:pass) else{inFlight.signal();return}
  let aspect=Float(view.drawableSize.width/view.drawableSize.height)
  // The aircraft is drawn in its own frame, nose toward -z, so the sun is turned by the
  // heading: the light moves across the airframe as the aircraft turns.
  let toLocal=rotation(game.yaw,SIMD3(0,1,0)),sun=toLocal*SIMD4<Float>(-0.55,0.72,0.42,0)
  var u=Uniforms();u.vp=aircraftOverlayProjection(eye:game.cameraEye,tilt:game.cameraTilt,aspect);u.eyeTime=SIMD4(game.cameraEye,clock);u.sun=sun
  // The map picture is slid (and in the cockpit, turned) on screen; this layer follows it.
  u.vp=screenClipTransform(mode:game.cameraMode,roll:game.roll,pitch:game.pitch,aspect:aspect)*u.vp
  // Close-up used to render the app icon artwork.
  if qaHero {let eye=SIMD3<Float>(0,2.2,30);u.vp=perspective(.pi/6,aspect)*lookAt(eye,SIMD3(0,-0.2,0));u.eyeTime=SIMD4(eye,clock);u.sun=SIMD4(-0.5,0.75,0.6,0)}
  enc.setRenderPipelineState(pipeline);enc.setDepthStencilState(solidDepth);enc.setCullMode(.none)
  func draw(_ m:Mesh,_ model:simd_float4x4,opacity:Float=1){
   u.model=model;u.options.x=opacity
   enc.setVertexBytes(&u,length:MemoryLayout<Uniforms>.stride,index:1);enc.setFragmentBytes(&u,length:MemoryLayout<Uniforms>.stride,index:1)
   enc.setVertexBuffer(m.buffer,offset:0,index:0);enc.drawPrimitives(type:.triangle,vertexStart:0,vertexCount:m.count)
  }
  func about(_ h:Hinge,_ angle:Float)->simd_float4x4 {translation(h.point)*rotation(angle,h.axis)*translation(-h.point)}
  if !game.paused {propSpeed += ((game.crashing ? 0:28+game.speed*0.22)-propSpeed)*(1-exp(-dt*3));propAngle=(propAngle+propSpeed*dt).truncatingRemainder(dividingBy:2*Float.pi)}
  // Impacts jolt the aircraft in frame; frozen while paused.
  let jolt=SIMD3<Float>(sin(clock*61),sin(clock*47+1),sin(clock*53+2))*(game.paused ? 0:game.shake*game.shake*1.1)
  let blur=clamp((propSpeed-8)/30,0,1)
  let showAircraft=game.cameraMode != 2      // the cockpit view is drawn by the interface instead
  var model=matrix_identity_float4x4
  if showAircraft {
   // A wreck tumbles about its own axes on top of the attitude it crashed with.
   model=translation(jolt)*rotation(game.pitch,SIMD3(1,0,0))*rotation(-game.roll,SIMD3(0,0,1))*rotation(game.tumble.y,SIMD3(0,1,0))*rotation(game.tumble.x,SIMD3(1,0,0))*rotation(game.tumble.z,SIMD3(0,0,1))
   // Control surfaces follow the stick: ailerons oppose each other, the elevator rises
   // to climb, and the rudder leads into the turn.
   let stick=game.crashing ? SIMD2<Float>.zero:SIMD2(game.turnInput,game.pitchInput)
   draw(aircraft.body,model)
   draw(aircraft.aileronRight,model*about(Airframe.aileronRight,-stick.x*0.38))
   draw(aircraft.aileronLeft,model*about(Airframe.aileronLeft,stick.x*0.38))
   draw(aircraft.elevator,model*about(Airframe.elevator,-stick.y*0.42))
   draw(aircraft.rudder,model*about(Airframe.rudder,stick.x*0.3))
   if blur<0.98 {draw(aircraft.propeller,model*rotation(propAngle,SIMD3(0,0,1)))}
  }
  // Solid debris first, with depth, so pieces hide each other correctly.
  let axis=normalize(SIMD3<Float>(1,0.6,0.3)),eye=game.cameraEye
  func local(_ p:Particle)->SIMD3<Float> {let r=toLocal*SIMD4(p.position-game.position,0);return SIMD3(r.x,r.y,r.z)+jolt}
  func fading(_ p:Particle)->Bool {p.kind != 0 || p.age/p.life>0.8}
  for p in game.particles where !fading(p) {draw(debris,translation(local(p))*rotation(p.age*p.spin,axis)*scaling(p.size))}
  // Translucent pass: no depth writes, drawn farthest first so overlapping smoke blends correctly.
  enc.setDepthStencilState(blendDepth)
  for (p,q) in game.particles.filter(fading).map({($0,local($0))}).sorted(by:{distance_squared($0.1,eye)>distance_squared($1.1,eye)}) {
   let f=p.age/p.life,spin=rotation(p.age*p.spin,axis)
   switch p.kind {
   case 1:draw(puff,translation(q)*spin*scaling(p.size*(0.5+f*1.8)),opacity:0.42*(1-f)*(1-f))
   case 2:draw(spray,translation(q)*scaling(p.size*(1-f*0.5)),opacity:0.8*(1-f))
   default:draw(debris,translation(q)*spin*scaling(p.size),opacity:(1-f)*5)
   }
  }
  if showAircraft && blur>0.02 {
   draw(aircraft.disc,model,opacity:0.2*blur)
   draw(aircraft.propeller,model*rotation(propAngle,SIMD3(0,0,1)),opacity:0.35*blur)
   draw(aircraft.propeller,model*rotation(propAngle+1.1,SIMD3(0,0,1)),opacity:0.18*blur)
  }
  // A ring of sparks around the aircraft when a point is collected.
  let age=game.time-game.burstTime
  if age>=0 && age<1.2 && !game.photoMode {for i in 0..<12 {let a=Float(i)*2*Float.pi/12+age,d=3+age*16;draw(sparkle,translation(SIMD3(sin(a)*d,cos(a)*d,0)),opacity:1-age/1.2)}}
  enc.endEncoding()
  if let path=qaPath,[40,80,120,160,200].contains(qaFrame) {capture(drawable.texture,command:command,to:URL(fileURLWithPath:path).appendingPathComponent(qaHero ? "aircraft-hero.png":"aircraft-\(qaFrame).png"))}
  command.addCompletedHandler{[weak self] _ in self?.inFlight.signal()}
  command.present(drawable);command.commit()
  fpsFrames+=1;if now-fpsStart>1 {game.fps=Int(Double(fpsFrames)/(now-fpsStart));fpsFrames=0;fpsStart=now}
 }
 func capture(_ texture:MTLTexture,command:MTLCommandBuffer,to url:URL){
  let w=texture.width,h=texture.height,row=((w*4+255)/256)*256;guard let buffer=device.makeBuffer(length:row*h,options:.storageModeShared),let blit=command.makeBlitCommandEncoder() else{return};blit.copy(from:texture,sourceSlice:0,sourceLevel:0,sourceOrigin:MTLOrigin(x:0,y:0,z:0),sourceSize:MTLSize(width:w,height:h,depth:1),to:buffer,destinationOffset:0,destinationBytesPerRow:row,destinationBytesPerImage:row*h);blit.endEncoding()
  command.addCompletedHandler{_ in
   let data=Data(bytes:buffer.contents(),count:row*h);let provider=CGDataProvider(data:data as CFData)!,space=CGColorSpace(name:CGColorSpace.sRGB)!;guard let image=CGImage(width:w,height:h,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:row,space:space,bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue),provider:provider,decode:nil,shouldInterpolate:false,intent:.defaultIntent) else{return}
   let rep=NSBitmapImageRep(cgImage:image);try? FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true);try? rep.representation(using:.png,properties:[:])?.write(to:url)
  }
 }
 // `--qa <folder>` poses the aircraft and saves transparent PNGs of it (four flight attitudes and an icon close-up), then quits.
 func qaStep(){
  qaFrame+=1
  switch qaFrame {
  case 1:game.cameraMode=0;game.pitch=0;game.roll=0;game.turnInput=0;game.pitchInput=0
  case 41:game.roll=0.9;game.pitch=0.25;game.turnInput=1;game.pitchInput=0.6
  case 81:game.roll = -0.7;game.pitch = -0.5;game.turnInput = -1;game.pitchInput = -0.8
  case 121:game.cameraMode=1;game.roll=1.4;game.pitch=0.9;game.turnInput=0;game.pitchInput=0;propSpeed=0
  case 161:qaHero=true;game.cameraMode=0;game.roll = -0.32;game.pitch=0.16;game.tumble=SIMD3(0,2.45,0);propSpeed=48
  case 210:NSApp.terminate(nil)
  default:break
  }
 }
}
