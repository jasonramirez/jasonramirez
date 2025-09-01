# Jasonramirez

# Tracking

## Google Analytics

We're using Google Analytics for tracking basic events like page views,
scrolling to the end of a page, etc.
Visit [Google Analytics](analytics.google.com) to
review this site's activity.

The tracking only happens on the production site where an environment
variable is present.

## Google Ads

We've connected our Google Analytics to Google Ads for improved tracking
of ads to conversions for actions like following.
Visit [Google Ads](ads.google.com) to review ads running and ad performance.

# Development

## Getting Started

After you have cloned this repo, run this setup script to set up your machine
with the necessary dependencies to run and test this app:

    % ./bin/setup

It assumes you have a machine equipped with Ruby, Postgres, etc. If not, set up
your machine with [this script].

[this script]: https://github.com/thoughtbot/laptop

After setting up, you can run the application using [Heroku Local]:

    % rails s

## Removing Unused Images

I've built a rake task to delete any unused images. From the command line run:

```
$ rake image_cleaner:find_unused_images
```

It will remove the images. You can commit the change to finalize it.

## Database Management

Use the [parity](https://github.com/thoughtbot/parity) gem for database backups
and copies.

### Copy Local Database to Production

From the command line:

```
$ production restore-from development --force
```

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

3. **Verify the deployment:**
   ```bash
   heroku open
   ```

### Rollback (if needed)

If you need to rollback to a previous version:

```bash
heroku rollback
```

### Check Deployment Status

View recent deployments:

```bash
heroku releases
```

View current app status:

```bash
heroku ps
```

## Guidelines

Use the following guides for getting things done, programming well, and
programming in style.

- [Protocol](http://github.com/thoughtbot/guides/blob/master/protocol)
- [Best Practices](http://github.com/thoughtbot/guides/blob/master/best-practices)
- [Style](http://github.com/thoughtbot/guides/blob/master/style)

# Creating Posts

## Hosting Images

We're using AWS S3 buckets to host images. Visit http://aws.amazon.com and login
with jason@jasonramirez.com credentials to upload images.

## Adding Images to a Post

Using markdown:

```
![image alt text](https://s3.amazonaws.com/jasonramirez/image.png)
```
