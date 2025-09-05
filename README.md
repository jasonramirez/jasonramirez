# Development

## Setup and Start

These scripts automate the most common development tasks.
Use them to quickly get your environment running or reset it when needed.

#### Set up your development environment

```
$ ./bin/setup
```

- Installs Ruby dependencies (bundler)
- Installs JavaScript dependencies (yarn)
- Prepares the database
- Clears old logs and temp files
- Optionally starts the development server

#### Start the development environment

```
$ bin/dev
```

- Runs the Rails server on port 3000
- Starts the DartSass CSS watcher for live CSS compilation
- Uses foreman to manage both processes simultaneously

## Maintainence

#### Removing Unused Images

```
$ rake image_cleaner:find_unused_images
```

- Scans your codebase for image references in views, CSS, and other files
- Identifies images in `app/assets/images/` that are no longer referenced anywhere
- Removes the unused image files from your assets directory
- **Note**: Run this carefully as it permanently deletes files

## Database Management

We use the [parity](https://github.com/thoughtbot/parity) gem for database
operations across environments. Parity provides simple commands for backing
up, restoring, and copying databases between development, staging, and
production.

### Environment Setup

- **Production**: `jasonramirez` (main Heroku app)
- **Staging**: `jasonramirez-staging` (staging Heroku app)
- **Development**: Local PostgreSQL database

### Common Parity Commands

```bash
# Database backups
./bin/parity production backup
./bin/parity staging backup

# Restore production data to development
./bin/parity development restore production
./bin/parity development restore staging

# Deploy to environments
./bin/parity production deploy
./bin/parity staging deploy

# Access consoles
./bin/parity production console
./bin/parity staging console

# View logs
./bin/parity production tail
./bin/parity staging tail

# Check dyno status
./bin/parity production ps
./bin/parity staging ps
```

### Database Restore Workflow

**Restore production data to development:**

```bash
# 1. Create a fresh backup of production
./bin/parity production backup

# 2. Restore to development
./bin/parity development restore production
```

**Deploy to staging:**

```bash
# 1. Deploy current branch to staging
./bin/parity staging deploy

# 2. Copy production data to staging (if needed)
./bin/parity staging restore production
```

### Copy Local Database to Production

**⚠️ Warning: This will overwrite your production database!**

Parity restore commands may fail due to system errors. Use the manual process below:

```bash
# 1. Create a backup of production first
heroku pg:backup --app jasonramirez

# 2. Create a dump of your local development database
pg_dump jasonramirez_development > latest.dump

# 3. Reset production database
heroku pg:reset DATABASE_URL --app jasonramirez --confirm jasonramirez

# 4. Restore your local data to production
DATABASE_URL=$(heroku config:get DATABASE_URL --app jasonramirez) && psql "$DATABASE_URL" < latest.dump

# 5. Run migrations (if needed)
heroku run rails db:migrate --app jasonramirez
```

**Alternative using Parity (if working):**

```bash
./bin/parity production restore development --force
```

**When to use this:**

- Setting up production with fresh data for testing
- Deploying a new feature that requires database changes
- Resetting production to match development state

**Before running:**

1. Ensure your local database is in the desired state
2. Make sure you have the latest production backup
3. Consider the impact on live users

## Knowledge Base Management

The AI chat system uses a knowledge base that's automatically updated from your published posts and case studies.

### How Knowledge Base Updates Work

**Automatic Updates**: The knowledge base is automatically updated daily via Heroku Scheduler.

1. **Heroku Scheduler** runs daily at 2:00 AM UTC
2. **Command**: `bundle exec rails knowledge:clear && bundle exec rails knowledge:import`
3. **Process**: Clears old knowledge items and imports fresh data from:
   - All published blog posts
   - Case studies from the works directory

### Manual Knowledge Base Updates

If you need to update the knowledge base immediately:

```bash
# Clear and reimport all knowledge
heroku run "bundle exec rails knowledge:clear && bundle exec rails knowledge:import"

# Or just import new posts (without clearing)
heroku run "bundle exec rails knowledge:import_posts"

# Check knowledge base stats
heroku run "bundle exec rails knowledge:stats"
```

### Knowledge Base Tasks

Available rake tasks for knowledge management:

```bash
# Import all posts and case studies
rails knowledge:import

# Import only posts
rails knowledge:import_posts

# Import only case studies
rails knowledge:import_case_studies

# Clear all knowledge items
rails knowledge:clear

# Show statistics
rails knowledge:stats
```

### Setting Up Heroku Scheduler

1. **Add the addon** (if not already added):

   ```bash
   heroku addons:create scheduler:standard
   ```

2. **Open the scheduler dashboard**:

   ```bash
   heroku addons:open scheduler
   ```

3. **Add a new job**:
   - **Command**: `bundle exec rails knowledge:clear && bundle exec rails knowledge:import`
   - **Frequency**: Daily
   - **Time**: 2:00 AM UTC (or your preferred time)

This ensures your AI chat always has access to your latest content without manual intervention.

## Deployment

### Updating Production

**Automatic Deployment**: When you push to the `main` branch, your site automatically deploys to production.

To deploy updates to production:

1. **Ensure your changes are committed and pushed to your main branch**

   ```bash
   git push origin main
   ```

   _Note: The automatic deployment will handle the rest!_

2. **If you need to manually deploy or run migrations:**

   ```bash
   git push heroku main
   heroku run rake db:migrate
   ```

# Production

## Tracking

### Google Analytics

We're using Google Analytics for tracking basic events like page views,
scrolling to the end of a page, etc.
Visit [Google Analytics](analytics.google.com) to
review this site's activity.

The tracking only happens on the production site where an environment
variable is present.

### Google Ads

We've connected our Google Analytics to Google Ads for improved tracking
of ads to conversions for actions like following.
Visit [Google Ads](ads.google.com) to review ads running and ad performance.
