### Version 1.2 (2017-08-08)

Important changes:

* updated Rails to version 5.1
* Ruby 2.2.2 or newer is required
* feed can be reloaded by calling an API endpoint, authenticating with an `X-Reload-Key` HTTP header (from [CocoaPods fork](https://github.com/CocoaPods/sparkler/pull/3))

Other changes:

- feed items that specify version using an alternate `<sparkle:version>` tag are properly parsed (https://github.com/mackuba/sparkler/issues/4)
- feed parser always finds the version with the highest version number, even if it's not the first item on the list (from [CocoaPods fork](https://github.com/CocoaPods/sparkler/pull/5))
- charts will now include a full range of months from the first to the last recorded data point, including months with no data (https://github.com/mackuba/sparkler/issues/3)
- renamed "OS X Version" chart to "macOS Version" and "Mac Model" to "Popular Mac Models"
- showing feed source URL on the index page
- larger fonts on the statistics page
- added signatures of some new Macs to the list
- updated all gem versions

---

### Version 1.1 (2016-05-28)

Important changes:

* Capistrano has been updated to 3.0 (which is backwards incompatible) and is now an optional component that needs to be installed separately - check the Capistrano section in the README and the files in `deploy/cap`
* Ruby 2.0 or newer is now required
* there are now unique indexes in the "options" and "properties" table - there is a possibility that a migration will fail if you have duplicate records, in that case you'll have to fix the issue manually

Other changes:

- updated gem versions
- added signatures of some new Macs to the list (for the "Mac Model" charts)

---

### Version 1.0.1 (2015-06-16)

- updated various gems because of security issues (Rails, Rack, Web Console, Sprockets)

---

### Version 1.0 (2015-05-07)

- initial release
