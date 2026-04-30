# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

JumpServer is an open-source PAM (Privileged Access Management) / bastion host platform. It manages access to servers, network devices, and cloud assets, with support for SSH, RDP, VNC, and other protocols, plus session recording, approval workflows, and multi-tenancy.

## Commands

All Django management runs from the `apps/` directory:

```bash
cd apps

# Run all tests in an app
python manage.py test orgs

# Run a specific test class or method
python manage.py test orgs.tests.OrgTests.test_create

# Database migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic

# Shell
python manage.py shell
```

**Service control** (project root):
```bash
./jms start all -d      # Start all services as daemon
./jms stop all
./jms restart web       # Restart only web service
./jms status
./jms upgrade_db        # Run migrations + post-upgrade tasks
```

**Linting:**
```bash
isort apps/             # Import sorting (line_length=120, per .isort.cfg)
pylint apps/            # Linting (see .pylintrc)
```

## Architecture

**Stack:** Django 4.1 + DRF 3.14, Celery 5, Channels 4/Daphne (WebSocket), Redis (cache/broker), Python 3.11+.

**Entry points:**
- WSGI: `apps/jumpserver/wsgi.py`
- ASGI: `apps/jumpserver/asgi.py`
- URLs: `apps/jumpserver/urls.py` — API v1 at `/api/v1/`, WebSocket routing in `routing.py`
- Docs: `/api/docs/` (drf-spectacular Swagger UI)

**Settings:** `apps/jumpserver/settings/` — split across `base.py` (core), `auth.py` (auth backends), `libs.py` (third-party config), `logging.py`, `custom.py`. Runtime config loaded from `config.yml` via `apps/jumpserver/conf.py`.

**Multi-tenancy:** The `orgs` app provides tenant isolation. `OrgMiddleware` sets the active org on each request. Most models inherit from org-aware base classes.

**Permissions:** Two-layer system — `rbac` app handles role definitions and assignments; `perms` app handles asset-level access grants (which user/user-group can access which asset/asset-group with which account).

### Core Apps

| App | Responsibility |
|-----|---------------|
| `users` | User accounts, groups, profile management |
| `assets` | Asset inventory (hosts, network devices, databases, cloud assets, web apps) |
| `accounts` | Credentials (accounts) on assets — passwords, SSH keys, automation |
| `perms` | Asset permission grants (user ↔ asset ↔ account) |
| `orgs` | Multi-tenancy — organizations and membership |
| `terminal` | Web terminal sessions, session recording, component registration (koko, lion, magnus, etc.) |
| `ops` | Task execution, Ansible playbooks, job scheduling |
| `authentication` | Auth backends: LDAP, OIDC, SAML, CAS, OAuth2, RADIUS, MFA |
| `rbac` | Roles, permissions, role assignments |
| `acls` | Access control rules (login ACLs, asset ACLs, command filters) |
| `tickets` | Approval workflows — access requests, login confirm, command confirm |
| `audits` | Audit logs, FTP logs, command logs, session activity |
| `notifications` | Email, DingTalk, Feishu, Slack, Weixin notifications |
| `settings` | System-level settings (stored in DB, managed via API) |
| `common` | Shared mixins, serializers, validators, management commands, utilities |

### Common Patterns

**ViewSets:** Most API views are DRF `ModelViewSet` subclasses with `OrgBulkMixin` or similar. Filter backends use `django-filter` with custom `FilterSet` classes defined per-app.

**Serializers:** Per-app serializers in `serializers/` subdirectory. Many use `BulkSerializerMixin` for bulk create/update operations.

**Signals:** Used extensively for audit logging, cache invalidation, and cross-app side effects. Check `signals.py` and `signal_handlers.py` in each app.

**Tasks:** Celery tasks in `tasks.py` per app; periodic tasks registered in `celery.py` or via `django-celery-beat`.

**Enterprise (XPack):** Premium features live in `apps/xpack/`. Detected and loaded conditionally at startup. The `_xpack.py` settings file enables XPack apps when the directory is present.

### Testing

Tests use `django.test.TestCase` or `rest_framework.test.APITestCase`. Test files are `tests.py` (or `tests/` directory) inside each app. No pytest — standard Django test runner only.
