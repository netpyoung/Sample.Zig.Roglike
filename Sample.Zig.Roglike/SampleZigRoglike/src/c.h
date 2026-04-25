// ref: https://ziggit.dev/t/translation-errors-trying-to-import-libtcod/13606

#define SDL_DISABLE_OLD_NAMES true
#define SDL_MAIN_HANDLED true
#include "SDL3/SDL.h"
//#include "SDL3/SDL_main.h"
//#include "SDL3/SDL_properties.h"

// ref: https://ziggit.dev/t/translation-errors-trying-to-import-libtcod/13606/10
#define _Pragma(x)
#include "libtcod.h"
//#include "libtcod/context.h"
//#include "libtcod/tileset.h"