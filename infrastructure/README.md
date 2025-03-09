# Amira Wellness Infrastructure

This directory contains all infrastructure configuration and deployment scripts for the Amira Wellness application. The infrastructure is designed with security, scalability, and high availability as primary concerns, particularly given the privacy-focused nature of the application.

## Overview

Amira Wellness uses a cloud-native infrastructure deployed on AWS with the following key components:

- **Terraform** for Infrastructure as Code (IaC)
- **Docker** for containerization
- **Amazon ECS** for container orchestration
- **AWS S3** for secure audio storage
- **AWS RDS** for relational database
- **AWS ElastiCache** for caching
- **AWS CloudFront** for content delivery
- **AWS Cognito** for authentication

## Directory Structure

```
infrastructure/
├── terraform/           # Terraform IaC configurations
│   ├── modules/         # Reusable Terraform modules
│   └── environments/    # Environment-specific configurations
├── kubernetes/          # Kubernetes manifests (for optional K8s deployment)
├── aws/                 # AWS-specific configurations and scripts
│   ├── cloudformation/  # CloudFormation templates
│   └── scripts/         # AWS utility scripts
└── docker/              # Docker configurations
```

## Getting Started

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform v1.0+ installed
- Docker installed
- kubectl installed (if using Kubernetes option)

### Environment Setup

1. Clone the repository
2. Navigate to the infrastructure directory
3. Initialize Terraform:

```bash
cd terraform
terraform init
```

4. Create a new workspace for your environment:

```bash
terraform workspace new dev|staging|prod
```

5. Apply the Terraform configuration:

```bash
terraform apply -var-file=environments/dev/terraform.tfvars
```

## Deployment Environments

### Development

The development environment is designed for feature development and testing. It uses smaller instance sizes and reduced redundancy to minimize costs while still providing a representative environment.

### Staging

The staging environment mirrors the production setup but with reduced capacity. It's used for pre-release validation, performance testing, and user acceptance testing.

### Production

The production environment is designed for high availability and scalability with multi-region deployment, automated failover, and comprehensive monitoring.

## Security Considerations

The infrastructure implements several security measures:

- End-to-end encryption for sensitive data
- Network segmentation with private subnets
- WAF and Shield for DDoS protection
- KMS for encryption key management
- IAM roles with least privilege principle
- VPC flow logs and CloudTrail for audit logging

## Disaster Recovery

The disaster recovery strategy includes:

- Multi-AZ deployment for high availability
- Cross-region replication for critical data
- Automated backups with point-in-time recovery
- Defined RTO (Recovery Time Objective) and RPO (Recovery Point Objective)
- Documented recovery procedures in case of region failure

## Monitoring and Alerting

The infrastructure includes comprehensive monitoring:

- CloudWatch for metrics, logs, and alarms
- X-Ray for distributed tracing
- Prometheus and Grafana for visualization (Kubernetes option)
- PagerDuty integration for critical alerts

## Cost Optimization

Cost optimization strategies include:

- Reserved Instances for baseline capacity
- Spot Instances for non-critical workloads
- Auto-scaling based on demand
- S3 lifecycle policies for storage optimization
- CloudFront caching to reduce origin requests

## Maintenance Procedures

### Backup and Restore

Database backups are performed daily with transaction logs for point-in-time recovery. The `infrastructure/aws/scripts/backup-db.sh` and `infrastructure/aws/scripts/restore-db.sh` scripts can be used for manual backup and restore operations.

### Infrastructure Updates

Infrastructure updates should follow the GitOps workflow:

1. Create a branch for your changes
2. Make changes to the Terraform configurations
3. Submit a pull request for review
4. After approval, apply changes through the CI/CD pipeline

### Scaling Procedures

The infrastructure is designed to scale automatically based on defined metrics. Manual scaling can be performed through the AWS console or by updating the Terraform configurations.

## Troubleshooting

### Common Issues

- **Deployment Failures**: Check CloudFormation or Terraform logs for specific errors
- **Container Issues**: Review ECS task logs in CloudWatch
- **Database Connectivity**: Verify security group rules and network ACLs
- **Performance Problems**: Check CloudWatch metrics for resource utilization

### Support

For infrastructure-related issues, contact the DevOps team through the #infrastructure Slack channel or create an issue in the GitHub repository.

## Contributing

When contributing to the infrastructure:

1. Follow the infrastructure coding standards
2. Include documentation for any new components
3. Ensure changes are tested in development before promoting to staging
4. Consider security implications of all changes

## License

This infrastructure code is subject to the same license as the main project.