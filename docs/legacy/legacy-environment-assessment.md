# Legacy Environment Assessment

## Overview

Before making any changes, I wanted to understand what is actually running in the legacy environment and what assumptions the application currently makes about the EC2 instance.

The current setup is a Flask application running with Gunicorn on a single EC2 instance, with Nginx acting as the reverse proxy.

The current request path is:

```text
User
  |
Nginx :80
  |
Gunicorn :5000
  |
Flask application
```

The application itself is fairly small, but a number of responsibilities are currently handled directly by the EC2 host. These responsibilities will need to be mapped to the new ECS platform rather than just copied into containers.

## Application

The application is a Python Flask API.

The production entry point is `app/wsgi.py`:

```text
Gunicorn
  |
app.wsgi
  |
Flask app
```

The application dependencies are currently:

```text
Flask==3.0.0
gunicorn==21.2.0
werkzeug==3.0.1
```

The application exposes the following endpoints:

```text
GET  /health
GET  /api/v1/products
GET  /api/v1/products/<id>
GET  /api/v1/orders
POST /api/v1/orders
GET  /api/v1/stats
```

The application also uses environment variables for:

```text
APP_NAME
APP_VERSION
ENVIRONMENT
```

These currently have default values in the application.

## Application State

One of the main migration concerns is that the application stores its data in memory.

Products are stored in a Python dictionary and orders are stored in a Python list. The order counter is also held in process memory.

This means the current application is stateful from the point of view of the process.

For example, if the application is restarted, the orders and any stock changes are lost.

This becomes more important with ECS because the service may eventually run more than one task. Separate tasks would have their own copy of the in-memory state, which could lead to inconsistent behaviour between tasks.

This needs to be considered during migration validation.

For this project, the goal is not to immediately redesign the application around a database. We need to understand and document the existing behaviour first and then decide whether any change is actually required for the migration.

## Gunicorn

Gunicorn is currently managed by systemd.

The current configuration uses:

```text
4 workers
sync worker class
60 second timeout
30 second graceful timeout
1000 max requests
100 max request jitter
INFO logging
```

Gunicorn listens on:

```text
127.0.0.1:5000
```

This works because Nginx and Gunicorn are running on the same EC2 instance.

In ECS, the networking model will be different, so the container will need to expose the application in a way that allows the ALB to reach it.

## Nginx

Nginx currently listens on port 80 and proxies requests to Gunicorn on port 5000.

It also handles:

- forwarding client and host headers
- proxy timeouts
- a 1 MB client body limit
- security response headers
- access logging
- error logging

The current Nginx configuration includes separate handling for `/health`, `/api/`, and the root path.

We should not automatically reproduce Nginx in ECS.

The ALB will eventually take over the public load balancing and health checking role, so part of the migration is deciding which current Nginx responsibilities are still required and which can be removed.

## systemd

systemd currently manages the Gunicorn process.

It is responsible for:

- starting the application
- restarting the application
- configuring the environment
- configuring Gunicorn
- managing application logging
- applying some host-level security settings

The service also uses:

```text
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
```

These settings are currently applied at the EC2 host level.

During the migration, we need to think about how the equivalent security and runtime controls are handled by Docker and ECS rather than assuming systemd will simply disappear without replacement.

## EC2 Setup

`scripts/setup.sh` is responsible for preparing the EC2 host.

The current process installs:

```text
Python 3.11
Python virtual environment
pip
Nginx
git
curl
wget
htop
unzip
```

It then:

1. Creates the application directory.
2. Creates the log directory.
3. Creates a Python virtual environment.
4. Installs the application dependencies.
5. Installs the Nginx configuration.
6. Installs the systemd service.
7. Starts the services.
8. Checks the service status.
9. Performs a health check.

This means the current deployment model depends heavily on configuring a mutable EC2 host.

One of the main improvements from containerisation will be moving the application runtime and its dependencies into an immutable container image instead.

## Logging

The legacy setup writes application logs to the EC2 filesystem.

Application logs are stored under:

```text
/var/log/flask-app/
```

Nginx logs are stored under:

```text
/var/log/nginx/
```

The ECS implementation will need to change this because containers are ephemeral and local container filesystems should not be treated as the permanent logging destination.

CloudWatch Logs will be used for the ECS workload.

## Legacy Infrastructure

The current Terraform configuration creates the legacy EC2 environment.

The main resources include:

```text
VPC
public subnet
private subnet
Internet Gateway
public route table
EC2 instance
Elastic IP
EC2 security group
EC2 IAM role
S3 bucket
Route 53 record (optional)
```

The EC2 instance downloads an application archive from S3 during startup and then runs the setup script.

This means S3 is currently part of the application deployment mechanism for the EC2 environment.

That mechanism is expected to be replaced by ECR and container images in the ECS architecture.

## IAM

The legacy environment uses an IAM role attached to the EC2 instance.

That role is given permission to download the application archive from S3.

The ECS architecture will need a different IAM model because the EC2 instance role will no longer be responsible for the application runtime.

The new environment should use separate ECS IAM roles with only the permissions actually required.

## Networking

The legacy environment uses a public subnet for the EC2 instance.

The Terraform also creates a private subnet, but the current application does not use ECS or private workload networking yet.

The target architecture will move the application tasks into private subnets and place the public ALB in public subnets.

This will also allow the security groups to be designed around the actual traffic flow instead of exposing the application directly to the internet.

## Provisioning Inconsistency

There is also an inconsistency in the existing Terraform and bootstrap configuration that needs to be understood.

The Terraform selects an Amazon Linux 2023 AMI, while the bootstrap scripts use `apt-get` and other Debian or Ubuntu style package management commands.

This should be treated as a legacy provisioning issue and not silently fixed as part of the migration.

The important question is whether the provided legacy setup is actually expected to run as-is or whether the environment used for the original application differs from the Terraform currently stored in the repository.

## FinOps Baseline

The legacy Terraform already uses provider-level default tags for:

```text
Project
Environment
ManagedBy
```

For the target ECS environment, we will extend this approach to use a consistent tag set:

```text
Project
Environment
ManagedBy
Owner
CostCenter
```

Tagging will be part of the infrastructure design from the start rather than something added during the final review.

The project will also consider cost when making architectural decisions. This includes avoiding unnecessary services, keeping temporary infrastructure short-lived, reviewing Fargate and ALB sizing, controlling log retention, and having a deliberate teardown process.

FinOps for this project is not only about tags. The aim is to understand what resources cost money, why they are needed, how long they need to exist, and whether a simpler or cheaper design would still meet the project requirements.

## Main Migration Risks Identified So Far

The main risks identified during the initial assessment are:

1. The application keeps state in memory.
2. Multiple ECS tasks could have different application state.
3. Restarting or replacing a task can lose in-memory data.
4. Nginx currently handles responsibilities that will need to be mapped to the ALB or container.
5. systemd currently controls Gunicorn lifecycle and runtime settings.
6. Logs currently depend on the EC2 filesystem.
7. The application deployment currently depends on mutable EC2 host configuration.
8. The current IAM model is tied to EC2 and S3.
9. The legacy networking model is not the same as the target private ECS architecture.
10. The Terraform and bootstrap scripts contain an OS and package manager mismatch.

## Migration Approach

The goal is not to recreate the EC2 environment inside Docker.

Instead, we want to preserve the application's required behaviour while moving the platform responsibilities to the services that are designed to handle them.

The rough mapping is:

```text
Legacy                          Target

EC2                             -> ECS Fargate
Nginx                           -> ALB
systemd                         -> ECS service/task lifecycle
EC2 filesystem logs             -> CloudWatch Logs
EC2 application archive         -> ECR container image
EC2 IAM role                    -> ECS IAM roles
public EC2 instance             -> private ECS tasks
host provisioning               -> Docker image build
```

The important part is validating this mapping rather than assuming the migration is successful just because the ECS service becomes healthy.

The ECS version needs to be compared with the legacy application and tested against the behaviours we identified here.

## CI/CD and DevSecOps Direction

The target project will use GitHub Actions with AWS OIDC rather than long-lived AWS credentials.

The intended delivery flow will include:

```text
Pull Request
  |
  +--> tests and validation
  |
  +--> container build
  |
  +--> SBOM generation
  |
  +--> vulnerability scanning
  |
  +--> ECR
  |
  +--> release candidate
  |
  +--> ECS deployment
  |
  +--> validation
  |
  +--> controlled traffic shift
  |
  +--> finalize or rollback
```

Grype will be used for container vulnerability scanning and Syft will be used for SBOM generation.

The goal is to understand container image security as part of the delivery lifecycle rather than treating infrastructure security as the only security concern.

## Migration Validation

The migration will use the legacy application as the behavioural baseline.

Before cutover, we should verify the ECS implementation against the known application behaviour, including:

- health endpoint
- product retrieval
- order creation
- stock updates
- error handling
- logging
- startup behaviour
- task health
- ALB target health

The in-memory state behaviour also needs to be explicitly tested because it is one of the biggest differences between running a single EC2 process and running an ECS service.

## Cutover and Rollback

The migration should run the legacy EC2 and ECS environments in parallel where appropriate.

ECS should be validated before receiving production traffic.

The cutover strategy will be selected based on the final architecture rather than automatically assuming Route 53 weighting is the correct solution.

The cutover plan should define:

- pre-migration validation
- ECS acceptance criteria
- traffic-shifting steps
- monitoring thresholds
- rollback triggers
- rollback steps
- observation period
- EC2 decommission criteria

Rollback must be tested rather than existing only as documentation.

## Bonus Scope

The project will aim to implement the bonus challenges that materially improve the migration story.

The current planned scope includes:

- Blue/Green ECS deployment
- Route 53 and ACM for HTTPS
- staging environment where cost-effective
- multi-AZ health monitoring
- a short-lived multi-region failover exercise

Redis/ElastiCache and a permanent multi-region deployment are intentionally out of scope because they add significant complexity and cost without being necessary to demonstrate the core migration skills.

Multi-region failover may still be demonstrated as a controlled exercise. The secondary environment should be created, validated, tested and then torn down rather than left running for the whole project.

## Documentation

The final documentation should explain the decisions made during the migration, not just list AWS services.

It should cover:

- legacy architecture
- target architecture
- application behaviour
- containerisation decisions
- networking
- security groups
- IAM and OIDC
- CI/CD
- image security and SBOMs
- observability
- autoscaling
- FinOps and tagging
- migration validation
- traffic cutover
- rollback
- troubleshooting
- testing
- cost decisions
- decommissioning
- lessons learned

Troubleshooting should be captured during the project so that important failures and tradeoffs are documented rather than reconstructed at the end.
