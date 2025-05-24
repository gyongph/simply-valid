# Installation
```bash
zig fetch --save git+https://github.com/gyongph/simply-valid.git
```

This Zig code defines a **schema validation library**. It allows you to create validation rules for common data types like strings, numbers, booleans, and arrays, and then apply these rules to structs to validate their fields.

## How to Use It

### 1. Define Your Data Structure and Schema

First, you usually define the structure of the data you expect and then a corresponding schema for it.

```zig
const std = @import("std");
// Assuming the provided code is in a file like "validator.zig"
const v = @import("validator.zig"); // Use the actual path

// Define the structure of your data (e.g., for a user)
const User = struct {
    name: ?[]const u8 = null,
    email: []const u8,
    age: ?u8 = null,
    isAdmin: bool = false,
    hobbies: ?[]const []const u8 = null,
};

// Define the schema for the User struct
const UserSchema = v.Schema(struct {
    name: v.String.min(2).max(50).nullable().errorMsg("Name must be 2-50 chars if provided."),
    email: v.String.min(5).errorMsg("A valid email is required."), // Non-nullable by default
    age: v.Numeric(u8).min(18).nullable().default(null).errorMsg("Age must be at least 18, if provided."),
    isAdmin: v.Bool.default(false), // Will default to false if input is null
    hobbies: v.Array.child_schema(v.String.min(1)).max(5).nullable(), // Optional list of up to 5 non-empty strings
});
```
### 2. Create Data and Validate/Parse It

Now, you can create instances of your `User` struct (or a similar anonymous struct) and use the `UserSchema` to validate or parse it.

```zig
pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Example 1: Valid data
    const validUserData = User {
        .name = "Alice Wonderland",
        .email = "alice@example.com",
        .age = 30,
        .hobbies = &.{ "reading", "coding" },
        // isAdmin will use default(false) from schema if we parse
    };

    var parsedUser = UserSchema.parseTo(User, validUserData) catch |err| {
        std.debug.print("Validation failed for validUserData: {any}\n", .{err});
        if (err == error.invalid_payload) {
            const errors = UserSchema.getFieldErrors();
            for (errors) |field_err| {
                std.debug.print(" - Field '{s}': {s}\n", .{ field_err.name, field_err.details });
            }
        }
        return;
    };
    std.debug.print("Parsed valid user: {any}\n\n", .{parsedUser});

    // Example 2: Invalid data
    const invalidUserData = struct {
        name: ?[]const u8 = "A", // Too short if provided based on schema
        email: ?[]const u8 = null, // Required by schema
        age: ?u8 = 16, // Too young
        isAdmin: ?bool = true,
        hobbies: ?[]const []const u8 = &.{ "a", "b", "c", "d", "e", "f" }, // Too many hobbies
    }{
        .name = "A",
        .email = null,
        .age = 16,
        .isAdmin = true,
        .hobbies = &.{ "a", "b", "c", "d", "e", "f" },
    };

    // Using parseTo with an inferred type might be cleaner if payload doesn't match User exactly
    const InferredUserType = UserSchema.infer();
    _ = UserSchema.parseTo(InferredUserType, invalidUserData) catch |err| {
        std.debug.print("Validation failed for invalidUserData: {any}\n", .{err});
        // Check for field-specific errors
        if (err == error.invalid_payload) {
            const errors = UserSchema.getFieldErrors();
            for (errors) |field_err| {
                std.debug.print(" - Field '{s}': {s}\n", .{ field_err.name, field_err.details });
            }
        }
        return;
    };
}
```

## Explanation of Chaining and Error Messages

- **Chaining:** `String.min(5).max(10).nullable()` first creates a String type that must be at least 5 chars, then modifies it to also be at most 10 chars, then modifies it to be nullable.

- **Error Messages:** `String.min(5).errorMsg("Too short!")` applies "Too short!" specifically to the min(5) rule. If you then add `.max(10).errorMsg("Too long!")`, that applies to the max rule. The `error_msg_for` field in StringArgs (and others) helps manage which rule the current errorMsg call applies to. The `.field_error_msg` is a general message for the field if no specific rule's message is hit.


