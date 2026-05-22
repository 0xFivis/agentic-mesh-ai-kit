# overrides/ — vendor-specific prompt differentiations

> Empty by default. Only add files here when a specific vendor (claude / cursor / copilot / codex) requires a divergent prompt that cannot be expressed via shared `review.md.tmpl`.

Each file must start with:
```
<!-- DERIVED from ../review.md.tmpl · only contains <vendor> diff -->
```

Naming convention: `<vendor>.md` (one per vendor maximum).
