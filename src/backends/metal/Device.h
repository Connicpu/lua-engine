#pragma once

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <backends/common/renderer.h>

@interface CNNRDevice : NSObject {
    id<MTLDevice> device;
}

-(id)initWithParams:(const device_params *)params;

@end
