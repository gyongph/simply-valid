# Zig Schema Validation Framework

A lightweight, type-safe, composable schema validation system written in Zig. Supports validation of primitives, arrays, and structs with customizable constraints and defaults.

## 🚀 Features

- ✅ Required, Nullable, and Default field support
- 🧮 Type-safe validation for `String`, `Numeric`, `Bool`, and `Array`
- 🔁 Custom error messages
- 🛠 Compile-time validation of schema defaults
- 🔍 Schema inference with structural validation

## 📦 Example Usage

```zig
const User = struct {
    string_required: []const u8,
    numeric_required: u8,
    bool_required: bool,
    array_required: []const bool,
};

const UserSchema = Schema(
    struct {
        string_required: String,
        string_default: String.Default("default text"),
        string_nullable: String.Nullable(),

        numeric_required: Numeric(u8),
        numeric_default: Numeric(u8).Default(42),
        numeric_nullable: Numeric(u8).Nullable(),

        bool_required: Bool,
        bool_default: Bool.Default(true),
        bool_nullable: Bool.Nullable(),

        array_required: Array.ChildSchema(Bool),
        array_default: Array.ChildSchema(Bool).Default(&.{false, true}),
        array_nullable: Array.ChildSchema(Bool).Nullable(),
    }
);

UserSchema.checkInfer(User); // Ensures schema matches `User` struct
```

## 🧪 Running Tests

Tests are included for:

- Required field validation
- Default and nullable values
- Min/max constraints
- Custom error messages
- Schema inference

To run:

```bash
zig test main.zig
```

## 🧰 Schema Types

- `String`
- `Numeric(T)` – accepts any integer or float type
- `Bool`
- `Array.ChildSchema(Schema)`

### Methods

- `.Nullable()` – allows null
- `.Default(value)` – provides a default value
- `.Min(value)` / `.Max(value)` – min/max constraints
- `.ErrorMsg("text")` – custom error message

## 📄 License

MIT – do whatever you want, just don’t blame us if you misuse it.

---

**Note**: This project is experimental and a great fit for projects needing lightweight schema validation without pulling in full-featured libraries or reflection systems.
