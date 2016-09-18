local ffi = require("ffi")

local ffi_new = ffi.new
local ffi_gc = ffi.gc
local ffi_cast = ffi.cast

local make_ptr_type

local function build_type(value_t)
    local option_t = ffi.typeof([[
        struct {
            bool exists;
            $ value;
        }
    ]], value_t)

    local option = {}
    local option_mt = { __index = option }
    local option_ct

    function option_mt.__new(tp, value)
        if value == nil then
            return ffi_new(tp, false)
        else
            return ffi_new(tp, true, ffi_gc(value, nil))
        end
    end

    function option_mt:__gc()
        self:unwrap()
    end

    function option:unwrap()
        if self.exists then
            self.exists = false
            return ffi_new(value_t, self.value)
        end
    end
    
    local ptr_t, optptr_t
    function option:as_ref()
        if not ptr_t then
            ptr_t, optptr_t = make_ptr_type(value_t)
        end

        if self.exists then
            return optptr_t(ffi_cast(ptr_t, self.value))
        else
            return optptr_t()
        end
    end

    option_ct = ffi.metatype(option_t, option_mt)
    return option_ct
end

local option_mt = {}
local option = setmetatable({ __cache = {} }, option_mt)

make_ptr_type = function(value_t)
    local ptr_t = ffi.typeof("$ *", value_t)
    return ptr_t, option[ptr_t]
end

function option_mt:__index(value_t)
    if not self.__cache[value_t] then
        self.__cache[value_t] = build_type(value_t)
    end
    return self.__cache[value_t]
end

return option
