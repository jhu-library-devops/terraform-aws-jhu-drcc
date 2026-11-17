# Migration and Rollback Guide

This release changes database ownership and security-group rule ownership. Treat it as a coordinated breaking upgrade. Do not apply it first to production, do not use routine targeted applies, and do not approve a plan that replaces or destroys RDS, its credentials secret, subnet group, or security group.

## Assumptions

- OpenTofu or Terraform `>= 1.6`
- AWS provider `~> 5.0`
- Remote state locking and a tested state-backup process
- Permission to create an RDS snapshot and inspect security-group rules
- Existing deployments use the historical module names `foundation`, `dspace_app`, and `solr`; adjust addresses when names differ

## 1. Preserve RDS identity while changing ownership

Database resources moved from `drcc-foundation` to `dspace-app-services`. The complete example includes declarative `moved` blocks in `examples/dspace-complete/migrations.tf` for these addresses:

```text
module.foundation.aws_db_subnet_group.main[0]
  -> module.dspace_app.aws_db_subnet_group.main[0]
module.foundation.random_password.db[0]
  -> module.dspace_app.random_password.db[0]
module.foundation.aws_secretsmanager_secret.db[0]
  -> module.dspace_app.aws_secretsmanager_secret.db[0]
module.foundation.aws_secretsmanager_secret_version.db[0]
  -> module.dspace_app.aws_secretsmanager_secret_version.db[0]
module.foundation.aws_db_instance.main[0]
  -> module.dspace_app.aws_db_instance.main[0]
module.foundation.aws_security_group.rds[0]
  -> module.dspace_app.aws_security_group.rds[0]
module.foundation.aws_vpc_security_group_ingress_rule.db_ingress_rule[0]
  -> module.dspace_app.aws_vpc_security_group_ingress_rule.db_ingress_rule[0]
```

Before planning:

1. Freeze concurrent infrastructure changes.
2. Create and verify a manual RDS snapshot.
3. Back up state with `tofu state pull` to an encrypted, access-controlled location. State contains sensitive data.
4. Copy the example `moved` blocks into a custom root module and adjust module names when necessary.
5. Remove database-creation arguments from foundation and configure identical database settings on DSpace. Keep identifiers, engine version, storage, Multi-AZ, backup, deletion-protection, and final-snapshot settings unchanged.
6. Run and save a full plan. The seven resources above must move addresses without create, delete, or replacement actions.
7. Have a second operator review the saved plan before applying it in a non-production environment.

The foundation compatibility outputs only look up a caller-supplied existing database. They do not proxy a database managed by DSpace. Replace consumers of `module.foundation.db_*` with `module.dspace_app.db_*`.

### Database rollback

Before apply, rollback is simply restoring the prior configuration and module pins. After addresses have moved, restore the previous release only after reversing each address with `tofu state mv <new-address> <old-address>`. Re-run a full plan and require zero database replacement or destruction. If a database resource changed unexpectedly, stop and restore under the incident and snapshot-recovery procedure rather than attempting an ad hoc apply.

## 2. Stage security-group ownership changes

Application modules now own narrow reciprocal rules attached to some foundation-owned security groups. Each AWS rule must have exactly one Terraform state owner. A duplicate rule in two states can fail creation and make teardown unsafe.

Use a two-phase rollout when modules have separate states or release pins:

1. Inventory current rules and state addresses. Decide the single owner for every rule.
2. Deploy the new Solr and Repository MCP module versions while retaining the previous foundation version and its broad compatibility egress.
3. Verify the new exact-port rules and application health. Import an existing identical rule into the selected owner or remove the obsolete owner; never leave duplicate ownership.
4. Deploy the new foundation version that removes broad ALB, ECS, Zookeeper, EFS, and canary paths.
5. Verify public ALB to DSpace/MCP, private ALB to API/Solr, DSpace to RDS/Solr, Solr to Zookeeper/EFS, node peer traffic, DNS, HTTPS, and canary health.

For a DSpace-managed database, `dspace-app-services` owns both ECS-to-RDS egress and RDS ingress on TCP 5432. For an external database that cannot be referenced by security group, explicitly set foundation `ecs_vpc_tcp_egress_ports = [5432]` and manage reciprocal database ingress in one state.

### Network rollback

Keep the previous foundation module pin available until connectivity checks pass. If traffic fails, restore the previous foundation rules through a reviewed full plan while retaining the new narrow application rules. Diagnose endpoint security-group selection and rule ownership before attempting the hardening step again.

## 3. Database secret contract

Managed RDS credentials are a Secrets Manager JSON object with `url`, `username`, `password`, `host`, `port`, and `dbname` fields. Module-managed DSpace API, Jobs, and initialization tasks consume that one secret. Existing-database mode must provide the same fields through `db_credentials_secret_arn_override`, or use the legacy SSM database parameters when no credentials secret override is supplied.

Because earlier task definitions ignored `container_definitions` drift to preserve CI image updates, existing module-managed deployments may require a reviewed one-time task-definition replacement to adopt the new secret references. CI/CD-managed task definitions should use `use_external_task_definitions = true` and be updated in their owning pipeline.

## 4. TLS certificate workflow

Supported examples default to a pre-issued, validated ACM certificate ARN for one-pass planning. If `create_ssl_certificate = true`, use a staged workflow: request the certificate, create the emitted DNS validation records with the authoritative DNS provider, wait for ACM status `ISSUED`, and only then attach it to the HTTPS listener in a reviewed full plan.

## Acceptance criteria

- Saved plan contains no unexpected replacement or destruction.
- RDS endpoint, identifier, credentials secret ARN, and security-group IDs remain stable.
- Every cross-module rule has one state owner and matching ingress/egress.
- DSpace API and Jobs start with the managed credentials secret.
- Solr/Zookeeper quorum, EFS mounts, DNS, canary, private API, public UI/API, and Repository MCP checks pass.
- A post-migration full plan is empty apart from explicitly accepted operational drift.
