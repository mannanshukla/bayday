import SwiftUI
// Native Liquid Glass chrome. On macOS 26 and later every surface is real system glass;
// earlier systems fall back to a material with the same shapes.
let aeroInk=Color.primary
let aeroBlue=Color.blue   // fixed rather than accentColor, which greys out when the window is inactive
let aeroGreen=Color.green
struct GlassSurface<S:Shape>:ViewModifier {
 var shape:S
 var tint:Color?=nil
 var interactive=false
 func body(content:Content)->some View {
  if #available(macOS 26.0,*) {
   content.glassEffect(Glass.regular.tint(tint).interactive(interactive),in:shape)
  } else {
   content.background(tint.map{AnyShapeStyle($0.opacity(0.85))} ?? AnyShapeStyle(.regularMaterial),in:shape)
    .overlay(shape.stroke(.white.opacity(0.22),lineWidth:0.5)).shadow(color:.black.opacity(0.18),radius:12,y:5)
  }
 }
}
// Groups neighbouring glass so the pieces share one sampling pass and can blend together.
struct GlassGroup<Content:View>:View {
 var spacing:CGFloat=8
 @ViewBuilder var content:()->Content
 var body:some View {
  if #available(macOS 26.0,*) {GlassEffectContainer(spacing:spacing){content()}} else {content()}
 }
}
extension View {
 func aeroPanel(_ radius:CGFloat=23)->some View{modifier(GlassSurface(shape:RoundedRectangle(cornerRadius:radius,style:.continuous)))}
 func aeroCapsule(tint:Color?=nil)->some View{modifier(GlassSurface(shape:Capsule(),tint:tint))}
 // A quiet inset for content that sits on glass; glass is never stacked on glass.
 func aeroInset(_ radius:CGFloat=14,selected:Bool=false)->some View{
  background(selected ? AnyShapeStyle(aeroBlue.opacity(0.22)):AnyShapeStyle(Color.primary.opacity(0.07)),in:RoundedRectangle(cornerRadius:radius,style:.continuous))
 }
}
struct AeroButtonStyle:ButtonStyle {
 var prominent=false
 var compact=false
 func makeBody(configuration:Configuration)->some View {AeroButtonBody(configuration:configuration,prominent:prominent,compact:compact)}
}
private struct AeroButtonBody:View {
 let configuration:ButtonStyleConfiguration
 let prominent:Bool,compact:Bool
 @Environment(\.isEnabled) private var enabled
 var body:some View {
  configuration.label.font(.system(size:compact ? 12:15,weight:.semibold)).foregroundStyle(prominent ? AnyShapeStyle(.white):AnyShapeStyle(.primary))
   .padding(.horizontal,compact ? 14:22).padding(.vertical,compact ? 8:12).contentShape(Capsule())
   .modifier(GlassSurface(shape:Capsule(),tint:prominent ? aeroBlue:nil,interactive:true))
   .opacity(!enabled ? 0.45:configuration.isPressed ? 0.8:1)
 }
}
struct InfoOrb:View {
 var collected=false
 var size:CGFloat=48
 var ghost=false
 var body:some View {
  let main=collected ? aeroGreen:Color.blue
  ZStack{
   Circle().fill(main.gradient)
   Circle().strokeBorder(.white.opacity(0.55),lineWidth:max(1,size*0.03))
   Image(systemName:collected ? "checkmark":"info").font(.system(size:size*0.46,weight:.bold)).foregroundStyle(.white)
  }.frame(width:size,height:size).shadow(color:.black.opacity(0.2),radius:size*0.07,y:size*0.04).opacity(ghost ? 0.38:1)
 }
}
struct AeroProgress:View {
 var value:Double
 var body:some View {ProgressView(value:min(1,max(0,value))).progressViewStyle(.linear).tint(aeroGreen)}
}
// The app icon, loaded from the bundle; absent when running outside the app (tests).
struct AppMark:View {
 static let image=Bundle.main.url(forResource:"AppIcon",withExtension:"icns").flatMap{NSImage(contentsOf:$0)}
 var size:CGFloat
 var body:some View {
  if let image=Self.image {Image(nsImage:image).resizable().interpolation(.high).frame(width:size,height:size)}
  else {Image(systemName:"airplane").font(.system(size:size*0.6,weight:.semibold)).foregroundStyle(aeroBlue).frame(width:size,height:size)}
 }
}
struct AeroLogo:View {
 var body:some View {
  HStack(spacing:7){AppMark(size:26);Text(appName).font(.system(size:16,weight:.bold))}.padding(.leading,9).padding(.trailing,15).padding(.vertical,6).aeroCapsule()
 }
}
// A brief white flash whenever the aircraft crashes.
struct ImpactFlash:View {
 let trigger:Int
 var body:some View {
  Color.white.ignoresSafeArea().allowsHitTesting(false)
   .phaseAnimator([0,1,2],trigger:trigger){view,phase in view.opacity(phase==1 ? 0.5:0)} animation:{phase in phase==1 ? .linear(duration:0.04):.easeOut(duration:0.55)}
 }
}
