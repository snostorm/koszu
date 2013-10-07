# Koszu

A programatic documentation generator (build your docs in code, not comments.)

## Why another documentation generator?

- **Cleaner**: We wanted to build out our API documentation in one place, without having
to mix in details of the usage within the codebase itself.

- **Readability**: Most libraries depend on writing your docs as inline comments,
  which means the loss of benefits such as syntax highlighting

- **Reusability**: Having the docs being build by code we could reference
  JSON schemas, response strings and more from the code itself to keep things
  in sync with the documentation over time.

## Todos

- Add more robust examples
- Include a grunt task
- Properly package and push to npm