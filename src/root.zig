const std = @import("std");
const t = std.testing;
const t_alloc = t.allocator;
const StringArgs = struct {
    min: ?u64 = null,
    max: ?u64 = null,
    default: ?[]const u8 = null,
    null_default: bool = false,
    nullable: bool = false,
    error_msg_for: enum { field, min, max, required } = .field,
    min_error_msg: []const u8 = "Length is less than minimum.",
    max_error_msg: []const u8 = "Length is greater than maximum.",
    field_error_msg: ?[]const u8 = null,
};
fn _String(comptime args: StringArgs) type {
    return struct {
        pub var error_message: ?[]const u8 = null;
        pub const _min = args.min;
        pub const _max = args.max;
        pub const _min_error_msg: ?[]const u8 = args.min_error_msg;
        pub const _max_error_msg: ?[]const u8 = args.max_error_msg;
        pub const _null_default = args.null_default;
        pub const _default = args.default;
        pub const _nullable = args.nullable;
        pub const _type = if (_nullable) ?[]const u8 else []const u8;
        pub fn fieldType(name: [:0]const u8) std.builtin.Type.StructField {
            return .{
                .name = name,
                .type = _type,
                .default_value_ptr = if (_default != null) @ptrCast(&_default.?) else if (_null_default) @ptrCast(&_default) else null,
                .is_comptime = false,
                .alignment = 0,
            };
        }
        pub fn max(v: u64) type {
            return _String(.{
                .max = v,
                .min = args.min,
                .default = args.default,
                .nullable = args.nullable,
                .null_default = args.null_default,
                .error_msg_for = .max,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .field_error_msg = args.max_error_msg,
            });
        }
        pub fn min(v: u64) type {
            return _String(.{
                .max = args.max,
                .min = v,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = args.nullable,
                .error_msg_for = .min,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .field_error_msg = args.max_error_msg,
            });
        }
        pub fn nullable() type {
            return _String(.{
                .max = args.max,
                .min = args.min,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = true,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .field_error_msg = args.max_error_msg,
            });
        }
        pub fn default(v: ?[]const u8) type {
            return _String(.{
                .max = args.max,
                .min = args.min,
                .default = v,
                .nullable = if (v == null) true else args.nullable,
                .null_default = if (v == null) true else args.null_default,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .field_error_msg = args.max_error_msg,
            });
        }
        pub fn errorMsg(err_msg: []const u8) type {
            return _String(.{
                .max = args.max,
                .min_error_msg = if (args.error_msg_for == .min) err_msg else args.min_error_msg,
                .max_error_msg = if (args.error_msg_for == .max) err_msg else args.max_error_msg,
                .field_error_msg = if (args.error_msg_for == .field) err_msg else args.field_error_msg,
                .min = args.min,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = args.nullable,
                .error_msg_for = .field,
            });
        }
        pub fn validate(v: ?[]const u8) !void {
            return _parse(v, true);
        }
        fn _parse(v: ?[]const u8, comptime check_only: bool) !if (check_only) void else _type {
            if (_nullable and v == null) return if (!check_only) v;
            if (!_nullable and v == null and _default != null) return _default.?;
            if (!_nullable and v == null) {
                if (!@inComptime()) error_message = "required";
                return error.required;
            }
            const sure_val = v.?;
            const v_length = sure_val.len;
            if (_max != null and v_length > _max.?) {
                if (!@inComptime()) error_message = _max_error_msg;
                return error.string_max_len;
            }
            if (_min != null and v_length < _min.?) {
                if (!@inComptime()) error_message = _min_error_msg;
                return error.string_min_len;
            }
            // Field with default value can accept a null input and will always
            // output a string
            return if (!check_only) sure_val;
        }
        pub fn parse(v: ?[]const u8) !_type {
            return _parse(v, false);
        }
    };
}

pub const String = _String(.{});

fn NumericArgs(T: type) type {
    return struct {
        min: ?u64 = null,
        max: ?u64 = null,
        default: ?T = null,
        null_default: bool = false,
        nullable: bool = false,
        error_msg_for: enum { field, min, max, required } = .field,
        min_error_msg: []const u8 = "Value is less than minimum.",
        max_error_msg: []const u8 = "Value is greater than maximum.",
        field_error_msg: ?[]const u8 = null,
    };
}
fn _Numeric(comptime T: type, comptime args: NumericArgs(T)) type {
    return struct {
        pub var error_message: ?[]const u8 = null;
        pub const _min = args.min;
        pub const _max = args.max;
        pub const _default = args.default;
        pub const _nullable = args.nullable;
        pub const _null_default = args.null_default;
        pub const _min_error_msg: ?[]const u8 = args.min_error_msg;
        pub const _max_error_msg: ?[]const u8 = args.max_error_msg;
        pub const _type = if (_nullable) ?T else T;

        pub fn fieldType(name: [:0]const u8) std.builtin.Type.StructField {
            return .{
                .name = name,
                .type = _type,
                .default_value_ptr = if (_default != null) @ptrCast(&_default.?) else if (_null_default) &_default else null,
                .is_comptime = false,
                .alignment = 0,
            };
        }

        pub fn min(v: u64) type {
            return _Numeric(T, .{
                .min = v,
                .max = args.max,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = args.nullable,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .error_msg_for = .min,
                .field_error_msg = args.field_error_msg,
            });
        }

        pub fn max(v: u64) type {
            return _Numeric(T, .{
                .min = args.min,
                .max = v,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = args.nullable,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .error_msg_for = .max,
                .field_error_msg = args.field_error_msg,
            });
        }

        pub fn default(v: ?T) type {
            return _Numeric(T, .{
                .min = args.min,
                .max = args.max,
                .default = v,
                .null_default = if (v == null) true else args.null_default,
                .nullable = if (v == null) true else args.nullable,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .field_error_msg = args.field_error_msg,
            });
        }

        pub fn nullable() type {
            return _Numeric(T, .{
                .max = args.max,
                .min = args.min,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = true,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .field_error_msg = args.max_error_msg,
            });
        }

        pub fn errorMsg(err_msg: []const u8) type {
            return _Numeric(T, .{
                .min = args.min,
                .max = args.max,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = args.nullable,
                .min_error_msg = if (args.error_msg_for == .min) err_msg else args.min_error_msg,
                .max_error_msg = if (args.error_msg_for == .max) err_msg else args.max_error_msg,
                .field_error_msg = if (args.error_msg_for == .field) err_msg else args.field_error_msg,
                .error_msg_for = .field,
            });
        }

        pub fn _parse(v: ?T, comptime check_only: bool) !if (check_only) void else _type {
            if (_nullable and v == null) return if (!check_only) null;
            if (!_nullable and v == null and _default != null) return if (!check_only) _default.?;
            if (!_nullable and v == null) {
                error_message = "required";
                return error.required;
            }
            const val = v.?;
            if (_min != null and val < _min.?) {
                error_message = _min_error_msg;
                return error.too_small;
            }
            if (_max != null and val > _max.?) {
                error_message = _max_error_msg;
                return error.too_large;
            }
            return if (!check_only) val;
        }
        pub fn parse(v: ?T) !_type {
            return _parse(v, false);
        }
        pub fn validate(v: ?T) !void {
            return _parse(v, true);
        }
    };
}

pub fn Numeric(comptime T: type) type {
    return _Numeric(T, .{});
}

pub const _BoolArgs = struct {
    nullable: bool = false,
    default: ?bool = null,
    null_default: bool = false,
};

fn _Bool(args: _BoolArgs) type {
    return struct {
        pub var error_message: ?[]const u8 = null;
        pub const _nullable = args.nullable;
        pub const _default = args.default;
        pub const _null_default = args.null_default;
        pub const _type = if (_nullable) ?bool else bool;
        pub fn default(v: ?bool) type {
            return _Bool(.{
                .null_default = v == null,
                .default = v,
                .nullable = if (v == null) true else args.nullable,
            });
        }
        pub fn nullable() type {
            return _Bool(.{
                .nullable = true,
                .default = args.default,
                .null_default = args.null_default,
            });
        }
        pub fn _parse(v: ?bool, comptime check_only: bool) !if (check_only) void else _type {
            if (_default != null and v == null) return if (!check_only) _default.?;
            if (_nullable and v == null) return if (!check_only) null;
            if (!_nullable and v == null) {
                error_message = "required";
                return error.required;
            }
            return if (!check_only) v.?;
        }
        pub fn parse(v: ?bool) !_type {
            return _parse(v, false);
        }
        pub fn validate(v: ?bool) !void {
            return _parse(v, true);
        }
        pub fn isValid(v: ?bool) bool {
            validate(v) catch return false;
            return true;
        }
    };
}

pub const Bool = _Bool(.{});

pub fn Schema(s: type) type {
    const real_struct = comptime switch (@typeInfo(s)) {
        .@"struct" => |info| info,
        else => @compileError("Not a struct!"),
    };
    return struct {
        const FieldError = struct {
            name: [:0]const u8,
            details: []const u8,
        };
        var field_error_count: u64 = 0;
        var field_errors: [real_struct.fields.len]FieldError = undefined;
        pub fn infer() type {
            var fields: [real_struct.fields.len]std.builtin.Type.StructField = undefined;
            inline for (real_struct.fields, 0..) |field, i| {
                fields[i] = field.type.fieldType(field.name);
            }

            return @Type(.{
                .@"struct" = .{
                    .layout = .auto,
                    .fields = fields[0..],
                    .decls = &[_]std.builtin.Type.Declaration{},
                    .is_tuple = false,
                },
            });
        }
        pub fn inferPartial() type {
            var fields: [real_struct.fields.len]std.builtin.Type.StructField = undefined;
            inline for (real_struct.fields, 0..) |field, i| {
                if (field.type._default == null and field.type._null_default == false) {
                    const new_type = field.type.default(null);
                    fields[i] = new_type.fieldType(field.name);
                } else fields[i] = field.type.fieldType(field.name);
            }

            return @Type(.{
                .@"struct" = .{
                    .layout = .auto,
                    .fields = fields[0..],
                    .decls = &[_]std.builtin.Type.Declaration{},
                    .is_tuple = false,
                },
            });
        }
        pub fn getFieldErrors() []const FieldError {
            return field_errors[0..field_error_count];
        }
        pub fn checkInfer(expect: type) void {
            const s_struct = comptime switch (@typeInfo(expect)) {
                .@"struct" => |info| info,
                else => @compileError("Not a struct!"),
            };

            inline for (s_struct.fields) |field| {
                if (@FieldType(s, field.name)._type != field.type) @compileError("Field type doesn't match: " ++ field.name);
            }
        }
        pub fn parse(payload: anytype) !@TypeOf(payload) {
            checkInfer(@TypeOf(payload));
            var out: @TypeOf(payload) = undefined;
            inline for (real_struct.fields) |field| {
                const parsed = field.type.parse(@field(payload, field.name)) catch blk: {
                    field_errors[field_error_count] = .{
                        .name = field.name,
                        .details = field.type.error_message orelse "",
                    };
                    field_error_count += 1;
                    break :blk null;
                };
                if (field_error_count == 0) {
                    @field(out, field.name) = if (field.type._nullable) parsed else parsed.?;
                }
            }
            if (field_error_count != 0) return error.invalid_payload;
            return out;
        }
        pub fn parseTo(T: type, payload: anytype) !T {
            checkInfer(T);
            var out: T = undefined;
            inline for (real_struct.fields) |field| {
                const parsed = field.type.parse(@field(payload, field.name)) catch blk: {
                    field_errors[field_error_count] = .{
                        .name = field.name,
                        .details = field.type.error_message orelse "",
                    };
                    field_error_count += 1;
                    break :blk null;
                };
                if (field_error_count == 0) {
                    @field(out, field.name) = if (field.type._nullable) parsed else parsed.?;
                }
            }
            if (field_error_count != 0) return error.invalid_payload;
            return out;
        }
        pub fn validate(payload: anytype) !void {
            checkInfer(@TypeOf(payload));
            inline for (real_struct.fields) |field| {
                field.type.validate(@field(payload, field.name)) catch {
                    field_errors[field_error_count] = .{
                        .name = field.name,
                        .details = field.type.error_message orelse "",
                    };
                    field_error_count += 1;
                };
            }
        }
    };
}

test Schema {
    const User = struct {
        name: ?[]const u8 = null,
        gender: []const u8,
        age: ?u8 = null,
    };
    const UserSchema = Schema(struct {
        name: String.min(1).errorMsg("Did not met minimum length: Name").nullable(),
        gender: String,
        age: Numeric(u8).nullable(),
    });

    const user = User{
        .gender = "tupac",
        .age = 69,
    };

    try UserSchema.validate(user);
    const validated = UserSchema.parseTo(User, user) catch |err| {
        const msg = try std.json.stringifyAlloc(
            t_alloc,
            UserSchema.getFieldErrors(),
            .{},
        );
        defer t_alloc.free(msg);
        std.log.info("{s}", .{msg});
        return err;
    };
    std.log.info("{?s}\n{s} {?}", .{ validated.name, validated.gender, validated.age });
}

test Numeric {
    // required
    {
        const age = Numeric(u8);
        try t.expectEqual(error.required, age.parse(null));
    }

    // min error msg
    {
        const age = Numeric(u8).min(18);
        try t.expectEqual(error.too_small, age.parse(16));
        try t.expectEqualStrings("Value is less than minimum.", age.error_message.?);
    }

    // min custom error msg
    {
        const age = Numeric(u8).min(4).errorMsg("Custom");
        try t.expectEqual(error.too_small, age.parse(1));
        try t.expectEqualStrings("Custom", age.error_message.?);
    }

    // max error msg
    {
        const age = Numeric(u8).max(18);
        try t.expectEqual(error.too_large, age.parse(19));
        try t.expectEqualStrings("Value is greater than maximum.", age.error_message.?);
    }

    // max custom error msg
    {
        const age = Numeric(u8).max(75).errorMsg("Too old");
        try t.expectEqual(error.too_large, age.parse(99));
        try t.expectEqualStrings("Too old", age.error_message.?);
    }

    // default value
    {
        const age = Numeric(u8).default(19);
        try t.expectEqual(19, try age.parse(null));
    }

    // null default
    {
        const age = Numeric(u8).min(1).default(null);
        try t.expectEqual(null, try age.parse(null));
    }

    // nullable
    {
        const age = Numeric(u8).min(1).nullable();
        try t.expectEqual(null, try age.parse(null));
        try t.expectEqual(1, try age.parse(1));
    }
}

test String {
    // required
    {
        const name_schema = String;
        try t.expectEqual(error.required, name_schema.parse(null));
    }

    // min error msg
    {
        const name_schema = String.min(4);
        try t.expectEqual(error.string_min_len, name_schema.parse("abc"));
        try t.expectEqualStrings("Length is less than minimum.", name_schema.error_message.?);
    }

    // min custom error msg
    {
        const name_schema = String.min(4).errorMsg("Custom");
        try t.expectEqual(error.string_min_len, name_schema.parse("abc"));
        try t.expectEqualStrings("Custom", name_schema.error_message.?);
    }

    // max error msg
    {
        const name_schema = String.max(4);
        try t.expectEqual(error.string_max_len, name_schema.parse("abcde"));
        try t.expectEqualStrings("Length is greater than maximum.", name_schema.error_message.?);
    }

    // max custom error msg
    {
        const name_schema = String.max(4).errorMsg("Custom");
        try t.expectEqual(error.string_max_len, name_schema.parse("abcde"));
        try t.expectEqualStrings("Custom", name_schema.error_message.?);
    }

    // default value
    {
        const name_schema = String.default("any text");
        try t.expectEqualStrings("any text", try name_schema.parse(null));
    }

    // null default
    {
        const name_schema = String.min(1).default(null);
        try t.expectEqual(null, try name_schema.parse(null));
    }

    // nullable
    {
        const name_schema = String.min(1).nullable();
        try t.expectEqual(null, try name_schema.parse(null));
        try t.expectEqual("Test", try name_schema.parse("Test"));
    }
}

test Bool {
    // required
    {
        const is_married = Bool;
        try t.expectEqual(error.required, is_married.parse(null));
    }

    // default
    {
        const is_married = Bool.default(false);
        try t.expectEqual(false, is_married.parse(null));
    }

    // null default
    {
        const is_married = Bool.default(null);
        try t.expectEqual(null, is_married.parse(null));
    }

    // nullable
    {
        const is_married = Bool.nullable();
        try t.expectEqual(null, is_married.parse(null));
    }
}

fn ArrayArgs(T: type) type {
    return struct {
        child_schema: type = T,
        min: ?i64 = null,
        min_error_msg: ?[]const u8 = "Too few items.",
        max: ?i64 = null,
        max_error_msg: ?[]const u8 = "Too many items.",
        error_msg_for: enum { field, min, max, required } = .field,
        default: ?[]const T._type = null,
        null_default: bool = false,
        nullable: bool = false,
    };
}
fn _Array(T: type, args: ArrayArgs(T)) type {
    return struct {
        pub var error_message: ?[]const u8 = null;
        pub const _min = args.min;
        pub const _max = args.max;
        pub const _min_error_msg = args.min_error_msg;
        pub const _max_error_msg = args.max_error_msg;
        pub const _nullable = args.nullable;
        pub const _default = args.default;
        pub const _null_default = args.null_default;
        pub const _type = if (args.nullable) ?[]const T._type else []const T._type;
        pub fn max(v: u64) type {
            return _Array(T, .{
                .child_schema = args.child_schema,
                .min = args.min,
                .max = v,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = args.nullable,
                .error_msg_for = .max,
            });
        }
        pub fn min(v: u64) type {
            return _Array(T, .{
                .child_schema = args.child_schema,
                .min = v,
                .max = args.max,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = args.nullable,
                .error_msg_for = .min,
            });
        }
        pub fn errorMsg(v: []const u8) type {
            return _Array(T, .{
                .child_schema = args.child_schema,
                .min = args.min,
                .max = args.max,
                .min_error_msg = if (args.error_msg_for == .min) v else args.min_error_msg,
                .max_error_msg = if (args.error_msg_for == .max) v else args.max_error_msg,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = args.nullable,
            });
        }
        pub fn default(v: ?[]const T._type) type {
            if (v != null) {
                const items = v.?;
                inline for (items) |item| {
                    T.validate(item) catch @compileError("Found an invalid default value.");
                }
            }
            return _Array(T, .{
                .child_schema = args.child_schema,
                .min = args.min,
                .max = args.max,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .default = v,
                .null_default = v == null,
                .nullable = if (v == null) true else args.nullable,
            });
        }
        pub fn nullable() type {
            return _Array(T, .{
                .child_schema = args.child_schema,
                .min = args.min,
                .max = args.max,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = true,
            });
        }
        pub fn _parse(v: ?[]const T._type, comptime check_only: bool) !if (check_only) void else _type {
            if (_nullable and v == null) return if (!check_only) v;
            if (!_nullable and v == null and _default != null) return _default.?;
            if (!_nullable and v == null) {
                if (!@inComptime()) error_message = "required";
                return error.required;
            }
            const sure_val = v.?;
            const v_length = sure_val.len;
            if (_max != null and v_length > _max.?) {
                if (!@inComptime()) error_message = _max_error_msg;
                return error.string_max_len;
            }
            if (_min != null and v_length < _min.?) {
                if (!@inComptime()) error_message = _min_error_msg;
                return error.string_min_len;
            }
            for (sure_val) |item| {
                try T.validate(item);
            }
            return if (!check_only) sure_val;
        }
        pub fn parse(v: ?[]const T._type) !_type {
            return _parse(v, false);
        }
        pub fn validate(v: ?[]const T._type) !_type {
            return _parse(v, true);
        }
    };
}

pub fn Array(T: type) type {
    return _Array(T, .{});
}
test Array {
    // required
    {
        const colors = Array(
            String.min(1).errorMsg("min error").default(null),
        );
        try t.expectEqual(error.required, colors.parse(null));
    }

    // min error msg
    {
        const colors = Array(Numeric(u8)).min(1);
        try t.expectEqual(error.string_min_len, colors.parse(&.{}));
        try t.expectEqualStrings("Too few items.", colors.error_message.?);
    }

    // min custom error msg
    {
        const name_schema = String.min(4).errorMsg("Custom");
        try t.expectEqual(error.string_min_len, name_schema.parse("abc"));
        try t.expectEqualStrings("Custom", name_schema.error_message.?);
    }

    // max error msg
    {
        const name_schema = String.max(4);
        try t.expectEqual(error.string_max_len, name_schema.parse("abcde"));
        try t.expectEqualStrings("Length is greater than maximum.", name_schema.error_message.?);
    }

    // max custom error msg
    {
        const name_schema = String.max(4).errorMsg("Custom");
        try t.expectEqual(error.string_max_len, name_schema.parse("abcde"));
        try t.expectEqualStrings("Custom", name_schema.error_message.?);
    }

    // default value
    {
        const name_schema = String.default("any text");
        try t.expectEqualStrings("any text", try name_schema.parse(null));
    }

    // null default
    {
        const name_schema = String.min(1).default(null);
        try t.expectEqual(null, try name_schema.parse(null));
    }

    // nullable
    {
        const name_schema = String.min(1).nullable();
        try t.expectEqual(null, try name_schema.parse(null));
        try t.expectEqual("Test", try name_schema.parse("Test"));
    }
}
