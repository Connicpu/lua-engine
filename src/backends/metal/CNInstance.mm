#import "CNInstance.h"

@implementation CNInstance

@end

instance *rd_create_instance()
{
    auto inst = [[CNInstance alloc] init];
    return from_objc<instance>(inst);
}

void rd_free_instance(instance *inst)
{
    drop(into_objc<CNInstance>(inst));
}
