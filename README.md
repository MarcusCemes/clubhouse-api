# 🍻 Clubhouse

_An unofficial website for the EPFL community._

## Getting Started

Clubhouse is written in Elixir is a relatively new programming language, running
on the [Erlang VM](https://www.erlang.org/) (used in several high-stake projects
such as WhatsApp and RabbitMQ) with an elegant syntax similar to that of Ruby.
In particular, it features a stellar web framework called
[Phoenix](https://www.phoenixframework.org/) that was used to make Clubhouse as
a single application, after various experiments with Svelte, Node.js, Deno, Go
and Rust.

### Dependencies

See the [Elixir website](https://elixir-lang.org/) for instructions on
installing Elixir and Erlang on your machine. If you're feeling slightly
adventurous, you can try installing Elixir using [asdf](https://asdf-vm.com) as
most distributions have an outdated Elixir version
([helpful guide](https://thinkingelixir.com/install-elixir-using-asdf/)).

Project dependencies are managed by Hex, Elixir's package manager.

```sh
$ mix deps.get
```

During development, you will likely also want to set up a Postgres database,
which is required for for most features of Clubhouse to work correctly. This
database is also used for tests.

```sh
$ docker run --name postgres -p 5455:5432 -e POSTGRES_PASSWORD=postgres -d postgres
```

You can also set the `DATABASE_HOST` environmental variable to `localhost` when
running the development server, as the database is considered to run at
`postgres` in a Docker Compose network by default.

### Compilation

The project can be built and run using Mix, Elixir's integrated build tool and
task runner.

```sh
$ mix compile
```

This will compile all the Elixir code into the `_build` directory as BEAM
modules. It is also possible to package the application as a self-contained
[release](https://elixir-lang.org/getting-started/mix-otp/config-and-releases.html)
that can be run in any similar environment, even without Elixir or Erlang
installed. This project uses Docker and releases together to simplify
deployment.

### Usage

The application will run differently, depending on the environment. The
development server can simply be started with no additional configuration (as
long as your database has the default hostname, or you have set the
`DATABASE_HOST` environmental variable).

When running for the first time, you will also have to to setup the database
schema using Ecto.

```sh
$ mix ecto.create
$ mix ecto.migrate
$ mix phx.server
```

The bridge and mailer will be emulated without any external network calls.

#### Supported environmental variables

The following environmental variables are supported when running the application
as a release (in production). During development, most variables use sane
defaults found in [dev.exs](./config/dev.exs) that an be changed for your
environment.

| Value            | Description                                                                 |
| ---------------- | --------------------------------------------------------------------------- |
| MIX_ENV          | This should be set to `prod` in production                                  |
| PHX_HOST         | The domain at which the application is accessible at (without the protocol) |
| PORT             | The port to bind the server to (default: 4000)                              |
| SECRET_KEY_BASE  | Secret value used to derive signing keys **(required)**                     |
| DATABASE_URL     | The connection string for the production database **(required)**            |
| BRIDGE_HOST      | The host at which the bridge is accessible on **(required)**                |
| BRIDGE_API_KEY   | The shared secret used as a Bearer token **(required)**                     |
| FORUM_URL        | THe URL at which the forum is available **(required)**                      |
| DISCOURSE_SECRET | The shared secret used for SSO token signing **(required)**                 |
| MAILER_SENDER    | The "from" address when sending mail **(required)**                         |
| SMTP_HOST        | The hostname of the SMTP server (default: postfix)                          |
| SMTP_PORT        | The port of the SMTP server (default: 587)                                  |
| APPEAL_ADDRESS   | Email which users can submit an appeal **(required)**                       |
| STATIC_URL       | THe URL for statically hosted resources (external) **(required)**           |

The [config](./config) directory can also be used as a reference to all
available application configuration.

#### Secret key base

This value is used to derive other private keys, such as those used to sign
session cookies. It should be unique and kept secret. A random value can be
generated using the `mix phx.gen.secret` command.

```sh
$ mix phx.gen.secret
# XidElJ...
```

#### Database URL

This value is used to connect to the database. It should be a full connection
string, including the password.

```yaml
# docker-compose.yml

app:
  environment:
    - "DATABASE_URL=ecto://clubhouse:${DATABASE_PASS}@postgres/clubhouse"
```

> **Tip**: Docker Compose can
> [substitute variables](https://docs.docker.com/compose/environment-variables/)
> using an adjacent `.env` file.

### Building the Docker container

The Dockerfile can be re-generated using `mix phx.gen.release --docker`. This
ensures that the OTP, Elixir and OS versions are a suitable match.

```sh
$ docker build --tag clubhouse .
```

Create a `.env` file to simplify runtime configuration:

```text
SECRET_KEY_BASE=<RANDOM VALUE>
```

Run the Docker container with `docker run`:

```sh
$ docker run --name clubhouse --env-file=.env -p 8080:4000 clubhouse
```

Transfer the image to a remote server:

```sh
$ docker save clubhouse | ssh some-host "docker load"
```

Use the image in a Docker Compose project:

```yaml
app:
  image: clubhouse
  ports:
    - "8080:4000"
  environment:
    - "DATABASE_URL=ecto://clubhouse:${DATABASE_PASS}@postgres/clubhouse"
    - "SECRET_KEY_BASE=${SECRET_KEY_BASE}"

bridge:
  image: clubhouse-bridge

postgres:
  image: postgres
  environment:
    - "POSTGRES_PASSWORD=${DATABASE_PASS}"
```

The entire project can be spun up and torn down on a private network with a
single command:

```sh
$ docker compose up -d   # -d is for --detach, runs in background
$ docker compose down
```

The docker image can also be used to run the database migrations, or to get an
IEx shell into the running application (even in production!).

```sh
$ docker compose run --rm app bin/migrate
$ docker compose exec app bin/clubhouse remote
```

Make sure that the database is running for the migration with
`docker compose up -d postgres`. Any environmental variables, such as
`DATABASE_URL` specified in `docker-compose.yml` will automatically be applied
with `docker compose run`.

## Authors

[Marcus Cemes](https://github.com/MarcusCemes)

## Version History

- 0.1
  - Initial release

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE)
file for details

## Acknowledgments

Built on the amazing work of the Elixir community.

- [Elixir](https://elixir-lang.org)
- [Phoenix](https://www.phoenixframework.org)
