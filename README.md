# AUPP LMS DevOps CI/CD Pipeline (Jenkins + SonarQube + Trivy + Docker + Terraform + Prometheus + Grafana)

---

## Project Overview

This project implements a complete **CI/CD pipeline** for AUPP's internal Learning Management System (LMS) platform (similar to Canvas LMS).  
The goal is to ensure:

- Fast feature delivery  
- Secure deployments  
- Automated infrastructure provisioning  
- Real-time monitoring  

The CI/CD pipeline is implemented using **Jenkins**, with integrations including:

- SonarQube (Code Quality)
- Trivy (Security Scanning)
- Docker (Containerization)
- Terraform (Infrastructure as Code)
- AWS EC2 (Deployment Target)
- Prometheus + Grafana (Monitoring & Dashboard)

---

## Assignment Evidence Checklist

---

### 1. Source Control & Collaboration (GitHub)

#### GitHub Merge Conflict & Resolution Workflow

Below is a step-by-step guide for handling merge conflicts when the main branch is locked.

---

**1. Main branch is locked (no direct push allowed)**  
![Main branch locked](./images/devops_images_1.png)

> The main branch is protected. Developers cannot push directly; all changes must go through Pull Requests (PRs).

---

**2. Developer A pushes code (creates a PR)**  
![Developer A PR](./images/devops_images_2.png)

> Developer A creates a PR to propose changes. The PR is now awaiting review and approval.

---

**3. PR requires 1 approval**  
![PR requires approval](./images/devops_images_6.png)

> The repository requires at least one approval before merging into the main branch.

---

**4. Developer B changes the same code (creates another PR)**  
![Developer B PR](./images/devops_images_3.png)

> Developer B also creates a PR but modifies the same lines, causing a conflict.

---

**5. Merge conflict occurs**  
![Merge conflict](./images/devops_images_4.png)

> GitHub detects a merge conflict because both PRs modify the same lines.

---

**6. Resolving the conflict**  
![Resolve conflict](./images/devops_images_5.png)

> Developers manually resolve the conflict by merging both changes correctly.

---

**7. After resolving, update the PR**  
![Update PR after resolve](./images/devops_images_8.png)

> After resolving, the PR is updated and may require another review.

---

**8. Merge to the main branch**  
![PR Approve](./images/devops_images_7.png)  
![Merge to main](./images/devops_images_9.png)

> Once approved and conflict-free, the PR is merged into the main branch.

---

### 2. Continuous Integration (CI)

#### Continuous Integration (CI) Workflow

---

**1. Code pushed to repository (triggers CI pipeline)**  
![Code push triggers CI](./images/devops_images_28.png)

> A webhook triggers the Jenkins CI pipeline automatically.

---

**2. Jenkins pipeline starts**  
![Jenkins pipeline start](./images/devops_images_29.png)

> Jenkins starts executing the pipeline defined in the Jenkinsfile.

---

#### Jenkinsfile Script

```groovy

```

> This Jenkinsfile defines all CI/CD stages including scanning, build, and deployment.

---

**3. SonarQube code quality scan**  
![SonarQube scan](./images/devops_images_14.png)  
![SonarQube scan](./images/devops_images_15.png)  
![SonarQube scan](./images/devops_images_16.png)  
![SonarQube scan](./images/devops_images_31.png)

> SonarQube analyzes code quality, bugs, and code smells.

---

**4. Quality Gate enforcement**  
![Quality Gate](./images/devops_images_17.png)

> The pipeline continues only if the Quality Gate passes.

---

**5. Trivy security scan (filesystem & image)**  
![Trivy scan](./images/devops_images_18.png)  
![Trivy scan](./images/devops_images_19.png)  
![Trivy scan](./images/devops_images_20.png)

> Trivy scans project files and Docker images for vulnerabilities.

---

**6. Docker image build**  
![Docker build](./images/devops_images_21.png)

> Docker image is built after successful scans.

---

#### Jenkins Credentials Plugin

**7. Credentials management setup**  
![Jenkins credentials plugin](./images/devops_images_10.png)  
![Jenkins credentials plugin](./images/devops_images_12.png)

> Jenkins securely stores credentials such as tokens and passwords.

---

**8. Publish HTML Reports**  
![Jenkins HTML report](./images/devops_images_30.png)

> HTML reports are published using Jenkins plugins.

---

### 3. Infrastructure as Code (Terraform)

#### Terraform Workflow

---

**1. Define infrastructure using Terraform**

> Infrastructure resources are defined using `.tf` files.
> Infrastructure resources are defined using `.tf` files. Example files:

**infra/terraform/main.tf**

```hcl
terraform {
    required_version = ">= 1.5.0"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
        local = {
            source  = "hashicorp/local"
            version = "~> 2.5"
        }
        null = {
            source  = "hashicorp/null"
            version = "~> 3.2"
        }
    }
}

provider "aws" {
    region = var.aws_region
}

data "aws_key_pair" "existing" {
    key_name = var.key_name
}

module "compute" {
    source = "./modules/compute"

    name_prefix   = var.name_prefix
    ami_id        = var.ami_id
    instance_type = var.instance_type
    key_name      = var.key_name
    my_ip_cidr    = var.my_ip_cidr
}

resource "local_file" "ansible_inventory" {
    count = var.provision_with_ansible ? 1 : 0

    content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
        host             = module.compute.ec2_public_ip
        ssh_user         = var.ssh_user
    })
    filename = "${path.module}/../ansible/inventory.ini"
}

resource "null_resource" "wait_for_cloud_init" {
    count = var.provision_with_ansible ? 1 : 0

    triggers = {
        instance_id = module.compute.instance_id
    }

    connection {
        type        = "ssh"
        host        = module.compute.ec2_public_ip
        user        = var.ssh_user
        private_key = file(var.ssh_private_key_path)
        timeout     = "5m"
    }
    # ... (rest of resource omitted for brevity)
}
```

**infra/terraform/variables.tf**

```hcl
variable "aws_region" {
    description = "AWS region for infrastructure deployment"
    type        = string
    default     = "us-east-1"
}

variable "name_prefix" {
    description = "Prefix used for naming AWS resources"
    type        = string
    default     = "aupp-lms"
}

variable "instance_type" {
    description = "EC2 instance size"
    type        = string
    default     = "t2.micro"
}

variable "ami_id" {
    description = "Amazon Linux 2023 or Ubuntu AMI ID"
    type        = string
    default     = "ami-009d9173b44d0482b" # Update with the latest AMI ID for your region
}

variable "key_name" {
    description = "Existing AWS key pair"
    type        = string
    default     = "devop-final-key"
}

variable "my_ip_cidr" {
    description = "Your public IP in CIDR format, example 1.2.3.4/32"
    type        = string
    default     = "0.0.0.0/0"
}

variable "ssh_private_key_path" {
    description = "Local path to the SSH private key matching key_name"
    type        = string
    default     = "../keys/devop-final-key.pem"
}

variable "ssh_user" {
    description = "SSH user for the EC2 instance (ec2-user for AL2023, ubuntu for Ubuntu)"
    type        = string
    default     = "ubuntu"
}

variable "provision_with_ansible" {
    description = "Run Ansible server provisioning after instance creation"
    type        = bool
    default     = true
}
```

**infra/terraform/outputs.tf**

```hcl
output "ec2_public_ip" {
    value = module.compute.ec2_public_ip
}

output "ansible_inventory_path" {
    value = var.provision_with_ansible ? local_file.ansible_inventory[0].filename : null
}
```

---

**2. Provision server and configure with Ansible**  
![Ansible provision](./images/devops_images_22.png)

> Terraform creates infrastructure, and Ansible configures the server.

---

### 4. Continuous Deployment (CD)

#### Deployment Workflow

---

**1. CI success triggers deployment**  
![Deployment](./images/devops_images_23.png)

> Successful CI triggers deployment automatically.

---

**2. Health check using curl**  
![Health check curl](./images/devops_images_24.png)

> The application is verified using curl after deployment.

---

### 5. Monitoring & Observability

#### Prometheus & Grafana

---

**1. Prometheus collects metrics**

> Prometheus scrapes and stores system and application metrics.

---

**2. Grafana dashboard visualization**  
![Grafana dashboard](./images/devops_images_26.png)

> Grafana visualizes metrics using dashboards.

---

**3. AWS EC2 console verification**  
![AWS EC2 UI](./images/devops_images_27.png)

> EC2 console confirms that infrastructure is running.

---

## Objectives

- Apply GitHub workflow (PR, review, conflict resolution)
- Automate CI pipeline using Jenkins
- Enforce code quality with SonarQube
- Perform security scans with Trivy
- Build Docker images
- Provision AWS EC2 using Terraform
- Deploy application automatically
- Access application from browser
- Monitor system using Prometheus & Grafana

---

## CI/CD Workflow Architecture

### Full DevOps Flow

![Full DevOps Flow](./images/devops_pipeline.png)

> Complete pipeline from development to monitoring.

---

## Full Pipeline Success & UI

---

**1. Jenkins pipeline dashboard**  
![Jenkins pipeline UI](./images/devops_images_25.png)  
![Jenkins pipeline UI](./images/devops_images_32.png)

> Shows all stages executed successfully.

---

**2. Application accessible via browser**  
![App UI](./images/devops-images_33.png)

> Final confirmation of successful deployment.

---

## Tools & Technologies Used

| Category | Tool |
|----------|------|
| Source Control | GitHub |
| CI/CD Pipeline | Jenkins |
| Code Quality | SonarQube |
| Security Scan | Trivy |
| Containerization | Docker |
| Infrastructure as Code | Terraform |
| Cloud Provider | AWS EC2 |
| Monitoring | Prometheus |
| Visualization | Grafana |
