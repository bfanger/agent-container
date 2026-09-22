---
description: Update dependencies
---

1. Check `pnpm-workspace.yaml` if there are `packages:` configured, if so run the pnpm commands in the following steps with the `-r` flag.

2. Run `pnpm upgrade --latest`

3. Use git to see all the diffs in all package.json files. If there where packages that had a fixed version number to a whole version number, for example: `"typescript": "6",` restore those entries in the package.json files and run `pnpm install`

4. If it's a SvelteKit project run `npx svelte-kit sync`

5. Run `pnpm audit` and if available run `pnpm run lint` and `pnpm run test`. Don't fix the reported issues, but give short report instead.
