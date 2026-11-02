# Ror Taskko Copilot Instructions

## Stack and architecture

- This is a Rails 8.1 application on Ruby 4.0.9 with PostgreSQL. The app is currently a scaffold: it has no domain models, feature routes, or feature tests. Add features through the normal Rails layers (`app/models`, `app/controllers`, `app/views`) and define their entry points in `config/routes.rb`.
- Frontend assets use Propshaft, Tailwind (`tailwindcss-rails`), and Hotwire. JavaScript is delivered with import maps: add package pins in `config/importmap.rb` and Stimulus controllers under `app/javascript/controllers`; do not introduce a Node build step.
- Development runs Rails and the Tailwind watcher together via `bin/dev` / `Procfile.dev`. The shared application layout loads the Propshaft stylesheet and import map tags.
- Production uses separate PostgreSQL databases for the primary app, Solid Cache, Solid Queue, and Solid Cable. Active Job uses Solid Queue and cache uses Solid Cache in production; recurring queue maintenance is configured in `config/recurring.yml`. Keep production multi-database configuration in `config/database.yml` consistent when changing persistence or background-job behavior.
- Production is containerized by `Dockerfile` and deployed with Kamal (`config/deploy.yml`). The web process runs the Solid Queue supervisor in Puma through `SOLID_QUEUE_IN_PUMA=true`; preserve that deployment assumption unless adding a dedicated job host.

## Commands

```sh
# Install dependencies and prepare PostgreSQL databases (without starting Foreman)
bin/setup --skip-server

# Start Rails plus the Tailwind watcher (default port 3000)
bin/dev

# Run all Rails tests
bin/rails test

# Run one test file, class, or line
bin/rails test test/models/example_test.rb
bin/rails test test/models/example_test.rb:12
bin/rails test test/models/example_test.rb -n test_example_name

# Run system tests
bin/rails test:system

# Lint Ruby
bin/rubocop

# Run the local CI sequence: setup, lint, security scans, tests, and seed replant
bin/ci
```

CI also runs `bin/brakeman --no-pager`, `bin/bundler-audit`, and `bin/importmap audit`. Ruby style inherits `rubocop-rails-omakase` through `.rubocop.yml`.

## Test conventions

- Tests use Minitest through `rails/test_help`, and `ActiveSupport::TestCase` runs in parallel using all available processors.
- All fixtures under `test/fixtures` are loaded for every `ActiveSupport::TestCase`. Place model/controller/integration tests in the corresponding existing `test/` subdirectory.
- The test environment is PostgreSQL (`ror_taskko_test` by default); prepare it with `bin/rails db:test:prepare` when needed.
