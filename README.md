# WeBWorK 3

[![GitHub Super-Linter](https://github.com/openwebwork/webwork3/workflows/Lint%20Code%20Base/badge.svg)
   ](https://github.com/openwebwork/webwork3/actions/workflows/linter.yml)
[![Unit Tests](https://github.com/openwebwork/webwork3/actions/workflows/unit-tests.yml/badge.svg)
   ](https://github.com/openwebwork/webwork3/actions/workflows/unit-tests.yml)
[![codecov](https://codecov.io/gh/openwebwork/webwork3/branch/main/graph/badge.svg?token=1XBWNRC9AB)
   ](https://codecov.io/gh/openwebwork/webwork3)
[![GitHub last commit](https://img.shields.io/github/last-commit/openwebwork/webwork3)
   ](https://github.com/openwebwork/webwork3/commits/main)

WeBWorK3 is the next generation of WeBWorK, an online open-source homework system.  This version is a complete rewrite
of the webwork2 system using more modern database, backend and UI frameworks, described below.

There are three main parts of this repository:

* webwork-db: basic functionality (database and other utils)
* webwork-mojo: mojolicious server backend to handle api requests.
* webwork-front-end: new webwork interface.

## webwork-db

This is code to handle a new database structure for webwork and
other utilities needed for non-gui webwork functionality.

See `docs/db.md` for more information on the database.

## webwork-mojo

We use [Mojolicious](http://mojolicious.org) to handle the webservices.  These include some basic webpages for
accessing, but more-importantly a CRUD api webservice for interacting at a service level to webwork.

## webwork-front-end

The front end/client side of webwork uses [quasar](http://quasar.dev), a highly flexible set of interactice web
components used with [VueJS](http://v3.vuejs.org).  The result is a Single Page Application (SPA) that runs extremely
fast in that most of the client-side code is loaded at the beginning and only small api webservice requests are made and
often handled in the background.

## Getting Started

The current version of this is for **DEVELOPMENT ONLY** and used as a proof of concept.  All of the instructions below
are assuming terminal/shell commands.

### Getting the webwork3 code

1. Clone the webwork3 code with `git clone https://github.com/openwebwork/webwork3.git`
2. Change directory to the webwork3 directory: `cd webwork3`
3. Copy conf/webwork3.yml.dist to conf/webwork3.yml and modify it appropriately if needed.

### Download Quasar

1. Make sure that `node` and `npm` are installed.
2. Install the Quasar cli using: `npm install -g @quasar/cli`

### Getting Mojolicious and other needed packages

1. Make sure that you have perl (at least version 5.20) installed.
2. Install `cpanm` from perl and install Mojolicious with `cpanm Mojolicious`.
   A one-liner install is available at [the Mojolicious homepage](https://mojolicious.org/).
3. Start mojolicious (from the `webwork3` directory) with `morbo bin/webwork3`.
4. Note if there are missing perl packages, it will let you know and you can install those with `cpanm`.
   Also, there may missing plugins, like `DBIC`.  Any Mojolicious plugins have a prefix of `Mojolicious::Plugin`, so to
   install the `DBIC` plugin, enter `cpanm Mojolicious::Plugin::DBIC`
5. If you get the message `Web application available at http://127.0.0.1:3000` then mojolicious is running and waiting
   for any requests.

### Getting the standalone renderer code running

1. Clone the repository with `git clone --recursive https://github.com/openwebwork/renderer`

2. copy `render_app.conf.dist` to `render_app.conf` and make any desired modifications including changing the ports
from 3000 to 3001

3. install other dependencies
   a. `cd lib/WeBWorK/htdocs`
   b. `npm install`

4. Either install the webwork open problem library or link to a current one with
   a. change to the top directory of the renderer
   b. `ln -s PATH_TO_OPL` (end with `webwork-open-problem-library`)

5. Start the standalone server with `morbo -l "http://*:3001" script/render_app`


### Creating some fake data

There is some fake data to get started with so there are a few courses and users.  The users are all based on Simpson's
characters.

1. Build the database as a sqlite database.  Again, from the `webwork3` directory, `perl t/db/build_db.pl`.  There
   shouldn't be an errors or output.
2. You can run database test, but unnecessary.  `prove t/db/*.t` and hopefully (again) no errors will pop up.

### Development build/test the web UI

This section builds all of the UI code using webpack and fires up a browser window to view the webwork3 interface.

1. Inside the `webwork3` directory, execute `yarn install` or `npm install`.  If you don't have yarn or npm installed,
   see [yarn homepage](https://yarnpkg.com/) or [npm homepage](https://docs.npmjs.com/).

   There are some warnings (mostly deprecations) that can be ignored.

2. Start the development server with `quasar dev` and again hopefully there are no errors.

3. Visit `http://localhost:8080/webwork3/login` (or perhaps a different port) in your web browser (the output of the
   the `quasar dev` command says where to go).

4. You should get a "Login to WeBWorK" screen.  You can use the Lisa Simpson account with the username `lisa` and the
   password `lisa`.

### Production build and deployment (instructions for apache2 on Ubuntu)

TODO: add instructions for other servers and operating systems and add a docker deployment approach

1. Install node version 16 with the following.

```sh
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install nodejs
```

2. Inside the `webwork3` directory, execute `yarn install` or `npm install`.

3. Build the client side user interface with `quasar build` or `npm run build`.

4. Copy `webwork3/dist/spa` to `/var/www/html/webwork3` (or create a link).

5. Enable the necessary apache2 modules.

```sh
sudo a2enmod headers proxy proxy_http rewrite
```

6. Copy `conf/apache2/webwork3-apache2.dist.conf` to `conf/apache2/webwork3-apache2.conf`, and create a link to that
   file in `/etc/apache2/conf-enabled`.  This can be accomplished by executing the following commands from the webwork3
   directory.

```sh
cp conf/apache2/webwork3-apache2.dist.conf conf/apache2/webwork3-apache2.conf
sudo ln -s $(pwd)/conf/apache2/webwork3-apache2.conf /etc/apache2/conf-enabled
```

7. Restart apache2 with `sudo systemctl restart apache2`.

8. Set up permissions for the api with the following commands executed from the webwork3 directory.

```sh
sudo chown -R youruser:www-data logs
sudo chmod g+rw logs/*
```

9. Copy `conf/apache2/webwork3.dist.service` to `conf/apache2/webwork3.service` and modify `WorkingDirectory` with the
   correct path to the webwork3 location.  Make sure to uncomment the hypnotoad `pid_file` setting in the `webwork3.yml`
   file.  Then enable and start the webwork3 api service by executing the following from within the `webwork3`
   directory.

```sh
sudo systemctl enable $(pwd)/conf/apache2/webwork3.service
sudo systemctl start webwork3
```

10. Set up permissions for the renderer with the following commands executed from the renderer directory.

```sh
sudo chown -R youruser:www-data logs 
sudo chmod g+rw logs/standalone_results.log
sudo chmod -R g+rw lib/WeBWorK/tmp/* lib/WeBWorK/htdocs/tmp/*
```

11. Copy `conf/apache2/renderer.dist.service` to `conf/apache2/renderer.service` and modify `WorkingDirectory` in the
   copied file with the correct path to the webwork3 location.  Add `pid_file => '/var/run/webwork3/renderer.pid'` and
   `proxy => 1` to the hypnotoad configuration in the `render_app.conf` file.  Then enable and start the renderer
   service by executing the following from within the `webwork3` directory.

```sh
sudo systemctl enable $(pwd)/conf/apache2/renderer.service
sudo systemctl start renderer
```

   Note that anytime the server is rebooted the webwork3 api and renderer services will be automatically started.

12. Visit `localhost/webwork3`.
