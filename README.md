## "~~Boring~~ Postgres" Session Material from SoCraTes 2024 UK

*⚠️DO NOT USE IN PRODUCTION ⚠️*

### Setup

Most code in here works with a standard Postgres 16 installation, 
but [pg_cron](https://github.com/citusdata/pg_cron) requires some 
manual setup. For the demo I used an image with pg_cron preinstalled.

```bash
docker run -p5432:5432 --name postgres-16 --rm -e POSTGRES_HOST_AUTH_METHOD=trust cleisonfmelo/postgres-pg-cron:latest
```

The files from the session are in `./sql`

### Topics covered

* Lightweight testing
* JSON generation
* Multi-tenancy using row-level-security
* Cron jobs