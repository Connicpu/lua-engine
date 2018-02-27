#include "pch.h"
#include <backends/common/hashmap.h>

extern "C" int foo()
{
    hashmap<std::string, int> bar;
    hashmap<std::string, void> baz;

    baz.insert("bar", {});
    baz.remove("bar");

    std::string key("foo");

    bar.insert(key, 5);
    return *bar.remove(key);
}
