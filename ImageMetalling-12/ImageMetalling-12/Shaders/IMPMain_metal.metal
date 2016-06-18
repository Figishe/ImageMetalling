//
//  IMPMain_metal.metal
//  ImageMetalling-09
//
//  Created by denis svinarchuk on 01.01.16.
//  Copyright © 2016 ImageMetalling. All rights reserved.
//

#include <metal_stdlib>
#include "IMPStdlib_metal.h"
using namespace metal;

fragment float4 fragment_gridGenerator(
                                       IMPVertexOut in [[stage_in]],
                                       texture2d<float, access::sample> texture [[ texture(0) ]],
                                       const device uint    &gridStep     [[ buffer(0) ]],
                                       const device uint    &gridSubDiv   [[ buffer(1) ]],
                                       const device float4  &gridColor    [[ buffer(2) ]],
                                       const device float4  &gridSubDivColor [[ buffer(3) ]],
                                       const device float4  &spotAreaColor  [[ buffer(4) ]],
                                       const device IMPRegion  &spotArea    [[ buffer(5) ]],
                                       const device uint     &spotAreaType    [[ buffer(6) ]]
                                       ) {
    
    constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
    
    uint w = texture.get_width();
    uint h = texture.get_height();
    uint x = uint(in.texcoord.x*w);
    uint y = uint(in.texcoord.y*h);
    uint sd = gridStep*gridSubDiv;
    
    float4 inColor = texture.sample(s, in.texcoord.xy);
    float4 color = inColor;
    
    if (x == 0 ) return color;
    if (y == 0 ) return color;
    
    float2 coords  = float2(in.texcoord.x,in.texcoord.y);
    float  isBoxed = IMProcessing::histogram::coordsIsInsideBox(coords, float2(spotArea.left,spotArea.bottom), float2(1.0-spotArea.right,1.0-spotArea.top));
    
    if(x % sd == 0 || y % sd == 0 ) {
        
        color = IMProcessing::blendNormal(inColor, gridSubDivColor);
     
        if (x % 2 == 0 && y % 2 == 0) color = inColor;
        else if ((gridStep+1)%2 == 0) {
            if (x % 2 != 0 && y % 2 != 0) color = inColor;
        }
        
        if (spotAreaType == 0 && isBoxed) {
            color = IMProcessing::blendNormal(color, spotAreaColor);
        }

    }
    else if(x % gridStep==0 || y % gridStep==0) {
        
        color = IMProcessing::blendNormal(inColor, gridColor);
        
        if (x % 2 == 0 && y % 2 == 0) color = inColor;
        else if ((gridStep+1)%2 == 0) {
            if (x % 2 != 0 && y % 2 != 0) color = inColor;
        }
        
        if (spotAreaType == 0 && isBoxed) {
            color = IMProcessing::blendNormal(color, spotAreaColor);
        }

    }

    if (spotAreaType == 1 && isBoxed) {
        color = IMProcessing::blendNormal(color, spotAreaColor);
    }

    return color;
}
