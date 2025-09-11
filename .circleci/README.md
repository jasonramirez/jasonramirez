# CircleCI Configuration

This directory contains the CircleCI configuration for automated testing and deployment.

## Overview

The CI pipeline runs on every push to:

- `main` branch
- `develop` branch
- Any `feature/*` branches

## Pipeline Jobs

### 1. `checkout_and_install`

- Checks out code
- Installs Ruby dependencies (gems)
- Installs Node.js dependencies (yarn)
- Caches dependencies for faster subsequent builds

### 2. `setup_database`

- Sets up PostgreSQL with pgvector extension
- Loads database schema from `db/structure.sql`
- Adds migration version records
- Prepares test database for testing

### 3. `run_tests`

- Runs the full RSpec test suite in parallel (4 workers)
- Generates JUnit XML reports for CircleCI
- Stores test results and coverage reports
- Currently runs **429 tests** with **0 failures**

### 4. `lint_and_security`

- Runs bundler-audit for security vulnerability scanning
- Runs Brakeman security analysis (if installed)

## Key Features

- **Parallel testing**: Tests run across 4 parallel containers for speed
- **pgvector support**: Properly installs and configures pgvector extension
- **Comprehensive caching**: Dependencies cached to minimize build time
- **Test reporting**: JUnit XML format for proper CircleCI integration
- **Security scanning**: Automated vulnerability detection

## Database Setup

The pipeline uses a custom script (`bin/setup_test_db`) that:

1. Creates the test database
2. Enables pgvector extension
3. Loads schema from `structure.sql`
4. Adds migration version records
5. Sets Rails test environment

## Environment Variables

You may want to set these in CircleCI project settings:

- `CC_TEST_REPORTER_ID`: For CodeClimate test coverage reporting
- `RAILS_MASTER_KEY`: For encrypted credentials (if needed)

## Running Tests Locally

To run tests the same way CircleCI does:

```bash
# Install dependencies
bundle install
yarn install

# Setup test database
./bin/setup_test_db

# Run all tests
bundle exec rspec --format progress

# Run tests with JUnit formatting (like CircleCI)
bundle exec rspec --format RspecJunitFormatter --out test_results/rspec.xml
```

## Troubleshooting

**pgvector issues**: Make sure `postgresql-*-pgvector` is installed in your CI environment.

**Database permission errors**: The CI uses `circleci` user with trust authentication.

**Test failures**: Check that your local test database is properly set up with the same schema.

## Performance

- **Full test suite**: ~30 seconds
- **Parallel execution**: ~4x speed improvement
- **Dependency caching**: Saves ~2-3 minutes per build
