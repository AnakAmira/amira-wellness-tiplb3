---
title: Backend Deployment Guide
---

## Introduction
This document provides comprehensive instructions for deploying the Amira Wellness backend services to AWS cloud infrastructure. The backend consists of several microservices that support the core functionality of the application, including voice journaling, emotional tracking, tool library, and progress tracking.

The deployment approach follows these key principles:

- **Infrastructure as Code**: All infrastructure is defined using Terraform for reproducibility and version control
- **Containerization**: Services are packaged as Docker containers for consistency across environments
- **CI/CD Automation**: Deployment is automated through GitHub Actions workflows
- **Environment Isolation**: Clear separation between development, staging, and production environments
- **Security First**: Comprehensive security controls at all layers of the stack
- **Observability**: Robust monitoring and logging for operational visibility

This guide is intended for DevOps engineers and system administrators responsible for deploying and maintaining the Amira Wellness backend infrastructure.

## Prerequisites
Before beginning the deployment process, ensure the following prerequisites are met:

### AWS Account and Access

- AWS account with administrative access
- AWS CLI installed and configured with appropriate credentials
- IAM user or role with necessary permissions for resource creation

### Tools and Software

- Terraform v1.5.0 or later
- Docker v20.10.0 or later
- Git client
- GitHub account with access to the Amira Wellness repository
- Python 3.11 or later (for running deployment scripts)

### Domain and Certificates

- Registered domain name (if using custom domain)
- SSL certificates (can be provisioned through AWS ACM)

### Security and Compliance

- Understanding of security requirements and compliance considerations
- Access to encryption keys and secrets management
- Familiarity with AWS security best practices

### Knowledge Prerequisites

- Basic understanding of AWS services (ECS, RDS, S3, etc.)
- Familiarity with Docker and containerization concepts
- Understanding of CI/CD principles
- Knowledge of the Amira Wellness backend architecture

## Containerization
The Amira Wellness backend services are containerized using Docker to ensure consistency across environments and simplify deployment. This section covers the containerization approach and best practices.

### Docker Image Structure

The backend services use a multi-stage build process to create optimized, secure container images:

```dockerfile
# Stage 1: Builder
FROM python:3.11-slim AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    ffmpeg \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser \
    && mkdir -p /app/data /var/log/supervisor \
    && chown -R appuser:appuser /app /var/log/supervisor

# Stage 2: Final
FROM python:3.11-slim

# Build arguments
ARG APP_ENV=production

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/app:$PATH \
    APP_ENV=${APP_ENV}

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    ffmpeg \
    curl \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /app /app/data /var/log/supervisor

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser \
    && chown -R appuser:appuser /app /var/log/supervisor

# Copy application from builder stage
COPY --from=builder --chown=appuser:appuser /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder --chown=appuser:appuser /usr/local/bin /usr/local/bin
COPY --from=builder --chown=appuser:appuser /app /app

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set working directory
WORKDIR /app

# Expose port
EXPOSE 8000

# Set user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/api/v1/health || exit 1

# Run supervisor to manage application processes
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
```

### Security Hardening

The Docker images include several security hardening measures:

- **Multi-stage builds**: Reduces attack surface by excluding build tools from final image
- **Non-root user**: Runs as unprivileged user (appuser) to limit potential damage from container breakout
- **Minimal dependencies**: Installs only necessary runtime packages
- **Health checks**: Implements container health checks for monitoring
- **Secure defaults**: Sets secure environment variables and configurations

### Image Tagging Strategy

Container images follow a consistent tagging strategy:

- `latest`: Points to the most recent stable build
- `{commit-hash}`: Unique identifier for each build (first 7 characters of Git commit hash)
- `{version}`: Semantic version for release builds (e.g., v1.2.3)

### Building Images Locally

To build the Docker image locally:

```bash
# Navigate to the backend directory
cd src/backend

# Build the image
docker build -t amira-wellness/backend:local .

# Run the container locally
docker run -p 8000:8000 \
  -e DATABASE_URL=postgresql://user:password@host:5432/dbname \
  -e SECRET_KEY=your_secret_key \
  amira-wellness/backend:local
```

### Container Registry

Production images are stored in Amazon Elastic Container Registry (ECR). The CI/CD pipeline automatically builds and pushes images to ECR when changes are merged to the main branch.

## Infrastructure Setup
The Amira Wellness backend infrastructure is provisioned using Terraform to ensure consistency, version control, and reproducibility. This section covers the infrastructure setup process.

### Infrastructure Architecture

```mermaid
flowchart TD
    subgraph "Networking"
        VPC[VPC]
        PublicSubnets[Public Subnets]
        PrivateSubnets[Private Subnets]
        DataSubnets[Data Subnets]
        IGW[Internet Gateway]
        NAT[NAT Gateway]
        ALB[Application Load Balancer]
    end
    
    subgraph "Compute"
        ECS[ECS Cluster]
        Services[ECS Services]
        TaskDefs[Task Definitions]
        AutoScaling[Auto Scaling]
    end
    
    subgraph "Storage"
        S3[S3 Buckets]
        RDS[PostgreSQL RDS]
        DocumentDB[MongoDB DocumentDB]
        ElastiCache[Redis ElastiCache]
    end
    
    subgraph "Security"
        KMS[KMS Keys]
        Cognito[Cognito User Pool]
        IAM[IAM Roles]
        WAF[WAF Rules]
        SecurityGroups[Security Groups]
    end
    
    subgraph "Monitoring"
        CloudWatch[CloudWatch]
        Alarms[CloudWatch Alarms]
        Dashboard[CloudWatch Dashboard]
        Logs[CloudWatch Logs]
    end
    
    VPC --> PublicSubnets
    VPC --> PrivateSubnets
    VPC --> DataSubnets
    PublicSubnets --> IGW
    PublicSubnets --> ALB
    PublicSubnets --> NAT
    PrivateSubnets --> NAT
    PrivateSubnets --> ECS
    DataSubnets --> RDS
    DataSubnets --> DocumentDB
    DataSubnets --> ElastiCache
    
    ECS --> Services
    Services --> TaskDefs
    Services --> AutoScaling
    
    SecurityGroups --> ALB
    SecurityGroups --> ECS
    SecurityGroups --> RDS
    SecurityGroups --> DocumentDB
    SecurityGroups --> ElastiCache
    
    KMS --> S3
    KMS --> RDS
    
    ALB --> WAF
    
    ECS --> CloudWatch
    RDS --> CloudWatch
    S3 --> CloudWatch
    CloudWatch --> Alarms
    CloudWatch --> Dashboard
    CloudWatch --> Logs
```

### Terraform Structure

The Terraform configuration is organized into modules for maintainability:

```
infrastructure/terraform/
├── main.tf                # Main configuration file
├── variables.tf           # Input variables
├── outputs.tf             # Output values
├── providers.tf           # Provider configuration
├── modules/
│   ├── networking/        # VPC, subnets, security groups
│   ├── compute/           # ECS cluster and services
│   ├── database/          # RDS, DocumentDB, ElastiCache
│   ├── storage/           # S3 buckets and policies
│   └── security/          # IAM, KMS, Cognito, WAF
└── environments/
    ├── dev/               # Development environment
    ├── staging/           # Staging environment
    └── prod/              # Production environment
```

### Provisioning Infrastructure

To provision the infrastructure:

```bash
# Navigate to the environment directory
cd infrastructure/terraform/environments/[env]

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Apply the changes
terraform apply tfplan
```

### Environment-Specific Configuration

Each environment (dev, staging, prod) has its own configuration values in `terraform.tfvars`:

```hcl
# Example terraform.tfvars for production
environment         = "production"
primary_region      = "us-east-1"
secondary_region    = "us-west-2"
tertiary_region     = "eu-west-1"

app_name            = "amira-wellness"
domain_name         = "amirawellness.com"

vpc_cidr            = "10.0.0.0/16"
app_port            = 8000

db_name             = "amira_production"
db_username         = "amira_admin"
db_instance_class   = "db.t3.medium"
db_allocated_storage = 100
db_multi_az         = true

redis_node_type     = "cache.t3.medium"
redis_num_cache_nodes = 2

app_count           = 3
fargate_cpu         = 1024
fargate_memory      = 2048

enable_monitoring   = true
waf_enabled         = true
shield_enabled      = true

tags = {
  Project     = "AmiraWellness"
  Environment = "production"
  ManagedBy   = "Terraform"
}
```

### Multi-Region Considerations

The infrastructure supports multi-region deployment for high availability and data residency requirements:

- **Primary Region**: Hosts the main application infrastructure
- **Secondary Region**: Provides disaster recovery capabilities
- **Tertiary Region**: Supports data residency requirements for specific regions

### Infrastructure Security

Security measures implemented at the infrastructure level include:

- **Network Segmentation**: VPC with public, private, and data subnets
- **Security Groups**: Restrictive inbound/outbound rules
- **IAM Roles**: Least privilege principle for service access
- **KMS Encryption**: Encryption for data at rest
- **WAF Protection**: Web application firewall for API endpoints
- **Shield Protection**: DDoS protection for critical resources

## CI/CD Pipeline
The Amira Wellness backend uses GitHub Actions for continuous integration and deployment. This section describes the CI/CD pipeline configuration and workflow.

### CI Workflow

The continuous integration workflow runs on every pull request and push to the main branch:

```mermaid
flowchart TD
    A[Code Push/PR] --> B[Lint]
    B --> C[Unit Tests]
    B --> D[Security Scan]
    C --> E{Tests Pass?}
    D --> F{Security Pass?}
    E -->|Yes| G[Build Docker Image]
    F -->|Yes| G
    E -->|No| H[Fail Build]
    F -->|No| H
    G --> I{Main Branch?}
    I -->|Yes| J[Push to Registry]
    I -->|No| K[Skip Push]
```

The CI workflow is defined in `.github/workflows/backend-ci.yml` and includes the following steps:

1. **Linting**: Checks code style and quality using flake8, black, isort, and mypy
2. **Unit Tests**: Runs unit tests with pytest and ensures 90% code coverage
3. **Security Scan**: Performs security scanning with Bandit and Safety
4. **Build**: Builds the Docker image using multi-stage build
5. **Push**: Pushes the image to the container registry (only on main branch)

### CD Workflow

The continuous deployment workflow deploys to production on a scheduled basis or manual trigger:

```mermaid
flowchart TD
    A[Scheduled/Manual Trigger] --> B[Verify Deployment Window]
    B --> C[Create Backup]
    C --> D[Approval Gate]
    D --> E[Deploy Infrastructure]
    E --> F[Deploy Backend]
    F --> G[Run Smoke Tests]
    F --> H[Run Security Verification]
    G --> I{Tests Pass?}
    H --> J{Security Pass?}
    I -->|Yes| K[Finalize Deployment]
    J -->|Yes| K
    I -->|No| L[Rollback]
    J -->|No| L
    K --> M[Notify Success]
    L --> N[Notify Failure]
```

The CD workflow is defined in `.github/workflows/deploy-production.yml` and includes the following steps:

1. **Verify Deployment Window**: Ensures deployment occurs during approved maintenance windows
2. **Create Backup**: Creates database snapshots and backups before deployment
3. **Approval Gate**: Requires explicit approval from authorized personnel
4. **Deploy Infrastructure**: Updates infrastructure using Terraform
5. **Deploy Backend**: Deploys the latest Docker image to ECS
6. **Run Tests**: Performs smoke tests and security verification
7. **Finalize/Rollback**: Completes deployment or rolls back on failure
8. **Notify**: Sends notifications about deployment status

### Environment Promotion Strategy

Code changes follow a structured promotion path through environments:

```mermaid
flowchart LR
    A[Feature Branch] --> B[Pull Request]
    B --> C[Main Branch]
    C --> D[Development]
    D --> E[Staging]
    E --> F[Production]
```

1. **Development**: Automatic deployment on merge to main branch
2. **Staging**: Scheduled deployment (daily) with automated testing
3. **Production**: Scheduled deployment (weekly) with approval gate

### Rollback Procedures

In case of deployment failures, the system supports automated and manual rollback:

- **Automated Rollback**: The CD workflow automatically rolls back on test failures
- **Manual Rollback**: Operators can trigger rollback through GitHub Actions

Rollback steps include:

1. Redeploying the previous ECS task definition
2. Restoring database from pre-deployment snapshot if needed
3. Reverting infrastructure changes if applicable
4. Verifying system stability after rollback

### Secrets Management

Sensitive information is managed securely using GitHub Secrets and AWS Secrets Manager:

- **GitHub Secrets**: Used for CI/CD authentication and access
- **AWS Secrets Manager**: Used for application secrets and credentials

No sensitive information is stored in the repository or container images.

## Kubernetes Deployment
In addition to AWS ECS, the Amira Wellness backend can be deployed to Kubernetes clusters. This section covers the Kubernetes deployment configuration and process.

### Kubernetes Architecture

```mermaid
flowchart TD
    subgraph "Kubernetes Cluster"
        Ingress[Ingress Controller]
        Service[Backend Service]
        Deployment[Backend Deployment]
        ConfigMap[ConfigMap]
        Secret[Secrets]
        PVC[Persistent Volume Claim]
    end
    
    subgraph "External Resources"
        DB[External Database]
        Redis[External Redis]
        S3[External S3]
    end
    
    Ingress --> Service
    Service --> Deployment
    Deployment --> ConfigMap
    Deployment --> Secret
    Deployment --> PVC
    Deployment --> DB
    Deployment --> Redis
    Deployment --> S3
```

### Deployment Configuration

The backend deployment is defined in `infrastructure/kubernetes/backend-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: amira-backend
  namespace: amira-wellness
  labels:
    app: amira-backend
    component: api
    part-of: amira-wellness
  annotations:
    kubernetes.io/description: "Amira Wellness Backend API Services"
    prometheus.io/scrape: "true"
    prometheus.io/port: "8000"
    prometheus.io/path: "/api/v1/metrics"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: amira-backend
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: amira-backend
        component: api
        part-of: amira-wellness
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8000"
        prometheus.io/path: "/api/v1/metrics"
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      containers:
      - name: api
        image: amira-wellness/backend:latest
        imagePullPolicy: Always
        ports:
        - name: http
          containerPort: 8000
          protocol: TCP
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop: ["ALL"]
        livenessProbe:
          httpGet:
            path: /api/v1/health
            port: http
          initialDelaySeconds: 60
          periodSeconds: 30
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /api/v1/health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /api/v1/health
            port: http
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 12
        envFrom:
        - configMapRef:
            name: amira-backend-config
        - secretRef:
            name: amira-backend-secrets
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: data
          mountPath: /app/data
        - name: logs
          mountPath: /var/log/supervisor
      volumes:
      - name: tmp
        emptyDir: {}
      - name: data
        persistentVolumeClaim:
          claimName: amira-backend-data
      - name: logs
        emptyDir: {}
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - amira-backend
              topologyKey: kubernetes.io/hostname
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values:
                - amd64
                - arm64
      terminationGracePeriodSeconds: 60
```

### Service Configuration

The service that exposes the deployment is defined in `infrastructure/kubernetes/backend-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: amira-backend
  namespace: amira-wellness
  labels:
    app: amira-backend
    component: api
    part-of: amira-wellness
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: amira-backend
```

### ConfigMap and Secrets

Configuration is managed through ConfigMaps and Secrets:

```yaml
# ConfigMap for non-sensitive configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: amira-backend-config
  namespace: amira-wellness
data:
  APP_ENV: "production"
  LOG_LEVEL: "INFO"
  ALLOWED_HOSTS: "*"
  CORS_ORIGINS: "https://amirawellness.com,https://www.amirawellness.com"
  API_VERSION: "v1"

# Secret for sensitive configuration
apiVersion: v1
kind: Secret
metadata:
  name: amira-backend-secrets
  namespace: amira-wellness
type: Opaque
data:
  DATABASE_URL: base64-encoded-value
  REDIS_URL: base64-encoded-value
  SECRET_KEY: base64-encoded-value
  AWS_ACCESS_KEY_ID: base64-encoded-value
  AWS_SECRET_ACCESS_KEY: base64-encoded-value
  S3_BUCKET_NAME: base64-encoded-value
```

### Deploying to Kubernetes

To deploy to a Kubernetes cluster:

```bash
# Create namespace
kubectl create namespace amira-wellness

# Apply ConfigMap and Secrets
kubectl apply -f infrastructure/kubernetes/backend-configmap.yaml
kubectl apply -f infrastructure/kubernetes/backend-secret.yaml

# Apply PVC
kubectl apply -f infrastructure/kubernetes/backend-pvc.yaml

# Apply Deployment and Service
kubectl apply -f infrastructure/kubernetes/backend-deployment.yaml
kubectl apply -f infrastructure/kubernetes/backend-service.yaml

# Apply Ingress
kubectl apply -f infrastructure/kubernetes/backend-ingress.yaml
```

### Kubernetes-Specific Considerations

- **Horizontal Pod Autoscaler**: Configure HPA for automatic scaling based on CPU/memory usage
- **Network Policies**: Implement network policies for pod-to-pod communication security
- **Pod Disruption Budget**: Define PDB to ensure availability during cluster operations
- **Resource Quotas**: Set namespace resource quotas to prevent resource exhaustion
- **Pod Security Policies**: Implement PSPs for enhanced security controls

## Environment Configuration
Proper environment configuration is essential for the Amira Wellness backend to function correctly. This section covers environment variables, configuration management, and environment-specific settings.

### Environment Variables

The backend services use environment variables for configuration. Key environment variables include:

| Variable | Description | Example |
|----------|-------------|--------|
| `APP_ENV` | Application environment | `production` |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:5432/dbname` |
| `REDIS_URL` | Redis connection string | `redis://host:6379/0` |
| `SECRET_KEY` | Secret key for security | `random-secure-string` |
| `AWS_ACCESS_KEY_ID` | AWS access key | `AKIAXXXXXXXXXXXXXXXX` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| `AWS_REGION` | AWS region | `us-east-1` |
| `S3_BUCKET_NAME` | S3 bucket for audio storage | `amira-audio-production` |
| `LOG_LEVEL` | Logging level | `INFO` |
| `ALLOWED_HOSTS` | Allowed host headers | `api.amirawellness.com` |
| `CORS_ORIGINS` | Allowed CORS origins | `https://amirawellness.com` |
| `API_VERSION` | API version | `v1` |
| `WORKERS` | Number of Gunicorn workers | `4` |
| `TIMEOUT` | Request timeout in seconds | `120` |
| `MAX_REQUESTS` | Maximum requests per worker | `1000` |
| `ENABLE_METRICS` | Enable Prometheus metrics | `true` |
| `ENABLE_PROFILING` | Enable performance profiling | `false` |

### Configuration Management

Configuration is managed differently based on the deployment platform:

#### AWS ECS

- **Task Definition**: Environment variables defined in ECS task definition
- **Secrets**: Sensitive values stored in AWS Secrets Manager and referenced in task definition
- **Parameter Store**: Non-sensitive configuration stored in AWS Parameter Store

#### Kubernetes

- **ConfigMap**: Non-sensitive configuration stored in ConfigMaps
- **Secrets**: Sensitive configuration stored in Kubernetes Secrets
- **Environment Variables**: Mounted from ConfigMaps and Secrets

### Environment-Specific Settings

Each environment has specific configuration values:

#### Development

```
APP_ENV=development
LOG_LEVEL=DEBUG
ALLOWED_HOSTS=*
CORS_ORIGINS=*
```

#### Staging

```
APP_ENV=staging
LOG_LEVEL=INFO
ALLOWED_HOSTS=api-staging.amirawellness.com
CORS_ORIGINS=https://staging.amirawellness.com
```

#### Production

```
APP_ENV=production
LOG_LEVEL=INFO
ALLOWED_HOSTS=api.amirawellness.com
CORS_ORIGINS=https://amirawellness.com,https://www.amirawellness.com
```

### Feature Flags

Feature flags are used to enable/disable features in different environments:

```python
# Example feature flag configuration
FEATURE_FLAGS = {
    "enable_new_recommendation_engine": {
        "development": True,
        "staging": True,
        "production": False
    },
    "enable_advanced_analytics": {
        "development": True,
        "staging": True,
        "production": True
    }
}
```

Feature flags can be managed through:

- Environment variables
- Configuration files
- Remote configuration service (future enhancement)

### Secrets Rotation

Sensitive credentials and secrets should be rotated regularly:

- **Database Credentials**: Rotate every 90 days
- **API Keys**: Rotate every 90 days
- **Encryption Keys**: Rotate yearly with proper key transition

The `scripts/encryption-key-rotation.py` script automates the encryption key rotation process.

## Database Migration
Database migrations are a critical part of the deployment process. This section covers the migration strategy, tools, and procedures.

### Migration Framework

The Amira Wellness backend uses Alembic for database migrations, which provides:

- Version-controlled schema changes
- Automatic migration generation
- Forward and backward migrations
- Dependency management between migrations

### Migration Directory Structure

```
src/backend/migrations/
├── env.py                # Migration environment configuration
├── script.py.mako        # Migration script template
├── versions/             # Migration version files
│   ├── 001_initial.py    # Initial schema
│   ├── 002_add_user_preferences.py
│   └── ...
└── alembic.ini           # Alembic configuration
```

### Creating Migrations

To create a new migration:

```bash
# Navigate to the backend directory
cd src/backend

# Create a new migration
alembic revision --autogenerate -m "description_of_changes"
```

This generates a new migration file in the `migrations/versions/` directory with automatically detected schema changes.

### Running Migrations

Migrations are applied during the deployment process:

```bash
# Apply all pending migrations
alembic upgrade head

# Apply specific migration
alembic upgrade <revision>

# Rollback to previous migration
alembic downgrade -1

# Rollback to specific migration
alembic downgrade <revision>
```

### Migration Safety Measures

To ensure safe migrations, the following practices are implemented:

1. **Pre-migration Validation**: Verify migration safety before applying
2. **Database Backup**: Create a backup before applying migrations
3. **Dry Run**: Test migrations in a staging environment first
4. **Rollback Plan**: Ensure each migration has a working downgrade path
5. **Transaction Wrapping**: Wrap migrations in transactions where possible

### Data Migration

For complex data migrations that can't be handled by schema changes alone:

1. Create a separate data migration script
2. Test thoroughly in staging environment
3. Consider performance impact for large datasets
4. Implement batching for large data migrations
5. Monitor database performance during migration

### Migration in CI/CD Pipeline

Migrations are integrated into the CI/CD pipeline:

1. **CI Phase**: Validate migrations against test database
2. **Deployment Phase**: Apply migrations before deploying new application version
3. **Rollback Phase**: Revert migrations if deployment fails

The `scripts/db-migration-helper.sh` script automates migration tasks in the CI/CD pipeline.

## Monitoring and Logging
Comprehensive monitoring and logging are essential for operating the Amira Wellness backend reliably. This section covers the monitoring and logging setup.

### Monitoring Architecture

```mermaid
flowchart TD
    subgraph "Data Sources"
        A[Application Metrics]
        B[Infrastructure Metrics]
        C[Database Metrics]
        D[API Metrics]
    end
    
    subgraph "Collection"
        E[CloudWatch Agent]
        F[Custom Metrics]
        G[X-Ray Traces]
        H[CloudWatch Logs]
    end
    
    subgraph "Storage"
        I[CloudWatch Metrics]
        J[CloudWatch Logs]
        K[X-Ray Traces]
    end
    
    subgraph "Visualization"
        L[CloudWatch Dashboards]
        M[X-Ray Console]
        N[Custom Dashboards]
    end
    
    subgraph "Alerting"
        O[CloudWatch Alarms]
        P[SNS Notifications]
        Q[PagerDuty]
    end
    
    A --> E
    A --> F
    B --> E
    C --> E
    D --> F
    D --> G
    
    E --> I
    E --> J
    F --> I
    G --> K
    
    H --> K
    I --> L
    I --> O
    J --> L
    
    O --> P
    P --> Q
```

### Key Metrics

The following key metrics are monitored:

| Metric Category | Specific Metrics | Threshold | Alert Severity |
|-----------------|------------------|-----------|----------------|
| API Performance | Response time | p95 > 500ms | Warning |
| API Performance | Error rate | > 1% | Critical |
| System Resources | CPU utilization | > 70% | Warning |
| System Resources | Memory utilization | > 80% | Warning |
| Database | Query performance | p95 > 100ms | Warning |
| Database | Connection count | > 80% capacity | Warning |
| Application | Authentication failures | > 10 in 5 minutes | Critical |
| Application | Failed journal uploads | > 5 in 15 minutes | Warning |

### CloudWatch Dashboards

Custom CloudWatch dashboards provide visibility into system performance:

1. **Operations Dashboard**: Overall system health and performance
2. **API Dashboard**: API performance, request rates, and errors
3. **Database Dashboard**: Database performance and utilization
4. **Application Dashboard**: Application-specific metrics and business KPIs

### Logging Strategy

The logging strategy includes:

1. **Structured Logging**: JSON-formatted logs for machine parsing
2. **Log Levels**: Appropriate log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
3. **Contextual Information**: Request IDs, user IDs (anonymized), and timestamps
4. **Centralized Collection**: All logs sent to CloudWatch Logs
5. **Log Retention**: Retention policies based on log importance

### Log Categories

| Log Category | Content | Retention | Privacy Considerations |
|--------------|---------|-----------|------------------------|
| Application Logs | Application events and errors | 30 days | No PII, anonymized user IDs |
| Access Logs | API requests and responses | 90 days | No request/response bodies, anonymized IPs |
| Security Logs | Authentication events, security alerts | 1 year | No sensitive data, anonymized identifiers |
| Performance Logs | Performance metrics and timings | 30 days | No user data |

### Distributed Tracing

AWS X-Ray is used for distributed tracing:

1. **Request Tracing**: End-to-end request tracking across services
2. **Performance Analysis**: Identifying bottlenecks and slow components
3. **Error Tracking**: Tracing error propagation through the system
4. **Service Map**: Visualizing service dependencies and interactions

### Alerting Configuration

Alerts are configured based on metric thresholds:

1. **Warning Alerts**: Sent to Slack channel for team awareness
2. **Critical Alerts**: Sent to PagerDuty for immediate response
3. **Business Alerts**: Sent to stakeholders for business impact awareness

Alert routing follows an escalation path:

1. On-call engineer receives initial alert
2. If not acknowledged within 15 minutes, escalate to backup on-call
3. If still not acknowledged, escalate to engineering manager

## Scaling and Performance
The Amira Wellness backend is designed to scale horizontally to accommodate growing user demand. This section covers scaling strategies and performance optimization.

### Scaling Dimensions

The system can scale along multiple dimensions:

```mermaid
flowchart TD
    A[Scaling Dimensions] --> B[Horizontal Scaling]
    A --> C[Vertical Scaling]
    A --> D[Data Scaling]
    A --> E[Geographic Scaling]
    
    B --> F[Increase Instance Count]
    B --> G[Load Balancing]
    
    C --> H[Increase Instance Size]
    C --> I[Resource Allocation]
    
    D --> J[Database Scaling]
    D --> K[Storage Scaling]
    
    E --> L[Multi-Region Deployment]
    E --> M[Content Distribution]
```

### Auto-Scaling Configuration

Auto-scaling is configured for ECS services:

```json
{
  "min_capacity": 2,
  "max_capacity": 10,
  "scaling_policies": [
    {
      "policy_name": "cpu-tracking",
      "policy_type": "TargetTrackingScaling",
      "target_value": 70.0,
      "predefined_metric": "ECSServiceAverageCPUUtilization",
      "scale_in_cooldown": 300,
      "scale_out_cooldown": 60
    },
    {
      "policy_name": "memory-tracking",
      "policy_type": "TargetTrackingScaling",
      "target_value": 70.0,
      "predefined_metric": "ECSServiceAverageMemoryUtilization",
      "scale_in_cooldown": 300,
      "scale_out_cooldown": 60
    }
  ]
}