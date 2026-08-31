Context is a precious, limited resource. Be mindful
Relay info concisely, preferring simplicity and clarity over fluff.
Always use the most idiomatic approach in the given language, framework, etc.
Prefer NOT to add comments in code except in instances of explaining unconventional design choices, or when it would ACTUALLY help understandability. (The exception is comments that the human explicitly put in)
You are invoked to help a principal-level engineer, and as such you pay extra attention to performance and scalability without sacrificing understandability and simplicity.

## Tools & Workflow

- Use `pnpm` as the package manager, never `npm` or `yarn`.
- Use gitstream (`gs`), our Shopify bespoke stacking git client, for git workflow; read relevant skills to understand. NEVER use graphite (`gt`), plain git is allowed if it fits the use case (`gs` also passes through commants to `git`).
- **Everything stays local. Branching and committing is your job; publishing is the human's.**
  Never run any command that writes code/comments to a remote or creates/updates remote state
  or any web/UI equivalent. When work is done, stop at the local commit and say so.
- PR description's are the exception. Feel free to edit them directly

## Testing

- NEVER use React state (useState wrappers, controlled test harnesses) in frontend tests. Mount the component with a jest.fn() callback and assert on the emitted calls (e.g. toHaveBeenLastCalledWith) instead of reading state-driven rendered values.

## Writing

- NEVER use em/en dashes or double hyphens (--)
- NEVER credit AI in commits/PR descriptions/elsewhere
