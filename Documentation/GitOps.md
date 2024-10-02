# Developer Guide: Using Our New Infrastructure

Welcome to the infrastructure guide! This document provides a detailed overview of how developers can interact with the infrastructure, from building and deploying applications to managing secrets and interacting with AWS resources. We are adopting a **GitOps** approach, and the key tools involved are **ArgoCD**, **Jenkins**, **EKS**, **ECR**, **AWS Secrets Manager**, and **Terraform**.

## Overview
- **GitOps Methodology**: We use ArgoCD for deploying applications, following a hybrid approach where infrastructure is managed through Terraform, and application changes are handled with Helm charts.
- **Jenkins for CI/CD**: Developers build application images using Jenkins, which stores them in ECR. Jenkins also manages secrets in AWS Secrets Manager.
- **Source Code**: GitHub is used for source code versioning. Developers manage their application configurations through Helm charts stored in the ArgoCD application repository.
- **Secrets Management**: Secrets are created via Jenkins jobs and stored in AWS Secrets Manager.
- **IRSA**: DevOps handles all IRSA permissions using Terraform for secure access to AWS resources.

### Key Tools:
- **ArgoCD**: Application deployment
- **Jenkins**: CI/CD and secrets management
- **AWS ECR**: Docker image storage
- **AWS Secrets Manager**: Secret storage
- **Terraform**: Infrastructure management
- **Helm**: Kubernetes application packaging
- **GitHub**: Source code management

---

## Developer Workflow

### 1. Building Application Images Using Jenkins
For development, you have complete control over building and managing application images. Here's the process:
1. **Commit Code to GitHub**: Push your code changes to the relevant GitHub repository.
2. **Trigger Jenkins Job**: Use the Jenkins interface to trigger a job to build your application. This job will:
   - Build the Docker image.
   - Push the image to AWS ECR.
3. **View Image in ECR**: Once Jenkins completes, the image will be stored in your designated ECR repository.

#### Flow:
```
GitHub → Jenkins Build → ECR (Image Stored)
```

### 2. Deploying Applications with ArgoCD
Once the image is built and stored in ECR, you can deploy your application using ArgoCD. Follow these steps:
1. **Update Helm Chart**: Add or update your Helm chart in the ArgoCD application repository in GitHub.
2. **Commit to ArgoCD Repo**: Ensure that your changes are committed to the correct environment branch (development or production).
3. **ArgoCD Sync**: ArgoCD will automatically sync and deploy your application based on the updated configuration in the Helm chart.

#### Flow:
```
Update Helm Chart → Commit to ArgoCD Repo → ArgoCD Deploys to EKS
```

### 3. Managing Secrets with Jenkins and AWS Secrets Manager
If your application requires secrets (e.g., API keys, database passwords), use Jenkins to create and manage them in AWS Secrets Manager. Here's how:
1. **Create a Secret via Jenkins**: Use the predefined Jenkins job to create secrets. The secret path follows this structure:  
   `sabri/${env}/services/${service}/${secret_name}`
2. **Use Secret in Application**: Add references to the created secrets in your Helm configuration, which will be used during deployment via ArgoCD.

#### Flow:
```
Create Secret in Jenkins → Store in AWS Secrets Manager → Helm Chart References Secret → ArgoCD Deploys with Secret
```

### 4. Using Public Docker Images
If your application requires using public Docker images, you must pull them from a public registry and push them to our private AWS ECR repository via Jenkins:
1. **Pull Public Image via Jenkins**: Use the Jenkins job to pull the public image from a public Docker registry.
2. **Push to Private ECR**: The Jenkins job will automatically push the image to AWS ECR.
3. **Update Helm Chart**: Reference the private ECR image in your Helm chart for deployment.

#### Flow:
```
Public Registry → Jenkins Pull → ECR Push → Helm Chart Updated → ArgoCD Deploy
```

### 5. Interacting with AWS Resources (IRSA)
Interaction with AWS resources such as S3, DynamoDB, or Secrets Manager requires **IAM Roles for Service Accounts (IRSA)**. DevOps manages IRSA permissions using Terraform, so you do not need to worry about setting this up. Ensure your application’s Kubernetes service account is configured with the correct IRSA role for AWS interactions.

#### Flow:
```
Terraform (IRSA Setup) → EKS Service Account → Access AWS Resource
```

---

## Best Practices
- **Version Control**: Always ensure that your application’s Helm chart is properly versioned in GitHub. This enables easy rollbacks and change tracking.
- **Secrets**: Never store sensitive data in plain text or in GitHub repositories. Use AWS Secrets Manager and manage secrets through Jenkins jobs.
- **Deployments**: For non-production environments, developers have full control over deployments. For production deployments, follow the necessary approval process.
- **Images**: Always use ECR to store images. If using public images, ensure they are pulled and pushed to ECR through the Jenkins pipeline.

## Developer FAQs

### How do I update my Helm chart for ArgoCD deployment?
1. Update your Helm chart in the relevant GitHub repository.
2. Commit your changes to the environment-specific branch (e.g., `dev`, `prod`).
3. ArgoCD will automatically deploy the updated application based on the changes.

### How do I create a new secret for my application?
1. Trigger the Jenkins job to create a new secret.
2. Provide the secret’s environment (`dev` or `prod`), service name, and secret name.
3. Reference the secret in your Helm chart for deployment.

### What should I do if I need to use a public Docker image?
1. Use Jenkins to pull the image from a public registry.
2. Push the image to your private ECR repository.
3. Update your Helm chart to reference the new image URL in ECR.

### Who manages IRSA permissions?
All IRSA-related configurations are handled by the DevOps team using Terraform. You only need to ensure your service account is correctly configured in Kubernetes.

---

## Conclusion
By following this guide, you can efficiently build, deploy, and manage your applications in our AWS-based infrastructure using Jenkins, ArgoCD, Helm, and Terraform. For any additional questions, feel free to reach out to the DevOps team!

