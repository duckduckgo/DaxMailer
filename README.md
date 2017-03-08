# DaxMailer
Subscriber management and email scheduling

## Schema Changes

When you have changed the DBIC schema, you will need to change the `$VERSION` in `lib/DaxMailer/Schema.pm`.
Then you can generate SQL diffs with the script:

```bash
DBIC_TRACE_PROFILE=console DBIC_TRACE=1 perl -Ilib -Ilocal/lib/perl5/ bin/schema_generate.pl
```

Then you will need to deploy them like so:

```bash
DBIC_TRACE_PROFILE=console DBIC_TRACE=1 perl -Ilib -Ilocal/lib/perl5/ bin/db_migrate.pl
```

New files in sql/ should be commited to git. You may make changes to these files after they are generated,
but if you run `schema_generate.pl` again these changes will be overwritten.

The `db_migrate.pl` script should also be run on each deployment to pull in new changes.
It is idempotent, so should be safe to run every time.
