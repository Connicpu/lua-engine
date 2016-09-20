local ffi = require("ffi")

ffi.cdef[[
    void *malloc(size_t size);
    void *realloc(void *ptr, size_t size);
    void free(void *ptr);

    void *memmove(void *dst, void *src, size_t len);
]]

local ffi_new = ffi.new
local ffi_gc = ffi.gc
local C = ffi.C

local function build_type(value_t, needs_dtor)
    local value_size = ffi.sizeof(value_t)

    local vector_t = ffi.typeof([[
        struct {
            $ *data;
            size_t cap;
            size_t len;
        }
    ]], value_t)

    local Vector = {}
    local Vector_mt = { __index = Vector }
    local Vector_ct

    local function alloc(self, new_cap)
        if new_cap == 0 then
            C.free(self.data)
            self.data = nil
        elseif self.cap == 0 then
            self.data = C.malloc(new_cap)
            if self.data == nil then
                error("malloc failed")
            end
        else
            local new_data = C.realloc(self.data, new_cap)
            if new_data == nil then
                error("realloc failed")
            end
            self.data = new_data
        end
        self.cap = new_cap
    end

    local function grow(self, required)
        local cap = self.cap * 2
        if cap < required then
            cap = required
        end
        alloc(self, cap)
    end

    function Vector_mt.__new(tp, cap)
        local vec = ffi_new(tp, nil, 0, 0)
        if cap and cap > 0 then
            alloc(vec, cap)
        end
        return vec
    end

    if needs_dtor then
        function Vector_mt:__gc()
            for i, v in ipairs(self) do
                ffi_new(value_t, v)
            end
            alloc(self, 0)
        end
    else
        function Vector_mt:__gc()
            alloc(self, 0)
        end
    end

    local function iter(vec, i)
        i = i + 1
        if i >= vec.len then
            return nil
        end
        return i, vec:get(i)
    end

    function Vector_mt:__ipairs()
        return iter, self, 0
    end

    function Vector:push(value)
        if self.len == self.cap then
            grow(self, self.len + 1)
        end
        self.data[self.len] = ffi_gc(value, nil)
        self.len = self.len + 1
    end

    function Vector:pop()
        if self.len == 0 then
            return nil
        end
        self.len = self.len - 1
        return ffi_new(value_t, self.data[self.len])
    end

    function Vector:get(i)
        if i < 1 or i > self.len then
            return nil
        end
        return self.data[i - 1]
    end

    function Vector:remove(i)
        if i < 1 or i > self.len then
            return nil
        end
        local tmp = ffi_new(value_t, self.data[i - 1])
        if i ~= self.len then
            C.memmove(self.data + i - 1, self.data + i, self.len - i)
        end
        self.len = self.len - 1
        return tmp
    end

    function Vector:front()
        if self.len > 0 then
            return self.data[0]
        end
    end

    function Vector:back()
        if self.len > 0 then
            return self.data[self.len - 1]
        end
    end

    Vector_ct = ffi.metatype(vector_t, vector_mt)

    return Vector_ct
end
