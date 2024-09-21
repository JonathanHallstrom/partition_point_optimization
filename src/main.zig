const std = @import("std");

pub fn partitionPoint(
    comptime T: type,
    items: []const T,
    context: anytype,
    comptime predicate: fn (@TypeOf(context), T) bool,
) usize {
    var low: usize = 0;
    var high: usize = items.len;

    while (low < high) {
        const mid = low + (high - low) / 2;
        if (predicate(context, items[mid])) {
            low = mid + 1;
        } else {
            high = mid;
        }
    }
    return low;
}

pub fn partitionPointNew(
    comptime T: type,
    items: []const T,
    context: anytype,
    comptime predicate: fn (@TypeOf(context), T) bool,
) usize {
    var it: usize = 0;
    var len: usize = items.len;

    const branchy_limit = (4 * std.atomic.cache_line) / @sizeOf(T);
    if (branchy_limit > 1) {
        while (len > branchy_limit) {
            const half: usize = len / 2;
            len -= half;
            if (predicate(context, items[it + half - 1])) {
                it += half;
            }
        }
    }
    while (len > 1) {
        const half: usize = len / 2;
        len -= half;
        if (predicate(context, items[it + half - 1])) {
            @branchHint(.unpredictable);
            it += half;
        }
    }

    if (it < items.len) {
        it += @intFromBool(predicate(context, items[it]));
    }

    return it;
}

fn testPartitionPointImpl(partitionPointImpl: anytype) !void {
    const S = struct {
        fn lowerU32(context: u32, item: u32) bool {
            return item < context;
        }
        fn lowerI32(context: i32, item: i32) bool {
            return item < context;
        }
        fn lowerF32(context: f32, item: f32) bool {
            return item < context;
        }
        fn lowerEqU32(context: u32, item: u32) bool {
            return item <= context;
        }
        fn lowerEqI32(context: i32, item: i32) bool {
            return item <= context;
        }
        fn lowerEqF32(context: f32, item: f32) bool {
            return item <= context;
        }
        fn isEven(_: void, item: u8) bool {
            return item % 2 == 0;
        }
    };

    try std.testing.expectEqual(0, partitionPointImpl(u32, &[_]u32{}, @as(u32, 0), S.lowerU32));
    try std.testing.expectEqual(0, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 16, 32, 64 }, @as(u32, 0), S.lowerU32));
    try std.testing.expectEqual(0, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 16, 32, 64 }, @as(u32, 2), S.lowerU32));
    try std.testing.expectEqual(2, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 16, 32, 64 }, @as(u32, 5), S.lowerU32));
    try std.testing.expectEqual(2, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 16, 32, 64 }, @as(u32, 8), S.lowerU32));
    try std.testing.expectEqual(6, partitionPointImpl(u32, &[_]u32{ 2, 4, 7, 7, 7, 7, 16, 32, 64 }, @as(u32, 8), S.lowerU32));
    try std.testing.expectEqual(2, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 8, 8, 8, 16, 32, 64 }, @as(u32, 8), S.lowerU32));
    try std.testing.expectEqual(5, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 16, 32, 64 }, @as(u32, 64), S.lowerU32));
    try std.testing.expectEqual(6, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 16, 32, 64 }, @as(u32, 100), S.lowerU32));
    try std.testing.expectEqual(2, partitionPointImpl(i32, &[_]i32{ 2, 4, 8, 16, 32, 64 }, @as(i32, 5), S.lowerI32));
    try std.testing.expectEqual(1, partitionPointImpl(f32, &[_]f32{ -54.2, -26.7, 0.0, 56.55, 100.1, 322.0 }, @as(f32, -33.4), S.lowerF32));
    try std.testing.expectEqual(0, partitionPointImpl(u32, &[_]u32{}, @as(u32, 0), S.lowerEqU32));
    try std.testing.expectEqual(0, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 16, 32, 64 }, @as(u32, 0), S.lowerEqU32));
    try std.testing.expectEqual(1, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 16, 32, 64 }, @as(u32, 2), S.lowerEqU32));
    try std.testing.expectEqual(2, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 16, 32, 64 }, @as(u32, 5), S.lowerEqU32));
    try std.testing.expectEqual(6, partitionPointImpl(u32, &[_]u32{ 2, 4, 7, 7, 7, 7, 16, 32, 64 }, @as(u32, 8), S.lowerEqU32));
    try std.testing.expectEqual(6, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 8, 8, 8, 16, 32, 64 }, @as(u32, 8), S.lowerEqU32));
    try std.testing.expectEqual(3, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 16, 32, 64 }, @as(u32, 8), S.lowerEqU32));
    try std.testing.expectEqual(6, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 16, 32, 64 }, @as(u32, 64), S.lowerEqU32));
    try std.testing.expectEqual(6, partitionPointImpl(u32, &[_]u32{ 2, 4, 8, 16, 32, 64 }, @as(u32, 100), S.lowerEqU32));
    try std.testing.expectEqual(2, partitionPointImpl(i32, &[_]i32{ 2, 4, 8, 16, 32, 64 }, @as(i32, 5), S.lowerEqI32));
    try std.testing.expectEqual(1, partitionPointImpl(f32, &[_]f32{ -54.2, -26.7, 0.0, 56.55, 100.1, 322.0 }, @as(f32, -33.4), S.lowerEqF32));
    try std.testing.expectEqual(4, partitionPointImpl(u8, &[_]u8{ 0, 50, 14, 2, 5, 71 }, {}, S.isEven));
}

test partitionPoint {
    try testPartitionPointImpl(partitionPoint);
}

test partitionPointNew {
    try testPartitionPointImpl(partitionPointNew);
}

const allocator = std.heap.c_allocator;

const iterations_per_byte = 2048;
const warmup_iterations = 64;
const repeats = 16;
const num_benchmarks = 8;
const growth_factor = 300;
const max_bytes = 1 << 24;

comptime {
    std.debug.assert(iterations_per_byte % repeats == 0);
    std.debug.assert(warmup_iterations % repeats == 0);
}

// #20357
pub fn sched_setaffinity(pid: std.os.linux.pid_t, set: *const std.os.linux.cpu_set_t) !void {
    const size = @sizeOf(std.os.linux.cpu_set_t);
    const rc = std.os.linux.syscall3(.sched_setaffinity, @as(usize, @bitCast(@as(isize, pid))), size, @intFromPtr(set));

    switch (std.posix.errno(rc)) {
        .SUCCESS => return,
        else => |err| return std.posix.unexpectedErrno(err),
    }
}
const Tp = u32;

fn lower(context: Tp, item: Tp) bool {
    return item < context;
}

pub fn main() !void {
    // Pin the process to a single core (1)
    if (@import("builtin").os.tag == .linux) {
        const cpu0001: std.os.linux.cpu_set_t = [1]usize{0b0001} ++ ([_]usize{0} ** (16 - 1));
        try sched_setaffinity(0, &cpu0001);
    }

    var new_sum_logs: f64 = 0;
    var old_sum_logs: f64 = 0;
    var num_entries: f64 = 0;

    var buf: [1 << 10]u8 = undefined;

    for (0..8) |benchmark| {
        std.debug.print("progress: {}/{}        \r", .{ benchmark, num_benchmarks });
        const data_filename = try std.fmt.bufPrint(&buf, "data{}.txt", .{benchmark});
        var file = try std.fs.cwd().createFile(data_filename, .{});
        defer file.close();
        const stdout = file;

        var rng = std.Random.DefaultPrng.init(0);
        const rand = rng.random();

        var N: usize = 1;
        var buffer_array_list = std.ArrayList(Tp).init(allocator);
        defer buffer_array_list.deinit();

        const queries = try allocator.alloc(Tp, iterations_per_byte + warmup_iterations);
        defer allocator.free(queries);

        while (N < max_bytes) {
            defer N = (N * (growth_factor + 1) + growth_factor - 1) / growth_factor;

            buffer_array_list.clearRetainingCapacity();
            const buffer = try buffer_array_list.addManyAsSlice(N);

            // uniform over whole range
            // for (queries) |*e| e.* = rand.intRangeAtMost(Tp, 0, @intCast(N));

            // uniform over first 16
            // for (queries) |*e| e.* = rand.intRangeAtMost(Tp, 0, @intCast(@min(N, 16)));

            // first
            // for (queries) |*e| e.* = 0;

            // one past the end
            // for (queries) |*e| e.* = @intCast(N);

            // mix of first, one past the end, and uniform
            // for (queries) |*e| e.* = switch (rand.int(u2)) {
            //     0 => 0,
            //     1, 2 => rand.intRangeAtMost(Tp, 0, @intCast(N)),
            //     3 => @intCast(N),
            // };

            // mix of first, middle, and one past the end
            // for (queries) |*e| e.* = switch (rand.intRangeAtMost(u2, 0, 2)) {
            //     0 => 0,
            //     1 => @intCast(N / 2),
            //     2 => @intCast(N),
            //     else => unreachable,
            // };

            const upper_bound: u32 = if (benchmark == num_benchmarks - 1) @intCast(N) else @as(u32, 1) << @as(u5, @intCast(benchmark));
            for (queries) |*e| e.* = rand.intRangeLessThan(Tp, 0, @intCast(@min(N, upper_bound)));

            for (0..N) |i| buffer[i] = @intCast(i);
            // cant run cross platform benchmarks with this
            // clflush(Tp, buffer);

            var new_i: u32 = 0;
            var new_ns: usize = 0;
            while (new_i < iterations_per_byte + warmup_iterations) : (new_i += repeats) {
                const start = std.time.Instant.now() catch unreachable;

                for (0..repeats) |offs| {
                    std.mem.doNotOptimizeAway(partitionPointNew(
                        Tp,
                        buffer,
                        queries[new_i + offs],
                        lower,
                    ));
                }

                const end = std.time.Instant.now() catch unreachable;
                if (new_i > warmup_iterations) new_ns += end.since(start);
            }

            for (0..N) |i| buffer[i] = @intCast(i);
            // cant run cross platform benchmarks with this
            // clflush(Tp, buffer);

            var old_i: u32 = 0;
            var old_ns: usize = 0;
            while (old_i < iterations_per_byte + warmup_iterations) : (old_i += repeats) {
                const start = std.time.Instant.now() catch unreachable;

                for (0..repeats) |offs| {
                    std.mem.doNotOptimizeAway(partitionPoint(
                        Tp,
                        buffer,
                        queries[old_i + offs],
                        lower,
                    ));
                }

                const end = std.time.Instant.now() catch unreachable;
                if (old_i > warmup_iterations) old_ns += end.since(start);
            }

            const new_cycles_per_byte = @as(f64, @floatFromInt(new_ns)) / @as(f64, @floatFromInt(iterations_per_byte));
            const old_cycles_per_byte = @as(f64, @floatFromInt(old_ns)) / @as(f64, @floatFromInt(iterations_per_byte));

            new_sum_logs += @log(new_cycles_per_byte);
            old_sum_logs += @log(old_cycles_per_byte);
            num_entries += 1.0;

            try stdout.writer().print("{},{d:.4},{d:.4}\n", .{
                N * @sizeOf(Tp),
                new_cycles_per_byte,
                old_cycles_per_byte,
            });
        }
    }
    const new_geo_mean = @exp(new_sum_logs / num_entries);
    const old_geo_mean = @exp(old_sum_logs / num_entries);

    const time_reduction = (old_geo_mean - new_geo_mean) / old_geo_mean * 100;
    const speedup_percent = old_geo_mean / new_geo_mean * 100 - 100;

    std.debug.print("speedup: {d:.0}% (time reduced by average of {d:.0}%) (NOTE: *almost* meaningless metric, see graph)\n", .{ speedup_percent, time_reduction });
}

inline fn rdtsc() usize {
    var a: u32 = undefined;
    var b: u32 = undefined;
    asm volatile ("rdtscp"
        : [a] "={edx}" (a),
          [b] "={eax}" (b),
        :
        : "ecx"
    );
    return (@as(u64, a) << 32) | b;
}

inline fn clflush(comptime T: type, slice: []const T) void {
    for (0..slice.len / @sizeOf(T)) |chunk| {
        const offset = slice.ptr + (chunk * @sizeOf(T));
        asm volatile ("clflush %[ptr]"
            :
            : [ptr] "m" (offset),
            : "memory"
        );
    }
}
