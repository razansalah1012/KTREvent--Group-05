# User Registration Test Cases

---

## 1. Role Flow Testing

| Test Case | Input | Expected Result |
|----------|------|----------------|
| Valid registration | email@test.com, 123456 | User registered successfully |
| Empty fields | "", "" | Show validation error |
| Valid format | test@gmail.com | Accept input |

---

## 2. Error Testing

| Test Case | Input | Expected Result |
|----------|------|----------------|
| Invalid email | test.com | Show "Enter valid email" |
| Short password | 123 | Show password error |
| Empty submit | nothing | Validation blocked |

---

## 3. Edge Cases

| Test Case | Input | Expected Result |
|----------|------|----------------|
| Long email | verylongemail@test.com | System handles safely |
| Spaces only | "   " | Show validation error |
| Special characters | @@@### | Handled safely |