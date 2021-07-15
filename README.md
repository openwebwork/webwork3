# webwork3

WeBWorK3 is the next generation of WeBWorK, an online open-source homework system.  This version is a complete rewrite of the webwork2 system using more modern database, backend and UI frameworks, described below.

There are three main parts of this repository:
* webwork-db: basic functionality (database and other utils)
* webwork-mojo: mojolicious server backend to handle api requests.
* webwork-front-end: new webwork interface.


## webwork-db

This is code to handle a new database structure for webwork and
other utilities needed for non-gui webwork functionality.

See `docs/db.md` for more information on the database.

## webwork-mojo

We use (Mojolicious)[http://mojolicious.org] to handle the webservices.  These include some basic webpages for accessing, but more-importantly a CRUD api webservice for interacting at a service level to webwork.

## webwork-front-end

The front end/client side of webwork uses [quasar](http://quasar.dev), a highly flexible set of interactice web components used with [VueJS](http://v3.vuejs.org).  The result is a Single Page Application (SPA) that runs extremely fast in that most of the client-side code is loaded at the beginning and only small api webservice requests are made and often handled in the background.

## Getting Started

The current version of this is for **DEVELOPMENT ONLY** and used as a proof of concept.  All of the instructions below are assuming terminal/shell commands.

### Getting the webwork3 code:

1. Clone the webwork3 code with `git clone https://github.com/openwebwork/webwork3.git`
2. Change directory to the webwork3 directory: `cd webwork3`
3. Switch to the `vue-quasar` branch with `git checkout vue-quasar`.


### Getting Mojolicious and other needed packages

1. Make sure that you have perl (at least version 5.20) installed.
2. Install `cpanm` from perl and install Mojolicious with `cpanm Mojolicious`.
  A one-liner install is available at [the Mojolicious homepage](https://mojolicious.org/).
3. Start mojolicious (from the `webwork3` directory) with `morbo bin/webwork3`.
4. Note if there are missing perl packages, it will let you know and you can install those with `cpanm`.
  Also, there may missing plugins, like `DBIC`.  Any Mojolicious plugins have a prefix
	of `Mojolicious::Plugin`, so to install the `DBIC` plugin, enter
	`cpanm Mojolicious::Plugin::DBIC`
5. If you get the message `Web application available at http://127.0.0.1:3000` then mojolicious is running and waiting for any requests.

### Creating some fake data

There is some fake data to get started with so there are a few courses and users.  The users are all based on Simpson's characters.

1. Build the database as a sqlite database.  Again, from the `webwork3` directory, `perl t/db/build_db.pl`.  There shouldn't be an errors or output.
2. You can run database test, but unnecessary.  `prove t/db/*.t` and hopefully (again) no errors will pop up.

### Build/test the web UI

This section builds all of the UI code using webpack and fires up a browser window to view the webwork3 interface.

1. Inside the `webwork3` directory, enter `yarn install`.  If you don't have yarn installed, see [yarn homepage](https://yarnpkg.com/).

	There are some warnings (mostly deprecations) that can be ignored.

2. Start the development server with `quasar dev` and again hopefully there are no errors.

3. Visit `http://localhost:8080/webwork3/login` (or perhaps a different port) in your web browser (the output of the the `quasar dev` command says where to go).

4. You should get a "Login to WeBWorK" screen.  You can use the Lisa Simpson login with `lisa@google.com` and her name in lower-case as the password.


