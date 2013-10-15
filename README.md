Juvenile
========

A simple tool for managing database backups and making sandwiches.

Installation
------------

- Fork or clone this repo.
- Copy config.yml.example to config.yml and edit accordingly.

Usage
-----

First off, Juvenile is intended to be used within a secured environment, for example within an AWS security group containing both the database and the server this is running on. Never expose your AWS keys publicly.

Single use:

    ruby juvenile.rb
    
Or run it via a cron job. This job, for example, will run every day at midnight:

    * 0 * * * /usr/bin/ruby <path to juvenile.rb>

Credits + License
-----------------

&copy; 2013 Ashe Avenue. Created by Tim Boisvert and Rob Farrell

Juvenile is released under the MIT license
