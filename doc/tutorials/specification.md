# How to Write a Specification in Elektra

## Overview

### Introduction

In this tutorial you will learn how to interactively use the `SpecElektra` specification language and `kdb` to write a configuration specification for an example application.

### What you should already know

- how to install Elektra
- basic Elektra commands and concepts (kdb get, kdb set, kdb ls)
- how to open and use a terminal

### What you’ll Learn

- how to create and mount a specification using `kdb`
- how to add keys with different types, defaults and examples to your specification and how to validate them
- the benefits of using `kdb` to generate a specification, instead of writing one by hand

### What you'll do

- use `kdb` to create and mount a specification for an example CRUD (Create, Read, Update, Delete) application
- define defaults, examples and checks for keys in the validation

## Example App Overview

For this tutorial you will write a specification for a simple CRUD backend application.
You need to configure a `port` and a `secure` property, that toggles SSL usage, for the REST server.
An `ip` and a SQL `dialect` for the database server the app
will connect to and finally a `date` where all the data will be saved to a backup.

So the application will need the following configuration options:

- a server port
- server secure
- a database ip
- a database dialect
- a backup date

## Getting Started

Make sure you have `Elektra` installed on your local machine:

```
kdb --version

KDB_VERSION: 0.9.6
SO_VERSION: 5
```

Otherwise refer to the [getting started guide](https://www.libelektra.org/getstarted/guide) to install it.

## Mounting the Specification

### Step 1: Mount a Specification File

First you need to mount a specification file, in this case `spec.ni` to the `spec:/` namespace.
You can define the path inside the `spec:/` namespace as `/sw/org/app/#0/current`, refer to
[the documentation](https://www.libelektra.org/tutorials/integration-of-your-c-application) to find out more about constructing the name.

You will also be using the profile `current`,
you can find out more about profiles in
[the documentation](https://www.libelektra.org/plugins/profile) aswell.

You also need the specify the plugin you will use for writing to the file in the correct format. In this case you can choose the `ni` plugin to write to the specification file.

```sh
sudo kdb mount `pwd`/spec.ni spec:/sw/org/app/\#0/current ni
```

Using the command below you can list the directory of the concrete file that is used by Elektra.

```sh
kdb file spec:/sw/org/app/\#0/current
```

### Step 2: Define a mountpoint

Next you can define, that this specification defines a specific mountpoint for a concrete application configuration.
So you can say the concrete configuraion should be written to `app.ni`.

```sh
kdb meta-set spec:/sw/org/app/\#0/current mountpoint app.ni
```

Your `spec.ni` file should now look something like this:

```sh
cat $(kdb file spec:/sw/org/app/\#0/current)

;Ni1
; Generated by the ni plugin using Elektra (see libelektra.org).

 =

[]
 meta:/mountpoint = app.ni
```

### Step 3: Do a specification mount

```sh
kdb spec-mount /sw/org/app/\#0/current ni
```

This specification mount makes sure that the paths where the concrete configuration should be, in this case `app.ni`, are ready to fulfill or specification, in this case `spec.ni`.

## Adding your first key to the specification

### Step 1: Adding the server port

The first key you will add to our specification will be the port of the server. You add it using the following command below.

```sh
kdb meta-set spec:/sw/org/app/\#0/current/server/port type short
```

What you also specified in the command above is the type of the configuration key. Elektra uses the [CORBA type system](https://www.libelektra.org/plugins/type)
and will check that keys conform to the type specified.

So after adding the initial key your specification should look something like this:

```
cat $(kdb file spec:/sw/org/app/\#0/current)


;Ni1
; Generated by the ni plugin using Elektra (see libelektra.org).

 =
server/port =

[]
 meta:/mountpoint = app.ni

[server/port]
 meta:/type = short
```

### Step 2: Adding more metadata

So with your first key added, you of course want to specify more information for the port. There surely is more information to a port than just the type.
What about a `default`, or what about an `example` for a usable port? Maybe a `description` what the port really is for?
Let's add that next!

```sh
kdb meta-set spec:/sw/org/app/\#0/current/server/port default 8080
kdb meta-set spec:/sw/org/app/\#0/current/server/port example 8080
kdb meta-set spec:/sw/org/app/\#0/current/server/port description "port of the REST server that runs the application"
```

Beautiful! Your specification is starting to look like something useful.
But wait! Shouldn't a port just use values between `1` and `65535`?

Of course Elektra also has a plugin for that. You can just use the [network](https://www.libelektra.org/plugins/network) checker plugin.

```sh
kdb meta-set spec:/sw/org/app/\#0/current/server/port check/port ''
```

Nice!
You just have to do one more thing when using a new plugin. Elektra needs to remount the spec to use the new plugin.
Use the command from before:

```sh
kdb spec-mount /sw/org/app/\#0/current ni
```

Your final specification after adding the port should now look something like this

```sh
cat $(kdb file spec:/sw/org/app/\#0/current)

;Ni1
; Generated by the ni plugin using Elektra (see libelektra.org).

 =
server/port =

[]
 meta:/mountpoint = app.ni

[server/port]
 meta:/check/port =
 meta:/type = short
 meta:/example = 8080
 meta:/description = port of the REST server that runs the application
 meta:/default = 8080
```

You can now try to read the value of the newly created configuration.
Since you did not set the value to anything yet, you will get the default value back.

```sh
kdb get /sw/org/app/\#0/current/server/port

#>8080
```

Try to set the port to `123456` now.

```sh
kdb set /sw/org/app/\#0/current/server/port 123456
# STDERR: Port 123456 on key /server/port was not within 0 - 65535
```

Did it work? I hope not. The validation plugin you specified will now correctly validate the port you enter and give you an error.

### Step 3: Adding boolean keys

Next up you will configure the `secure` property of our server. This boolean key will toggle if your server encrypts the communication via SSL.

So we will add the key and some metadata for it:

```sh
kdb meta-set spec:/sw/org/app/\#0/current/server/secure type boolean
kdb meta-set spec:/sw/org/app/\#0/current/server/secure default 1
kdb meta-set spec:/sw/org/app/\#0/current/server/secure example 0
kdb meta-set spec:/sw/org/app/\#0/current/server/secure description "true if the REST server uses SSL for communication"
```

By default the `type` plugin will normalize boolean values when setting them, before storing them.
This only works for the concrete config, so when setting the values for the spec you have to use the unnormalized values.
In the case it uses `1` for boolean `true` and `0` for boolean `false`.

You can read more about this in the documentation for the [type plugin](https://www.libelektra.org/plugins/type#normalization).

## Adding the database keys to the specification

### Step 1: Adding the database ip

Next up you will add a key for the database `ip` address. Like with the key before, you will add a `type`, `default`, `example` and a `description` so that the configuration will be easily usable.

Don't forget the most important rule of configurations: **Always add sensible defaults!**

Now let's try something different. What if you change the file manually? Will Elektra pick up on
the changes? And save you from writing **a lot** of `kdb` commands?

_of course_

So just open your file using good old `vim` and add the following lines to specify configuration for the `ip` address.

```sh
vim $(kdb file spec:/sw/org/app/\#0/current)

;Ni1
; Generated by the ni plugin using Elektra (see libelektra.org).

database/ip =
 =
server/port =
server/secure =

[database/ip]
 meta:/check/ipaddr =
 meta:/type = string
 meta:/example = 127.0.0.1
 meta:/description = ip address of the database server, that the application will connect to
 meta:/default = 127.0.0.1

[]
 meta:/mountpoint = app.ni

[server/port]
 meta:/check/port =
 meta:/type = short
 meta:/example = 8080
 meta:/description = port of the REST server that runs the application
 meta:/default = 8080

[server/secure]
 meta:/type = boolean
 meta:/example = 0
 meta:/description = true if the REST server uses SSL for communication
 meta:/default = 1
```

Alternatively you can of course use `kdb` again to set the configuration values that way. Here are the commands to do that.

```sh
kdb meta-set spec:/sw/org/app/\#0/current/database/ip type string
kdb meta-set spec:/sw/org/app/\#0/current/database/ip default 127.0.0.1
kdb meta-set spec:/sw/org/app/\#0/current/database/ip example 127.0.0.1
kdb meta-set spec:/sw/org/app/\#0/current/database/ip description "ip address of the database server, that the application will connect to"
kdb meta-set spec:/sw/org/app/\#0/current/database/ip check/ipaddr ''
```

### Step 2: Adding the database dialect

Next up you will add a key for the SQL `dialect` the database will use. Since there are only a few databases your application will support,
you can define the possible dialects via an [enum](https://www.libelektra.org/plugins/type#enums) type.
This allows us to prohibit all other possible dialects that are not SQL.

First you define the size of the `enum` type, and then you can add the different `enum` values.

```sh
kdb meta-set spec:/sw/org/app/\#0/current/database/dialect type enum
kdb meta-set spec:/sw/org/app/\#0/current/database/dialect check/enum "#4"
kdb meta-set spec:/sw/org/app/\#0/current/database/dialect check/enum/\#0 postgresql
kdb meta-set spec:/sw/org/app/\#0/current/database/dialect check/enum/\#1 mysql
kdb meta-set spec:/sw/org/app/\#0/current/database/dialect check/enum/\#2 mssql
kdb meta-set spec:/sw/org/app/\#0/current/database/dialect check/enum/\#3 mariadb
kdb meta-set spec:/sw/org/app/\#0/current/database/dialect check/enum/\#4 sqlite
```

Afterwards you define all the other parameters, just as before.

```sh
kdb meta-set spec:/sw/org/app/\#0/current/database/dialect default sqlite
kdb meta-set spec:/sw/org/app/\#0/current/database/dialect example mysql
kdb meta-set spec:/sw/org/app/\#0/current/database/dialect description "SQL dialect of the database server, that the application will connect to"
```

After this meta-setting bonanza your specification file should look something like this:

```sh
cat $(kdb file spec:/sw/org/app/\#0/current)

;Ni1
; Generated by the ni plugin using Elektra (see libelektra.org).

database/ip =
 =
server/port =
server/secure =
database/dialect =

[database/ip]
 meta:/check/ipaddr =
 meta:/type = string
 meta:/example = 127.0.0.1
 meta:/description = ip address of the database server, that the application will connect to
 meta:/default = 127.0.0.1

[]
 meta:/mountpoint = app.ni

[server/port]
 meta:/check/port =
 meta:/type = short
 meta:/example = 8080
 meta:/description = port of the REST server that runs the application
 meta:/default = 8080

[server/secure]
 meta:/type = boolean
 meta:/example = 0
 meta:/description = true if the REST server uses SSL for communication
 meta:/default = 1

[database/dialect]
 meta:/check/enum/#2 = mssql
 meta:/check/enum/\#0 = postgresql
 meta:/type = enum
 meta:/check/enum/#1 = mysql
 meta:/example = mysql
 meta:/description = SQL dialect of the database server, that the application will connect to
 meta:/check/enum/#4 = sqlite
 meta:/check/enum/#3 = mariadb
 meta:/default = sqlite
 meta:/check/enum = #4
```

## Adding the backup date

The last key you will add to our application is a `date` key for the annual backup and restart (this should probably not be annually in a real application).
Here you use the [check/date](https://www.libelektra.org/plugins/date) plugin with the `ISO8601` format.
You also specify a `check/date/format`. You can find all possible date formats on the [plugin page](https://www.libelektra.org/plugins/date).
For this you can use the following commands:

```sh
kdb meta-set spec:/sw/org/app/\#0/current/backup/date type string
kdb meta-set spec:/sw/org/app/\#0/current/backup/date check/date ISO8601
kdb meta-set spec:/sw/org/app/\#0/current/backup/date check/date/format "calendardate complete extended"
```

Then just add examples, defaults and description as always.

```sh
kdb meta-set spec:/sw/org/app/\#0/current/backup/date default 2021-11-01
kdb meta-set spec:/sw/org/app/\#0/current/backup/date example 2021-01-12
kdb meta-set spec:/sw/org/app/\#0/current/backup/date description "date of the annual server and database backup"
```

Your specification looks to be complete now! Make sure it look something like the one below and you are good to go using it and configuring the heck out of it!

```sh
cat $(kdb file spec:/sw/org/app/\#0/current)

;Ni1
; Generated by the ni plugin using Elektra (see libelektra.org).

backup/date =
database/ip =
 =
server/port =
server/secure =
database/dialect =

[backup/date]
 meta:/check/date/format = calendardate complete extended
 meta:/type = string
 meta:/example = 2021-01-12
 meta:/description = date of the annual server and database backup
 meta:/default = 2021-11-01
 meta:/check/date = ISO8601

[database/ip]
 meta:/check/ipaddr =
 meta:/type = string
 meta:/example = 127.0.0.1
 meta:/description = ip address of the database server, that the application will connect to
 meta:/default = 127.0.0.1

[]
 meta:/mountpoint = app.ni

[server/port]
 meta:/check/port =
 meta:/type = short
 meta:/example = 8080
 meta:/description = port of the REST server that runs the application
 meta:/default = 8080

[server/secure]
 meta:/type = boolean
 meta:/example = 0
 meta:/description = true if the REST server uses SSL for communication
 meta:/default = 1

[database/dialect]
 meta:/check/enum/#2 = mssql
 meta:/check/enum/\#0 = postgresql
 meta:/type = enum
 meta:/check/enum/#1 = mysql
 meta:/example = mysql
 meta:/description = SQL dialect of the database server, that the application will connect to
 meta:/check/enum/#4 = sqlite
 meta:/check/enum/#3 = mariadb
 meta:/default = sqlite
 meta:/check/enum = #4
```

## Final specification code

After adding all the keys that are necessary for our application to the server, your specification should look something like this:

```sh
cat $(kdb file spec:/sw/org/app/\#0/current)

;Ni1
; Generated by the ni plugin using Elektra (see libelektra.org).

backup/date =
database/ip =
 =
server/port =
server/secure =
database/dialect =

[backup/date]
 meta:/check/date/format = calendardate complete extended
 meta:/type = string
 meta:/example = 2021-01-12
 meta:/description = date of the annual server and database backup
 meta:/default = 2021-11-01
 meta:/check/date = ISO8601

[database/ip]
 meta:/check/ipaddr =
 meta:/type = string
 meta:/example = 127.0.0.1
 meta:/description = ip address of the database server, that the application will connect to
 meta:/default = 127.0.0.1

[]
 meta:/mountpoint = app.ni

[server/port]
 meta:/check/port =
 meta:/type = short
 meta:/example = 0
 meta:/description = port of the REST server that runs the application
 meta:/default = 1

[server/secure]
 meta:/type = boolean
 meta:/example = false
 meta:/description = true if the REST server uses SSL for communication
 meta:/default = false

[database/dialect]
 meta:/check/enum/#2 = mssql
 meta:/check/enum/\#0 = postgresql
 meta:/type = enum
 meta:/check/enum/#1 = mysql
 meta:/example = mysql
 meta:/description = SQL dialect of the database server, that the application will connect to
 meta:/check/enum/#4 = sqlite
 meta:/check/enum/#3 = mariadb
 meta:/default = sqlite
 meta:/check/enum = #4
```

## Summary

- You setup and mounted a specification using `kdb mount` and `kdb spec-mount`
- You added keys the specification using `kdb meta-set`
- You added different types of keys with `type string`, `type boolean` or `type short`
- You added keys with enum types, to get specific configuration values, with ``
- You added default parameters, examples and descriptions with `example`, `default`, `description`
- You also added validation checks using different plugins, like `check/port` or `check/ipaddr`

## Learn more

- [Tutorial Overview](https://www.libelektra.org/tutorials/readme)