← [2.10 The PostgreSQL CLI](10-postgres-cli.md)

# 2.11 User & Permission Management

Before any code — a naming clash to clear up first, since "users" means two
very different things.

- An **application-level user** — like a row in a `customers` table — is
  just data. Anyone with the right permissions can read or write it.
- A **database-level user (role)** — what this lesson covers — is
  PostgreSQL's own login identity: *who* is allowed to connect to the
  database at all, and *what* they're allowed to do once connected.

So far, every example in this course has run as the all-powerful `postgres`
(or `root`) superuser. Real applications never should — this lesson walks
through the full cycle: see who has access, add someone, hand them
*everything*, understand exactly what that gave away (and what each smaller
piece of it means on its own), scale it back down, and take it all away
again.

## Step 1 — See who already has access

Before adding anyone, check who's already there — you can't reason about
"least privilege" without knowing the starting point:

```
\du
```

`\du` is the same meta-command [Lesson 2.10](10-postgres-cli.md) introduced —
it lists every role on the server, plus a column of attributes
(`Superuser`, `Create role`, `Create DB`, ...). On a fresh database, you'll
likely see just one: your own superuser role (`postgres` or `root`,
depending on how [Lesson 1.6](../01-fundamentals/06-run-with-docker.md) set
up the container).

Prefer plain SQL, or scripting this check? The same information lives in
`pg_roles`:

```sql
SELECT rolname, rolsuper, rolcreatedb, rolcanlogin
FROM pg_roles
ORDER BY rolname;
```

## Step 2 — Add a new user

```sql
CREATE ROLE app_user WITH LOGIN PASSWORD 'change_me_123';
```

`CREATE USER` is identical, just shorthand — a "user" is simply a role
created with `LOGIN` permission built in:

```sql
CREATE USER app_user WITH PASSWORD 'change_me_123';   -- LOGIN is implied
```

Run `\du` again — `app_user` is now in the list. But try connecting as it
and querying `products`, and you'll get `permission denied for table
products`. Creating a role only grants the ability to *log in* — every
permission on every table still has to be handed out explicitly.

## Step 3 — Give permission: all of it, on everything

Let's start as wide as PostgreSQL allows, then explain and scale back from
there. Every permission, on every table, in every database — step by step:

```sql
-- 1. Every permission, on every table that exists right now, in one schema
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_user;

-- 2. Every permission on sequences too — a SERIAL primary key needs this for
--    INSERT to work, and it's easy to forget since it's a separate object
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- 3. Cover tables created LATER too — step 1 only covers what exists today
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO app_user;

-- 4. Every permission on the database itself (connect, create schemas/tables, temp tables)
GRANT ALL PRIVILEGES ON DATABASE apple_store TO app_user;

-- 5. The widest possible grant: bypass permission checks entirely, on every database
ALTER ROLE app_user WITH SUPERUSER;
```

`app_user` can now do absolutely anything, anywhere on this server —
identical to `postgres`/`root` itself. Step 4 explains exactly what each of
those five statements actually gave away, and why real applications almost
never want to stop here.

## Step 4 — Explain permission

### First: what "all" actually means

- **`GRANT ALL PRIVILEGES ON ALL TABLES ...`** is shorthand for every
  individual table permission below (`SELECT, INSERT, UPDATE, DELETE,
  TRUNCATE, REFERENCES`, plus `TRIGGER`) — all at once, for every table
  that currently exists in that schema.
- **`ALL SEQUENCES`** matters because every `SERIAL`/`IDENTITY` primary key
  ([Lesson 2.2](02-your-first-database-apple-example.md)) is backed by its
  own sequence object. Grant `INSERT` on the table but forget this, and
  inserts still fail — the role can't advance the sequence that generates
  the id.
- **`ALTER DEFAULT PRIVILEGES`** doesn't grant anything on its own — it's a
  standing rule: *"whenever a new table shows up in this schema from now
  on, auto-grant this too."* Without it, a table created next week starts
  back at zero permissions for `app_user`, even though step 1 covered
  everything else.
- **`GRANT ALL PRIVILEGES ON DATABASE`** is smaller than it sounds — it
  covers connecting to the database and creating schemas/tables/temp
  tables inside it. It does **not** by itself grant access to the tables
  already in it — that's the separate `ALL TABLES` grant above.
- **`ALTER ROLE ... SUPERUSER`** is the real "everything, everywhere" —
  a superuser bypasses every `GRANT`/`REVOKE` on the whole server, across
  every database, no exceptions. This is what `postgres`/`root` already is.

⚠️ Reach for `SUPERUSER` (or even schema-wide `ALL PRIVILEGES`) sparingly.
One leaked password or one SQL-injection bug in that role's application,
and whoever exploits it now has *everything*, not "everything in 3
tables." Save it for a human administrator or a genuinely trusted internal
tool — a migration script, a backup job — never for a public-facing app's
own database user.

### Then: the individual privileges that make it up

Each keyword below is one specific capability, grantable on its own instead
of all at once:

| Permission | Lets the role... |
|---|---|
| `SELECT` | Read rows (`SELECT * FROM ...`) |
| `INSERT` | Add new rows |
| `UPDATE` | Modify existing rows |
| `DELETE` | Remove rows |
| `TRUNCATE` | Empty the whole table at once ([Lesson 2.9](09-table-management.md)) |
| `REFERENCES` | Create a foreign key that points at this table |
| `ALL PRIVILEGES` | Every permission above, at once — Step 3 granted this broadly |

This is where **the principle of least privilege** comes in: give a role
exactly the capabilities it needs to do its job, nothing more — the exact
opposite of Step 3's "grant everything." You'll meet this same instinct
again in [Lesson 2.16](16-constraints.md)'s constraints, just applied there
to *what values* are allowed instead of *who* can act. Scaling `app_user`
back down to what an application actually needs:

```sql
ALTER ROLE app_user WITH NOSUPERUSER;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM app_user;
GRANT SELECT, INSERT, UPDATE ON products, orders, order_items TO app_user;
```

Notice what's missing: **not** `DELETE`, and **not** `customers`,
`reviews`, or any other table — deliberate, not an oversight.

`REVOKE` also works one permission at a time, without touching the rest:

```sql
REVOKE UPDATE ON products FROM app_user;
```

`app_user` can still `SELECT` and `INSERT` on `products`, but no longer
`UPDATE` it — maybe price changes should only happen through a separate,
more tightly controlled process.

Repeating the same `GRANT`s for every new role doesn't scale — instead,
define a reusable "template" role, and let others inherit its permissions
by membership:

```sql
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE analyst WITH LOGIN PASSWORD 'analyst_pw_123';
GRANT read_only TO analyst;   -- analyst now inherits every SELECT read_only has
```

`analyst` can now query every table — but never `INSERT`, `UPDATE`, or
`DELETE` anything, anywhere. Add a new table later, re-run one `GRANT` on
`read_only`, and every role that inherits from it picks up the change
automatically.

## Step 5 — Remove a user

Before dropping a role, check what it still owns or has been granted —
`DROP ROLE` refuses to run otherwise:

```sql
DROP ROLE analyst;
-- ERROR: role "analyst" cannot be dropped because some objects depend on it
```

Clear that first — either reassign what it owns to another role, or drop it
outright, then drop the role itself:

```sql
REASSIGN OWNED BY analyst TO postgres;   -- hand off anything analyst owns
DROP OWNED BY analyst;                   -- or: discard its remaining grants/privileges
DROP ROLE analyst;                       -- now succeeds
```

Not ready to fully remove someone, just lock them out temporarily? Revoke
`LOGIN` instead of dropping the role — every `GRANT` stays intact for if
they come back:

```sql
ALTER ROLE analyst WITH NOLOGIN;
```

Confirm the removal (or lockout) the same way you started — `\du` again.

## Step 6 — A realistic role setup for our schema

Step 3 showed the widest possible grant; real applications look like Step
4's scaled-back version instead. Pulling that together for the actual
`apple_store` database from
[Lesson 2.2](02-your-first-database-apple-example.md):

```sql
-- The application itself: read/write its own operational tables only
CREATE ROLE app_user WITH LOGIN PASSWORD 'change_me_123';
GRANT SELECT, INSERT, UPDATE ON products, customers, orders, order_items TO app_user;

-- Read-only reporting/BI access
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE analyst WITH LOGIN PASSWORD 'analyst_pw_123';
GRANT read_only TO analyst;
```

Notice neither role can `DROP TABLE`, `DELETE` arbitrary data, or manage
other roles — capabilities reserved for whoever administers the database
directly (still `postgres`/`root`, used sparingly, by a human, not an
application).

## Step 7 — Recap

| Command | Does |
|---|---|
| `\du` / `SELECT * FROM pg_roles` | Lists every role that currently exists |
| `CREATE ROLE` / `CREATE USER` | Creates a new database login identity |
| `GRANT ALL PRIVILEGES ON ALL TABLES/SEQUENCES IN SCHEMA ...` | Every permission, on every existing table/sequence in a schema |
| `ALTER DEFAULT PRIVILEGES ... GRANT ALL ON TABLES ...` | Auto-grants that same access to tables created *later* |
| `GRANT ALL PRIVILEGES ON DATABASE ...` | Every permission on the database itself (connect, create inside it) |
| `ALTER ROLE ... SUPERUSER` / `NOSUPERUSER` | Bypasses (or restores) all permission checks, on every database |
| `GRANT ... ON ... TO ...` | Gives a specific permission on specific tables |
| `REVOKE ... ON ... FROM ...` | Takes a permission back |
| `GRANT role TO role` | One role inherits another's permissions (group membership) |
| `ALTER ROLE ... WITH PASSWORD / NOLOGIN` | Changes a role's password, or locks it out without deleting it |
| `REASSIGN OWNED BY` / `DROP OWNED BY` | Clears what a role owns/was granted, so it can be dropped |
| `DROP ROLE` | Deletes a role (after clearing anything it owns) |

---
← [2.10 The PostgreSQL CLI](10-postgres-cli.md) | Next: [2.12 Normalization →](12-normalization.md)
