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

-(bool)drawToTarget:(render_target *)rt
             device:(device *)dev
             camera:(camera *)cam
           viewport:(const viewport *)vp
{
    // TODO!
    drop(rt), drop(dev), drop(cam), drop(vp);
    return set_error_and_ret(false, "Unimplemented");
}

-(sprite_handle)newSpriteWithParams:(const sprite_params *)params
{
    return _graph.create_object(params);
}
-(void)destroySprite:(sprite_handle)sprite
{
    _graph.destroy_object(sprite);
}

-(void)getSpriteUv:(sprite_handle)sprite
         topLeftUv:(vec2 *)topLeft
     bottomRightUv:(vec2 *)bottomRight
{
    *topLeft = sprite->uv0;
    *bottomRight = sprite->uv1;
}
-(float)getSpriteLayer:(sprite_handle)sprite
{
    return sprite->layer;
}
-(texture *)getSpriteTexture:(sprite_handle)sprite
{
    return sprite->tex;
}
-(matrix2d)getSpriteTransform:(sprite_handle)sprite
{
    return sprite->transform;
}
-(color)getSpriteTint:(sprite_handle)sprite
{
    return sprite->tint;
}

-(void)updateSprite:(sprite_handle)sprite
          topLeftUV:(vec2)topLeft
      bottomRightUV:(vec2)bottomRight
{
    sprite->uv0 = topLeft;
    sprite->uv1 = bottomRight;
    _graph.updated_field(sprite);
}
-(void)updateSprite:(sprite_handle)sprite
              layer:(float)layer
{
    sprite->layer = layer;
    _graph.updated_layer(sprite);
}
-(void)updateSprite:(sprite_handle)sprite
            texture:(texture *)texture
{
    _graph.change_texture(sprite, texture);
}
-(void)updateSprite:(sprite_handle)sprite
          transform:(matrix2d)transform
{
    _graph.move_object(sprite, transform);
}
-(void)updateSprite:(sprite_handle)sprite
               tint:(color)tint
{
    sprite->tint = tint;
    _graph.updated_field(sprite);
}

@end

scene *rd_create_scene(device *, float grid_width, float grid_height)
{
    vec2 size = vec2{ grid_width, grid_height };
    auto scene = [[CNNRScene alloc] initWithSize:size];
    return from_objc<struct scene>(scene);
}

void rd_free_scene(scene *scene)
{
    drop(into_objc<CNNRScene>(scene));
}

bool rd_draw_scene(device *dev, render_target *rt, scene *pscene, camera *cam, const viewport *vp)
{
    auto scene = ref_objc<CNNRScene>(pscene);
    return [scene drawToTarget:rt
                        device:dev
                        camera:cam
                      viewport:vp];
}

sprite_handle rd_create_sprite(scene *pscene, const sprite_params *params)
{
    auto scene = ref_objc<CNNRScene>(pscene);
    return [scene newSpriteWithParams:params];
}

void rd_destroy_sprite(scene *pscene, sprite_handle sprite)
{
    auto scene = ref_objc<CNNRScene>(pscene);
    [scene destroySprite:sprite];
}

void rd_get_sprite_uv(scene *pscene, sprite_handle sprite, vec2 *topleft, vec2 *bottomright)
{
    auto scene = ref_objc<CNNRScene>(pscene);
    [scene getSpriteUv:sprite
             topLeftUv:topleft
         bottomRightUv:bottomright];
}

void rd_set_sprite_uv(scene *pscene, sprite_handle sprite, const vec2 *topleft, const vec2 *bottomright)
{
    auto scene = ref_objc<CNNRScene>(pscene);
    [scene updateSprite:sprite
              topLeftUV:*topleft
          bottomRightUV:*bottomright];
}

float rd_get_sprite_layer(scene *pscene, sprite_handle sprite)
{
    auto scene = ref_objc<CNNRScene>(pscene);
    return [scene getSpriteLayer:sprite];
}

void rd_set_sprite_layer(scene *pscene, sprite_handle sprite, float layer)
{
    auto scene = ref_objc<CNNRScene>(pscene);
    [scene updateSprite:sprite
                  layer:layer];
}

texture *rd_get_sprite_texture(scene *pscene, sprite_handle sprite)
{
    auto scene = ref_objc<CNNRScene>(pscene);
    return [scene getSpriteTexture:sprite];
}

void rd_set_sprite_texture(scene *pscene, sprite_handle sprite, texture *tex)
{
    auto scene = ref_objc<CNNRScene>(pscene);
    [scene updateSprite:sprite
                texture:tex];
}

void rd_get_sprite_transform(scene *pscene, sprite_handle sprite, matrix2d *transform)
{
    auto scene = ref_objc<CNNRScene>(pscene);
    *transform = [scene getSpriteTransform:sprite];
}

void rd_set_sprite_transform(scene *pscene, sprite_handle sprite, const matrix2d *transform)
{
    auto scene = ref_objc<CNNRScene>(pscene);
    [scene updateSprite:sprite
              transform:*transform];
}

void rd_get_sprite_tint(scene *pscene, sprite_handle sprite, color *tint)
{
    auto scene = ref_objc<CNNRScene>(pscene);
    *tint = [scene getSpriteTint:sprite];
}

void rd_set_sprite_tint(scene *pscene, sprite_handle sprite, const color *tint)
{
    auto scene = ref_objc<CNNRScene>(pscene);
    [scene updateSprite:sprite
                   tint:*tint];
}

