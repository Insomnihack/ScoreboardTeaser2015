# README #

### What is this repository for? ###

* Insomni'hack hipster haskell scoreboard

### How do I get set up? ###

* You need connection to postgresql database, application will create every table at first launch.
* Install haskell and use stackage cabal repository (that is a clean repo without buggy version dependencies) https://github.com/fpco/stackage/wiki/Preparing-your-system-to-use-Stackage
* Install necessary build tools: `cabal install alex happy yesod-bin`
* Install unknown stackage dependencies (RESPECT ORDER)
    * nonce https://hackage.haskell.org/package/nonce
        * Find download link, wget it and then `cabal install nonce-X.tar.gz`
    * yesod-auth-account https://hackage.haskell.org/package/yesod-auth-account
        * Find download link, wget it and then `cabal install yesod-auth-X.tar.gz`
* Go into your cloned directory and run `cabal install`

Under ubuntu if you get the following error you need to install libpq-dev `apt-get install libpq-dev`:
```
cabal: Error: some packages failed to install:
TeaserInso15-0.0.0 depends on postgresql-libpq-0.9.0.1 which failed to
install.
persistent-postgresql-2.1.0.1 depends on postgresql-libpq-0.9.0.1 which failed
to install.
postgresql-libpq-0.9.0.1 failed during the configure step. The exception was:
ExitFailure 1
postgresql-simple-0.4.7.0 depends on postgresql-libpq-0.9.0.1 which failed to
install.
```

During installation you could get this error :
```
ghc: out of memory (requested 1048576 bytes)
Failed to install persistent-postgresql-2.1.0.1
cabal: Error: some packages failed to install:
persistent-postgresql-2.1.0.1 failed during the building phase. The exception
was:
ExitFailure 1
```

This mean you don't have enough RAM to compile.

* Configuration
    * Create and edit config/settings.yml as follow
```
#!yaml

Default: &defaults
  host: "*4" # any IPv4 host
  port: 3000
  approot: ""
  staticHost: "http://<ip>:3000/static"
  cacheHost: "http://<ip>:3000/"
  copyright: "Teaser Insomni'hack 2015"
  defaultHostname: "http://<ip>:3000"
  TLS: False
  SESFrom: "insomnihack@scrt.ch"
  SESAccessKey: "AccessKey"
  SESSecretKey: "SecretKey"
  SESRegion: "eu-west-1"

Development:
  <<: *defaults

Testing:
  <<: *defaults

Staging:
  <<: *defaults

Production:
  <<: *defaults

```

* Create and edit config/postgresql.yml as follow

```
#!yaml

# NOTE: These settings can be overridden by environment variables as well, in
# particular:
#
#    PGHOST
#    PGPORT
#    PGUSER
#    PGPASS
#    PGDATABASE

Default: &defaults
  user: teaser_inso15
  password: passw0rd
  host: 127.0.0.1
  port: 5432
  database: teaser_inso15_db
  poolsize: 10

Development:
  <<: *defaults

Testing:
  <<: *defaults

Staging:
  <<: *defaults

Production:
  <<: *defaults

```

* Create and edit config/keter.yml as follow

```
#!yaml

user-edited: true
stanzas:

  # Your Yesod application.
  - type: webapp

    exec: ../dist/build/TeaserInso15/TeaserInso15

    # Command line options passed to your application.
    args:
      #- Testing
      - Production

    hosts:
      # You can specify one or more hostnames for your application to respond
      # to. The primary hostname will be used for generating your application
      # root.
      - inso2015-2124835692.eu-west-1.elb.amazonaws.com

# Use the following to automatically copy your bundle upon creation via `yesod
# keter`. Uses `scp` internally, so you can set it to a remote destination
#copy-to: ubuntu@ec2-54-171-54-232.eu-west-1.compute.amazonaws.com:/opt/keter/incoming

```

* From your cloned directory run `yesod devel`

It will compile and run your instance in dev mode (more verbosity), enjoy !