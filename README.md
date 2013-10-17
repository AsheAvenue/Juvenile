Juvenile
========

A simple tool for managing database backups and making sandwiches. 

Features
--------

- Runs a dump of the specified database
- Tarballs the dump file
- Pushes the tarballed dump file to the specified S3 bucket
- Removes old backup from S3
- Can run across any number of databases and S3 buckets
- Can be scheduled via cron or other process scheduler to run regularly

Installation
------------

- Fork or clone this repo.
- Copy config.yml.example to config.yml and edit accordingly.
- Install the **aws-sdk** gem

Config
------

    apps:
      <app key>:
        db:
          type: <mysql or herokupg>
          host: <database host>
          database: <database name>
          username: <database user>
          password: <database password>
        s3:
          access_key_id: <AWS access key id>
          secret_access_key: <AWS secret access key>
          bucket: <S3 bucket to use>
          subdirectory: <a subdirectory in the bucket>
        number_of_days_to_keep: <7, for example>
        prefix: <"db_backup_", for example>
        
- Give each app a unique, single-word key
- Input the number of days of logs you want to keep. 7 is a nice number, for example. Juvenile will remove any of this app's database backups from S3 that are more than this number of days old.
- Add a prefix for the file name if you think it'll help you manage the file later.

Usage
-----

First off, Juvenile is intended to be used within a secured environment, for example within an AWS security group containing both the database and the server this is running on. Never expose your AWS keys publicly.

Single use:

    ruby juvenile.rb
    
Or run it via a cron job. This job, for example, will run every day at midnight:

    0 0 * * * /usr/bin/ruby <path to juvenile.rb>

Future plans
------------

- Finish Postgres support
- Email a specified address on upload failure

Credits + License
-----------------

&copy; 2013 Ashe Avenue. Created by Tim Boisvert and Rob Farrell

Juvenile is released under the MIT license
