# Sparkler

Sparkler is a web application written in Ruby on Rails that collects system profile statistics from macOS apps using [Sparkle updater library](https://sparkle-project.org).

<a href="https://www.flickr.com/photos/lilcrabbygal/418166137" title="sparkler against night by Vanessa Pike-Russell, on Flickr"><img src="https://farm1.staticflickr.com/132/418166137_9c4d64dec4.jpg" width="360" alt="sparkler against night"></a>

[![Travis build status](https://travis-ci.org/mackuba/sparkler.svg)](https://travis-ci.org/mackuba/sparkler)

## What it does

Sparkle is a very popular library used by a significant percentage of (non-app-store) macOS apps, created by [Andy Matuschak](https://andymatuschak.org) and now maintained by [porneL](https://github.com/pornel). Apps use it to check if a newer version is available and present the familiar "A new version of X is available!" dialog to the users.

One of the features of Sparkle is that during the update check it can also [send anonymous system info](https://sparkle-project.org/documentation/system-profiling/) back to the author in the form of URL parameters like "?osVersion=10.13.0". The author can collect this data and then use the gathered statistics to determine e.g. if it's worth supporting Macs with older processors or older versions of macOS.

However, in order to collect these statistics and do something useful with them, you need to have a place to store and present them. Sparkler is meant to be that place: it's a web app that Mac app authors can set up on their servers to collect this kind of statistics from their own users.

To get an idea of how the statistics can look, check out the Sparkler pages for these apps:

- [CocoaPods app](http://usage.cocoapods.org/feeds/cocoapods_app/statistics)
- [Gitifier](http://sparkle.psionides.eu/feeds/gitifier/statistics)

Here's a small preview:

![](http://i.imgur.com/7BkXWZf.png)

## How it works

After you set up Sparkler on your server (yes, you need to have one) you use the admin panel to add a feed there. You need to give it a name and either a URL of a remote appcast file (e.g. a "raw" link to a GitHub resource) or a path to a file located on the same server.

Sparkler then acts as a proxy to the actual appcast file: if you make a request to e.g. http://your.server/feeds/feed-name, it will cache and serve you the feed XML file as if it was located there, but it will also save any parameters sent with the request to the database.

When you have that working, you need to release an update to your app that points it to http://your.server/feeds/feed-name instead of directly to the actual XML file. Once your users start updating to the new version, you should start seeing data on the statistics page (it might take a few days for the first data to appear, because the system profile info is only sent once a week at most).

## Requirements

To install Sparkler on your server, you need a few other things there first:

- Ruby 2.0 or newer
- an HTTP server (Nginx/Apache)
- a Ruby/Rails app server
- a MySQL database

If you already have these set up or you know how to install them, you can skip this section.

### Ruby

Any recent Linux distribution will usually include some version of Ruby by default. However, it's possible that it's an older version of Ruby - specifically, the 1.8.x versions are not supported by Rails anymore.

Check which version you have:

```
ruby -v
```

If you don't have any or if it's too old, you need to install a more recent version.

You could use a Ruby version manager like [RVM](https://rvm.io) or [ruby-build](https://github.com/sstephenson/ruby-build), but if you don't need to switch between multiple versions of Ruby, it's enough if you install just one version directly. If you use Ubuntu, the [Brightbox repository](https://www.brightbox.com/docs/ruby/ubuntu) provides well prepared and up to date Ruby packages for all recent versions that can be easily installed in common versions of Ubuntu. Follow the instructions there and install the latest Ruby version from the repository.

Also, make sure you have Bundler installed - it's a gem (library) used for installing all gems needed by an app:

```
gem install bundler
```

(you might need to add `sudo` depending on how you've installed Ruby).


### HTTP server

If you have a VPS or another kind of server, you almost certainly have this already, but in case you don't: I recommend Nginx which is more lightweight and easier to set up than Apache. You can install Nginx together with Passenger, the Ruby app server (see below) from the [Phusion repository](https://www.phusionpassenger.com/library/install/apt_repo/).

Remember to also open the HTTP(S) ports on your firewall.

### Ruby app server

There are several different competing Ruby app servers, but most of them require running additional server processes in the background that need to be separately monitored, restarted if they go down etc. The one that's easiest to set up and use (IMHO) is [Passenger by Phusion](https://www.phusionpassenger.com), which integrates with Apache or Nginx and uses the web server to launch itself automatically. Follow the [instructions on their website](https://www.phusionpassenger.com/library/install/nginx/) to set it up.

Once you have Nginx and Passenger installed, you'll need to add a server block to your Nginx config that looks something like this:

```
server {
  server_name sparkle.yourserver.com;

  passenger_enabled on;
  root /var/www/sparkler/current/public;

  access_log /var/log/nginx/sparkler-access.log;
  error_log /var/log/nginx/sparkler-error.log;
}
```

Other Ruby servers you might consider instead include e.g. Unicorn or Puma.

## Deploying the app

The recommended approach is to use Capistrano, which is a tool commonly used for deploying Rails apps. The advantages are that:

- you can play with the app on your own computer first to test it there
- you get automatic app versioning on the server, so you can roll back to a previous version easily
- the installation is more automated

### Running the app locally

If you want to try the app locally first, clone the repository to your machine:

```
git clone https://github.com/mackuba/sparkler.git
cd sparkler
```

Install the required Ruby gems:

```
bundle install
```

Create a database config file based on the template file:

```
cp config/database.yml.example config/database.yml
```

The default config uses `sparkler_development` database in development mode and a `root` user with no password. Edit the file if needed.

Create an empty database:

```
bin/rake db:create
```

Run the "migrations" that create a correct database schema:

```
bin/rake db:migrate
```

And then start the server at `localhost:3000`:

```
bin/rails server
```

### Deploying with Capistrano

Capistrano uses a few config files to tell it where and how to deploy the app. Since everyone will deploy it a bit differently, this repository only includes templates of those files that you need to copy and update to suit your needs. You can find them in `deploy/cap`, and you can make copies this way:

```
deploy/cap/install
```

Next, install the Capistrano gems:

```
bundle --gemfile Gemfile.deploy --binstubs deploy/bin
```

Then look at the `config/deploy.rb` and `config/deploy/production.rb` files. In the simplest case you'll only need to update the user and hostname in `config/deploy/production.rb`. The configs are prepared for a server that uses Passenger and doesn't use any Ruby version manager like RVM. If you use a Ruby version manager on the server or you use a different Ruby web server, you'll need to tweak the gems in `Gemfile.deploy` and the include lines in `Capfile`.

When you're ready, call this command to deploy:

```
deploy/bin/cap deploy
```

The first deploy should fail with a message "linked file ... does not exist", because you're missing some config files. It will only create the necessary directory structure for you in the specified location on the server:

- `releases` - this will contain subdirectories with several previous versions of the app
- `shared` - this will contain some shared data like installed gems, custom configs etc.
- there will also be a `current` directory later which will be a symlink to the latest release

After you run this, log in to your server, go to `/your-app-location/shared/config` and create two files there:

- `database.yml` based on the [config/database.yml.example](https://github.com/mackuba/sparkler/blob/master/config/database.yml.example) file from the Sparkler repo - fill it in with your chosen database name (under `production`), database user and password
- `secret_key_base.key` which needs to contain a long random string for encrypting cookie sessions - you can generate it by running `bin/rake secret` in the Sparkler directory on your machine

You also need to actually set up the user/password in your MySQL and create the specified database (you can use `bin/rake db:create`).

Once this is done, you can complete the deploy using the same command again:

```
deploy/bin/cap deploy
```

Repeat this any time you want to update Sparkler to a new version. This will deploy the latest version to a new subdirectory in `releases` and will change the `current` link to point to it.

### Installing the app directly on the server

If you prefer, you can clone the repository directly on the server:

```
git clone https://github.com/mackuba/sparkler.git
cd sparkler
```

Next, install the required gems (you don't need the ones used in development and for running tests):

```
bundle install --without development test
```

Then create the `database.yml` and `secret_key_base.key` files in the `config` directory as described in the previous section.

You'll also need to run this task to compile asset files like scripts and stylesheets (rerun this after every update too):

```
RAILS_ENV=production bin/rake assets:precompile
```


## Configuring and using Sparkler

When you first open your Sparkler site in a browser, you should see a "Feeds at [hostname]" page and a message that you've been logged in without a password. Go to the account page and set up a password. Then go back to the feeds page and add one or more feeds.

### Adding a feed

The options for each feed are:

- *title* - this is only displayed on the feed pages (visible only to you) and the statistics page
- *name* - this goes in the URL of the feed XML, e.g. `/feeds/gitifier` - take into account that if you already have an app version out that loads the feed from this URL, changing the name will break the updates for existing users unless you set up a redirect manually
- *location* - the location (local or remote) where the actual feed XML will be located

The appcast location can be one of two things:

- a URL to a remote file; for example, you can keep the appcast file in your repository and link Sparkler to the master version of the file, which will be updated when you change the file and push the changes to the repo (e.g. the Gitifier appcast is located [here](https://raw.githubusercontent.com/nschum/Gitifier/master/Sparkle/gitifier_appcast.xml))
- a path to a local file, like `/var/www/foobarapp/appcast.xml`; this is useful if you prefer to keep the appcast on the same server and update it e.g. through FTP

You can also configure access to the feed statistics page - you have three options:

- private statistics page - only you can access it
- public statistics page, but download counts are hidden - only you will see the "show absolute amounts" switches, everyone else will only see percentages
- completely public statistics page - everyone can see all the data you can see there

And finally, you can choose to make a feed inactive - this is almost like deleting it, except the data isn't actually deleted. This is because deleting a feed is a dangerous operation since you could accidentally lose years' worth of data, so it's better to just hide it from the view. If you're really sure that you want to completely delete a feed together with the data, do this manually in the database or in a Rails console (run `RAILS_ENV=production bin/rails console` in the `current` directory on the server).

### Updating the Info.plist

To collect the statistics, you need to update your app to make it load the appcast from the Sparkler server. Change the `SUFeedURL` key in your `Info.plist` to e.g. `http://your.server/feeds/foobar` (`/feed/foobar` also works as an alias to `/feeds/foobar`). Once you release the next update (and add it to the old appcast location!), the data should start coming in a few days at most depending on the amount of users you have.

If you haven't done that before, you also need to add the `SUEnableSystemProfiling` key with value `YES` to tell Sparkle that you want it to send the system info in the GET parameters if the user agrees (more info on [Sparkle wiki](https://github.com/sparkle-project/Sparkle/wiki/System-Profiling)). Alternatively, you can ask the user for permission using a custom dialog and then set `SUSendProfileInfo = YES` in the user defaults if they accept it (setting it without asking might be considered not nice...).

### Reusing an existing URL

If you have complete control over the current appcast location (i.e. it's on your server), you might be able to reuse the existing URL by simply adding a redirect rule to your HTTP server config. That way, you don't need to change anything in the app (apart from perhaps enabling sending profile info at all, see above).

For example, you could add something like this to Nginx config:

```
location /my/old/feed/location {
    return 301 $scheme://$host/sparkle/feed/foo;
}
```

### Releasing new updates

There's one caveat you need to remember about: the webapp caches the appcast file forever once it downloads it successfully - the feed would load much slower and less reliably for your users if it had to make requests to a remote server every time. However, this means that when you update the source appcast with a new entry, Sparkler will still serve the old version. 

To fix this, you need to remember to go to the feeds index page on your Sparkler site and press the "Reload data" link under the given feed:

![](http://i.imgur.com/wd8gL0j.png)

## Updating Sparkler

From time to time Rails releases updated versions that fix some security issues. I'll try to update Sparkler quickly when that happens, but in any case, I'd recommend that you follow [@rails](https://twitter.com/rails) on Twitter so that you don't miss that (or alternatively, you can subscribe to the [Rails Security mailing list](https://groups.google.com/forum/#!forum/rubyonrails-security)).

I don't expect to find many security issues in Sparkler itself since there isn't that much backend code here, but just in case you can check the project's GitHub page now and then :)

## Switching back to a direct link to appcast

If at any moment you decide not to use Sparkler anymore, you'll have to deal with the fact that users using older versions of your app will still make requests to the Sparkler URL to check for updates, so you have to keep that working. However, you can handle this by simply configuring your web server to redirect requests made to that URL to the new location, e.g.:

```
location /feed/foobar {
    return 301 http://real.server.com/appcast.xml;
}
```

## Credits & contributing

Copyright © 2016 [Kuba Suder](https://mackuba.eu). Licensed under [Very Simple Public License](https://github.com/mackuba/sparkler/blob/master/VSPL-LICENSE.txt) (a simplified version of the MIT license that fits in 3 lines).

If you have any ideas for new features, improvements and bug fixes, pull requests are very welcome. (Just make sure you follow the existing code formatting style since I have a bit of an OCD...)
