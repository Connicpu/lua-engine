#include <lua.hpp>
#include <unordered_map>
#include <string>
#include <iostream>

#ifdef BAKED_CODE
extern std::unordered_map<std::string, std::string> baked_bytecode;
static void inject_baked(lua_State *L)
{
    lua_getfield(L, LUA_GLOBALSINDEX, "package");
    lua_getfield(L, -1, "preload");

    for (auto &pair : baked_bytecode)
    {
        lua_pushlstring(L, pair.first.c_str(), pair.first.size());
        if (luaL_loadbuffer(L, pair.second.c_str(), pair.second.size(), pair.first.c_str()))
        {
            std::cerr << "Failed to load `" << pair.first << "` bytecode" << std::endl;
            std::cerr << lua_tostring(L, -1) << std::endl;
            exit(1);
        }
        lua_settable(L, -3);
    }

    lua_pop(L, 2);
}
#endif

int main(int argc, char **argv)
{
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);

#ifdef BAKED_CODE

    inject_baked(L);
    auto &engine = baked_bytecode["main"];
    if (luaL_loadbuffer(L, engine.c_str(), engine.size(), "main"))
    {
        std::cerr << "Failed to load `main` bytecode" << std::endl;
        std::cerr << lua_tostring(L, -1) << std::endl;
        lua_close(L);
        return 1;
    }
    lua_pushliteral(L, "--skip-package-bs");
    for (int i = 1; i < argc; ++argv)
    {
        lua_pushstring(L, argv[i]);
    }
    if (lua_pcall(L, argc, 0, 0))
    {
        std::cerr << lua_tostring(L, -1) << std::endl;
        lua_close(L);
        return 1;
    }

#else

    if (luaL_loadfile(L, "src/main.lua"))
    {
        std::cerr << "Failed to load main.lua" << std::endl;
        std::cerr << lua_tostring(L, -1) << std::endl;
        lua_close(L);
        return 1;
    }
    for (int i = 1; i < argc; ++i)
    {
        lua_pushstring(L, argv[i]);
    }
    if (lua_pcall(L, argc - 1, 0, 0))
    {
        std::cerr << lua_tostring(L, -1) << std::endl;
        lua_close(L);
        return 1;
    }

#endif

    lua_close(L);
    return 0;
}
