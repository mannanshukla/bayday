import Foundation
import AVFoundation
import simd

// Flight model tuning. Accelerations are per unit mass (m/s²); speeds are m/s.
enum Aero {
 static let gravity:Float=9.81
 static let cruise:Float=120
 static let boostSpeed:Float=230                // level top speed on boost
 static let brakeSpeed:Float=55                 // level speed with the airbrake out
 static let drag:Float=0.0022                 // parasitic drag: a = drag · V²
 static let cruiseThrust:Float=drag*cruise*cruise
 static let boostThrust:Float=drag*boostSpeed*boostSpeed
 static let brakeDrag:Float=0.006             // airbrake out: much more drag
 static let brakeThrust:Float=brakeDrag*brakeSpeed*brakeSpeed
 static let stall:Float=42                    // 1 g stall speed
 static let turnGain:Float=4                  // arcade multiplier on the coordinated-turn rate
 static let clearance:Float=3                 // the floats sit about 2 m below the aircraft origin
 static let crashDuration:Float=2.6
 static let ceiling:Float=2400               // service ceiling above sea level
}
struct Particle {
 var position:SIMD3<Float>,velocity:SIMD3<Float>
 var age:Float=0
 let life:Float,size:Float,kind:Int           // 0 debris, 1 smoke/dust, 2 water spray
 let spin:Float
}
struct Contact {let normal:SIMD3<Float>,depth:Float,water:Bool}

extension FlightGame {
 var crashing:Bool{crashTime>=0}
 // Velocity of whatever is moving now: the aircraft in flight, or the wreck after a crash.
 var motion:SIMD3<Float> {crashing ? crashVelocity:velocityDir*speed}
 func resetDynamics(){
  velocityDir=forward;rollRate=0;pitchRate=0;loadFactor=1;stallAmount=0;thrust=Aero.cruiseThrust
  crashTime = -1;crashVelocity = .zero;tumble = .zero;tumbleRate = .zero;shake=0;smokeTimer=0;particles.removeAll()
  if crashed{crashed=false};if stalling{stalling=false};if atCeiling{atCeiling=false}
 }

 // MARK: Flight
 func fly(_ dt:Float,turn:Float,climb:Float,boosting:Bool,braking:Bool){
  let g=Aero.gravity
  // Control surfaces bite harder with airspeed and go mushy in a stall.
  let authority=clamp(speed/Aero.cruise,0.35,1.25)*(1-0.65*stallAmount)
  turnInput += (turn-turnInput)*(1-exp(-dt*7));pitchInput += (climb-pitchInput)*(1-exp(-dt*7))
  // Roll is a damped spring toward the commanded bank, so the aircraft has some weight.
  rollRate += ((turnInput*1.08-roll)*20*authority-rollRate*7.5)*dt;roll += rollRate*dt
  pitchRate += (pitchInput*0.9*authority-pitchRate)*(1-exp(-dt*6))
  // The nose drops a little in a bank and decisively in a stall.
  pitch += (pitchRate-(1-cos(roll))*0.07-stallAmount*0.8)*dt
  if abs(climb)<0.08{pitch *= exp(-dt*0.65*(1-stallAmount))}
  if abs(pitch)>=1.05{pitch=clamp(pitch,-1.05,1.05);pitchRate=0}
  // Service ceiling: the steepest climb the thin air allows eases to level flight over the
  // last 500 m, so the aircraft tops out smoothly instead of being snapped nose-down.
  let climbLimit=1.05*clamp((Aero.ceiling-position.y)/500,-0.2,1)
  if pitch>climbLimit {pitch += (climbLimit-pitch)*(1-exp(-dt*4));pitchRate=min(pitchRate,0)}
  loadFactor=clamp(cos(pitch)/max(0.35,cos(roll))+speed*pitchRate/g,-2,6)
  // Pulling g raises the stall speed (accelerated stall).
  let stallSpeed=Aero.stall*sqrt(clamp(abs(loadFactor),1,1.4))
  let stallTarget=clamp((stallSpeed*1.05-speed)/(stallSpeed*0.25),0,1)
  stallAmount += (stallTarget-stallAmount)*(1-exp(-dt*(stallTarget>stallAmount ? 5:1.6)))
  // Coordinated turn: rate = g·tan(bank)/V, so slow flight turns tighter than boosted flight.
  yaw += Aero.turnGain*g*tan(clamp(roll,-1.2,1.2))/max(speed,45)*(1-0.5*stallAmount)*dt
  let boostActive=boosting && boost>0.02
  boost=clamp(boost+(boostActive ? -0.12:0.065)*dt,0,1)
  let density=clamp(1-(position.y-1500)/3000,0.55,1)
  // Thin air costs engine power; the airbrake setting is held so braked flight keeps its
  // stall margin at any altitude.
  let wanted=boostActive ? Aero.boostThrust*density:braking ? Aero.brakeThrust:Aero.cruiseThrust*density
  thrust += (wanted-thrust)*(1-exp(-dt*4))
  let dragK=braking && !boostActive ? Aero.brakeDrag:Aero.drag
  // Lift-induced drag: turning and pulling cost airspeed. Scaled down at low speed so a
  // braked turn stays flyable instead of falling straight into a stall.
  let induced=min(7,2.6*max(0,abs(loadFactor)-1)*clamp(speed*speed/(Aero.cruise*Aero.cruise),0.2,1))
  forward=SIMD3(sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))
  // The flight path lags the nose, and sinks when the wing stops flying.
  var dir=velocityDir+(forward-velocityDir)*(1-exp(-dt*(2+7*authority)));dir.y -= stallAmount*0.6*dt
  velocityDir=normalize(dir)
  // Energy: thrust and drag along the path, plus gravity traded for speed in climbs and dives.
  speed=clamp(speed+(thrust-dragK*speed*speed-induced-g*velocityDir.y)*dt,15,320)
  position += velocityDir*speed*dt
 }

 // MARK: Collision
 func terrainNormal(_ p:SIMD3<Float>)->SIMD3<Float> {
  guard let t=terrain,t.height(p.x,p.z)>0 else{return SIMD3(0,1,0)}
  let e:Float=24
  return normalize(SIMD3(t.surface(SIMD3(p.x-e,0,p.z))-t.surface(SIMD3(p.x+e,0,p.z)),2*e,t.surface(SIMD3(p.x,0,p.z-e))-t.surface(SIMD3(p.x,0,p.z+e))))
 }
 // Lowest point of the aircraft below its origin for the current attitude. Level flight
 // rests on the floats; a tumbling wreck can be standing on a wingtip or its nose.
 var wreckClearance:Float {
  let m=rotation(pitch,SIMD3(1,0,0))*rotation(-roll,SIMD3(0,0,1))*rotation(tumble.y,SIMD3(0,1,0))*rotation(tumble.x,SIMD3(1,0,0))*rotation(tumble.z,SIMD3(0,0,1))
  return max(Aero.clearance,abs(m.columns.0.y)*Airframe.halfSpan+abs(m.columns.1.y)*Airframe.belly+abs(m.columns.2.y)*Airframe.halfLength)
 }
 // Checks the path in short steps so a fast aircraft cannot skip past a ridge on a slow frame. Returns the first touching point and its contact.
 func sweptContact(from a:SIMD3<Float>,to b:SIMD3<Float>,clearance:Float=Aero.clearance)->(SIMD3<Float>,Contact)? {
  let steps=max(1,Int(ceil(length(b-a)/2.5)))
  for i in 1...steps {let p=a+(b-a)*(Float(i)/Float(steps));if let c=contact(p,clearance:clearance){return (p,c)}}
  return nil
 }
 func contact(_ p:SIMD3<Float>,clearance:Float=Aero.clearance)->Contact? {
  guard let terrain else{return nil}
  let depth=terrain.surface(p)+clearance-p.y
  guard depth>0 else{return nil}
  let n=terrainNormal(p)
  return Contact(normal:n,depth:depth*n.y,water:terrain.height(p.x,p.z)<=0.5)
 }
 func impact(_ c:Contact){
  let v=velocityDir*speed,closing = -dot(v,c.normal)
  position += c.normal*(c.depth+0.3)
  // A shallow touch skips off the surface; the floats make water more forgiving.
  let limit=Aero.cruise*(c.water ? 0.23:0.18)
  if closing>limit || (!c.water && speed<Aero.stall) {crash(v,c,closing)}else{skim(v,c,max(0,closing))}
 }
 func skim(_ v:SIMD3<Float>,_ c:Contact,_ closing:Float){
  let bounced=v+c.normal*closing*1.45
  speed=max(15,length(bounced)*(c.water ? 0.88:0.8));velocityDir=normalize(bounced+c.normal*4)
  pitch=max(pitch,asin(clamp(velocityDir.y,-1,1))+0.1);pitchRate=max(pitchRate,0.3);rollRate += Float.random(in:-1.2...1.2)
  shake=max(shake,0.35+closing/40)
  emit(c.water ? 2:1,count:c.water ? 14:8,at:position-c.normal*2,velocity:v*0.35+c.normal*(8+closing),spread:c.water ? 14:7,life:c.water ? 0.9:1.3,size:c.water ? 0.7:1.2)
  playThud(0.22+closing/60)
  if collideCooldown==0 {
   let scored=challenge && !routeFinished;if scored{points=max(0,points-50)}
   notify((c.water ? "Bounced off the water":"Bounced off the ground")+(scored ? " · −50":""));collideCooldown=2.5
  }
 }
 func crash(_ v:SIMD3<Float>,_ c:Contact,_ closing:Float){
  crashTime=0;crashed=true;impactFlash+=1;crashStart=position;crashWater=c.water
  let along=v+c.normal*closing              // slides along the surface
  crashVelocity=along*(c.water ? 0.3:0.55)+c.normal*(closing*(c.water ? 0.12:0.36)+5)
  // Nose digs in: tumble forward, with a cartwheel on a banked or glancing hit.
  tumbleRate=SIMD3(-(3.5+closing*0.07),Float.random(in:-3...3),roll*4+Float.random(in:-3...3));tumble = .zero
  if c.water{tumbleRate *= 0.45}
  shake=1;smokeTimer=0;boost=max(boost,0.35);clearInput();photoMode=false
  let scored=challenge && !routeFinished;if scored{points=max(0,points-250)}
  emit(0,count:c.water ? 5:16,at:position,velocity:along*0.45+c.normal*14,spread:16,life:2.2,size:0.8)
  emit(c.water ? 2:1,count:c.water ? 26:12,at:position-c.normal*2,velocity:along*0.2+c.normal*(c.water ? 20:9),spread:c.water ? 18:9,life:c.water ? 1.2:1.9,size:c.water ? 0.9:1.8)
  playThud(1)
  notify(scored ? "−250 points":"")
 }
 func updateCrash(_ dt:Float){
  crashTime += dt
  crashVelocity.y -= 22*dt;crashVelocity *= exp(-dt*(crashWater ? 0.9:0.22))
  let start=position
  position += crashVelocity*dt;tumble += tumbleRate*dt
  if let (p,c)=sweptContact(from:start,to:position,clearance:wreckClearance) {
   position=p+c.normal*c.depth
   let closing = -dot(crashVelocity,c.normal)
   if closing>0 {
    let slide=crashVelocity+c.normal*closing
    crashVelocity=slide*(c.water ? 0.5:0.72)+c.normal*closing*(c.water ? 0.08:0.34)
    tumbleRate *= c.water ? 0.4:0.62
    if closing>5 {shake=max(shake,min(0.8,closing/28));emit(c.water ? 2:1,count:6,at:position-c.normal*2,velocity:slide*0.2+c.normal*6,spread:6,life:1.1,size:c.water ? 0.6:1.3);emit(0,count:c.water ? 0:3,at:position,velocity:slide*0.4+c.normal*8,spread:8,life:1.6,size:0.8);playThud(min(0.6,closing/35))}
    else{tumbleRate *= exp(-dt*5)}        // resting: scrub off the last of the spin
   }
  }
  smokeTimer -= dt
  if smokeTimer<=0 && !crashWater {smokeTimer=0.07;emit(1,count:1,at:position,velocity:SIMD3(0,5,0),spread:2,life:1.4,size:1.1)}
  if crashTime>Aero.crashDuration || (crashTime>1.4 && length(crashVelocity)<3) {recover()}
 }
 // Put the aircraft back over the crash site, high enough to clear whatever it hit.
 func recover(){
  let heading=SIMD3<Float>(sin(yaw),0,-cos(yaw))
  var p=crashStart,safe:Float=0
  p.x=clamp(p.x,-worldHalf+400,worldHalf-400);p.z=clamp(p.z,-worldHalf+400,worldHalf-400)
  for step in 0...4 {
   let q=p+heading*Float(step)*220
   safe=max(safe,(terrain?.surface(q) ?? 0)+130)
  }
  position=SIMD3(p.x,min(max(safe,p.y),2300),p.z);previous=position
  pitch=0.08;roll=0;speed=Aero.cruise*0.9;forward=SIMD3(sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))
  let debris=particles;resetDynamics();particles=debris;collideCooldown=1.5
  mapCameraPosition=SIMD3(repeating:.infinity)
 }

 // MARK: Effects
 func emit(_ kind:Int,count:Int,at p:SIMD3<Float>,velocity:SIMD3<Float>,spread:Float,life:Float,size:Float){
  guard count>0,particles.count<160 else{return}
  for _ in 0..<count {
   let jitter=SIMD3<Float>(Float.random(in:-1...1),Float.random(in:-0.4...1),Float.random(in:-1...1))
   particles.append(Particle(position:p+jitter*1.5,velocity:velocity+jitter*spread,life:life*Float.random(in:0.6...1.15),size:size*Float.random(in:0.6...1.3),kind:kind,spin:Float.random(in:-9...9)))
  }
 }
 func updateParticles(_ dt:Float){
  guard !particles.isEmpty else{return}
  for i in particles.indices {
   particles[i].age += dt
   if particles[i].kind==1 {particles[i].velocity *= exp(-dt*1.8);particles[i].velocity.y += 3*dt}
   else{
    particles[i].velocity.y -= 22*dt
    let floor=(terrain?.surface(particles[i].position) ?? 0)+0.4
    if particles[i].position.y<floor && particles[i].velocity.y<0 {particles[i].position.y=floor;particles[i].velocity=particles[i].velocity*SIMD3(0.6,-0.35,0.6)}
   }
   particles[i].position += particles[i].velocity*dt
  }
  particles.removeAll{$0.age>=$0.life}
 }
 func playThud(_ volume:Float){
  guard let thud,!isTesting else{return}
  thud.volume=clamp(volume,0.1,1)*0.8;thud.currentTime=0;thud.play()
 }
}
