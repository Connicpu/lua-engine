local ffi = require("engine.graphics.renderer.typedefs")

ffi.rd_header.cdef[[
    struct adapter_output {
        // An index that can be used for looking up this adapter later,
        // but only within this process on this specific instance.
        uint32_t process_index;

        output_id id;
        uint64_t device_memory;
        uint64_t system_memory;
        char device_name[64];
    };

    enum window_state #ENUM {
        windowed = 0,
        borderless = 1,
        fullscreen = 2,
    };

    struct window_params {
        window_state state;
        int windowed_width;
        int windowed_height;
        const char *title;
    };

    // Call this function with (inst, 0, nil) and it will return the
    // number of outputs available. Otherwise it will fill `outputs`
    // up to the number of outputs or len, and return the number
    // written.
    size_t rd_get_outputs(instance *inst, size_t len, adapter_output *outputs);

    window *rd_create_window(device *dev, const window_params *params);
    void rd_free_window(window *win);

    bool rd_set_window_state(window *win, window_state state);
    render_target *rd_get_window_target(window *win);
    void rd_get_window_dpi(window *win, float *dpix, float *dpiy);
    bool rd_prepare_window_for_drawing(device *dev, window *win);
    int rd_present_window(window *win);
    bool rd_test_window_occlusion(window *win);
]]

return ffi
