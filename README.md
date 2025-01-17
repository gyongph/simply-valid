# simply-valid
A zig simple validation. 
# Installation
```bash
zig fetch --save git+https://github.com/gyongph/simply-valid.git
```
# How to use
```zig
const SimplyValid = @import("simply-valid");
const String = SimplyValid.String;
const Numeric = SimplyValid.Numeric;
const Boolean = SimplyValid.Boolean;
const Array = SimplyValid.Array;

const ProfileSchema = SimplyValid.schema(struct {
    first_name: String
        .min(1, error.min_first_name)
        .max(25, error.max_first_name),
    middle_name: String
        .min(1, error.min_middle_nae)
        .max(25, error.max_middle_name)
        .optional(),
    last_name: String
        .min(1, error.min_last_name)
        .max(25, error.max_last_name),
    gender: String
        .min(4, error.min_gender)
        .default("others"),
    age: Numeric(u8).min(18, error.min_age),
    is_single: Boolean.default(true),
    contact_numbers: Array(String.min(11))
        .min(1, error.min_contact_number)
        .max(5, error.max_contact_number),
    fav_numbers: Array(
        Numeric(u5)
            .min(0, null)
            .max(10, error.max_fav_number),
    ).min(3, error.fav_number_min),
});

const profile = ProfileSchema.infer(){
    .first_name = "jhon",
    .last_name = "Doe",
    .age = 77,
    .is_single = false,
    .contact_numbers = &.{"631-112-7777"},
    .fav_numbers = &.{ 1, 2, 3 },
};

// allocator is use in array type field where the item type of that array has a default value
// allocator can be null if you just want to check the validity
const validified = try ProfileSchema.validate(profile, allocator);
```
