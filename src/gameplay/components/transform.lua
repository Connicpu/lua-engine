local scomp = require("engine.components.struct_components")
local entity = require("engine.entities.entity")
local ffi = require("ffi")

local rotation = math.matrix2d.rotation
local scale = math.matrix2d.scale
local translation = math.matrix2d.translation

ffi.cdef[[
    struct Transform {
        vec2 position;
        vec2 size;
        float scale;
        float rotation;
        entity_t parent;

        matrix2d transform;
        matrix2d self_transform;
    };
]]

local Transform = {}
local Transform_mt = { __index = Transform }
local Transform_ct
local Transform_id

function Transform:initialize()
    self.position = math.vec2(0, 0)
    self.size     = math.vec2(1, 1)
    self.scale    = 1
    self.rotation = 1
    self.parent   = entity.empty
end

function Transform:update()
    self.hierarchy_transform =
        scale(self.size) *
        rotation(self.rotation) *
        translation(self.position)
end

function Transform:update_self(data)
    local transforms = data.components.transform
    local transform = self.transform
    
    local parent = self.parent
    while parent:is_valid() do
        local pt = transforms[parent]
        transform = transform * pt.transform
        parent = pt.parent
    end

    self.self_transform = scale(self.size) * transform
end

function Transform:serialize(state)
    state:write_vec2("position", self.position)
    state:write_vec2("size", self.size)
    state:write_float("scale", self.scale)
    state:write_float("rotation", self.rotation)
    state:write_entity("parent", self.parent)
end

function Transform:deserialize(state)
    self.position = state:read_vec2("position", math.vec2(0, 0))
    self.size     = state:read_vec2("size", math.vec2(1, 1))
    self.scale    = state:read_float("scale", 1)
    self.rotation = state:read_float("rotation", 0)
    self.parent   = state:read_entity("parent")
end

Transform_ct = ffi.metatype()
Transform_id = scomp.define("Transform", Transform_ct)
