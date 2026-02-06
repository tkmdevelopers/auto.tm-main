<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
    <p align="center">
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://coveralls.io/github/nestjs/nest?branch=master" target="_blank"><img src="https://coveralls.io/repos/github/nestjs/nest/badge.svg?branch=master#9" alt="Coverage" /></a>
<a href="https://discord.gg/G7Qnnhy" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://opencollective.com/nest#backer" target="_blank"><img src="https://opencollective.com/nest/backers/badge.svg" alt="Backers on Open Collective" /></a>
<a href="https://opencollective.com/nest#sponsor" target="_blank"><img src="https://opencollective.com/nest/sponsors/badge.svg" alt="Sponsors on Open Collective" /></a>
  <a href="https://paypal.me/kamilmysliwiec" target="_blank"><img src="https://img.shields.io/badge/Donate-PayPal-ff3f59.svg" alt="Donate us"/></a>
    <a href="https://opencollective.com/nest#sponsor"  target="_blank"><img src="https://img.shields.io/badge/Support%20us-Open%20Collective-41B883.svg" alt="Support us"></a>
  <a href="https://twitter.com/nestframework" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow" alt="Follow us on Twitter"></a>
</p>
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Description

[Nest](https://github.com/nestjs/nest) framework TypeScript starter repository.

## Project setup

```bash
$ npm install
```

## Compile and run the project

```bash
# development
$ npm run start

# watch mode
$ npm run start:dev

# production mode
$ npm run start:prod
```

## Run tests

```bash
# unit tests
$ npm run test

# e2e tests
$ npm run test:e2e

# test coverage
$ npm run test:cov
```

## Deployment

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

If you are looking for a cloud-based platform to deploy your NestJS application, check out [Mau](https://mau.nestjs.com), our official platform for deploying NestJS applications on AWS. Mau makes deployment straightforward and fast, requiring just a few simple steps:

```bash
$ npm install -g mau
$ mau deploy
```

With Mau, you can deploy your application in just a few clicks, allowing you to focus on building features rather than managing infrastructure.

---

## 🔐 Production Deployment (Docker + Postgres)

This project is containerized. Follow these steps to replace any old native Postgres instance with the Docker stack safely.

### 1. Backup Existing Server Database (IMPORTANT)
If you have an existing Postgres running directly on the host:

```bash
# Adjust user/db as needed
pg_dump -U auto_tm -d auto_tm -F c -f backup_$(date +%Y%m%d).dump
```

Verify backup integrity:

```bash
pg_restore -l backup_YYYYMMDD.dump | head
```

### 2. Stop & Disable Old Postgres Service

```bash
sudo systemctl stop postgresql || true
sudo systemctl disable postgresql || true
```

Optionally remove old data directory AFTER confirming you have backups:

```bash
sudo rm -rf /var/lib/postgresql/data_old_backup_if_any
```

### 3. Copy Artifacts to Server

```bash
scp -r backend/ user@server:/opt/alpha-motors-backend
```

### 4. Create `.env` (Server)
Use `backend/.env.example` as a template:

```bash
cd /opt/alpha-motors-backend
cp .env.example .env
nano .env   # set secrets (DB creds, JWT, email, firebase keys)
```

### 5. Build Image (Online Build Path)

```bash
docker compose -f docker-compose.build.yml build api
```

If building offline, pre-build elsewhere:

```bash
# Build a versioned release bundle (reads version from package.json)
./scripts/build-release.sh

# Transfer the release folder to the server
scp -r release/alpha-motors-v0.2.0 user@server:/opt/alpha-motors/

# On the server, run the deploy script
./deploy-update.sh alpha-motors-backend-0.2.0.tar.gz
```

### 6. Start Production Stack

```bash
docker compose -f docker-compose.prod.yml up -d
```

### 7. Verify

```bash
docker ps
docker logs alpha_backend --tail 80
curl -f http://SERVER_IP:3080/api-docs | head
docker exec auto_tm_postgres psql -U auto_tm -d auto_tm -c '\dt'
```

### 8. Schedule Backups

Create a backup script `/usr/local/bin/pg_backup_alpha.sh`:

```bash
#!/bin/bash
set -euo pipefail
STAMP=$(date +%Y%m%d_%H%M)
docker exec auto_tm_postgres pg_dump -U auto_tm -d auto_tm -F c > /opt/backups/alpha_${STAMP}.dump
find /opt/backups -type f -name 'alpha_*.dump' -mtime +7 -delete
```

Cron entry (`crontab -e`):

```bash
0 2 * * * /usr/local/bin/pg_backup_alpha.sh >> /var/log/alpha_pg_backup.log 2>&1
```

### 9. Log Rotation

Use `docker logs --since 1h alpha_backend` for ad-hoc inspection. For persistent logs create a Fluent Bit / Loki pipeline (optional).

### 10. Updating the App

```bash
git pull origin development
docker compose -f docker-compose.build.yml build --no-cache api
docker compose -f docker-compose.prod.yml up -d --force-recreate api
```

### 11. Hardening Checklist

- Remove debug logs in `entrypoint.sh` / `database.ts`.
- Ensure JWT secrets are long & random.
- Restrict inbound traffic to port 3080 only (ufw / security group).
- Consider pgBouncer if connection churn grows.
- Add monitoring (Prometheus or managed service).

### 12. Disaster Recovery Drill

Test restore quarterly:

```bash
docker exec auto_tm_postgres dropdb -U auto_tm restore_test || true
docker exec auto_tm_postgres createdb -U auto_tm restore_test
docker exec -i auto_tm_postgres pg_restore -U auto_tm -d restore_test < /opt/backups/latest.dump
```

---

## Removing Obsolete Migrations (Optional)
Legacy no-op migrations can be pruned once you are on a stable schema snapshot (take a backup first). Removing them reduces noise:

```bash
git rm backend/migrations/20251009120000-add-reply-to-comments.js
git rm backend/migrations/20251010000000-rename-posts-uudi-to-uuid.js
git rm backend/migrations/20251012000000-rename-posts-uudi-and-fix-comments-fk.js
```

Then tag a release: `git tag v1.0.0 && git push --tags`.

---

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
