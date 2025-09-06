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

## AI Chat System & Knowledge Base Management

The AI chat system uses semantic search with embeddings to provide intelligent responses based on your content.

### System Architecture

- **Knowledge Base**: Blog posts and case studies stored as searchable items
- **Content Chunks**: Large content automatically split into focused chunks for precise retrieval
- **Embeddings**: Vector representations enable semantic search (understanding meaning, not just keywords)
- **Conversation Memory**: Chat history provides context for follow-up questions

### Automatic Updates (Daily via Heroku Scheduler)

**Current Heroku Scheduler Job**: Runs daily at 2:00 AM UTC

```bash
bundle exec rails knowledge:clear && bundle exec rails knowledge:import
```

**✅ ENHANCED**: Your Heroku Scheduler job now uses background processing:

```bash
bundle exec rails knowledge:clear && bundle exec rails knowledge:import
```

**What happens automatically:**

1. Fresh knowledge items are imported
2. **Background jobs** generate embeddings for new items (no blocking)
3. **Background jobs** create content chunks with embeddings
4. Chat responses improve as jobs complete

**Why this is better:**

- ⚡ Faster daily updates (no waiting for embedding generation)
- 🔄 Non-blocking processing (jobs run in parallel)
- 💪 Resilient (failed jobs retry automatically)
- 📊 Better resource usage (spreads load over time)

### Manual Knowledge Base Updates

**Full system refresh** (use when adding new content types):

```bash
# Production - Background jobs handle embeddings automatically
heroku run "bundle exec rails knowledge:clear && bundle exec rails knowledge:import"

# Development - Same automatic background processing
rails knowledge:clear && rails knowledge:import
```

**Quick content update** (for new posts only):

```bash
# Production - New posts get embeddings automatically
heroku run "bundle exec rails knowledge:import_posts"

# Development - Same automatic processing
rails knowledge:import_posts
```

**Force immediate processing** (if you need embeddings right away):

```bash
# Production - Only use if you can't wait for background jobs
heroku run "bundle exec rails embeddings:generate_all && bundle exec rails embeddings:generate_chunks"

# Development
rails embeddings:generate_all && rails embeddings:generate_chunks
```

### Available Rake Tasks

**Knowledge Base Management:**

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

**Embedding & Search Management:**

```bash
# Generate embeddings for all knowledge items (one-time setup)
rails embeddings:generate_all

# Generate content chunks with embeddings (one-time setup)
rails embeddings:generate_chunks

# Generate embeddings for chat messages (one-time setup)
rails embeddings:generate_chat_embeddings

# Test semantic search
rails 'embeddings:test_search[your query here]'

# Test chunk-based search
rails 'embeddings:test_chunk_search[your query here]'
```

### One-Time Setup (Already Done)

These were needed to set up the enhanced chat system but shouldn't need to be run again:

1. ✅ Generate embeddings for existing knowledge items
2. ✅ Create content chunks from existing items
3. ✅ Generate embeddings for existing chat messages
4. ✅ Set up vector indexes for fast similarity search

### Troubleshooting

**If chat responses seem outdated:**

```bash
heroku run "bundle exec rails knowledge:import && bundle exec rails embeddings:generate_all"
```

**If search results are poor:**

```bash
heroku run "bundle exec rails embeddings:generate_chunks"
```

**Check system health:**

```bash
heroku run "bundle exec rails knowledge:stats"
# Should show: Knowledge items, chunks, and embedding counts
```

### Setting Up Enhanced Heroku Scheduler

**Your existing job is now optimized**:

1. Open scheduler: `heroku addons:open scheduler`
2. Verify your daily job command is: `bundle exec rails knowledge:clear && bundle exec rails knowledge:import`
3. **That's it!** Background jobs now handle embeddings automatically

**What changed:**

- ✅ Faster daily updates (scheduler job completes quickly)
- ✅ Automatic embedding generation (happens in background)
- ✅ Automatic chunk creation (happens in background)
- ✅ Better error handling (jobs retry on failure)

**Monitor background jobs:**

```bash
# Check job status
heroku run "bundle exec rails runner 'puts Delayed::Job.count'"

# View recent jobs
heroku logs --tail | grep "GenerateEmbeddingsJob\|GenerateChunksJob"
```

This ensures your AI chat system stays current with semantic search capabilities while being more efficient and resilient.

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
