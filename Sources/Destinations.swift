import SwiftUI

// A passport stamp for a city: faint until every point there has been found.
struct Stamp:View {
 let city:Region
 let earned:Bool
 var size:CGFloat=84
 // Each city gets its own ink, fixed by its name.
 private var ink:Color {Color(hue:Double(city.id.unicodeScalars.reduce(0){($0*31+Int($1.value))%360})/360,saturation:0.75,brightness:0.85)}
 var body:some View {
  ZStack {
   Circle().strokeBorder(ink,lineWidth:size*0.035)
   Circle().inset(by:size*0.075).strokeBorder(ink,style:StrokeStyle(lineWidth:size*0.014,dash:[size*0.03,size*0.03]))
   VStack(spacing:size*0.01) {
    Text(city.flag).font(.system(size:size*0.27))
    Text(city.name.uppercased()).font(.system(size:size*0.105,weight:.heavy,design:.monospaced)).lineLimit(1).minimumScaleFactor(0.5).padding(.horizontal,size*0.13)
    Text(earned ? "ALL FOUND":"\(city.sites.count) POINTS").font(.system(size:size*0.07,weight:.bold,design:.monospaced))
   }.foregroundStyle(ink)
  }.frame(width:size,height:size).rotationEffect(.degrees(-11)).opacity(earned ? 1:0.3)
  .accessibilityLabel(earned ? "\(city.name) stamp earned":"\(city.name) stamp not yet earned")
 }
}
// Shown for a few seconds as a flight begins: where you are, in the local hand.
struct TitleCard:View {
 let city:Region
 var body:some View {
  VStack(spacing:6) {
   Text(city.flag).font(.system(size:38))
   Text(city.localName ?? city.name).font(.system(size:46,weight:.bold)).lineLimit(1).minimumScaleFactor(0.5)
   Text(city.localName == nil ? city.country:"\(city.name) · \(city.country)").font(.system(size:14,weight:.medium)).foregroundStyle(.secondary)
   if let greeting=city.greeting {Text(greeting).font(.system(size:17,weight:.medium)).italic().padding(.top,4)}
  }.padding(.horizontal,40).padding(.vertical,24).aeroPanel(30)
  .accessibilityElement(children:.combine)
 }
}
// Every city, with what has been found there. Choosing one flies there.
struct DestinationsView:View {
 @ObservedObject var game:FlightGame
 let available:CGSize
 var body:some View {
  let done=Region.all.filter{game.found(in:$0)==$0.sites.count}.count
  ZStack {
   Color.black.opacity(0.3).ignoresSafeArea().onTapGesture {game.showDestinations=false}
   VStack(alignment:.leading,spacing:14) {
    HStack {
     VStack(alignment:.leading,spacing:2) {
      Text("Destinations").font(.system(size:22,weight:.bold))
      Text("\(done) of \(Region.all.count) stamps earned").font(.system(size:12,weight:.medium)).foregroundStyle(.secondary).monospacedDigit()
     }
     Spacer()
     Button("Done") {game.showDestinations=false}.buttonStyle(AeroButtonStyle(compact:true))
    }
    ScrollView {
     LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:12),count:available.width<1000 ? 2:3),spacing:12) {
      ForEach(Region.all,id:\.id) {city in card(city)}
     }.padding(2)
    }
   }.padding(24).frame(width:min(860,available.width-48),height:min(640,available.height-80)).aeroPanel(26)
  }
 }
 private func card(_ city:Region)->some View {
  let found=game.found(in:city),total=city.sites.count,current=city.id==game.regionID
  return Button {game.setRegion(city.id);game.showDestinations=false} label:{
   HStack(alignment:.center,spacing:12) {
    VStack(alignment:.leading,spacing:4) {
     HStack(spacing:6) {
      Text(city.name).font(.system(size:16,weight:.bold)).lineLimit(1).minimumScaleFactor(0.7)
      if let local=city.localName {Text(local).font(.system(size:13,weight:.medium)).foregroundStyle(.secondary)}
     }
     Text("\(city.tagline) · \(city.country)").font(.system(size:11)).foregroundStyle(.secondary).lineLimit(1)
     AeroProgress(value:Double(found)/Double(max(1,total))).padding(.top,4)
     Text(current ? "\(found) of \(total) points · you are here":"\(found) of \(total) points").font(.system(size:11,weight:.medium)).foregroundStyle(.secondary).monospacedDigit()
    }
    Spacer(minLength:0)
    Stamp(city:city,earned:found==total,size:66)
   }.padding(14).frame(maxWidth:.infinity,alignment:.leading).aeroInset(16,selected:current).contentShape(Rectangle())
  }.buttonStyle(.plain).help(current ? "You are flying here":"Fly to \(city.name)")
 }
}
