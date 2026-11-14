#include <metal_stdlib>
using namespace metal;
// Draws the aircraft and its effects over the map. Material kinds:
// 0 gloss paint, 1 glass, 2 matte, 3 emissive. options.x is the opacity of the draw.
struct Vertex {packed_float3 p;packed_float3 n;packed_float3 c;packed_float2 uv;float kind;};
struct Uniforms {float4x4 vp;float4x4 model;float4 eyeTime;float4 sun;float4 options;};
struct Out {float4 position [[position]];float3 world;float3 normal;float3 color;float kind [[flat]];};
vertex Out worldVertex(uint id [[vertex_id]],const device Vertex* verts [[buffer(0)]],constant Uniforms& u [[buffer(1)]]) {
 Vertex v=verts[id];Out o;float4 w=u.model*float4(float3(v.p),1);o.position=u.vp*w;o.world=w.xyz;
 o.normal=normalize((u.model*float4(float3(v.n),0)).xyz);o.color=float3(v.c);o.kind=v.kind;return o;
}
float3 sky(float3 d){return mix(float3(.50,.56,.58),float3(.20,.42,.80),saturate(d.y*.5+.5));}
fragment float4 worldFragment(Out in [[stage_in]],constant Uniforms& u [[buffer(1)]]) {
 float3 view=normalize(u.eyeTime.xyz-in.world),n=normalize(in.normal),sun=normalize(u.sun.xyz);
 if(dot(n,view)<0)n=-n;                       // thin parts are lit from both sides
 float3 base=pow(max(in.color,float3(0)),float3(2.2));
 float ndl=max(0.,dot(n,sun)),ndv=max(0.,dot(n,view)),fresnel=pow(1-ndv,5);
 float3 halfway=normalize(sun+view),sunlight=float3(1.,.95,.86)*ndl;
 float3 ambient=mix(float3(.16,.17,.15),float3(.42,.52,.68),n.y*.5+.5);
 float3 color;
 if(in.kind<.5){
  color=base*(ambient*.72+sunlight*.82);
  color+=sky(reflect(-view,n))*(.04+.30*fresnel);
  color+=float3(1.,.96,.9)*pow(max(0.,dot(n,halfway)),90)*.8*ndl;
 }else if(in.kind<1.5){
  color=mix(base*.35,sky(reflect(-view,n)),.22+.7*fresnel);
  color+=float3(1.)*pow(max(0.,dot(n,halfway)),260)*2.2;
 }else if(in.kind<2.5){
  color=base*(ambient*.9+sunlight*.9);
 }else{
  color=base*1.4;
 }
 // The layer is composited as premultiplied sRGB, so encode here and premultiply after;
 // an sRGB attachment would encode the premultiplied value and brighten soft edges.
 float alpha=u.options.x;
 return float4(pow(saturate(color),float3(1/2.2))*alpha,alpha);
}
