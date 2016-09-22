#include <Windows.h>
#include <stdio.h>
#include <stdlib.h>

extern "C" INT WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, INT)
{
    int argc = __argc;
    char **argv = __argv;

    bool console = false;
    for (int i = 1; i < argc; ++i)
    {
        if (strcmp(argv[i], "--console") == 0)
        {
            console = true;
        }
    }

    if (console)
    {
        AllocConsole();
        FILE *f;
        freopen_s(&f, "CONIN$", "r", stdin);
        freopen_s(&f, "CONOUT$", "w", stdout);
        freopen_s(&f, "CONOUT$", "w", stderr);
    }

    int main(int argc, char **argv);
    return main(argc, argv);
}
