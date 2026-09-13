← [2.18 The PostgreSQL CLI](18-postgres-cli.md)

# 2.19 User & Permission Management

Before any code — a naming clash to clear up first, since "users" means two
very different things.

- An **application-level user** — like a row in a `customers` table — is
  just data. Anyone with the right permissions can read or write it.
- A **database-level user (role)** — what this lesson covers — is
  PostgreSQL's own login identity: *who* is allowed to connect to the
  database at all, and *what* they're allowed to do once connected.

So far, every example in this course has run as the all-powerful `postgres`
(or `root`) superuser. Real applications never should — this lesson walks
through the full cycle: see who has access, add someone, give them exactly
what they need, understand what you just gave them, and take it away again.

## Step 1 — See who already has access

Before adding anyone, check who's already there — you can't reason about
"least privilege" without knowing the starting point:

```
\du
```

`\du` is the same meta-command [Lesson 2.18](18-postgres-cli.md) introduced —
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
permission on every table still has to be handed out explicitly, one
`GRANT` at a time.

## Step 3 — Give permission

```sql
GRANT SELECT, INSERT, UPDATE ON products, orders, order_items TO app_user;
```

`app_user` can now read, insert, and update rows in exactly those 3 tables —
notice **not** `DELETE`, and **not** `customers`, `reviews`, or any other
table. That's deliberate, not an oversight — see Step 4.

To hand out the same permission across every table at once, rather than
naming them one by one:

```sql
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_user;
```

## Step 4 — Explain permission: what you just gave away

Each keyword in a `GRANT` maps to one specific capability on a table:

| Permission | Lets the role... |
|---|---|
| `SELECT` | Read rows (`SELECT * FROM ...`) |
| `INSERT` | Add new rows |
| `UPDATE` | Modify existing rows |
| `DELETE` | Remove rows |
| `TRUNCATE` | Empty the whole table at once ([Lesson 2.17](17-table-management.md)) |
| `REFERENCES` | Create a foreign key that points at this table |
| `ALL PRIVILEGES` | Every permission above, at once |

Granting only `SELECT, INSERT, UPDATE` above (and leaving out `DELETE`) is
the **principle of least privilege** in action: give a role exactly the
capabilities it needs to do its job, nothing more — the same instinct
behind [Lesson 2.13](13-constraints.md)'s constraints, just applied to *who*
can act, instead of *what values* are allowed.

`REVOKE` is the mirror image — it takes one permission back without
touching the others:

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

Pulling all five steps together for the actual `apple_store` database from
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
| `GRANT ... ON ... TO ...` | Gives a specific permission on specific tables |
| `REVOKE ... ON ... FROM ...` | Takes a permission back |
| `GRANT role TO role` | One role inherits another's permissions (group membership) |
| `ALTER ROLE ... WITH PASSWORD / NOLOGIN` | Changes a role's password, or locks it out without deleting it |
| `REASSIGN OWNED BY` / `DROP OWNED BY` | Clears what a role owns/was granted, so it can be dropped |
| `DROP ROLE` | Deletes a role (after clearing anything it owns) |

---
← [2.18 The PostgreSQL CLI](18-postgres-cli.md) | Next: [2.20 Capstone →](20-capstone.md)
