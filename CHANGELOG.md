# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- more efficient URL scanning, skipping non-html content. thanks to @apfeltee

## [0.6.0] - 2025-09-08

### Added
- updates to gemspec such as minimum ruby version
- markdown format changelog
- rebuilt test suite with Minitest
- mock memcached and redis-server for testing

### Fixed
- better handling of port numbers
- better handling of status codes

## [0.5.3] - 2018-04-23
* release simply to add missing CHANGES notes

## [0.5.2] - 2018-04-23
* fixed #2 thanks to @jeremyevans
* added Redis as cache wrapper thanks to @brigriffin

## [0.5.1] - 2016-09-04 v
* added the ability to stop a crawl

## [0.5.0] - 2016-05-13
* fixed #1 thanks to @eribertomota
* got it running on more recent versions of ruby
* cleaned up the docs a bit
* cleaned up the licensing and attribution

## 2009-05-21
* fixed an issue with robots.txt on ssl hosts
* fixed an issue with pulling robots.txt from disallowed hosts
* fixed a documentation error with ExpiredLinks
* Many thanks to Brian Campbell

## 2008-10-09
* fixed a situation with nested slashes in urls, thanks to Sander van der Vliet and John Buckley

## 2008-07-06
* Trap interrupts and shutdown gracefully
* Support for custom urls-to-crawl objects
* Example AmazonSQS urls-to-crawl support (next_urls_in_sqs.rb)

## 2007-11-09:
* Handle redirects that assume a base URL.

## 2007-11-08:
* Move spider_instance.rb, robot_rules.rb, and included_in_memcached.rb into
  spider subdirectory.

## 2007-11-02:
* Memcached support.

## 2007-10-31:
* Add `setup' and `teardown' handlers.
* Can set the headers for a HTTP request.
* Changed :any to :every .
* Changed the arguments to the :every, :success, :failure, and code handler.

## [0.2.1] - 2007-10-23:
* URLs without a page component but with a query component.
* HTTP Redirect.
* HTTPS.
* Version 0.2.1 .

## [0.2.0] - 2007-10-22:
* Use RSpec to ensure that it mostly works.
* Use WEBrick to create a small test server for additional testing.
* Completely re-do the API to prepare for future expansion.
* Add the ability to apply each URL to a series of custom allowed?-like
  matchers.
* BSD license.
* Version 0.2.0 .

## 2007-03-30:
* Clean up the documentation.

## [0.1.0] - 2007-03-28:
* Change the tail recursion to a `while' loop, to please Ruby.
* Documentation.
* Initial release: version 0.1.0 .
