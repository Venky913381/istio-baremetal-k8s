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
│   ├── route53/
│   └── security-groups/
├── backend.tf