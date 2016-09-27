#pragma once

#include <backends/common/renderer.h>

void rd_set_error(int code, const char *msg);
void rd_append_error(const char *msg);

bool rd_last_error(renderer_error *error);
void rd_clear_error();
