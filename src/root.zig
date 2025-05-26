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
        pub fn FieldType(name: [:0]const u8) std.builtin.Type.StructField {
            return .{
                .name = name,
                .type = _type,
                .default_value_ptr = if (_default != null) if (_nullable) &_default else @ptrCast(&_default.?) else if (_null_default) @ptrCast(&_default) else null,
                .is_comptime = false,
                .alignment = 0,
            };
        }
        pub fn Max(v: u64) type {
            return _String(.{
                .max = v,
                .min = args.min,
                .default = args.default,
                .nullable = args.nullable,
                .null_default = args.null_default,
                .error_msg_for = .max,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .field_error_msg = args.field_error_msg,
            });
        }
        pub fn Min(v: u64) type {
            return _String(.{
                .max = args.max,
                .min = v,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = args.nullable,
                .error_msg_for = .min,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .field_error_msg = args.field_error_msg,
            });
        }
        pub fn Nullable() type {
            return _String(.{
                .max = args.max,
                .min = args.min,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = true,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .field_error_msg = args.field_error_msg,
            });
        }
        pub fn Default(v: ?[]const u8) type {
            return _String(.{
                .max = args.max,
                .min = args.min,
                .default = v,
                .nullable = if (v == null) true else args.nullable,
                .null_default = if (v == null) true else args.null_default,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .field_error_msg = args.field_error_msg,
            });
        }
        pub fn ErrorMsg(err_msg: []const u8) type {
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
        fn _parse(v: ?[]const u8, comptime check_only: bool) !if (check_only) void else _type {
            if (_nullable and v == null) return if (!check_only) v;
            if (v == null and _default != null) return if (!check_only) _default.?;
            if (!_nullable and v == null) {
                if (!@inComptime()) error_message = "required";
                return error.required;
            }
            const sure_val = v.?;
            const v_length = sure_val.len;
            if (_max != null and v_length > _max.?) {
                if (!@inComptime()) error_message = args.field_error_msg orelse _max_error_msg;
                return error.too_long;
            }
            if (_min != null and v_length < _min.?) {
                if (!@inComptime()) error_message = args.field_error_msg orelse _min_error_msg;
                return error.too_short;
            }
            // Field with default value can accept a null input and will always
            // output a string
            return if (!check_only) sure_val;
        }
        pub fn validate(v: ?[]const u8) !void {
            return _parse(v, true);
        }
        pub fn ParseStructField(v: ?[]const u8) !_type {
            return _parse(v, true);
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

        pub fn FieldType(name: [:0]const u8) std.builtin.Type.StructField {
            return .{
                .name = name,
                .type = _type,
                .default_value_ptr = if (_default != null) if (_nullable) &_default else @ptrCast(&_default.?) else if (_null_default) @ptrCast(&_default) else null,
                .is_comptime = false,
                .alignment = 0,
            };
        }

        pub fn Min(v: u64) type {
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

        pub fn Max(v: u64) type {
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

        pub fn Default(v: ?T) type {
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

        pub fn Nullable() type {
            return _Numeric(T, .{
                .max = args.max,
                .min = args.min,
                .default = args.default,
                .null_default = args.null_default,
                .nullable = true,
                .min_error_msg = args.min_error_msg,
                .max_error_msg = args.max_error_msg,
                .field_error_msg = args.field_error_msg,
            });
        }

        pub fn ErrorMsg(err_msg: []const u8) type {
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
            if (v == null and _default != null) return if (!check_only) _default.?;
            if (!_nullable and v == null) {
                error_message = "required";
                return error.required;
            }
            const val = v.?;
            if (_min != null and val < _min.?) {
                if (!@inComptime()) error_message = args.field_error_msg orelse _min_error_msg;
                return error.too_small;
            }
            if (_max != null and val > _max.?) {
                if (!@inComptime()) error_message = args.field_error_msg orelse _max_error_msg;
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
    field_error_msg: ?[]const u8 = null,
};

fn _Bool(args: _BoolArgs) type {
    return struct {
        pub var error_message: ?[]const u8 = null;
        pub const _nullable = args.nullable;
        pub const _default = args.default;
        pub const _null_default = args.null_default;
        pub const _type = if (_nullable) ?bool else bool;
        pub fn FieldType(name: [:0]const u8) std.builtin.Type.StructField {
            return .{
                .name = name,
                .type = _type,
                .default_value_ptr = if (_default != null) if (_nullable) &_default else @ptrCast(&_default.?) else if (_null_default) @ptrCast(&_default) else null,
                .is_comptime = false,
                .alignment = 0,
            };
        }
        pub fn Default(v: ?bool) type {
            return _Bool(.{
                .null_default = v == null,
                .default = v,
                .nullable = if (v == null) true else args.nullable,
            });
        }
        pub fn Nullable() type {
            return _Bool(.{
                .nullable = true,
                .default = args.default,
                .null_default = args.null_default,
            });
        }
        pub fn _parse(v: ?bool, comptime check_only: bool) !if (check_only) void else _type {
            if (_nullable and v == null) return if (!check_only) null;
            if (v == null and _default != null) return if (!check_only) _default.?;
            if (!_nullable and v == null) {
                if (!@inComptime()) error_message = args.field_error_msg orelse "required";
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
        const Inferred = Infer();
        fn Infer() type {
            var fields: [real_struct.fields.len]std.builtin.Type.StructField = undefined;
            inline for (real_struct.fields, 0..) |field, i| {
                fields[i] = field.type.FieldType(field.name);
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
        ///  Every field is **nullable** and all fields without default will have a `null` as a default.
        const InferredPartial = InferPartial();
        ///  Every field is **nullable** and all fields without default will have a `null` as a default.
        fn InferPartial() type {
            var fields: [real_struct.fields.len]std.builtin.Type.StructField = undefined;
            inline for (real_struct.fields, 0..) |field, i| {
                if (field.type._default == null and field.type._null_default == false) {
                    fields[i] = .{
                        .name = field.name,
                        .type = if (field.type._nullable) field.type._type else ?field.type._type,
                        .default_value_ptr = &field.type._default,
                        .is_comptime = false,
                        .alignment = 0,
                    };
                } else fields[i] = field.type.FieldType(field.name);
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
                if (@FieldType(s, field.name)._type != field.type) {
                    @compileLog(@FieldType(s, field.name)._type, field.type);
                    @compileError("Field type doesn't match: " ++ field.name);
                }
            }
        }
        pub fn parse(payload: anytype) !@TypeOf(payload) {
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
            inline for (real_struct.fields) |field| {
                field.type.validate(@field(payload, field.name)) catch {
                    field_errors[field_error_count] = .{
                        .name = field.name,
                        .details = field.type.error_message orelse "",
                    };
                    field_error_count += 1;
                };
            }
            if (field_error_count != 0) return error.invalid_payload;
        }
    };
}

test Schema {
    const User = struct {
        string_required: []const u8,
        string_default: []const u8,
        string_nullable: ?[]const u8,
        string_default_null: ?[]const u8,
        string_nullable_with_default: ?[]const u8,

        numeric_required: u8,
        numeric_default: u8,
        numeric_nullable: ?u8,
        numeric_default_null: ?u8,
        numeric_nullable_with_default: ?u8,

        bool_required: bool,
        bool_default: bool,
        bool_nullable: ?bool,
        bool_default_null: ?bool,
        bool_nullable_with_default: ?bool,

        array_required: []const bool,
        array_default: []const bool,
        array_nullable: ?[]const bool,
        array_default_null: ?[]const bool,
        array_nullable_with_default: ?[]const bool,
    };

    const UserSchema = Schema(
        struct {
            string_required: String,
            string_default: String.Default("new-test"),
            string_nullable: String.Nullable(),
            string_default_null: String.Default(null),
            string_nullable_with_default: String.Nullable().Default("test"),

            numeric_required: Numeric(u8),
            numeric_default: Numeric(u8).Default(19),
            numeric_nullable: Numeric(u8).Nullable(),
            numeric_default_null: Numeric(u8).Default(null),
            numeric_nullable_with_default: Numeric(u8).Nullable().Default(20),

            bool_required: Bool,
            bool_default: Bool.Default(false),
            bool_nullable: Bool.Nullable(),
            bool_default_null: Bool.Default(null),
            bool_nullable_with_default: Bool.Nullable().Default(true),

            array_required: Array.ChildSchema(Bool),
            array_default: Array.ChildSchema(Bool).Default(&.{false}),
            array_nullable: Array.ChildSchema(Bool).Nullable(),
            array_default_null: Array.ChildSchema(Bool).Default(null),
            array_nullable_with_default: Array.ChildSchema(Bool).Nullable().Default(&.{true}),
        },
    );

    UserSchema.checkInfer(User);

    // required fields
    {
        var it_fails = false;
        const user = UserSchema.InferredPartial{};

        UserSchema.validate(user) catch {
            it_fails = true;
            const errors = UserSchema.getFieldErrors();
            try t.expect(errors.len == 4);
            try t.expectEqualStrings("string_required", errors[0].name);
            try t.expectEqualStrings("required", errors[0].details);
            try t.expectEqualStrings("numeric_required", errors[1].name);
            try t.expectEqualStrings("required", errors[1].details);
            try t.expectEqualStrings("bool_required", errors[2].name);
            try t.expectEqualStrings("required", errors[2].details);
            try t.expectEqualStrings("array_required", errors[3].name);
            try t.expectEqualStrings("required", errors[3].details);
        };

        try t.expect(it_fails);
    }
    // defaults
    {
        const sample = UserSchema.Inferred{
            .string_required = "",
            .numeric_required = 1,
            .bool_required = false,
            .array_required = &.{},
            .string_nullable = null,
            .numeric_nullable = null,
            .bool_nullable = null,
            .array_nullable = null,
        };

        try t.expectEqualStrings("new-test", sample.string_default);
        try t.expectEqual(19, sample.numeric_default);
        try t.expectEqual(false, sample.bool_default);
        try t.expectEqualSlices(bool, &.{false}, sample.array_default);

        // nullable fields with default
        try t.expectEqualStrings("test", sample.string_nullable_with_default.?);
        try t.expectEqual(20, sample.numeric_nullable_with_default.?);
        try t.expectEqual(true, sample.bool_nullable_with_default.?);
        try t.expectEqual(&.{true}, sample.array_nullable_with_default.?);

        // Fields with a null default
        try t.expectEqual(null, sample.string_default_null);
        try t.expectEqual(null, sample.numeric_default_null);
        try t.expectEqual(null, sample.bool_default_null);
        try t.expectEqual(null, sample.array_default_null);
    }
}

test Numeric {
    // required
    {
        const age = Numeric(u8);
        try t.expectEqual(error.required, age.parse(null));
    }

    // min error msg
    {
        const age = Numeric(u8).Min(18);
        try t.expectEqual(error.too_small, age.parse(16));
        try t.expectEqualStrings("Value is less than minimum.", age.error_message.?);
    }

    // min custom error msg
    {
        const age = Numeric(u8).Min(4).ErrorMsg("Custom");
        try t.expectEqual(error.too_small, age.parse(1));
        try t.expectEqualStrings("Custom", age.error_message.?);
    }

    // max error msg
    {
        const age = Numeric(u8).Max(18);
        try t.expectEqual(error.too_large, age.parse(19));
        try t.expectEqualStrings("Value is greater than maximum.", age.error_message.?);
    }

    // max custom error msg
    {
        const age = Numeric(u8).Max(75).ErrorMsg("Too old");
        try t.expectEqual(error.too_large, age.parse(99));
        try t.expectEqualStrings("Too old", age.error_message.?);
    }

    // default value
    {
        const age = Numeric(u8).Default(19);
        try t.expectEqual(19, try age.parse(null));
    }

    // null default
    {
        const age = Numeric(u8).Min(1).Default(null);
        try t.expectEqual(null, try age.parse(null));
    }

    // nullable
    {
        const age = Numeric(u8).Min(1).Nullable();
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
        const name_schema = String.Min(4);
        try t.expectError(error.too_short, name_schema.parse("abc"));
        try t.expectEqualStrings("Length is less than minimum.", name_schema.error_message.?);
    }

    // min custom error msg
    {
        const name_schema = String.Min(4).ErrorMsg("Custom");
        try t.expectEqual(error.too_short, name_schema.parse("abc"));
        try t.expectEqualStrings("Custom", name_schema.error_message.?);
    }

    // max error msg
    {
        const name_schema = String.Max(4);
        try t.expectEqual(error.too_long, name_schema.parse("abcde"));
        try t.expectEqualStrings("Length is greater than maximum.", name_schema.error_message.?);
    }

    // max custom error msg
    {
        const name_schema = String.Max(4).ErrorMsg("Custom");
        try t.expectEqual(error.too_long, name_schema.parse("abcde"));
        try t.expectEqualStrings("Custom", name_schema.error_message.?);
    }

    // default value
    {
        const name_schema = String.Default("any text");
        try t.expectEqualStrings("any text", try name_schema.parse(null));
    }

    // null default
    {
        const name_schema = String.Min(1).Default(null);
        try t.expectEqual(null, try name_schema.parse(null));
    }

    // nullable
    {
        const name_schema = String.Min(1).Nullable();
        try t.expectEqual(null, try name_schema.parse(null));
        try t.expectEqual("Test", try name_schema.parse("Test"));
    }

    // nullable with default
    {
        const name_schema = String.Nullable().Default("MUST NOT BE");
        try t.expectEqual(null, try name_schema.parse(null));
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
        const is_married = Bool.Default(false);
        try t.expectEqual(false, is_married.parse(null));
    }

    // null default
    {
        const is_married = Bool.Default(null);
        try t.expectEqual(null, is_married.parse(null));
    }

    // nullable
    {
        const is_married = Bool.Nullable();
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
        pub fn FieldType(name: [:0]const u8) std.builtin.Type.StructField {
            return .{
                .name = name,
                .type = _type,
                .default_value_ptr = if (_default != null) if (_nullable) &_default else @ptrCast(&_default.?) else if (_null_default) @ptrCast(&_default) else null,
                .is_comptime = false,
                .alignment = 0,
            };
        }
        pub fn Max(v: u64) type {
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
        pub fn Min(v: u64) type {
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
        pub fn ErrorMsg(v: []const u8) type {
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
        pub fn Default(v: ?[]const T._type) type {
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
        pub fn Nullable() type {
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
            if (v == null and _default != null) return if (!check_only) _default.?;
            if (!_nullable and v == null) {
                if (!@inComptime()) error_message = "required";
                return error.required;
            }
            const sure_val = v.?;
            const v_length = sure_val.len;
            if (_max != null and v_length > _max.?) {
                if (!@inComptime()) error_message = _max_error_msg;
                return error.too_many_items;
            }
            if (_min != null and v_length < _min.?) {
                if (!@inComptime()) error_message = _min_error_msg;
                return error.too_few_items;
            }
            for (sure_val) |item| {
                try T.validate(item);
            }
            return if (!check_only) sure_val;
        }
        pub fn parse(v: ?[]const T._type) !_type {
            return _parse(v, false);
        }
        pub fn validate(v: ?[]const T._type) !void {
            return _parse(v, true);
        }
    };
}

pub const Array = struct {
    pub fn ChildSchema(T: type) type {
        return _Array(T, .{});
    }
};
test Array {
    // required
    {
        const colors = Array.ChildSchema(
            String.Min(1).ErrorMsg("min error").Default(null),
        );
        try t.expectEqual(error.required, colors.parse(null));
    }

    // min error msg
    {
        const colors = Array.ChildSchema(Numeric(u8)).Min(1);
        try t.expectEqual(error.too_few_items, colors.parse(&.{}));
        try t.expectEqualStrings("Too few items.", colors.error_message.?);
    }

    // min custom error msg
    {
        const numbers = Array.ChildSchema(Numeric(u8)).Min(4).ErrorMsg("Custom");
        try t.expectEqual(error.too_few_items, numbers.parse(&.{ 1, 2, 3 }));
        try t.expectEqualStrings("Custom", numbers.error_message.?);
    }

    // max error msg
    {
        const flags = Array.ChildSchema(Bool).Max(2);
        try t.expectEqual(error.too_many_items, flags.parse(&.{ false, true, true }));
        try t.expectEqualStrings("Too many items.", flags.error_message.?);
    }

    // max custom error msg
    {
        const flags = Array.ChildSchema(Bool.Nullable()).Max(2).ErrorMsg("Custom");
        try t.expectEqual(error.too_many_items, flags.parse(&.{ false, true, null }));
        try t.expectEqualStrings("Custom", flags.error_message.?);
    }

    // default value
    {
        const default_colors = &.{ "red", "blue", "green" };
        const primary_colors = Array.ChildSchema(String).Default(default_colors);
        try t.expectEqualSlices([]const u8, default_colors, try primary_colors.parse(null));
    }

    // null default
    {
        const cart_items = Array.ChildSchema(String).Default(null);
        try t.expectEqual(null, try cart_items.parse(null));
    }

    // nullable
    {
        const contacts = Array.ChildSchema(Numeric(u32)).Nullable();
        try t.expectEqual(null, try contacts.parse(null));
        const sample: []const u32 = &.{ 99991122, 11233312 };
        try t.expectEqual(sample, try contacts.parse(sample));
    }
}
