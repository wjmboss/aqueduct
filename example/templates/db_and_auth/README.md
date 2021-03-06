
# wildfire

An application built with [aqueduct](https://github.com/stablekernel/aqueduct).

## Running the Application in Development

Run `aqueduct serve` from this directory to run the application.

If you wish to use the debugger in your IDE, run the `bin/main.dart` script from your IDE.

You must have a `config.yaml` file that has connection information to a locally running PostgreSQL database. To provision a local database with this application's schema, run the following commands from this directory:

```
aqueduct db generate
aqueduct db upgrade --connect postgres://user:password@localhost:5432/app_name
```

You must also configure OAuth 2.0 Client IDs in this database; see a later section.

## Running Application Tests

This application is tested against a local PostgreSQL database. The test harness (`test/harness/app.dart`) creates database tables for each `ManagedObject` subclass declared in this application. These tables are discarded when the tests complete.

The local database installation must have a database named `dart_test`, for which a user named `dart` (with password `dart`) has full privileges to.
The following command creates this database and user on a locally running PostgreSQL database:

```
aqueduct setup
```

See `test/identity_controller_test.dart` for an example of a test suite.

To run all tests for this application, run the following in this directory:

```
pub run test
```

You may also run tests from an IntelliJ IDE by right-clicking on a test file or test case and selected 'Run tests'.

Tests will be run using the configuration file `config.src.yaml`. This file should contain  test configuration values and remain in source control. This file is the template for `config.yaml` files, which live on deployed server instances.

See the application test harness, `test/app/harness.dart`, for more details. This file contains a `TestApplication` class that can be set up and torn down for tests. It will create a temporary database that the tests run against. See examples of usage in the `_test.dart` files in `test/`.

For more information, see [Getting Started](https://aqueduct.io/docs/) and [Testing](https://aqueduct.io/docs/testing/overview).

## Application Structure

The data model of this application is defined by all declared subclasses of `ManagedObject`. Each of these subclasses is defined in a file in the `lib/model` directory.

Routes and other initialization are configured in `lib/wildfire_sink.dart`. Endpoint controllers file are in `lib/controller/`.

## Authentication/Authorization

This application uses OAuth 2.0 and has endpoints (`/auth/token` and `/auth/code`) for supporting the resource owner and authorization code flows.

The test harness inserts OAuth 2.0 clients into the application's storage prior to running a test. See `test/harness/app.dart` for more details and `test/identity_controller_test.dart` for usage.

OAuth 2.0 clients are added to a live database with the `aqueduct auth` command. For example,

```
aqueduct auth add-client \
    --id com.wildfire.mobile
    --secret myspecialsecret
    --connect postgres://user:password@host:5432/wildfire
```

For more information and more configuration options for OAuth 2.0 clients, see [OAuth 2.0 CLI](https://aqueduct.io/docs/auth/cli/)

## Configuration

The configuration file (`config.yaml`) currently requires an entry for `database:` which describes a database connection.

The file `config.src.yaml` is used for testing: it should be checked into source control and contain values for testing purposes. It should maintain the same keys as `config.yaml`.

## Creating API Documentation

In the project directory, run:

```bash
aqueduct document
```

This will print a JSON OpenAPI specification to stdout.

## Deploying an Application

See the documentation for [Deployment](https://aqueduct.io/docs/deploy/overview/).
