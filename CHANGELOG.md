Version 1.1 (2016-05-28)

Important changes:

* Capistrano has been updated to 3.0 (which is backwards incompatible) and is now an optional component that needs to be installed separately - check the Capistrano section in the README and the files in `deploy/cap`
* Ruby 2.0 or newer is now required
* there are now unique indexes in the "options" and "properties" table - there is a possibility that a migration will fail if you have duplicate records, in that case you'll have to fix the issue manually

Other changes:

- updated gem versions
- added signatures of some new Macs to the list (for the "Mac Model" charts)

---

Version 1.0.1 (2015-06-16)

- updated various gems because of security issues (Rails, Rack, Web Console, Sprockets)

---

Version 1.0 (2015-05-07)

- initial release
