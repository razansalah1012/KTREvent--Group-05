# User Registration Test Cases

## Role Flow
- Valid email + password → Success
- Invalid email → Error shown
- Empty form → Blocked

## Error Cases
- Email missing @ → Invalid email error
- Password < 6 → Error message
- Empty fields → Required validation

## Edge Cases
- Very long email → handled
- Spaces only → rejected
- Special characters password → allowed if valid length