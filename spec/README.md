# Monorepo test harness

This directory is **not** where feature specs live. Each `decidim-restfull-*` gem owns its examples under `<gem>/spec/`.

| Path | Role |
|------|------|
| `spec_helper.rb` / `swagger_helper.rb` | Shared RSpec + RSwag setup for the dummy app |
| `decidim_dummy_app/` | Generated Decidim test application |
| `rest_full_swagger_spec_paths.rb` | Registers gem-local request spec globs for `bin/swaggerize` |

Run all gem specs from the repo root:

```bash
bundle exec rspec decidim-restfull-*/spec
```

Or use `./bin/check` (resolves paths via `Decidim::RestFull::Core::GemSpecPaths`).
