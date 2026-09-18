← [2.20 Capstone](20-capstone.md)

# 2.21 Part 1 Conclusion

Part 1 is done. Let's connect everything it covered, and confirm you're
genuinely ready for Part 2.

## What you've learned

| Lesson | Big idea |
|---|---|
| [2.1 What Is SQL?](01-what-is-sql.md) | SQL is the language; PostgreSQL is the database that understands it |
| [2.2 Your First Database](02-your-first-database-apple-example.md) | `CREATE`, `INSERT`, `SELECT`, `UPDATE`, `DELETE` — the full lifecycle of data |
| [2.3 Types of SQL Queries](03-types-of-sql-queries.md) | DDL, DML, DQL, DCL, TCL — every command fits one of 5 jobs |
| [2.4 Data Types in PostgreSQL](04-postgresql-data-types.md) | Numeric, text, boolean, date/time, and PostgreSQL-special types |
| [2.5 Operators](05-operators.md) | Filtering rows with `WHERE`, `BETWEEN`, `IN`, `LIKE`, `IS NULL`, `AND`/`OR`/`NOT` |
| [2.6 Sort](06-sort.md) | `ORDER BY`, `LIMIT`, `OFFSET` |
| [2.7 Functions](07-functions.md) | Aggregate, math, string, and date functions, plus `COALESCE` |
| [2.8 Group](08-group.md) | `GROUP BY` and `HAVING` — summaries per category, not just per table |
| [2.9 Table Management](09-table-management.md) | More `CREATE TABLE` patterns, plus `ALTER`/`DROP TABLE` and evolving a schema safely |
| [2.10 The PostgreSQL CLI](10-postgres-cli.md) | Connecting with `psql`, listing databases/tables, and other everyday meta-commands |
| [2.11 User & Permission Management](11-user-permission-management.md) | Roles, `GRANT`/`REVOKE`, and least privilege |
| [2.12 Normalization](12-normalization.md) | Why data gets split across tables in the first place |
| [2.13 Relationships & Foreign Keys](13-relationships-and-foreign-keys.md) | One-to-many and many-to-many, enforced by the database itself |
| [2.14 Joins](14-joins.md) | Putting split tables back together — `INNER`/`LEFT`/`RIGHT`/`FULL` |
| [2.15 Subqueries & CTEs](15-subqueries-and-ctes.md) | Multi-step queries, including recursive CTEs for hierarchies |
| [2.16 Constraints](16-constraints.md) | Rules the database enforces, so bad data can't sneak in |
| [2.17 Transactions](17-transactions.md) | All-or-nothing guarantees across multiple statements |
| [2.18 Indexes & Performance](18-indexes-and-performance.md) | Why queries stay fast (or don't) at real scale |
| [2.19 Views](19-views.md) | Saving a query under a name, reused like a table |
| [2.20 Capstone](20-capstone.md) | Every skill above, used together on one real feature |

## The one idea to carry forward

Every lesson answered part of the same question: *"how do I model, store,
protect, and retrieve related facts, reliably?"* Normalization decided
**where** facts live; relationships and constraints decided **what's
allowed**; joins, subqueries, and functions decided **how you ask
questions**; transactions, indexes, and roles decided **how safely and how
fast**. None of these ideas are PostgreSQL-specific tricks — they're how
relational databases work, full stop.

## Readiness checklist

- [ ] I can design a normalized, multi-table schema from a plain-English requirement
- [ ] I can write `SELECT` queries with filtering, sorting, grouping, and joins across several tables
- [ ] I understand why a transaction is all-or-nothing, and can write one
- [ ] I know the difference between a regular index helping and a small table ignoring it
- [ ] I can create a role with only the permissions it actually needs

## What's next

**Part 2 — NoSQL** starts now, with **MongoDB**. Several ideas will look
familiar (data still needs structure, relationships still need
representing, queries still need to filter/sort/aggregate) — but the *tools*
for solving them will be genuinely different: documents instead of tables,
embedding instead of joining, and a schema that bends instead of one that's
enforced up front. That contrast is exactly the point.

---
← [2.20 Capstone](20-capstone.md) | Next: [3.1 What Is a Document Database? →](../03-document-db/01-what-is-a-document-database.md)
