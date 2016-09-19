#pragma once

#include <backends/common/renderer.h>

void rd_set_error(int code, const char *msg);

extern "C" bool rd_last_error(renderer_error *error);
extern "C" void rd_clear_error();
