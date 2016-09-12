local ffi = require("ffi")

ffi.cdef[[
    struct lua_stringbuilder {
        char *data;
        size_t len;
        size_t cap;
    };

    void *malloc(size_t len);
    void *realloc(void *ptr, size_t len);
    void free(void *ptr);
]]

local C = ffi.C
local ffi_new = ffi.new
local ffi_copy = ffi.copy
local ffi_string = ffi.string

local stringbuilder = {}
local stringbuilder_mt = { __index = stringbuilder }
local stringbuilder_ct

function stringbuilder_mt.__new(tp, cap)
    cap = math.max(cap or 64, 8)
    local data = ffi.cast("char *", C.malloc(cap))
    if data == nil then
        error("Failed to allocate a buffer for the stringbuilder")
    end
    return ffi_new(tp, data, 0, cap)
end

function stringbuilder_mt:__gc()
    C.free(self.data)
end

function stringbuilder:grow_at_least(amount)
    local new_cap = self.cap * 2
    if new_cap < self.cap + amount then
        new_cap = self.cap + amount
    end
    local new_data = C.realloc(self.data, new_cap)
    if new_data == nil then
        error("Failed to allocate a buffer for the stringbuilder")
    end
    self.data = ffi.cast("char *", new_data)
    self.cap = new_cap
end

function stringbuilder:append(str)
    str = tostring(str)
    local remaining = self.cap - self.len
    if remaining < #str then
        self:grow_at_least(#str - remaining)
    end

    ffi_copy(self.data + self.len, str, #str)
    self.len = self.len + #str
end

function stringbuilder:tostring()
    return tostring(self)
end

function stringbuilder_mt:__tostring()
    return ffi_string(self.data, self.len)
end

stringbuilder_ct = ffi.metatype("struct lua_stringbuilder", stringbuilder_mt)

return {
    stringbuilder = stringbuilder_ct
}
