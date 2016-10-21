#include "Scene.h"
#include "InstanceBuffer.h"
#include <backends/common/scene_graph.h>

@implementation CNNRScene
{
    scene_graph<
        sprite_object,
        sprite_instance,
        InstanceBuffer,
        error_interface
    > _graph;
}

-(instancetype)initWithSize:(vec2)size
{
    self = [super init];
    if (self)
    {
        _graph.init(size);
    }
    return self;
}

@end

