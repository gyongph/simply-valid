const std = @import("std");
const Validation = @This();
_schema: type,

pub fn schema(str: type) Validation {
    return .{
        ._schema = str,
    };
}

const FieldType = enum {
    string,
    numeric,
    array,
    boolean,
};

pub const String = struct {
    const tag: FieldType = .string;
    const _min: ?usize = null;
    const _max: ?usize = null;
    const _def: ?[]const u8 = null;
    const _opt: bool = false;
    const _min_err: ?anyerror = null;
    const _max_err: ?anyerror = null;
    pub fn min(size: usize, err: ?anyerror) type {
        return StringConfig(size, null, null, null, err, null);
    }
    pub fn max(size: usize, err: ?anyerror) type {
        return StringConfig(null, size, null, null, null, err);
    }
    pub fn default(def: []const u8) type {
        return StringConfig(null, null, null, def, null, null);
    }
    pub fn optional() type {
        return StringConfig(null, null, true, null, null, null);
    }
};

fn StringConfig(minimum: ?usize, maximum: ?usize, _optional: ?bool, _default: ?[]const u8, minimum_error: ?anyerror, maximum_error: ?anyerror) type {
    if (maximum != null and minimum != null and maximum.? < minimum.?) @compileError("Min can't be greater than max");
    return struct {
        const self = @This();
        const tag: FieldType = .string;
        const _min = minimum;
        const _max = maximum;
        const _def = _default;
        const _opt: bool = _optional orelse false;
        const _min_err: ?anyerror = minimum_error;
        const _max_err: ?anyerror = maximum_error;
        pub fn min(size: usize, err: ?anyerror) type {
            return StringConfig(size, self._max, self._opt, self._def, err, self._max_err);
        }
        pub fn max(size: usize, err: ?anyerror) type {
            return StringConfig(self._min, size, self._opt, self._def, self._min_err, err);
        }
        pub fn default(def: if (self._opt) ?[]const u8 else []const u8) type {
            return StringConfig(self._min, self._max, self._opt, def, self._min_err, self._max_err);
        }
        pub fn optional() type {
            return StringConfig(self._min, self._max, true, self._def, self._min_err, self._max_err);
        }
    };
}

pub fn Numeric(t: type) type {
    const base_type = if (@typeInfo(t) == .optional) std.meta.Child(t) else t;
    switch (@typeInfo(base_type)) {
        .comptime_int, .comptime_float, .int, .float => {},
        else => @compileError("It should be float or int type"),
    }
    return struct {
        const tag: FieldType = .numeric;
        const num_type = t;
        const _min: ?base_type = null;
        const _max: ?base_type = null;
        const _def: if (@typeInfo(t) == .optional) t else ?t = null;
        pub fn min(size: base_type, err: ?anyerror) type {
            return NumericConfig(t, size, null, null, err, null);
        }
        pub fn max(size: base_type, err: ?anyerror) type {
            return NumericConfig(t, null, size, null, null, err);
        }
        pub fn default(size: base_type) type {
            return NumericConfig(t, null, null, size, null, null);
        }
    };
}

fn NumericConfig(
    t: type,
    minimum: if (@typeInfo(t) == .optional) t else ?t,
    maximum: if (@typeInfo(t) == .optional) t else ?t,
    def: if (@typeInfo(t) == .optional) t else ?t,
    minimum_error: ?anyerror,
    maximum_error: ?anyerror,
) type {
    const base_type = if (@typeInfo(t) == .optional) std.meta.Child(t) else t;
    if (maximum != null and minimum != null and maximum.? < minimum.?) @compileError("Min can't be greater than max");
    if (maximum != null and def != null and maximum.? < def.?) @compileError("Default can't be greater than max");
    if (minimum != null and def != null and minimum.? > def.?) @compileError("Default can't be less than min");
    return struct {
        const self = @This();
        const num_type = t;
        const tag: FieldType = .numeric;
        const _min = minimum;
        const _min_error = minimum_error;
        const _max = maximum;
        const _max_error = maximum_error;
        const _def: if (@typeInfo(t) == .optional) t else ?t = def;
        pub fn min(size: base_type, err: ?anyerror) type {
            return NumericConfig(t, size, self._max, self._def, err, self._max_error);
        }
        pub fn max(size: base_type, err: ?anyerror) type {
            return NumericConfig(t, self._min, size, self._def, self._min_error, err);
        }
        pub fn default(size: base_type) type {
            return NumericConfig(t, self._min, self._max, size, self._min_error, self._max_error);
        }
    };
}

pub const Boolean = struct {
    const tag: FieldType = .boolean;
    const _def: ?bool = null;
    const _opt: bool = false;
    pub fn default(state: bool) type {
        return BooleanConfig(state, null);
    }
    pub fn optional() type {
        return BooleanConfig(null, true);
    }
};

fn BooleanConfig(def: ?bool, opt: ?bool) type {
    return struct {
        const self = @This();
        const tag: FieldType = .boolean;
        const _def: ?bool = def;
        const _opt: bool = opt orelse false;
        pub fn default(state: if (self._opt) ?bool else bool) type {
            return BooleanConfig(state, self._opt);
        }
        pub fn optional() type {
            return BooleanConfig(self._def, true);
        }
    };
}

pub fn Array(t: type) type {
    return struct {
        const self = @This();
        const tag = FieldType.array;
        const item = t;
        const _min = null;
        const _max = null;
        const _def: if (@typeInfo(t) == .optional) ?[]const parseFieldTypeConfig(std.meta.Child(t)).type else ?[]const parseFieldTypeConfig(t).type = null;
        pub fn default(def: if (@typeInfo(t) == .optional) []const parseFieldTypeConfig(std.meta.Child(t)).type else []const parseFieldTypeConfig(t).type) type {
            return ArrayConfig(t, null, null, def, null, null);
        }
        pub fn min(size: usize, err: ?anyerror) type {
            return ArrayConfig(t, size, null, null, err, null);
        }
        pub fn max(size: usize, err: ?anyerror) type {
            return ArrayConfig(t, null, size, null, null, err);
        }
    };
}

fn ArrayConfig(t: type, minimum: ?usize, maximum: ?usize, _default: if (@typeInfo(t) == .optional) ?[]const parseFieldTypeConfig(std.meta.Child(t)).type else ?[]const parseFieldTypeConfig(t).type, minimum_error: ?anyerror, maximum_error: ?anyerror) type {
    if (maximum != null and minimum != null and maximum.? < minimum.?) @compileError("Min can't be greater than max");
    if (_default != null and minimum != null and _default.?.len < minimum.?) @compileError("Default len is less than min");
    if (_default != null and maximum != null and _default.?.len > maximum.?) @compileError("Default len is greater than min");
    return struct {
        const self = @This();
        const tag = FieldType.array;
        const item = t;
        const _min = minimum;
        const _max = maximum;
        const _min_err = minimum_error;
        const _max_err = maximum_error;
        const _def: if (@typeInfo(t) == .optional) ?[]const parseFieldTypeConfig(std.meta.Child(t)).type else ?[]const parseFieldTypeConfig(t).type = _default orelse null;
        pub fn default(def: if (@typeInfo(t) == .optional) []const parseFieldTypeConfig(std.meta.Child(t)).type else []const parseFieldTypeConfig(t).type) type {
            return ArrayConfig(t, self._min, self._max, def, self._min_err, self._max_err);
        }
        pub fn min(size: usize, err: ?anyerror) type {
            return ArrayConfig(t, size, self._max, self._def, err, self._max_err);
        }
        pub fn max(size: usize, err: ?anyerror) type {
            return ArrayConfig(t, self._min, size, self._def, self._min_err, err);
        }
    };
}

fn parseFieldTypeConfig(f: type) struct {
    type: type,
    default_value: ?*const anyopaque,
} {
    return switch (f.tag) {
        .string => .{
            .type = if (f._opt) ?[]const u8 else []const u8,
            .default_value = if (f._opt) @as(?*const anyopaque, @ptrCast(&f._def)) else if (f._def != null) @as(?*const anyopaque, @ptrCast(&f._def.?)) else null,
        },
        .numeric => .{
            .type = f.num_type,
            .default_value = if (@typeInfo(f.num_type) == .optional) @as(?*const anyopaque, @ptrCast(&f._def)) else if (f._def != null) @as(?*const anyopaque, @ptrCast(&f._def.?)) else null,
        },
        .boolean => .{
            .type = if (f._opt) ?bool else bool,
            .default_value = if (f._opt) @as(?*const anyopaque, @ptrCast(&f._def)) else if (f._def != null) @as(?*const anyopaque, @ptrCast(&f._def.?)) else null,
        },
        .array => .{
            .type = if (@typeInfo(f.item) == .optional) ?[]const parseFieldTypeConfig(std.meta.Child(f.item)).type else []const parseFieldTypeConfig(f.item).type,
            .default_value = if (@typeInfo(f.item) == .optional) @as(?*const anyopaque, @ptrCast(&f._def)) else if (f._def != null) @as(?*const anyopaque, @ptrCast(&f._def.?)) else null,
        },
    };
}

pub fn infer(self: *const Validation) type {
    const st_fields = std.meta.fields(self._schema);
    var fields: [st_fields.len]std.builtin.Type.StructField = undefined;
    inline for (st_fields, 0..) |f, i| {
        const config = parseFieldTypeConfig(f.type);
        fields[i] = .{
            .name = f.name,
            .type = config.type,
            .default_value = config.default_value,
            .is_comptime = false,
            .alignment = 0,
        };
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
///! Provide an allocator if you have an item in array that you want to have a default value
pub fn validate(self: *const Validation, payload: self.infer(), allocator: ?std.mem.Allocator) anyerror!infer(self) {
    const fields = std.meta.fields(self._schema);
    var new: infer(self) = undefined;

    inline for (fields) |f| {
        const field_schema = f.type;
        const field_val = @field(payload, f.name);
        switch (f.type.tag) {
            .string => {
                if ((field_schema._min != null and field_val.len < field_schema._min.?)) {
                    return field_schema._min_err orelse error.invalid_payload;
                } else if ((field_schema._max != null and field_val.len > field_schema._max.?)) {
                    return field_schema._max_err orelse error.invalid_payload;
                }
                @field(new, f.name) = field_val;
            },
            .numeric => {
                if ((field_schema._min != null and field_val < field_schema._min.?)) {
                    return field_schema._max_err orelse error.invalid_payload;
                } else if ((field_schema._max != null and field_val > field_schema._max.?)) {
                    return field_schema._max_err orelse error.invalid_payload;
                }
                @field(new, f.name) = field_val;
            },
            .array => {
                if (@typeInfo(field_schema.item) == .optional) {
                    if (field_val != null) {
                        if ((field_schema._min != null and field_val.?.len < field_schema._min.?)) {
                            return field_schema._min_err orelse error.invalid_payload;
                        }
                        if ((field_schema._max != null and field_val.?.len > field_schema._max.?)) {
                            return field_schema._max_err orelse error.invalid_payload;
                        }
                        const item_schema = std.meta.Child(field_schema.item);
                        const new_items = try checkArrayItems(field_val.?, item_schema, allocator);
                        @field(new, f.name) = new_items orelse field_val;
                    }
                } else {
                    if ((field_schema._min != null and field_val.len < field_schema._min.?)) {
                        return field_schema._min_err orelse error.invalid_payload;
                    }
                    if ((field_schema._max != null and field_val.len > field_schema._max.?)) {
                        return field_schema._max_err orelse error.invalid_payload;
                    }
                    const item_schema = field_schema.item;
                    const new_items = try checkArrayItems(field_val, item_schema, allocator);
                    @field(new, f.name) = new_items orelse field_val;
                }
            },
            .boolean => @field(new, f.name) = field_val,
        }
    }
    return new;
}

fn checkArrayItems(items: anytype, item_schema: type, allocator: ?std.mem.Allocator) !?[]const parseFieldTypeConfig(item_schema).type {
    var new_items = if (allocator != null) std.ArrayList(parseFieldTypeConfig(item_schema).type).init(allocator.?) else null;
    defer {
        if (new_items != null) new_items.?.deinit();
    }
    switch (item_schema.tag) {
        .string => {
            if (items.len > 0) {
                for (items) |val| {
                    if (item_schema._min != null) {
                        if (item_schema._opt and val != null and val.?.len < item_schema._min.?) {
                            return item_schema._min_err orelse error.invalid_payload;
                        } else if (!item_schema._opt and val.len < item_schema._min.?) {
                            return item_schema._min_err orelse error.invalid_payload;
                        }
                    }
                    if (item_schema._max != null) {
                        if (item_schema._opt and val != null and val.?.len > item_schema._max.?) {
                            return error.invalid_payload;
                        } else if (!item_schema._opt and val.len > item_schema._max.?) {
                            return error.invalid_payload;
                        }
                    }
                    if (new_items != null) {
                        if (item_schema._opt and val == null and item_schema._def != null) {
                            try new_items.?.append(item_schema._def.?);
                        } else {
                            try new_items.?.append(val);
                        }
                    }
                }
            }
        },
        .numeric => {
            if (items.len > 0) {
                const num_type_info = @typeInfo(item_schema.num_type);
                for (items) |item| {
                    if (item_schema._min != null) {
                        if (num_type_info == .optional and item != null and item.? < item_schema._min.?) {
                            return error.invalid_payload;
                        } else if (num_type_info != .optional and item < item_schema._min.?) return error.invalid_payload;
                    }
                    if (item_schema._max != null) {
                        if (num_type_info == .optional and item != null and item.? > item_schema._max.?) {
                            return error.invalid_payload;
                        } else if (num_type_info != .optional and item > item_schema._max.?) return error.invalid_payload;
                    }

                    if (new_items != null) {
                        if (num_type_info == .optional and item == null and item_schema._def != null) {
                            try new_items.?.append(item_schema._def.?);
                        } else {
                            try new_items.?.append(item);
                        }
                    }
                }
            }
        },
        .boolean => {
            const num_type_info = @typeInfo(item_schema.num_type);
            for (items) |item| {
                if (new_items != null) {
                    if (num_type_info == .optional and item == null and item_schema._def != null) {
                        try new_items.?.append(item_schema._def.?);
                    } else {
                        try new_items.?.append(item);
                    }
                }
            }
        },
        else => {},
    }

    if (new_items != null) {
        return try new_items.?.toOwnedSlice();
    } else return null;
}

test String {
    { //check defaults
        const name_field = String;
        try std.testing.expect(name_field.tag == .string);
        try std.testing.expect(name_field._def == null);
        try std.testing.expect(name_field._min == null);
        try std.testing.expect(name_field._max == null);
        try std.testing.expect(name_field._opt == false);
    }

    { // modfication
        const field_min_max = String.min(1, null).max(10, null).default("asgard").optional();
        try std.testing.expect(field_min_max.tag == .string);
        try std.testing.expectEqualStrings(field_min_max._def.?, "asgard");
        try std.testing.expect(field_min_max._min.? == 1);
        try std.testing.expect(field_min_max._max.? == 10);
        try std.testing.expect(field_min_max._opt == true);
    }

    { // in struct with default value
        const sample_schema = schema(struct {
            name: String.min(1, null).max(5, null).default("test"),
        });
        const result = sample_schema.infer();
        const instance = result{};
        try std.testing.expect(@FieldType(result, "name") == []const u8);
        try std.testing.expectEqualStrings(instance.name, "test");
    }

    { // in struct with optional type
        const sample_schema = schema(struct {
            name: String.min(1, null).max(5, null).optional(),
        });
        const result = sample_schema.infer();
        const instance = result{};
        try std.testing.expect(@FieldType(result, "name") == ?[]const u8);
        try std.testing.expect(instance.name == null);
    }

    { // in struct with defined value
        const sample_schema = schema(struct {
            name: String.min(1, null).max(5, null).optional().default("test"),
        });
        const result = sample_schema.infer();
        const instance = result{ .name = "no-change" };
        try std.testing.expect(@FieldType(result, "name") == ?[]const u8);
        try std.testing.expectEqualStrings(instance.name.?, "no-change");
    }
}

test Numeric {
    { //check defaults
        const small_int = Numeric(u16);
        try std.testing.expect(small_int.tag == .numeric);
        try std.testing.expect(small_int.num_type == u16);
        try std.testing.expect(small_int._def == null);
        try std.testing.expect(small_int._min == null);
        try std.testing.expect(small_int._max == null);
    }
    { // modfication
        const small_int = Numeric(u16).min(1, null).max(10, null).default(8);
        try std.testing.expect(small_int.tag == .numeric);
        try std.testing.expect(small_int.num_type == u16);
        try std.testing.expect(small_int._def.? == 8);
        try std.testing.expect(small_int._min.? == 1);
        try std.testing.expect(small_int._max.? == 10);
    }
    { // in struct with default value
        const sample_schema = schema(struct {
            age: Numeric(u8).min(18, null).max(99, null).default(18),
        });
        const result = sample_schema.infer();
        const instance = result{};
        try std.testing.expect(@FieldType(result, "age") == u8);
        try std.testing.expect(instance.age == 18);
    }
    { // in struct with optional type
        const sample_schema = schema(struct {
            age: Numeric(?u8).min(18, null).max(99, null),
        });
        const result = sample_schema.infer();
        const instance = result{};
        try std.testing.expect(@FieldType(result, "age") == ?u8);
        try std.testing.expect(instance.age == null);
    }
    { // in struct with defined value
        const sample_schema = schema(struct {
            age: Numeric(u8).min(18, null).max(99, null).default(18),
        });
        const result = sample_schema.infer();
        const instance = result{
            .age = 55,
        };
        try std.testing.expect(@FieldType(result, "age") == u8);
        try std.testing.expect(instance.age == 55);
    }
}

test Boolean {
    { //check defaults
        const boolean = Boolean;
        try std.testing.expect(boolean.tag == .boolean);
        try std.testing.expect(boolean._def == null);
        try std.testing.expect(boolean._opt == false);
    }

    { // modfication
        const boolean = Boolean.default(false).optional();
        try std.testing.expect(boolean.tag == .boolean);
        try std.testing.expect(boolean._def.? == false);
        try std.testing.expect(boolean._opt == true);
    }
    { // in struct with default value
        const boolean = schema(struct {
            is_email_verified: Boolean.default(false),
        });
        const result = boolean.infer();
        const instance = result{};
        try std.testing.expect(@FieldType(result, "is_email_verified") == bool);
        try std.testing.expect(instance.is_email_verified == false);
    }
    { // in struct with optional type
        const sample_schema = schema(struct {
            is_email_verified: Boolean.optional(),
        });
        const result = sample_schema.infer();
        const instance = result{};
        try std.testing.expect(@FieldType(result, "is_email_verified") == ?bool);
        try std.testing.expect(instance.is_email_verified == null);
    }
}

test Array {
    { //check defaults
        const many_strings = Array(String);
        try std.testing.expect(many_strings.tag == .array);
        try std.testing.expect(many_strings._def == null);
        try std.testing.expect(many_strings._min == null);
        try std.testing.expect(many_strings._max == null);
        try std.testing.expect(many_strings.item == String);
    }
    { //check defaults
        const many_strings = Array(String).min(0, error.min_error).max(10, error.max_error).default(&.{"testing"});
        try std.testing.expect(many_strings.tag == .array);
        try std.testing.expect(many_strings._min.? == 0);
        try std.testing.expect(many_strings._max.? == 10);
        try std.testing.expect(many_strings.item == String);
        try std.testing.expectEqualSlices([]const u8, &.{"testing"}, many_strings._def.?);
    }
    { // in struct with default value
        const sample_schema = schema(struct {
            team: Array(String).default(&.{ "autobots", "decepticons", "machine" }),
        });
        const result = sample_schema.infer();
        const instance = result{};
        try std.testing.expect(@FieldType(result, "team") == []const []const u8);
        try std.testing.expectEqualSlices([]const u8, &.{ "autobots", "decepticons", "machine" }, instance.team);
    }
    { // in struct with default value
        const sample_schema = schema(struct {
            team: Array(?String),
        });
        const result = sample_schema.infer();
        const instance = result{};
        try std.testing.expect(@FieldType(result, "team") == ?[]const []const u8);
        try std.testing.expect(instance.team == null);
    }
}
