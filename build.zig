const std = @import("std");
const Target = std.Target;
const CrossTarget = std.zig.CrossTarget;

pub fn build(b: *std.Build) !void {
    const targetQuery = CrossTarget {
        .cpu_arch = .avr,
        .cpu_model = .{
            .explicit = &Target.avr.cpu.atmega328p,
        },
        .os_tag = .freestanding,
        .abi = .none,
    };

    const target = b.resolveTargetQuery(targetQuery);
    const optimize = b.standardOptimizeOption(.{});

    const kernel = b.addExecutable(.{
        .name = "rtos",
        .root_source_file = b.path("source/start.zig"),
        .target = target,
        .optimize = optimize,
    });

    kernel.setLinkerScriptPath(b.path("source/linker.ld"));

    b.installArtifact(kernel);

    const tty = b.option(
        []const u8,
        "tty",
        "Specify the port to which the Arduino is connected (defaults to /dev/ttyACM0)",
    ) orelse "/dev/ttyACM0";

    const bin_path = b.getInstallPath(.{ .custom = kernel.installed_path orelse "./bin" }, kernel.out_filename);

    const flash_command = blk: {
        var tmp = std.ArrayList(u8).init(b.allocator);
        try tmp.appendSlice("-Uflash:w:");
        try tmp.appendSlice(bin_path);
        try tmp.appendSlice(":e");
        break :blk try tmp.toOwnedSlice();
    };

    const upload = b.step("upload", "Upload the code to an Arduino device using avrdude");
    const avrdude = b.addSystemCommand(&.{
        "sudo",
        "avrdude",
        "-carduino",
        "-patmega328p",
        "-D",
        "-P",
        tty,
        flash_command,
    });
    upload.dependOn(&avrdude.step);
    avrdude.step.dependOn(&kernel.step);

    const objdump = b.step("objdump", "Show dissassembly of the code using avr-objdump");
    const avr_objdump = b.addSystemCommand(&.{
        "avr-objdump",
        "-dh",
        bin_path,
    });
    objdump.dependOn(&avr_objdump.step);
    avr_objdump.step.dependOn(&kernel.step);
}
