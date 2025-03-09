# AWS Provider version requirement
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Local variables for resource naming and tagging
locals {
  common_tags = {
    Project     = "AmiraWellness"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Component   = "Database"
  }
}

# Data sources
data "aws_kms_alias" "encryption_key" {
  name = "alias/amira-wellness-${var.environment}"
}

data "aws_kms_key" "by_id" {
  key_id = data.aws_kms_alias.encryption_key.target_key_id
}

data "aws_secretsmanager_secret" "database_credentials" {
  name = "amira-database-credentials-${var.environment}"
}

#######################
# PostgreSQL Resources
#######################

resource "aws_db_subnet_group" "postgresql" {
  name       = "${var.environment}-postgresql-subnet-group"
  subnet_ids = var.data_subnet_ids
  tags       = merge(local.common_tags, var.tags)
}

resource "aws_db_parameter_group" "postgresql" {
  name   = "${var.environment}-postgresql-params"
  family = "postgres13"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = merge(local.common_tags, var.tags)
}

resource "aws_db_instance" "postgresql" {
  identifier                  = "${var.environment}-postgresql"
  engine                      = "postgres"
  engine_version              = "13.7"
  instance_class              = var.db_instance_class
  allocated_storage           = var.db_allocated_storage
  storage_type                = "gp3"
  storage_encrypted           = true
  kms_key_id                  = data.aws_kms_key.by_id.arn
  db_name                     = var.db_name
  username                    = var.db_username
  password                    = var.db_password
  port                        = 5432
  vpc_security_group_ids      = [var.db_security_group_id]
  db_subnet_group_name        = aws_db_subnet_group.postgresql.name
  parameter_group_name        = aws_db_parameter_group.postgresql.name
  backup_retention_period     = var.db_backup_retention_period
  backup_window               = "03:00-04:00"
  maintenance_window          = "Mon:04:00-Mon:05:00"
  multi_az                    = var.db_multi_az
  skip_final_snapshot         = false
  final_snapshot_identifier   = "${var.environment}-postgresql-final-snapshot"
  deletion_protection         = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = true
  performance_insights_retention_period = 7
  copy_tags_to_snapshot       = true
  auto_minor_version_upgrade  = true
  apply_immediately           = false
  tags                        = merge(local.common_tags, var.tags)
}

#######################
# DocumentDB Resources
#######################

resource "aws_docdb_subnet_group" "documentdb" {
  name       = "${var.environment}-documentdb-subnet-group"
  subnet_ids = var.data_subnet_ids
  tags       = merge(local.common_tags, var.tags)
}

resource "aws_docdb_cluster_parameter_group" "documentdb" {
  family = "docdb4.0"
  name   = "${var.environment}-documentdb-params"

  parameter {
    name  = "tls"
    value = "enabled"
  }

  parameter {
    name  = "ttl_monitor"
    value = "enabled"
  }

  tags = merge(local.common_tags, var.tags)
}

resource "aws_docdb_cluster" "documentdb" {
  cluster_identifier              = "${var.environment}-documentdb"
  engine                          = "docdb"
  master_username                 = var.db_username
  master_password                 = var.db_password
  backup_retention_period         = var.db_backup_retention_period
  preferred_backup_window         = "03:00-04:00"
  preferred_maintenance_window    = "mon:04:00-mon:05:00"
  skip_final_snapshot             = false
  final_snapshot_identifier       = "${var.environment}-documentdb-final-snapshot"
  deletion_protection             = true
  storage_encrypted               = true
  kms_key_id                      = data.aws_kms_key.by_id.arn
  vpc_security_group_ids          = [var.db_security_group_id]
  db_subnet_group_name            = aws_docdb_subnet_group.documentdb.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.documentdb.name
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]
  tags                            = merge(local.common_tags, var.tags)
}

resource "aws_docdb_cluster_instance" "documentdb_instances" {
  count              = 2
  identifier         = "${var.environment}-documentdb-${count.index}"
  cluster_identifier = aws_docdb_cluster.documentdb.id
  instance_class     = "db.t3.medium"
  tags               = merge(local.common_tags, var.tags)
}

#######################
# ElastiCache Resources
#######################

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.environment}-redis-subnet-group"
  subnet_ids = var.data_subnet_ids
  tags       = merge(local.common_tags, var.tags)
}

resource "aws_elasticache_parameter_group" "redis" {
  name   = "${var.environment}-redis-params"
  family = "redis6.x"

  parameter {
    name  = "maxmemory-policy"
    value = "volatile-lru"
  }

  tags = merge(local.common_tags, var.tags)
}

resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.environment}-redis"
  description                = "Redis cluster for Amira Wellness"
  node_type                  = var.redis_node_type
  port                       = 6379
  parameter_group_name       = aws_elasticache_parameter_group.redis.name
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [var.db_security_group_id]
  automatic_failover_enabled = true
  multi_az_enabled           = true
  num_cache_clusters         = var.redis_num_cache_nodes
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result
  kms_key_id                 = data.aws_kms_key.by_id.arn
  snapshot_retention_limit   = 7
  snapshot_window            = "03:00-04:00"
  maintenance_window         = "mon:04:00-mon:05:00"
  auto_minor_version_upgrade = true
  apply_immediately          = false
  tags                       = merge(local.common_tags, var.tags)
}

#######################
# Monitoring Resources
#######################

resource "aws_sns_topic" "database_alarms" {
  name              = "${var.environment}-database-alarms"
  kms_master_key_id = data.aws_kms_key.by_id.arn
  tags              = merge(local.common_tags, var.tags)
}

resource "aws_cloudwatch_metric_alarm" "postgresql_cpu_alarm" {
  alarm_name          = "${var.environment}-postgresql-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "This metric monitors PostgreSQL CPU utilization"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgresql.id
  }
  alarm_actions = [aws_sns_topic.database_alarms.arn]
  ok_actions    = [aws_sns_topic.database_alarms.arn]
  tags          = merge(local.common_tags, var.tags)
}

resource "aws_cloudwatch_metric_alarm" "postgresql_memory_alarm" {
  alarm_name          = "${var.environment}-postgresql-memory-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 100000000  # 100MB in bytes
  alarm_description   = "This metric monitors PostgreSQL freeable memory"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgresql.id
  }
  alarm_actions = [aws_sns_topic.database_alarms.arn]
  ok_actions    = [aws_sns_topic.database_alarms.arn]
  tags          = merge(local.common_tags, var.tags)
}

resource "aws_cloudwatch_metric_alarm" "documentdb_cpu_alarm" {
  alarm_name          = "${var.environment}-documentdb-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/DocDB"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "This metric monitors DocumentDB CPU utilization"
  dimensions = {
    DBClusterIdentifier = aws_docdb_cluster.documentdb.id
  }
  alarm_actions = [aws_sns_topic.database_alarms.arn]
  ok_actions    = [aws_sns_topic.database_alarms.arn]
  tags          = merge(local.common_tags, var.tags)
}

resource "aws_cloudwatch_metric_alarm" "redis_cpu_alarm" {
  alarm_name          = "${var.environment}-redis-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "This metric monitors Redis CPU utilization"
  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.redis.id
  }
  alarm_actions = [aws_sns_topic.database_alarms.arn]
  ok_actions    = [aws_sns_topic.database_alarms.arn]
  tags          = merge(local.common_tags, var.tags)
}

#######################
# Secrets Management
#######################

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = data.aws_secretsmanager_secret.database_credentials.id
  secret_string = jsonencode({
    "postgresql": {
      "username": "${var.db_username}",
      "password": "${var.db_password}",
      "engine": "postgres",
      "host": "${aws_db_instance.postgresql.address}",
      "port": ${aws_db_instance.postgresql.port},
      "dbname": "${var.db_name}"
    },
    "documentdb": {
      "username": "${var.db_username}",
      "password": "${var.db_password}",
      "engine": "documentdb",
      "host": "${aws_docdb_cluster.documentdb.endpoint}",
      "port": ${aws_docdb_cluster.documentdb.port}
    },
    "redis": {
      "host": "${aws_elasticache_replication_group.redis.primary_endpoint_address}",
      "port": ${aws_elasticache_replication_group.redis.port},
      "auth_token": "${random_password.redis_auth_token.result}"
    }
  })
}