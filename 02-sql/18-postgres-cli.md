← [2.17 Table Management](17-table-management.md)

# 2.18 The PostgreSQL CLI

Every lesson so far has run SQL "somehow" — in `psql`, a GUI, or wherever
your setup put it. Let's make that explicit: `psql` is PostgreSQL's own
command-line client, and knowing it well means you're never stuck without a
GUI. This lesson also covers everyday tasks the SQL lessons never did —
listing databases, connecting to a different one, and browsing what tables
exist without already knowing their names.

## Step 1 — Connecting

If PostgreSQL runs natively ([Lesson 1.5](../01-fundamentals/05-installation.md)):

```bash
psql -U postgres
```

If it runs in Docker ([Lesson 1.6](../01-fundamentals/06-run-with-docker.md)),
`psql` lives *inside* the container — run it through `docker exec`:

```bash
docker exec -it my-postgres psql -U postgres
```

| Piece | Means |
|---|---|
| `docker exec` | Run a command inside an already-running container |
| `-it` | Interactive + a proper terminal — needed for a prompt you can type into |
| `my-postgres` | The container's name, from `docker run --name my-postgres ...` |
| `psql -U postgres` | The command to run inside it: `psql`, logging in as role `postgres` |

Either way, you land on a prompt like `postgres=#` — you're now talking
directly to the database.

## Step 2 — `psql` meta-commands vs. SQL

Everything typed at this prompt is one of two things:

- **SQL**, ending in `;` — `SELECT * FROM products;` — sent to PostgreSQL
  itself, works identically in any client (GUI included).
- **Meta-commands**, starting with `\` and **no** `;` — `\dt`, `\l`, `\q` —
  shortcuts understood only by `psql`, not by PostgreSQL. They exist purely
  to make the command line livable.

```
\?      -- list every meta-command, with what it does
\q      -- quit psql
```

## Step 3 — Databases: list, create, switch, drop

```
\l
```
Lists every database on this server — `apple_store` (from
[Lesson 2.2](02-your-first-database-apple-example.md)) among them, alongside
system databases like `postgres` and `template1`.

```sql
CREATE DATABASE apple_store;
```
```
\c apple_store
```
`\c` (or `\connect`) switches your session to a different database —
everything after this runs against `apple_store`, not whatever you were
connected to before. This is the same command Lesson 2.2 used without
stopping to explain it.

```sql
DROP DATABASE apple_store;
```
Deletes the entire database — every table, every row, permanently. You
can't drop the database you're currently connected to; `\c` to a different
one (e.g., `\c postgres`) first.

## Step 4 — Tables: browse without already knowing the names

```
\dt
```
Lists every table in the current database — the CLI answer to "what tables
even exist here?" when you've just connected to something unfamiliar.

```
\d products
```
Describes one table in detail: every column, its type, defaults, and — at
the bottom — its indexes, foreign keys, and constraints all in one view.
Compare that to hunting the same information down with `information_schema`
queries; `\d` is the fast path.

```
\dt+
```
Same list as `\dt`, plus size on disk and a description column — handy once
a database has grown to dozens of tables and a few of them are suspiciously
large.

## Step 5 — Dropping a table from the CLI

[Lesson 2.17](17-table-management.md) covered `DROP TABLE` as SQL — it's
identical here, `psql` is just where you're typing it:

```sql
DROP TABLE IF EXISTS inventory;
```

Run `\dt` again afterward to confirm — the fastest way to check a `DROP`
actually landed.

## Step 6 — A few more meta-commands worth knowing

```
\du          -- list roles/users on this server (Lesson 2.19 covers creating them)
\x           -- toggle "expanded display": one column per line — much easier to
                read a wide row than psql's default side-scrolling table
\timing      -- show how long each query took to run
\i script.sql -- run every command in a .sql file, as if you'd typed it in
\!           -- drop into your regular shell temporarily, without leaving psql
```

`\x` in particular is worth turning on by default when a table has more
than 5–6 columns — `SELECT * FROM products;` wraps into an unreadable mess
in a normal terminal window otherwise.

## Step 7 — Recap

| Command | Does |
|---|---|
| `psql -U <user>` | Connect (native install) |
| `docker exec -it <container> psql -U <user>` | Connect (Docker) |
| `\l` | List databases |
| `\c <database>` | Switch to a different database |
| `\dt` | List tables in the current database |
| `\d <table>` | Describe one table: columns, types, indexes, constraints |
| `\dt+` | List tables with size on disk |
| `\du` | List roles/users |
| `\x` | Toggle expanded (one-column-per-line) row display |
| `\q` | Quit |

---
← [2.17 Table Management](17-table-management.md) | Next: [2.19 User & Permission Management →](19-user-permission-management.md)
