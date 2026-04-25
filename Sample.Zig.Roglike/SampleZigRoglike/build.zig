const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
    });

    const c_module = translate_c.createModule();

    if (target.result.os.tag == .windows) {
        {
            // install libtcod
            const dynamic_link_opts: std.Build.Module.LinkSystemLibraryOptions = .{
                .preferred_link_mode = .dynamic,
                .search_strategy = .mode_first,
                .use_pkg_config = .no,
            };

            {
                const sdl_path = b.path("../../SDL3_lib/SDL3/");
                translate_c.addIncludePath(sdl_path.join(b.allocator, "include") catch unreachable);
                c_module.addLibraryPath(sdl_path.join(b.allocator, "lib/x64") catch unreachable);
                const bin = sdl_path.join(b.allocator, "lib/x64/SDL3.dll") catch unreachable;
                b.installBinFile(bin.src_path.sub_path, "SDL3.dll");
                c_module.linkSystemLibrary("SDL3", dynamic_link_opts);
            }

            {
                const tcod_path = b.path("../../libtcod/");
                translate_c.addIncludePath(tcod_path.join(b.allocator, "include") catch unreachable);
                c_module.addLibraryPath(tcod_path.join(b.allocator, "lib") catch unreachable);
                c_module.linkSystemLibrary("libtcod", dynamic_link_opts);

                b.installBinFile("../../libtcod/bin/libtcod.dll", "libtcod.dll");
                //b.installBinFile("../../libtcod/bin/SDL3.dll", "SDL3.dll");
                b.installBinFile("../../libtcod/bin/zlib1.dll", "zlib1.dll");
                b.installBinFile("../../libtcod/bin/utf8proc.dll", "utf8proc.dll");
                b.installBinFile("../../libtcod/bin/terminal.png", "terminal.png");
            }

            b.installBinFile("../../res/dejavu10x10_gs_tc.png", "dejavu10x10_gs_tc.png");
            b.installBinFile("../../res/menu_background.png", "menu_background.png");
        }
    }

    root_module.addImport("c", c_module);
    root_module.link_libc = true;

    const exe = b.addExecutable(.{
        .name = "SampleZigRoglike",
        .root_module = root_module,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.setCwd(.{ .cwd_relative = b.exe_dir });
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
