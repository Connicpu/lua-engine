local ffi = require("ffi")

ffi.cdef[[
    struct NaiveDate {
        int32_t ymfd;
    };
    struct NaiveTime {
        uint32_t secs;
        uint32_t frac;
    };
    struct NaiveDateTime {
        struct NaiveDate date;
        struct NaiveTime time;
    };

    struct UtcDate {
        struct NaiveDate date;
    };
    struct UtcDateTime {
        struct NaiveDateTime datetime;
    };

    struct LocalDate {
        struct NaiveDate date;
    };
    struct LocalDateTime {
        struct NaiveDateTime datetime;
    };
]]

local tlib = ffi.load("time_helper")

local chrono = {}


return chrono
