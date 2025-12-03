const std = @import("std");

const ModuleMap = std.StringArrayHashMap(*std.Build.Module);
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // setup our dependencies
    const allocator = gpa.allocator();

    var modules = ModuleMap.init(allocator);
    defer modules.deinit();

    // Expose this as a module that others can import
    const mod = b.addModule("simply-valid", .{
        .root_source_file = b.path("src/root.zig"),
        .optimize = optimize,
        .target = target,
    });

    {
        // test step
        const lib_test = b.addTest(.{
            .root_module = mod,
            .test_runner = .{
                .mode = .simple,
                .path = b.path("test-runner.zig"),
            },
        });
        addLibs(lib_test, modules);

        const run_test = b.addRunArtifact(lib_test);
        run_test.has_side_effects = true;

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_test.step);
    }
}

fn addLibs(step: *std.Build.Step.Compile, modules: ModuleMap) void {
    var it = modules.iterator();
    while (it.next()) |m| {
        step.root_module.addImport(m.key_ptr.*, m.value_ptr.*);
    }
}
