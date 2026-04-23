# AUPP LMS DevOps CI/CD Pipeline (Jenkins + SonarQube + Trivy + Docker + Terraform + Prometheus + Grafana)

## Project Overview

This project implements a complete **CI/CD pipeline** for AUPP's internal Learning Management System (LMS) platform (similar to Canvas LMS).  
The goal is to ensure **fast feature delivery**, **secure deployments**, **automated infrastructure provisioning**, and **real-time monitoring**.

The CI/CD pipeline is implemented using **Jenkins**, with integrations including:

- SonarQube (Code Quality)
- Trivy (Security Scanning)
- Docker (Containerization)
- Terraform (Infrastructure as Code)
- AWS EC2 (Deployment Target)
- Prometheus + Grafana (Monitoring & Dashboard)

Required Jenkins plugin for the SonarQube report step:

- SonarQube Scanner plugin (`sonar`)

---

## Assignment Evidence Checklist

Place the screenshots in this order so the submission reads naturally from collaboration to deployment and monitoring.

### 1. Source Control & Collaboration (GitHub)

Capture the GitHub workflow first.

1. GitHub Branches + Pull Request
    - Show the feature branch, open PR, and source/target branches.

    branch main is lock so no one can push directly
    Developer A have push some code 
    Developer B change the code that Dev A that lead to conflict

    Required 1 approval to request
    Merege Conflict 
    Resolving conflict 
    after resolve conflict
    mereg to the main branch



2. Reviewer Approval
    - Show at least 1 reviewer approval on the PR.
    - Place the screenshot directly after the PR screenshot.

3. Merge Conflict + Resolved
    - Show the merge conflict first, then the resolved file or resolved PR diff.
    - Place the screenshot under `1.4 Merge Conflict Demonstration & Resolution`.

### 2. Continuous Integration (CI)

Capture the pipeline script and the quality/security results.

1. Jenkins / GitHub Action full script

    Jenkinsfile Script
    Webhook with jenkins
    Sonarqube report

    Quablity Gate only success to pass through
        
    Trivy Report
        Filesystem
        Docker image scan

### 3. Infrastructure as Code (Terraform)

1. Terraform
    - Show `terraform init`, `terraform apply`, and the final EC2 public IP or instance ID.
    - Place the screenshot under `6. Infrastructure as Code (Terraform)`.

    Dockerfile
    Docker build 
    server created using terraform and ansible to configure

### 4. Continuous Deployment (CD)

    After CI success deploy the docker image to the server
    test the server with curl to confirm it work fine

### 5. Monitoring & Observability

1. Grafana dashboard
 - Show dashboard panels such as CPU, memory, disk, or container health metrics.
 - Place the screenshot under `9.2 Grafana Dashboard`.

---

## Objectives

- Apply GitHub collaboration workflow (branches, PR, review, conflict resolution)
- Automate CI pipeline using Jenkins
- Enforce code quality gates using SonarQube
- Perform vulnerability scanning using Trivy
- Build Docker images for backend APIs
- Provision AWS EC2 automatically using Terraform
- Deploy Docker container automatically to EC2
- Access application from laptop
- Monitor server/container metrics using Prometheus + Grafana

---

## CI/CD Workflow Architecture

### Full DevOps Flow

```bash
Developer → GitHub → Pull Request → Reviewer Approval 
→ Merge Conflict Resolve → Merge to main  
→ Jenkins Pipeline Runs → SonarQube Scan → Trivy Scan 
→ Docker Build → Terraform Create EC2 → Deploy Docker Image 
→ Access Application → Prometheus Monitoring → Grafana Dashboard
```

---

## Tools & Technologies Used

|       Category         |    Tool    |
|------------------------|------------|
| Source Control         | GitHub     |
| CI/CD Pipeline         | Jenkins    |
| Code Quality           | SonarQube  |
| Security Scan          | Trivy      |
| Containerization       | Docker     |
| Infrastructure as Code | Terraform  |
| Cloud Provider         | AWS EC2    |
| Monitoring             | Prometheus |
| Visualization          | Grafana    |
