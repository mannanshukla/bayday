import AppKit
import SwiftUI
import MetalKit

class FlightMetalView:MTKView {
 override var isOpaque:Bool{false}
}
struct MetalCanvas:NSViewRepresentable {
 @ObservedObject var game:FlightGame
 func makeNSView(context:Context)->MTKView {
  let view=FlightMetalView(frame:.zero)
  DispatchQueue.main.async {
   do {let renderer=try FlightRenderer(view:view,game:game);game.renderer=renderer;game.loading="Loading scenery…"
    DispatchQueue.main.asyncAfter(deadline:.now()+0.1){do{try renderer.load()
     // `--fly <camera> <turn> <climb> <start>` starts a flight immediately with a steady input (for checking views).
     let args=CommandLine.arguments;if let i=args.firstIndex(of:"--fly") {func value(_ k:Int)->Float {i+k<args.count ? Float(args[i+k]) ?? 0:0};game.launchIndex=clamp(Int(value(4)),0,launches.count-1);game.begin();game.cameraMode=clamp(Int(value(1)),0,2);game.demoInput=SIMD2(value(2),value(3))}
     // `--city <id>` changes city three seconds after launch (for checking that the menu follows).
     if let i=args.firstIndex(of:"--city"),i+1<args.count {let id=args[i+1];DispatchQueue.main.asyncAfter(deadline:.now()+3){game.setRegion(id)}}
     // `--land [look]` (after --fly over water) sets the aircraft down at once, and with `look`
     // opens Look Around five seconds later (for checking the landing and Look Around).
     if let i=args.firstIndex(of:"--land") {game.demoInput = .zero;game.position.y=(game.terrain?.surface(game.position) ?? 0)+Aero.clearance;game.land();game.speed=0
      if i+1<args.count && args[i+1]=="look" {DispatchQueue.main.asyncAfter(deadline:.now()+5){game.openLookAround()}}}
     // `--panel destinations|record|controls` opens a panel at launch (for checking the interface).
     if let i=args.firstIndex(of:"--panel"),i+1<args.count {switch args[i+1] {case "destinations":game.openDestinations();case "record":game.openPassport();case "controls":game.openHelp();default:break}}
    }catch{game.error=error.localizedDescription}}
   }catch{game.error=error.localizedDescription}
  }
  return view
 }
 func updateNSView(_ nsView:MTKView,context:Context){}
}
struct FlightMap:View {
 @ObservedObject var game:FlightGame
 let size:CGFloat
 var body:some View {
  LiveFlightMap(game:game,size:size).frame(width:size,height:size).clipShape(RoundedRectangle(cornerRadius:20,style:.continuous)).overlay(RoundedRectangle(cornerRadius:20,style:.continuous).strokeBorder(.white.opacity(0.35),lineWidth:1)).shadow(color:.black.opacity(0.25),radius:12,y:5)
 }
}
class AppDelegate:NSObject,NSApplicationDelegate {
 var window:NSWindow!,game=FlightGame(),monitor:Any?,flagsMonitor:Any?
 func applicationDidFinishLaunching(_ notification:Notification){
  NSApp.setActivationPolicy(.regular)
  let menu=NSMenu(),item=NSMenuItem();menu.addItem(item);let app=NSMenu();app.addItem(withTitle:"About \(appName)",action:#selector(about),keyEquivalent:"");app.addItem(.separator());app.addItem(withTitle:"Quit \(appName)",action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q");item.submenu=app;NSApp.mainMenu=menu
  window=NSWindow(contentRect:NSRect(x:0,y:0,width:1280,height:800),styleMask:[.titled,.closable,.miniaturizable,.resizable,.fullSizeContentView],backing:.buffered,defer:false);window.title=appName;window.titleVisibility = .hidden;window.titlebarAppearsTransparent=true;window.isReleasedWhenClosed=false;window.minSize=NSSize(width:900,height:620);window.contentView=NSHostingView(rootView:FlightView(game:game));window.setContentSize(NSSize(width:1280,height:800));window.center();window.makeKeyAndOrderFront(nil);NSApp.activate(ignoringOtherApps:true)
  monitor=NSEvent.addLocalMonitorForEvents(matching:[.keyDown,.keyUp]){[weak self] e in guard let self,self.window.isKeyWindow else{return e};if e.modifierFlags.contains(.command){return e};let shortcut=[UInt16(53),35,36,8,17,40,45,15,46,4,38,44].contains(e.keyCode);if !self.game.paused || shortcut{self.game.key(e.keyCode,down:e.type == .keyDown,repeatKey:e.isARepeat);return nil};return e}
  flagsMonitor=NSEvent.addLocalMonitorForEvents(matching:.flagsChanged){[weak self] e in self?.game.shift=e.modifierFlags.contains(.shift);return e}
  NotificationCenter.default.addObserver(forName:NSWindow.didResignKeyNotification,object:window,queue:.main){[weak self]_ in if !CommandLine.arguments.contains("--fly") && !CommandLine.arguments.contains("--panel"){self?.game.pause()}}
 }
 @objc func about(){game.openCredits()}
 func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication)->Bool{true}
}
@main struct BayDayEntry {
 static func main(){let app=NSApplication.shared;let delegate=AppDelegate();app.delegate=delegate;app.run();withExtendedLifetime(delegate){}}
}
