#include "Instance.h"

@implementation CNNRInstance

@end

instance *rd_create_instance()
{
    auto inst = [[CNNRInstance alloc] init];
    return from_objc<instance>(inst);
}

void rd_free_instance(instance *inst)
{
    drop(into_objc<CNNRInstance>(inst));
}
