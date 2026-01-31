// ref: https://ziggit.dev/t/translation-errors-trying-to-import-libtcod/13606
pub const c = @cImport({
    @cDefine("SDL_DISABLE_OLD_NAMES", {});
    @cDefine("SDL_MAIN_HANDLED", {});
    @cInclude("SDL3/SDL.h");
    //@cInclude("SDL3/SDL_main.h");
    //@cInclude("SDL3/SDL_properties.h");

    @cInclude("libtcod.h");
    //@cInclude("libtcod/context.h");
    //@cInclude("libtcod/tileset.h");
});
