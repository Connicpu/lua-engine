#include "Scene.h"
#include "InstanceBuffer.h"
#include <backends/common/scene_graph.h>

struct error_interface
{
    template <typename T>
    static T append_ret(T ret, const char *msg)
    {
        return append_error_and_ret(ret, msg);
    }
};

@implementation CNNRScene
{
    std::optional<scene_graph<
        sprite_object,
        sprite_instance,
        InstanceBuffer,
        error_interface
    >> graph;
}

-(instancetype)initWithSize:(vec2)size {
    self.graph = { size };
}

@end
