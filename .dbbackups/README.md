# Database Backups

This directory contains local copies of production database backups for disaster recovery and development purposes.

## Files

- `latest.dump` - Most recent production backup (downloaded automatically)
- `production_backup_YYYYMMDD.dump` - Named backups by date
- `development_backup_YYYYMMDD_HHMMSS.sql` - Development database backups
- `development_backup_YYYYMMDD_HHMMSS.sql.gz` - Compressed development backups

## Usage

### Download Latest Backup

```bash
cd .dbbackups
heroku pg:backups:download --app jasonramirez
```

### Download Specific Backup

```bash
cd .dbbackups
heroku pg:backups:download b028 --app jasonramirez -o production_backup_20250912.dump
```

### Backup Local Development

```bash
# Create development backup (uncompressed)
pg_dump jasonramirez_development > .dbbackups/development_backup_$(date +%Y%m%d_%H%M%S).sql

# Create development backup (compressed)
pg_dump jasonramirez_development | gzip > .dbbackups/development_backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Restore to Local Development

```bash
# Drop and recreate local database
rails db:drop db:create

# Restore from production backup
pg_restore --verbose --clean --no-acl --no-owner -h localhost -U jasonramirez -d jasonramirez_development latest.dump

# Run any pending migrations
rails db:migrate

# Restore from development backup (uncompressed)
psql jasonramirez_development < .dbbackups/development_backup_YYYYMMDD_HHMMSS.sql

# Restore from development backup (compressed)
gunzip -c .dbbackups/development_backup_YYYYMMDD_HHMMSS.sql.gz | psql jasonramirez_development
```

### Restore to Production

```bash
heroku pg:backups:restore --app jasonramirez
```

## Backup Schedule

- **Automatic**: Heroku creates daily backups automatically
- **Manual**: Download important backups before major deployments
- **Retention**: Keep 3-5 recent backups locally

## Quick Restore Script

For convenience, you can create a quick restore script:

```bash
#!/bin/bash
# quick-restore.sh - Restore production data to development

echo "🔄 Restoring production data to development..."

# Create fresh backup
echo "📦 Creating fresh production backup..."
heroku pg:backups:capture --app jasonramirez

# Download backup
echo "⬇️  Downloading backup..."
heroku pg:backups:download --app jasonramirez

# Drop and recreate database
echo "🗑️  Dropping development database..."
rails db:drop db:create

# Restore data
echo "📥 Restoring production data..."
pg_restore --verbose --clean --no-acl --no-owner -h localhost -U jasonramirez -d jasonramirez_development latest.dump

# Run migrations
echo "🔄 Running migrations..."
rails db:migrate

echo "✅ Restore complete!"
```

## Security Note

These files contain production data and are excluded from git. Handle with care and never commit to version control.
