# Typo (ROOL Edition)
## What is it?

Typo is a weblog system written in Ruby using Ruby on Rails. Weblogs are cool,
weblogs are "in" and everyone who writes code has an different opinion on how
a weblog should be written. Typo is our take on it. Typo is designed to be
usable by programmers and non-programmers, while being easy for programmers to
extend.

## Requirements

Currently you need all of those things to get typo to run:

 * Ruby 1.8.4 or higher
 * Rails 1.2.x
 * A database.  Typo supports MySQL, PostgreSQL, and SQLite.
 * Ruby drivers for your database.
 * For best performance, you should have a web server running either Apache or Lighttpd along with FastCGI, although these aren't strictly required--you can use Ruby's built-in web server for low-volume testing.

## Installation

See `doc/Installer.text` and `doc/typo-4.0-release-notes.txt`.

## Usage

Typo's administrative interface is available at http://your.domain.com/admin. You can use this to post articles and change Typo's configuration settings. For posting new content, you can either use this administrative web interface or a desktop blog editor like MarsEdit or Ecto. For a short list of clients which are confirmed to work please visit http://typosphere.org/trac/wiki/DesktopClients.

## Client setup

Set your desktop client to Movable Type API and enter http://your.domain.com/backend/xmlrpc as endpoint address.

## Tell me about your blog

Add yourself to the list of typo blogs at http://typosphere.org/trac/wiki/TypoPowered and subscribe to the typo mailing list.

Enjoy,
Your typo team
