#pragma once

#include <string>
#include <unordered_set>
#include <unordered_map>

struct bytecode_listing
{
    bytecode_listing(
        std::unordered_set<std::string> items,
        std::unordered_map<std::string, bytecode_listing> subdirs
    ) : items(std::move(items)), subdirs(std::move(subdirs))
    {
    }

    std::unordered_set<std::string> items;
    std::unordered_map<std::string, bytecode_listing> subdirs;
};

extern std::unordered_map<std::string, std::string> baked_bytecode;
extern bytecode_listing bytecode_list;

