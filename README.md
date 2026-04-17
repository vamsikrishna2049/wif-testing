# Workload Identity Federation (WIF) Setup for GitHub Actions

This repository demonstrates how to securely deploy infrastructure on Google Cloud Platform (GCP) using GitHub Actions and Workload Identity Federation, without storing long-lived credentials.

## Architecture Overview

The setup consists of three main components:

1. **Bootstrap** (`gcp-wif-terraform/bootstrap/`) - Sets up WIF infrastructure
   - Workload Identity Pool
   - OIDC Provider pointing to GitHub Actions
   - Service Account with necessary permissions
   - IAM bindings to allow GitHub to impersonate the service account

2. **Infrastructure** (`gcp-wif-terraform/infra/`) - Deploys actual GCP resources
   - Currently includes a Cloud Storage demo bucket
   - Configured to use WIF for authentication

3. **GitHub Actions Workflow** (`.github/workflows/terraform.yml`) - Automates deployments
   - Uses `google-github-actions/auth@v2` for WIF authentication
   - Runs Terraform plan on pull requests
   - Applies changes on merges to main branch

## Prerequisites

- GCP Project with billing enabled
- `gcloud` CLI installed and configured
- Terraform 1.6.0 or later
- GitHub repository with Actions enabled

## Initial Setup

### 1. Set up Application Default Credentials (First Time Only)

```bash
gcloud auth application-default login --no-launch-browser
```

Follow the link provided to authenticate with your Google account.

### 2. Bootstrap the WIF Infrastructure

Navigate to the bootstrap directory and apply the configuration:

```bash
cd gcp-wif-terraform/bootstrap
terraform init
terraform apply \
  -var="project_id=YOUR_PROJECT_ID" \
  -var="github_repo=GITHUB_ORG/GITHUB_REPO"
```

Replace:
- `YOUR_PROJECT_ID` with your GCP project ID
- `GITHUB_ORG/GITHUB_REPO` with your repository (e.g., `vamsikrishna2049/wif-testing`)

### 3. Note the Outputs

After successful bootstrap, Terraform will output:
- `workload_identity_provider` - URL for GitHub Actions authentication
- `service_account_email` - Service account email
- `workload_identity_pool_id` - Pool ID
- `project_number` - GCP project number

These values are used by the GitHub Actions workflow.

## GitHub Actions Workflow

The workflow (`terraform.yml`) automatically:

1. **On Pull Request**: Runs `terraform plan` to show proposed changes
2. **On Push to Main**: Runs `terraform apply` to deploy changes

### Workflow Permissions

The GitHub Actions workflow needs:
- `contents: read` - To checkout the repository
- `id-token: write` - To request and use OIDC tokens

These are configured in the workflow file and cannot be overridden by repository settings for security.

## Deploying Infrastructure

### Manual Deployment (Local)

```bash
cd gcp-wif-terraform/infra
terraform init
terraform plan
terraform apply
```

### Automated Deployment (GitHub Actions)

1. Push changes to a feature branch
2. Create a Pull Request
3. Review the `terraform plan` output in the PR
4. Merge to main to trigger `terraform apply`

## File Structure

```
├── .github/
│   └── workflows/
│       └── terraform.yml          # GitHub Actions workflow
├── gcp-wif-terraform/
│   ├── bootstrap/
│   │   ├── main.tf                # WIF infrastructure
│   │   ├── outputs.tf             # Outputs for WIF setup
│   │   ├── provider.tf            # Provider configuration
│   │   └── variables.tf           # Input variables
│   └── infra/
│       ├── main.tf                # GCP resources to deploy
│       ├── outputs.tf             # Infrastructure outputs
│       ├── provider.tf            # Provider configuration
│       └── variables.tf           # Input variables
└── readme.md                       # This file
```

## Security Considerations

✅ **Secure by Default**
- No long-lived credentials stored in GitHub
- OIDC tokens are short-lived (1 hour)
- Service account access is limited to specific permissions
- Repository name is verified in the OIDC claim

⚠️ **Best Practices**
- Regularly audit service account permissions
- Use separate service accounts for different environments
- Enable audit logging in GCP
- Review GitHub Actions workflow changes before merging
- Keep Terraform provider versions pinned

## Troubleshooting

### "Apply requires configuration to be present"

Make sure you're running terraform commands from the correct directory:
- For bootstrap: `gcp-wif-terraform/bootstrap/`
- For infrastructure: `gcp-wif-terraform/infra/`

### "Attempted to load application default credentials"

Run: `gcloud auth application-default login --no-launch-browser`

### "Identity Pool does not exist"

The GitHub Actions workflow uses the bootstrap outputs. After making changes to bootstrap, redeploy and update the workflow file with new values.

### GitHub Actions Workflow Failures

Check the workflow logs in the Actions tab of your GitHub repository. Common issues:
- Mismatched repository name in the WIF binding
- Service account doesn't have required permissions
- Provider ID or pool ID incorrect in the workflow

## Next Steps

1. Customize `gcp-wif-terraform/infra/main.tf` with your actual GCP resources
2. Test the workflow with a pull request
3. Monitor deployments in Github Actions and GCP Cloud Console
4. Add more sophisticated Terraform configurations for your use case

## Additional Resources

- [GCP Workload Identity Federation Documentation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub OIDC in GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest)
- [google-github-actions/auth](https://github.com/google-github-actions/auth)
