resource "aws_codepipeline" "codepipeline" {
  name     = "tf-pipeline-tarea-2"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"


  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github-connection.arn
        FullRepositoryId = "devsecops-jm-usach/tools-second-assignment"
        BranchName       = "main"
        DetectChanges    = "true"

      }
    }


  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build_task.name
      }
    }
  }


  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.my_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.my_deployment_group.deployment_group_name
      }
    }
  }
}

resource "aws_codedeploy_app" "my_app" {
  name = "my-codedeploy-app"
}

resource "aws_codedeploy_deployment_group" "my_deployment_group" {
  app_name              = aws_codedeploy_app.my_app.name
  deployment_group_name = "my-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_config_name = "CodeDeployDefault.OneAtATime"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "MyEC2Instance"
    }
  }
}

resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "codedeploy_policy" {
  name = "codedeploy-policy"
  role = aws_iam_role.codedeploy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "s3:Get*",
          "s3:List*",
          "autoscaling:Describe*",
          "cloudwatch:PutMetricData",
          "sns:Publish",
          "cloudformation:Describe*",
          "cloudformation:GetTemplate",
          "cloudformation:List*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}





resource "aws_codestarconnections_connection" "github-connection" {
  name          = "github-connection"
  provider_type = "GitHub"
  tags          = local.common_tags
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket_prefix = "codepipeline-"
  tags          = local.common_tags
  force_destroy = true

}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "test-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.github-connection.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:CreateDeploymentGroup",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:GetDeployment",
      "codedeploy:UpdateDeploymentGroup",
      "codedeploy:ListApplications",
      "codedeploy:ListDeploymentConfigs",
      "codedeploy:ListDeploymentGroups",
      "codedeploy:ListDeployments"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

# Obtener la última versión de Amazon Linux 2 AMI de forma dinámica
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    #values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    values = ["al2023-ami-2023.*"] # Pattern for Amazon Linux 2023 AMI  
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}


# Crear una instancia EC2
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  #key_name      = "my-key-pair" # Asegúrate de tener un key pair creado en AWS
  tags = {
    Name = "MyEC2Instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
              sudo wget -O /etc/yum.repos.d/microsoft-prod.repo https://packages.microsoft.com/config/fedora/37/prod.repo
              sudo dnf install -y dotnet-sdk-8.0
              sudo yum install -y ruby wget
              cd /home/ec2-user
              wget https://aws-codedeploy-us-west-2.s3.us-west-2.amazonaws.com/latest/install
              chmod +x ./install
              sudo ./install auto
              sudo service codedeploy-agent start

              EOF

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
}

# Crear un perfil de instancia para la instancia EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

# Crear un rol de IAM para la instancia EC2
resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Política de IAM para la instancia EC2
resource "aws_iam_role_policy" "ec2_instance_policy" {
  name = "ec2-instance-policy"
  role = aws_iam_role.ec2_instance_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*",
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_codebuild_project" "build_task" {
  name         = "codebuild_task_2"
  description  = "codebuild ejemplo"
  service_role = aws_iam_role.codebuild.arn
  tags         = local.common_tags

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }
}


data "aws_iam_policy_document" "code_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "codebuild_example"
  assume_role_policy = data.aws_iam_policy_document.code_assume_role.json
}

data "aws_iam_policy_document" "codebuild_example" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    sid = "SSOCodebuildAllow"

    actions = [
      "s3:*",
      "kms:*",
      "ssm:*",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "codebuild_example" {
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_example.json
}
