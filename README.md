# Zig Schema Validation Library Documentation (Inferred from Tests)

This document provides an overview of a Zig library for data schema definition, validation, and parsing, as inferred from its test suite. It allows defining schemas for strings, numerics, booleans, and arrays with various constraints.

---

## Core Concepts (Inferred from Tests)

The library enables the creation of validator "types" (e.g., `String`, `Numeric`, `Bool`, `Array`) which can be configured with rules like minimum/maximum length/value, default values, and nullability. These validator types are then typically used as fields within a `Schema`.

- **Validation and Parsing**: Methods like `.parse()` and `.validate()` are used to check data against these rules. `.parse()` typically returns the validated (and possibly transformed, e.g., defaulted) value or an error, while `.validate()` returns an error if invalid.
- **Error Handling**: When validation fails, specific errors (e.g., `error.required`, `error.string_min_len`, `error.too_small`) are returned. An `error_message` property on the validator instance often provides a human-readable string detailing the error.
- **Chaining Configuration**: Validator types are configured by chaining methods like `.Min()`, `.Max()`, `.Default()`, `.Nullable()`, and `.ErrorMsg()`.

---

## String Validation: `String`

Used for validating string inputs.

**Basic Usage:**
- A plain `String` validator expects a non-null string. If `null` is passed to `.parse()`, it results in `error.required`.

```zig
// From test String: required
const name_schema = String;
try t.expectEqual(error.required, name_schema.parse(null));
```

**Features Demonstrated in Tests:**

-   **`Min(length: u64)`**: Sets a minimum length.
    -   If the input string's length is less than `length`, `.parse()` returns `error.string_min_len`.
    -   The default `error_message` is "Length is less than minimum."
    -   Can be combined with `.ErrorMsg("Custom Message")` to override the default error message.
   ```zig 
    // From test String: min error msg
    const name_schema = String.Min(4);
    try t.expectError(error.string_min_len, name_schema.parse("abc"));
    try t.expectEqualStrings("Length is less than minimum.", name_schema.error_message.?);

    // From test String: min custom error msg
    const custom_msg_schema = String.Min(4).ErrorMsg("Custom");
    try t.expectEqual(error.string_min_len, custom_msg_schema.parse("abc"));
    try t.expectEqualStrings("Custom", custom_msg_schema.error_message.?);
   ``` 

-   **`Max(length: u64)`**: Sets a maximum length.
    -   If the input string's length is greater than `length`, `.parse()` returns `error.string_max_len`.
    -   The default `error_message` is "Length is greater than maximum."
    -   Can be combined with `.ErrorMsg("Custom Message")` to override.
   ```zig 
    // From test String: max error msg
    const name_schema = String.Max(4);
    try t.expectEqual(error.string_max_len, name_schema.parse("abcde"));
    try t.expectEqualStrings("Length is greater than maximum.", name_schema.error_message.?);
   ``` 

-   **`Default(value: []const u8)`**: Provides a default value if `null` is parsed.
   ```zig 
    // From test String: default value
    const name_schema = String.Default("any text");
    try t.expectEqualStrings("any text", try name_schema.parse(null));
   ``` 

-   **`Default(null)`**: Allows the string to be `null` by default if `null` is parsed. This also implies nullability for the field type.
   ```zig 
    // From test String: null default
    const name_schema = String.Min(1).Default(null); // .Min(1) still applies if a non-null value is given
    try t.expectEqual(null, try name_schema.parse(null));
   ``` 

-   **`Nullable()`**: Allows `null` as a valid value. `.parse(null)` will return `null`.
    - If `Nullable()` is used with `Default(value)`, `null` input to `parse` still results in `null`, not the default value. The default value would likely apply if the field was part of a larger structure that was missing the field entirely, rather than explicit `null`.
   ```zig 
    // From test String: nullable
    const name_schema = String.Min(1).Nullable();
    try t.expectEqual(null, try name_schema.parse(null));
    try t.expectEqual("Test", try name_schema.parse("Test"));

    // From test String: nullable with default
    const nullable_default_schema = String.Nullable().Default("MUST NOT BE");
    try t.expectEqual(null, try nullable_default_schema.parse(null)); // Null input results in null, default isn't used here.
   ``` 

---

## Numeric Validation: `Numeric(T: type)`

Used for validating numeric inputs of a given type `T` (e.g., `u8`, `i32`).

**Basic Usage:**
- `Numeric(T)` expects a non-null number of type `T`. If `null` is parsed, it results in `error.required`.

```zig
// From test Numeric: required
const age = Numeric(u8);
try t.expectEqual(error.required, age.parse(null));
```

**Features Demonstrated in Tests:**

-   **`Min(value: u64)`**: Sets a minimum allowed value.
    -   If the input number is less than `value`, `.parse()` returns `error.too_small`.
    -   The default `error_message` is "Value is less than minimum."
    -   Can be combined with `.ErrorMsg("Custom Message")`.
   ```zig 
    // From test Numeric: min error msg
    const age = Numeric(u8).Min(18);
    try t.expectEqual(error.too_small, age.parse(16));
    try t.expectEqualStrings("Value is less than minimum.", age.error_message.?);
   ``` 

-   **`Max(value: u64)`**: Sets a maximum allowed value.
    -   If the input number is greater than `value`, `.parse()` returns `error.too_large`.
    -   The default `error_message` is "Value is greater than maximum."
    -   Can be combined with `.ErrorMsg("Custom Message")`.
   ```zig 
    // From test Numeric: max error msg
    const age = Numeric(u8).Max(18);
    try t.expectEqual(error.too_large, age.parse(19));
    try t.expectEqualStrings("Value is greater than maximum.", age.error_message.?);
   ``` 

-   **`Default(value: T)`**: Provides a default value if `null` is parsed.
   ```zig 
    // From test Numeric: default value
    const age = Numeric(u8).Default(19);
    try t.expectEqual(19, try age.parse(null));
   ``` 

-   **`Default(null)`**: Allows the number to be `null` by default if `null` is parsed.
   ```zig 
    // From test Numeric: null default
    const age = Numeric(u8).Min(1).Default(null);
    try t.expectEqual(null, try age.parse(null));
   ``` 

-   **`Nullable()`**: Allows `null` as a valid value. `.parse(null)` will return `null`.
   ```zig 
    // From test Numeric: nullable
    const age = Numeric(u8).Min(1).Nullable();
    try t.expectEqual(null, try age.parse(null));
    try t.expectEqual(1, try age.parse(1));
   ``` 

---

## Boolean Validation: `Bool`

Used for validating boolean inputs.

**Basic Usage:**
- A plain `Bool` validator expects a non-null boolean. If `null` is passed to `.parse()`, it results in `error.required`.

```zig
// From test Bool: required
const is_married = Bool;
try t.expectEqual(error.required, is_married.parse(null));
```

**Features Demonstrated in Tests:**

-   **`Default(value: bool)`**: Provides a default value if `null` is parsed.
   ```zig 
    // From test Bool: default
    const is_married = Bool.Default(false);
    try t.expectEqual(false, try is_married.parse(null));
   ``` 

-   **`Default(null)`**: Allows the boolean to be `null` by default if `null` is parsed.
   ```zig 
    // From test Bool: null default
    const is_married = Bool.Default(null);
    try t.expectEqual(null, try is_married.parse(null));
   ``` 

-   **`Nullable()`**: Allows `null` as a valid value. `.parse(null)` will return `null`.
   ```zig 
    // From test Bool: nullable
    const is_married = Bool.Nullable();
    try t.expectEqual(null, try is_married.parse(null));
   ``` 

---

## Array Validation: `Array.ChildSchema(T: type)`

Used for validating arrays (slices) where `T` is the validator type for each element in the array.

**Basic Usage:**
- `Array.ChildSchema(ElementType)` expects a non-null array. If `null` is passed to `.parse()`, it results in `error.required`.
- The elements within the array are validated by `ElementType`.

```zig
// From test Array: required
const colors = Array.ChildSchema(
    String.Min(1).ErrorMsg("min error").Default(null), // Element schema
);
try t.expectEqual(error.required, colors.parse(null)); // Validating the array itself
```

**Features Demonstrated in Tests:**

-   **`Min(count: u64)`**: Sets a minimum number of items in the array.
    -   If the array has fewer items, `.parse()` returns `error.string_min_len` (Note: test uses this error, it might be a general "length violation" error).
    -   The default `error_message` is "Too few items."
    -   Can be combined with `.ErrorMsg("Custom Message")`.
   ```zig 
    // From test Array: min error msg
    const colors = Array.ChildSchema(Numeric(u8)).Min(1);
    try t.expectEqual(error.string_min_len, colors.parse(&.{})); // Empty array, expecting at least 1
    try t.expectEqualStrings("Too few items.", colors.error_message.?);
   ``` 

-   **`Max(count: u64)`**: Sets a maximum number of items in the array.
    -   If the array has more items, `.parse()` returns `error.string_max_len`.
    -   The default `error_message` is "Too many items."
    -   Can be combined with `.ErrorMsg("Custom Message")`.
   ```zig 
    // From test Array: max error msg
    const flags = Array.ChildSchema(Bool).Max(2);
    try t.expectEqual(error.string_max_len, flags.parse(&.{ false, true, true })); // 3 items, expecting at most 2
    try t.expectEqualStrings("Too many items.", flags.error_message.?);
   ``` 

-   **`Default(value: []const ElementType._type)`**: Provides a default array if `null` is parsed.
   ```zig 
    // From test Array: default value
    const default_colors = &.{ "red", "blue", "green" };
    const primary_colors = Array.ChildSchema(String).Default(default_colors);
    try t.expectEqualSlices([]const u8, default_colors, try primary_colors.parse(null));
   ``` 

-   **`Default(null)`**: Allows the array to be `null` by default if `null` is parsed.
   ```zig 
    // From test Array: null default
    const cart_items = Array.ChildSchema(String).Default(null);
    try t.expectEqual(null, try cart_items.parse(null));
   ``` 

-   **`Nullable()`**: Allows `null` as a valid value for the array itself. `.parse(null)` will return `null`.
   ```zig 
    // From test Array: nullable
    const contacts = Array.ChildSchema(Numeric(u32)).Nullable();
    try t.expectEqual(null, try contacts.parse(null));
    const sample: []const u32 = &.{ 99991122, 11233312 };
    try t.expectEqual(sample, try contacts.parse(sample));
   ``` 

-   **Element Validation**: Each element in the array is validated against the schema provided to `ChildSchema`. (e.g., `String.Min(1)` for string elements).

---

## Schema Definition and Validation: `Schema(S: type)`

Combines multiple validators into a single schema for a struct. `S` is a struct type where fields are validator instances (e.g., `String`, `Numeric(u8).Default(19)`).

**Defining a Schema:**
```zig
// From test Schema
const UserSchema = Schema(
    struct {
        string_required: String,
        string_default: String.Default("new-test"),
        string_nullable: String.Nullable(),
        string_default_null: String.Default(null),
        string_nullable_with_default: String.Nullable().Default("test"),

        numeric_required: Numeric(u8),
        numeric_default: Numeric(u8).Default(19),
        // ... and so on for bool and array types
    },
);
```

**Features Demonstrated in Tests:**

-   **`Inferred` Type**: The schema generates an `Inferred` type. Instances of this type will have default values applied as per the schema definition.
   ```zig 
    // From test Schema: defaults
    const sample = UserSchema.Inferred{
        .string_required = "", // Required fields must be provided
        .numeric_required = 1,
        .bool_required = false,
        .array_required = &.{},
        .string_nullable = null, // Nullable fields can be explicitly null
        // ... other nullable fields
    };

    try t.expectEqualStrings("new-test", sample.string_default); // Default applied
    try t.expectEqual(19, sample.numeric_default);             // Default applied
    try t.expectEqual(null, sample.string_default_null);       // Default(null) results in null
    try t.expectEqualStrings("test", sample.string_nullable_with_default.?); // Nullable with default
   ``` 

-   **`InferredPartial` Type**: The schema generates an `InferredPartial` type.
    -   When an empty `InferredPartial{}` is validated using `UserSchema.validate()`, fields that are "required" (i.e., defined without `.Nullable()` or a `.Default()`) will cause validation errors. This suggests `InferredPartial` might initialize such fields in a way (e.g. to `null`) that triggers "required" validation.
   ```zig 
    // From test Schema: required fields
    var it_fails = false;
    const user_payload = UserSchema.InferredPartial{}; // Represents a payload potentially missing fields

    UserSchema.validate(user_payload) catch {
        it_fails = true;
        const errors = UserSchema.getFieldErrors();
        // Test expects errors for: string_required, numeric_required, bool_required, array_required
        // e.g. try t.expectEqualStrings("string_required", errors[0].name);
        //      try t.expectEqualStrings("required", errors[0].details);
    };
    try t.expect(it_fails);
   ``` 

-   **`validate(payload: anytype)`**: Validates a given payload against the schema.
    -   If validation fails, it `catch`es an error (the specific error type for invalid payload isn't explicitly named in the snippet but leads to the `catch` block).
    -   `getFieldErrors()` can be called after a failed validation to get details.

-   **`getFieldErrors() []const FieldError`**: Returns a slice of `FieldError` structs.
    -   Each `FieldError` has a `.name` (string, name of the field) and `.details` (string, the specific error message like "required").

-   **`checkInfer(ExpectedType: type)`**: A compile-time check. It ensures that a manually defined struct `ExpectedType` matches the structure that `Schema` infers (likely based on non-nullable fields and fields with non-null defaults).
   ```zig 
    // From test Schema
    const User = struct { // A manually defined struct
        string_required: []const u8,
        string_default: []const u8 = "test", // Note: schema uses "new-test"
    };
    // UserSchema.checkInfer(User);
    // The test has UserSchema.checkInfer(User) commented out,
    // but its presence implies a compile-time structural check.
    // If active and User field 'string_default' type or name differs from schema's inferred non-nullable type,
    // or if 'string_required' differs, it would likely compile error.
    // The original code has this check, and it passes because the types match what `Infer` generates.
    // The default value "test" in `User` struct definition doesn't affect `checkInfer`'s comparison of types.
   ``` 

    *(Note: The example `User` struct in the test has `string_default: []const u8 = "test"`, while the `UserSchema` defines `string_default: String.Default("new-test")`. `checkInfer` seems to focus on the type compatibility for non-nullable fields and their names, not necessarily the default values themselves directly in this check, but rather the resulting type after defaults are considered for the schema's inferred structure.)*

    The `test Schema` has an explicit `UserSchema.checkInfer(User);` line which would be used to verify that the `User` struct is compatible with the schema's inferred type structure (likely `UserSchema.Inferred` or a variant of it focusing on the non-nullable aspects). The properties of `Inferred` (like default values) are then tested by instantiating `UserSchema.Inferred` and checking its fields.

---

This documentation is based on the observed behavior in the provided test blocks. The exact mechanisms and all capabilities might be more extensive.
