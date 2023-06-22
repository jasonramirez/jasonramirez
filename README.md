# Jasonramirez

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

## Guidelines

Use the following guides for getting things done, programming well, and
programming in style.

-   [Protocol](http://github.com/thoughtbot/guides/blob/master/protocol)
-   [Best Practices](http://github.com/thoughtbot/guides/blob/master/best-practices)
-   [Style](http://github.com/thoughtbot/guides/blob/master/style)

# Creating Posts

## Hosting Images

We're using AWS S3 buckets to host images. Visit http://aws.amazon.com and login
with jason@jasonramirez.com credentials to upload images.

## Adding Images to a Post

Using markdown:

```
![image alt text](https://s3.amazonaws.com/jasonramirez/image.png)
```
