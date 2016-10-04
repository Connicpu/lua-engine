local class = require("class")

local ComponentManager = class()

function ComponentManager:initialize()
    self.comptypes = {}
end

function ComponentManager:register(module)
    local factory_type = require(module)
    self:register_factory(factory_type.name, factory_type:build())
end

function ComponentManager:register_factory(name, factory)
    self.comptypes[name] = factory
end

function ComponentManager:build_data()
    local components = {}
    for name, factory in pairs(self.comptypes) do
        components[name] = factory:build_list()
    end
end

return {
    ComponentManager = ComponentManager
}
