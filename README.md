# AWS Infrastructure with Terraform

This directory contains the Terraform configuration for provisioning AWS infrastructure for Istio Bare Metal Kubernetes Lab.

## Project Structure

```
infra/
├── environments/
│   ├── dev/
│   ├── stage/
│   └── prod/
├── modules/
│   ├── vpc/
│   ├── eks/
│   ├── iam/
│   ├── ecr/
│   ├── alb/
│   ├── ecs/
│   └── security-groups/
├── backend.tf
```

## CI/CD: GitHub Actions Workflows

Three GitHub Actions workflows are included:
1. `.github/workflows/deploy-infra.yml` - Combined pipeline for both ECS and EKS (VPC, IAM, Security Groups, ALB, EKS, ECR, ECS).
2. `.github/workflows/deploy-ecs.yml` - Standalone ECS pipeline (VPC, IAM, Security Groups, ECR, ECS) using Fargate Spot and public IP exposure (without ALB dependency to reduce cost).
3. `.github/workflows/deploy-eks.yml` - Standalone EKS pipeline (VPC, IAM, Security Groups, ALB, EKS, ECR).

Key behavior:

- Pushes to the `infra` branch:
  - Run the `validate` job (format, validate, tflint).
  - On push (refs/heads/infra) the `apply` job runs (applies to the `dev` workspace by default).
- Pull requests targeting `infra`:
  - Run `validate` and `plan` for dev/stage/prod (matrix) and upload the plan artifact.
- workflow_dispatch (manual run):
  - The manual trigger accepts inputs:
    - environment: one of `dev`, `stage`, `prod` (required)
    - run_validate: boolean (default: false)
    - run_plan: boolean (default: false)
    - run_apply: boolean (default: false)
    - run_destroy: boolean (default: false)
  - Use these booleans to control which jobs run. Examples:
    - Plan only for `stage`: set `environment=stage`, `run_plan=true`.
    - Validate + Plan for `prod`: set `environment=prod`, `run_validate=true`, `run_plan=true`.
    - Apply for `dev`: set `environment=dev`, `run_apply=true` (requires AWS secrets).
    - Destroy for `dev`: set `environment=dev`, `run_destroy=true` (use with caution).

Secrets required for plan/apply/destroy:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

These must be added to repository or organization secrets.

Notes and recommendations:

- The workflow uploads plan artifacts for review when planning; you can download plans from the workflow run artifacts if needed.
- For safety, consider protecting stage/prod apply with one of these options:
  - Add branch protection/environment protection with required reviewers for the `stage` and `prod` environments.
  - Require manual approval before running `apply` in non-dev environments.
- If you want different default behavior for the manual inputs (for example default `run_plan=true`), update the workflow inputs accordingly.

If you want, I can add a short example section showing screenshots/step-by-step of triggering the workflow from the Actions UI or provide a separate docs file with run examples.