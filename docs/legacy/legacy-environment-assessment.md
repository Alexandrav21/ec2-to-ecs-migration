# Legacy Environment Assessment

## Overview

Before starting the migration, I reviewed how the Flask app depended on its EC2 host and what would need to change for ECS.

This document records the initial legacy assessment, not the current deployment. The [project README](../../README.md) describes the implemented architecture and final scope. Legacy configuration and dependency versions below refer to that starting point.

The original request path was:

```text
User -> Nginx :80 -> Gunicorn :5000 -> Flask
```

Everything ran on one EC2 instance. The migration needed to move the host's responsibilities to Docker and ECS, not simply copy the entire EC2 setup into a container.

## Application

The Python Flask API uses `app/wsgi.py` as its production entry point.

The initial dependency versions were:

```text
Flask==3.0.0
gunicorn==21.2.0
werkzeug==3.0.1
```

The API exposes:

```text
GET  /health
GET  /api/v1/products
GET  /api/v1/products/<id>
GET  /api/v1/orders
POST /api/v1/orders
GET  /api/v1/stats
```

`APP_NAME`, `APP_VERSION` and `ENVIRONMENT` are read from environment variables, with defaults in the application.

### In-memory state

Products are stored in a Python dictionary, orders in a list, and the order counter in process memory.

This creates two important limitations:

- Restarting a process loses its orders and stock changes.
- Separate Gunicorn workers or ECS tasks have independent data, so requests can see different state.

The migration exercise preserves this behaviour rather than adding a database. However, multiple healthy tasks do not make the application's data durable or consistent. That would need a separate design before a real production migration.

## Host Runtime

### Gunicorn

The legacy systemd service configured Gunicorn with:

| Setting | Value |
|---|---|
| Workers | 4 |
| Worker class | `sync` |
| Request timeout | 60 seconds |
| Graceful timeout | 30 seconds |
| Maximum requests | 1,000 |
| Maximum request jitter | 100 |
| Logging | INFO |
| Listen address | `127.0.0.1:5000` |

Listening on localhost worked because Nginx was on the same host. In ECS, the app must listen on an interface the ALB can reach.

### Nginx

Nginx listened on port 80 and proxied requests to Gunicorn. It also handled:

- client and host headers
- proxy timeouts and a 1 MB request-body limit
- security response headers
- access and error logs
- separate routing for `/health`, `/api/` and `/`

The ALB replaces public ingress and health checking, but it does not automatically reproduce every Nginx setting. Headers, limits and routing behaviour need to be reviewed separately.

### systemd

systemd started and restarted Gunicorn, supplied its environment and runtime settings, and managed logging. It also applied host-level protections:

```text
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
```

Docker and ECS take over process lifecycle management. Relevant security controls must be considered explicitly rather than assumed to carry over from systemd.

## EC2 Provisioning and Infrastructure

The legacy `scripts/setup.sh` installed Python 3.11, virtualenv/pip, Nginx and supporting utilities such as Git, curl, wget, htop and unzip. It created the application and log directories, installed dependencies and service configuration, started the services and checked health.

The original Terraform provisioned:

- a VPC, public and private subnets, an internet gateway and a public route table
- an EC2 instance in the public subnet, an Elastic IP and a security group
- an EC2 IAM role and an S3 bucket
- an optional Route 53 record

At startup, EC2 downloaded an application archive from S3 using its instance role, then ran the setup script. Deployment therefore depended on changing the host itself. The target approach packages the runtime into a Docker image stored in ECR.

The target network places ECS tasks in private subnets behind a public ALB. Separate ECS task and execution roles replace the EC2 instance role, with permissions based on their responsibilities.

### Provisioning inconsistency

The legacy Terraform selected an Amazon Linux 2023 AMI, but its bootstrap scripts used `apt-get` and Debian/Ubuntu-style commands.

This was a baseline issue to investigate, not silently treat as a working setup. The original host may have differed from the supplied Terraform configuration.

## Logging

The legacy application wrote logs under `/var/log/flask-app/`, while Nginx used `/var/log/nginx/`.

Container filesystems are temporary, so they should not be the permanent log destination. The ECS design sends container logs to CloudWatch Logs instead.

## Migration Approach

| Legacy responsibility | ECS approach |
|---|---|
| EC2 host management | ECS Fargate |
| Nginx public ingress and health checks | ALB |
| systemd process lifecycle | ECS service and task lifecycle |
| EC2 filesystem logs | CloudWatch Logs |
| Application archive in S3 | Container image in ECR |
| EC2 instance role | ECS task and execution roles |
| Public application host | Private ECS tasks |
| Host setup scripts | Docker image build |

These are responsibility changes, not exact feature-for-feature replacements. Validation must check application behaviour as well as infrastructure health.

### Main risks

1. **Data loss and inconsistency:** in-memory state is lost on restart and differs between workers or tasks.
2. **Runtime differences:** Nginx routing, headers, limits and systemd controls may not have direct equivalents.
3. **Deployment changes:** host setup and S3 archive delivery are replaced by container builds and ECR.
4. **Access and networking:** IAM permissions and security groups must match the new private-task architecture.
5. **Baseline reliability:** the AMI/package-manager mismatch needs to be understood before comparing environments.

## CI/CD and Security Direction

The initial plan was to use GitHub Actions with AWS OIDC rather than stored AWS access keys, build container images, generate SBOMs with Syft and scan them with Grype.

The delivery process should validate changes before deployment, check the deployed service and provide a clear rollback path. The exact workflow triggers and safeguards are documented in the [README](../../README.md#cicd).

## Migration Validation

Use the legacy API as the behavioural baseline and check:

- `/health`, product retrieval, order creation and stock updates
- error responses and application logs
- startup behaviour and health after a restart
- ECS task health and ALB target health
- behaviour when requests reach different workers or tasks

A successful deployment or green health check does not prove that orders and stock remain consistent.

## Cutover and Rollback

For a real traffic switch, keep EC2 available while testing ECS. Define the checks that must pass, how traffic will move, what would trigger rollback and when EC2 can be removed.

The plan must also address orders and stock: switching DNS does not move in-memory data. Decide how to preserve that data and pause or coordinate writes before switching users.

Test rollback rather than relying only on written commands. The [README's cutover section](../../README.md#cutover-strategy) describes the proposed approach and distinguishes it from work actually performed.

## Cost and Scope

The legacy Terraform used the tags `Project`, `Environment` and `ManagedBy`. The initial target tagging plan also included `Owner` and `CostCenter`.

Cost decisions should cover more than tags:

- keep temporary infrastructure short-lived
- review Fargate sizing and ALB/networking costs
- set log retention
- capture evidence before teardown
- avoid extra services unless they solve a clear problem

### Initial bonus ideas

The original assessment considered blue/green deployment, Route 53 and ACM, a staging environment, multi-AZ monitoring and a short-lived multi-region failover exercise. Redis/ElastiCache and permanent multi-region infrastructure were out of scope.

These were ideas, not a list of completed features. The final project kept HTTPS and multi-AZ monitoring, used the existing ECS deployment mechanism with manual image rollback, and did not add staging, CodeDeploy blue/green or multi-region infrastructure.

## Documentation

The final documentation should explain the architecture, migration decisions, validation evidence, costs and known limitations. Troubleshooting and rollback lessons are as important as screenshots of successful deployments.
