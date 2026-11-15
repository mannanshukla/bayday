import SwiftUI

private let controlKeys:[(action:String,keys:String)] = [
 ("Steer","← →  /  A D"),("Climb","↓  /  S"),("Dive","↑  /  W"),("Boost","Shift  /  E"),("Brake","Space  /  Q"),
 ("Camera: chase, far, cockpit","C"),("Scenery","T"),("Map","M"),("Flight record","J"),("Hide interface","H"),
 ("Music on / off","K"),("Next track","N"),("Restart flight","R"),("Pause","P  /  Esc"),("Resume or start","Return")
]

struct FlightView:View {
 @ObservedObject var game:FlightGame
 private var modal:Bool {game.showHelp || game.showCredits || game.showPassport || game.showMap}
 private var flying:Bool {game.ready && !game.paused}
 private var cockpit:Bool {game.cameraMode==2 && game.launched && !game.photoMode}
 private var found:Int {game.discovered.count}
 private var total:Int {sights.count}

 var body:some View {
  GeometryReader {g in
   ZStack {
    // Sky behind the map: in the cockpit the map slides down as the nose rises and this shows above it.
    LinearGradient(colors:[Color(red:0.22,green:0.48,blue:0.88),Color(red:0.74,green:0.87,blue:0.97)],startPoint:.top,endPoint:.center).ignoresSafeArea()
    AppleScenery(game:game).ignoresSafeArea()
    MetalCanvas(game:game).ignoresSafeArea().allowsHitTesting(false)
    if cockpit {CockpitView(game:game,paused:game.paused)}
    if game.paused {Color.black.opacity(0.22).ignoresSafeArea().allowsHitTesting(false)}
    ImpactFlash(trigger:game.impactFlash)
    if game.photoMode {
     VStack {Spacer();Text("H shows the interface").font(.system(size:11,weight:.medium)).padding(.horizontal,12).padding(.vertical,7).aeroCapsule().padding(.bottom,18)}.allowsHitTesting(false)
    } else {
     VStack(spacing:12) {
      topBar
      if flying {hud(g.size)} else {Spacer(minLength:0)}
     }.padding(.horizontal,22).padding(.top,36).padding(.bottom,20)
    }
    if game.paused && !modal {menu(g.size)}
    if game.showMap {mapPanel(g.size)}
    if game.showPassport {FlightRecordView(game:game,available:g.size)}
    if game.showHelp {controlsPanel}
    if game.showCredits {creditsPanel}
   }
  }.frame(minWidth:900,minHeight:620)
 }

 // MARK: Top bar
 private var sceneryLabel:String {game.scenery==1 ? "Apple Maps 3D":"Satellite"}
 private var topBar:some View {
  HStack(alignment:.top) {
   AeroLogo()
   Spacer()
   GlassGroup {
    HStack(spacing:8) {
     Button(action:game.toggleSceneryStyle){Label(sceneryLabel,systemImage:game.scenery==1 ? "building.2.fill":"globe.americas.fill")}.help("Switch between Satellite and Apple Maps 3D (T)")
     Button(action:game.toggleMap){Label("Map",systemImage:"map.fill")}.help("Map (M)")
     Button(action:game.openPassport){Label("Flight record",systemImage:"list.bullet.rectangle.fill")}.help("Flight record (J)")
     Button(action:game.togglePause){Label(game.paused ? (game.launched ? "Resume":"Start"):"Pause",systemImage:game.paused ? "play.fill":"pause.fill")}.help(game.paused ? "Resume (Return)":"Pause (P)")
    }.buttonStyle(AeroButtonStyle(compact:true)).disabled(!game.ready)
   }
  }
 }

 // MARK: In-flight HUD
 private func hud(_ size:CGSize)->some View {
  VStack(spacing:10) {
   HStack(alignment:.top) {progressChip;Spacer(minLength:8);placeChip;Spacer(minLength:8);targetChip}.allowsHitTesting(false)
   status.allowsHitTesting(false)
   Spacer(minLength:0)
   if let i=game.activeDiscovery {
    DiscoveryCard(game:game,id:i).frame(maxWidth:min(560,size.width-80)).transition(.scale(scale:0.94).combined(with:.opacity))
   } else if !game.challenge && found==0 && game.elapsed<15 {
    Text("Fly near a blue marker to collect it").font(.system(size:12,weight:.medium)).padding(.horizontal,14).padding(.vertical,8).aeroCapsule().allowsHitTesting(false).transition(.opacity)
   }
   // In the cockpit, cards and hints sit above the glareshield, clear of the instruments.
   if cockpit {Color.clear.frame(height:max(0,size.height*(1-CockpitView.panelTop+0.05)-max(110,min(190,size.height*(1-CockpitView.panelTop)-52))-30)).allowsHitTesting(false)}
   HStack(alignment:.bottom,spacing:14) {
    // In the cockpit the panel carries the instruments; the map sits at its right end.
    if !cockpit {instruments.allowsHitTesting(false)}
    Spacer()
    FlightMap(game:game,size:cockpit ? max(110,min(190,size.height*(1-CockpitView.panelTop)-52)):size.width<1000 ? 145:190)
   }
  }
  .animation(.snappy(duration:0.25),value:game.activeDiscovery)
  .animation(.snappy(duration:0.25),value:game.crashed)
  .animation(.snappy(duration:0.25),value:game.stalling)
  .animation(.snappy(duration:0.25),value:game.atCeiling)
  .animation(.snappy(duration:0.25),value:game.toast)
  .animation(.easeInOut(duration:0.3),value:game.place)
 }
 // The neighbourhood, town or water below the aircraft.
 @ViewBuilder private var placeChip:some View {
  if !game.place.name.isEmpty {
   HStack(spacing:8) {
    Image(systemName:"mappin.and.ellipse").font(.system(size:13,weight:.semibold)).foregroundStyle(aeroBlue)
    VStack(alignment:.leading,spacing:1) {
     Text(game.place.name).font(.system(size:14,weight:.semibold)).lineLimit(1)
     if !game.place.detail.isEmpty {Text(game.place.detail).font(.system(size:11,weight:.medium)).foregroundStyle(.secondary).lineLimit(1)}
    }
   }.padding(.horizontal,14).padding(.vertical,8).aeroCapsule().transition(.opacity)
   .accessibilityElement(children:.combine).accessibilityLabel("Flying over \(game.place.name)")
  }
 }
 private var progressChip:some View {
  HStack(spacing:10) {
   InfoOrb(collected:found==total,size:30)
   VStack(alignment:.leading,spacing:5) {
    Text("\(found) of \(total) points").font(.system(size:13,weight:.semibold)).monospacedDigit()
    AeroProgress(value:Double(found)/Double(total)).frame(width:110)
   }
  }.padding(.horizontal,14).padding(.vertical,11).aeroPanel(18)
 }
 private var targetChip:some View {
  let gate=game.challenge && !game.routeFinished
  return HStack(spacing:12) {
   Image(systemName:"location.north.fill").font(.system(size:20)).rotationEffect(.radians(Double(game.courseBearing))).foregroundStyle(aeroBlue)
   VStack(alignment:.leading,spacing:2) {
    Text(gate ? "Gate \(game.nextGate+1) of \(routes[game.routeIndex].gates.count)":game.trackedDiscovery != nil ? "Course":"Nearest point").font(.system(size:10,weight:.semibold)).foregroundStyle(.secondary)
    Text(game.nearest).font(.system(size:15,weight:.semibold)).lineLimit(1)
    if !game.distanceText.isEmpty {Text(game.distanceText).font(.system(size:11,weight:.medium)).foregroundStyle(.secondary).monospacedDigit()}
   }
   if game.challenge {
    Divider().frame(height:34)
    VStack(alignment:.trailing,spacing:2) {
     Text(String(format:"%d:%02d",Int(game.elapsed)/60,Int(game.elapsed)%60)).font(.system(size:17,weight:.semibold)).monospacedDigit()
     Text("\(game.points) pts").font(.system(size:11,weight:.medium)).foregroundStyle(.secondary).monospacedDigit()
    }
   }
  }.padding(.horizontal,14).padding(.vertical,11).aeroPanel(18)
 }
 @ViewBuilder private var status:some View {
  if game.crashed {
   statusPill("Crashed · restarting",symbol:"exclamationmark.triangle.fill",tint:.red)
  } else if game.stalling {
   statusPill("Stall · lower the nose",symbol:"arrow.down.to.line",tint:.orange)
  } else if game.atCeiling {
   statusPill("Maximum altitude",symbol:"arrow.up.to.line",tint:.gray)
  }
  if !game.toast.isEmpty {
   Text(game.toast).font(.system(size:12,weight:.semibold)).multilineTextAlignment(.center).padding(.horizontal,16).padding(.vertical,8).aeroCapsule().transition(.opacity)
  } else if !game.mapNotice.isEmpty {
   Text(game.mapNotice).font(.system(size:11,weight:.medium)).foregroundStyle(.secondary).padding(.horizontal,14).padding(.vertical,7).aeroCapsule()
  }
 }
 private func statusPill(_ text:String,symbol:String,tint:Color)->some View {
  Label(text,systemImage:symbol).font(.system(size:13,weight:.semibold)).foregroundStyle(.white).padding(.horizontal,16).padding(.vertical,9).aeroCapsule(tint:tint).transition(.scale(scale:0.9).combined(with:.opacity))
 }
 private var instruments:some View {
  HStack(spacing:20) {
   metric("Speed",String(game.speedReadout),"kn")
   metric("Altitude",String(game.altitude),"ft")
   metric("Above ground",String(game.height),"ft")
   VStack(alignment:.leading,spacing:7) {
    Text("Boost").font(.system(size:10,weight:.semibold)).foregroundStyle(.secondary)
    AeroProgress(value:Double(game.boostReadout)).frame(width:64)
    Text("Shift").font(.system(size:10,weight:.medium)).foregroundStyle(.tertiary)
   }
  }.padding(.horizontal,18).padding(.vertical,13).aeroPanel(20)
 }
 private func metric(_ label:String,_ value:String,_ unit:String)->some View {
  VStack(alignment:.leading,spacing:3) {
   Text(label).font(.system(size:10,weight:.semibold)).foregroundStyle(.secondary)
   HStack(alignment:.firstTextBaseline,spacing:3) {
    Text(value).font(.system(size:24,weight:.semibold)).monospacedDigit()
    Text(unit).font(.system(size:11,weight:.medium)).foregroundStyle(.secondary)
   }
  }.frame(minWidth:70,alignment:.leading)
 }

 // MARK: Pause menu
 private func menu(_ size:CGSize)->some View {
  ViewThatFits(in:.vertical) {
   menuContent
   ScrollView {menuContent}
  }.frame(width:400).aeroPanel(26).frame(maxHeight:max(280,size.height-130))
 }
 private var menuContent:some View {
  VStack(alignment:.leading,spacing:14) {
   HStack(spacing:12) {if !game.launched {AppMark(size:56)};Text(game.launched ? "Paused":region.appName).font(.system(size:24,weight:.bold))}
   HStack(spacing:11) {
    InfoOrb(collected:found==total,size:30)
    VStack(alignment:.leading,spacing:5) {
     Text("\(found) of \(total) points found").font(.system(size:12,weight:.medium)).foregroundStyle(.secondary).monospacedDigit()
     AeroProgress(value:Double(found)/Double(total))
    }
   }
   if let error=game.error {
    Text(error).font(.system(size:12)).foregroundStyle(.red).textSelection(.enabled)
   } else if !game.ready {
    HStack(spacing:8) {ProgressView().controlSize(.small);Text(game.loading).font(.system(size:12,weight:.medium)).foregroundStyle(.secondary)}
   } else {
    Divider()
    menuSettings
    Divider()
    menuActions
   }
  }.padding(24)
 }
 @ViewBuilder private var menuSettings:some View {
  row("Mode") {Picker("Mode",selection:$game.selectedChallenge){Text("Explore").tag(false);Text("Gate challenge").tag(true)}.pickerStyle(.segmented)}
  if game.selectedChallenge {
   row("Route") {Picker("Route",selection:$game.selectedRouteIndex){ForEach(0..<routes.count,id:\.self){Text(routes[$0].name).tag($0)}}}
   note(routes[game.selectedRouteIndex].subtitle)
  } else {
   row("Start") {Picker("Start",selection:$game.launchIndex){ForEach(0..<launches.count,id:\.self){Text(launches[$0].name).tag($0)}}}
  }
  row("Scenery") {Picker("Scenery",selection:Binding(get:{game.preferredScenery},set:game.chooseScenery)){Text("Satellite").tag(2);Text("Apple Maps 3D").tag(1)}.pickerStyle(.segmented)}
  if !game.mapNotice.isEmpty {note(game.mapNotice)}
  row("Music") {Toggle("Music",isOn:Binding(get:{game.musicOn},set:{_ in game.toggleMusic()})).toggleStyle(.switch).controlSize(.small)}
 }
 @ViewBuilder private var menuActions:some View {
  if game.launched {
   Button(action:game.resume){Label("Resume",systemImage:"play.fill").frame(maxWidth:.infinity)}.buttonStyle(AeroButtonStyle(prominent:true))
   Button(action:game.begin){Label("New flight",systemImage:"arrow.counterclockwise").frame(maxWidth:.infinity)}.buttonStyle(AeroButtonStyle())
  } else {
   Button(action:game.begin){Label("Start flight",systemImage:"airplane").frame(maxWidth:.infinity)}.buttonStyle(AeroButtonStyle(prominent:true))
  }
  HStack(spacing:8) {
   Button("Controls",action:game.openHelp);Button("Flight record",action:game.openPassport);Button("Credits",action:game.openCredits)
  }.buttonStyle(AeroButtonStyle(compact:true)).frame(maxWidth:.infinity)
 }
 private func row<Content:View>(_ title:String,@ViewBuilder content:()->Content)->some View {
  HStack(spacing:10) {
   Text(title).font(.system(size:12,weight:.medium)).foregroundStyle(.secondary).frame(width:62,alignment:.leading)
   content().labelsHidden()
   Spacer(minLength:0)
  }
 }
 private func note(_ text:String)->some View {
  Text(text).font(.system(size:11)).foregroundStyle(.secondary).fixedSize(horizontal:false,vertical:true).padding(.leading,72)
 }

 // MARK: Panels
 private func mapPanel(_ size:CGSize)->some View {
  ZStack {
   Color.black.opacity(0.3).ignoresSafeArea().onTapGesture(perform:game.closeMap)
   VStack(spacing:16) {
    FlightMap(game:game,size:min(size.height-170,size.width-80,650))
    Button(game.mapReturnsToFlight ? "Resume":"Close",action:game.closeMap).buttonStyle(AeroButtonStyle())
   }
  }
 }
 private func panel<Content:View>(_ title:String,width:CGFloat,close:@escaping()->Void,@ViewBuilder content:()->Content)->some View {
  ZStack {
   Color.black.opacity(0.3).ignoresSafeArea().onTapGesture(perform:close)
   VStack(alignment:.leading,spacing:16) {
    HStack {Text(title).font(.system(size:22,weight:.bold));Spacer();Button("Done",action:close).buttonStyle(AeroButtonStyle(compact:true))}
    content()
   }.font(.system(size:12)).padding(24).frame(width:width).aeroPanel(26)
  }
 }
 private var controlsPanel:some View {
  panel("Controls",width:600,close:{game.showHelp=false}) {
   LazyVGrid(columns:[GridItem(.flexible(),spacing:28),GridItem(.flexible())],spacing:9) {
    ForEach(controlKeys,id:\.action) {item in
     HStack {
      Text(item.action).font(.system(size:12,weight:.medium))
      Spacer()
      Text(item.keys).font(.system(size:11,weight:.semibold,design:.monospaced)).padding(.horizontal,7).padding(.vertical,3).aeroInset(6)
     }
    }
   }
   Divider()
   VStack(alignment:.leading,spacing:6) {
    Text("Gamepad: left stick steers, right trigger boosts, left trigger brakes.")
    Text("Dives gain airspeed; climbs and hard turns lose it. Braking tightens turns, and braking in a steep climb stalls the wing. The aircraft levels off at 2,400 m.")
    Text("A shallow touch on the ground or water bounces. A steep impact is a crash, and the flight restarts above the crash site.")
    Text("Points and gates are markers on the map. Passing within 140 m collects one at any altitude.")
   }.foregroundStyle(.secondary).fixedSize(horizontal:false,vertical:true)
  }
 }
 private var creditsPanel:some View {
  panel("Credits",width:560,close:{game.showCredits=false}) {
   VStack(alignment:.leading,spacing:10) {
    Text("Scenery and maps: Apple Maps (MapKit). An internet connection is required.")
    Text("Terrain elevation for collisions: Mapzen / AWS Terrain Tiles, including USGS data.")
    if region.id=="nyc" {Text("Water areas: USGS National Land Cover Database.")}
    Text("Music: Bossa Antigua, Backbay Lounge and Carefree by Kevin MacLeod (incompetech.com), CC BY 4.0, transcoded for the app.")
    Text("The flight model is simplified.")
    Link("Music license",destination:URL(string:"https://creativecommons.org/licenses/by/4.0/")!).font(.system(size:12,weight:.medium))
   }.fixedSize(horizontal:false,vertical:true)
  }
 }
}

struct DiscoveryCard:View {
 @ObservedObject var game:FlightGame
 let id:Int
 var body:some View {
  let site=discoverySites[id]
  HStack(alignment:.top,spacing:14) {
   InfoOrb(collected:true,size:40)
   VStack(alignment:.leading,spacing:6) {
    HStack(alignment:.firstTextBaseline) {
     Text(site.place.name).font(.system(size:18,weight:.bold))
     Spacer()
     Text("\(game.discovered.count) of \(sights.count)").font(.system(size:11,weight:.medium)).foregroundStyle(.secondary).monospacedDigit()
     Button {game.activeDiscovery=nil} label:{Image(systemName:"xmark.circle.fill").font(.system(size:15)).foregroundStyle(.secondary)}.buttonStyle(.plain).help("Dismiss")
    }
    Text(site.fact).font(.system(size:12)).fixedSize(horizontal:false,vertical:true)
    Button("Open in flight record") {game.selectedDiscovery=id;game.openPassport()}.buttonStyle(AeroButtonStyle(compact:true)).padding(.top,2)
   }
  }.padding(16).aeroPanel(22)
 }
}

struct FlightRecordView:View {
 @ObservedObject var game:FlightGame
 let available:CGSize
 private var selected:Int {clamp(game.selectedDiscovery,0,discoverySites.count-1)}
 var body:some View {
  ZStack {
   Color.black.opacity(0.3).ignoresSafeArea().onTapGesture {game.showPassport=false}
   VStack(alignment:.leading,spacing:14) {
    HStack {
     VStack(alignment:.leading,spacing:2) {
      Text("Flight record").font(.system(size:22,weight:.bold))
      Text("\(game.discovered.count) of \(sights.count) points found").font(.system(size:12,weight:.medium)).foregroundStyle(.secondary).monospacedDigit()
     }
     Spacer()
     Button("Done") {game.showPassport=false}.buttonStyle(AeroButtonStyle(compact:true))
    }
    AeroProgress(value:Double(game.discovered.count)/Double(sights.count))
    HStack(alignment:.top,spacing:18) {
     ScrollView {grid.padding(2)}.frame(maxWidth:.infinity)
     ScrollView {detail}.frame(width:270).aeroInset(18)
    }
   }.padding(24).frame(width:min(900,available.width-48),height:min(600,available.height-80)).aeroPanel(26)
  }
 }
 private var grid:some View {
  LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:8),count:available.width<1000 ? 4:6),spacing:8) {
   ForEach(0..<discoverySites.count,id:\.self) {i in cell(i)}
  }
 }
 private func cell(_ i:Int)->some View {
  let has=game.discovered.contains(i)
  return Button {game.selectedDiscovery=i} label:{
   VStack(spacing:5) {
    InfoOrb(collected:has,size:34,ghost:!has)
    Text(discoverySites[i].place.name).font(.system(size:10,weight:.medium)).lineLimit(2).multilineTextAlignment(.center).foregroundStyle(has ? .primary:.secondary).frame(height:26,alignment:.top)
   }.padding(.horizontal,4).padding(.vertical,8).frame(maxWidth:.infinity).aeroInset(13,selected:selected==i).contentShape(Rectangle())
  }.buttonStyle(.plain)
 }
 private var detail:some View {
  let site=discoverySites[selected],found=game.discovered.contains(selected)
  return VStack(alignment:.leading,spacing:11) {
   Text(site.region).font(.system(size:11,weight:.semibold)).foregroundStyle(.secondary)
   Text(site.place.name).font(.system(size:20,weight:.bold))
   if found {
    Text(site.fact).font(.system(size:13)).fixedSize(horizontal:false,vertical:true)
    Link("Source",destination:URL(string:site.source)!).font(.system(size:12,weight:.medium))
   } else {
    Label("Not found yet",systemImage:"circle.dashed").font(.system(size:12,weight:.semibold)).foregroundStyle(.secondary)
    Text(site.hint).font(.system(size:13)).fixedSize(horizontal:false,vertical:true)
    Button {game.setCourse(selected)} label:{Label("Set course",systemImage:"location.north.fill")}.buttonStyle(AeroButtonStyle(prominent:true,compact:true)).padding(.top,2)
   }
  }.frame(maxWidth:.infinity,alignment:.leading).padding(16)
 }
}
