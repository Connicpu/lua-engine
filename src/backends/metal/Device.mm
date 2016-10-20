#include "Device.h"

@implementation CNNRDevice

-(id)initWithParams:(const device_params *)params {
    drop(params); // I don't know what to do with these yet
    self = [super init];
    if (self)
    {
        // Create the Metal device, etc
    }
    return self;
}

@end

device *rd_create_device(const device_params *params)
{
    id dev = [[CNNRDevice alloc] initWithParams: params];
    return from_objc<device>(dev);
}

void rd_free_device(device *dev)
{
    drop(into_objc<CNNRDevice>(dev));
}
