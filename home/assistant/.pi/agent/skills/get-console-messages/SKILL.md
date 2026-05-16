---
name: get-console-messages
description: Navigates to a URL and returns the console messages (logs, warnings, errors). Use for debugging errors
---

## Usage

Run the browser script with a URL as an argument:

```bash
node scripts/get-console-messages.ts http://localhost:5173/
```

## Output Format

The script outputs the console messages as a JSON array.

## Error Handling

- Network errors will be caught and reported
- The browser will close automatically after execution
