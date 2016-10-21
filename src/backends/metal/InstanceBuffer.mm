#include "InstanceBuffer.h"
#include "Device.h"

ib_state::ib_state()
{
    rd_ib_deactivate(*this);
}

static bool should_resize(uint32_t count, ib_state &state)
{
    if (!state.buffer)
        return true;

    if (state.cap < count)
        return true;

    for (size_t c : state.previous_counts)
    {
        if (c != ~0u && c > state.cap / 3)
            return false;
    }

    return true;
}

bool rd_ib_start_upload(device *pdev, uint32_t count, uint32_t isize, ib_state &state)
{
    if (count == 0)
        return set_error_and_ret(false, "Cannot create an instance buffer of size 0");

    auto dev = ref_objc<CNNRDevice>(pdev);

    if (should_resize(count, state))
    {
        rd_ib_deactivate(state);
        uint32_t new_cap = uint32_t(count * 1.5);
        NSUInteger byte_cap = (NSUInteger)(new_cap * isize);
        
        // Create the buffer
        state.buffer = [dev.device newBufferWithLength:byte_cap
                                               options:kResourceOptions];
        if (state.buffer == nil)
            return set_error_and_ret(false, "Failed to create Metal buffer");

        state.cap = new_cap;
    }
    
    memmove(state.previous_counts + 1, state.previous_counts, 7 * sizeof(uint32_t));
    state.previous_counts[0] = count;

    state.written_bytes = 0;
    state.mapped_data = (uint8_t *)[state.buffer contents];
    if (state.mapped_data == nullptr)
        return set_error_and_ret(false, "Buffer could not be mapped to CPU memory");
    
    return true;
}

void rd_ib_push(const void *data, uint32_t size, uint32_t count, ib_state &state)
{
    assert(state.idx + count <= state.cap);
    auto offset = size * state.idx;
    auto dst = state.mapped_data + offset;

    memcpy(dst, data, size * count);

    state.idx += count;
    state.written_bytes += size * count;
}

bool rd_ib_finish(device *, ib_state &state)
{
    #ifdef MACOS
    [state.buffer didModifyRange:NSMakeRange(0, state.written_bytes)];
    #endif
    return true;
}

void rd_ib_deactivate(ib_state &state)
{
    state.buffer = nil;
    state.cap = 0;
    memset(state.previous_counts, 0xFF, sizeof(state.previous_counts));
}
