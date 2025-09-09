# IAM Key Rotation, Storage & Deletion — Terraform + GitHub Actions + AWS Lambda

Automated, least-privilege **IAM access key rotation** with:
- **Two Lambdas**
  - `rotate-and-deactivate-keys`: creates a new access key for a target IAM user, deactivates the old key, stores the new key in **AWS Secrets Manager**, and notifies stakeholders via **SNS**.
  - `purge-deactivated-keys`: deletes previously **Inactive** access keys for the same user.
- **Terraform** to provision IAM roles/policies, the Secrets Manager secret, SNS topic/subscription, and optional **EventBridge** schedules.
- **GitHub Actions**:
  - `infra-provision.yml`: validates/plan/apply infrastructure using an **S3 + DynamoDB** remote backend.
  - `ci-cd-lambda.yml`: multi-job pipeline (**lint → test → build → deploy**) that creates/updates both Lambdas with safe **AWS waiters** to avoid conflicts.

---

## Architecture

[<img alt="System Architecture Diagram"
      src="https://drive.google.com/uc?export=view&id=1QNnHxBmmsVVsdzh3C4nz8Y0yiUXQxwbb"
      width="100%">](https://drive.google.com/file/d/1QNnHxBmmsVVsdzh3C4nz8Y0yiUXQxwbb/view?usp=drive_link)

> If the inline image does not render (Google Drive hotlinking can be flaky), use the direct link:  
> **Diagram:** https://drive.google.com/file/d/1QNnHxBmmsVVsdzh3C4nz8Y0yiUXQxwbb/view?usp=drive_link

---

## Repository Layout
<h3>Repository Layout</h3>
<table>
  <tr>
    <th>lambdas/rotate_and_deactivate_keys/</th>
    <th>lambdas/purge_deactivated_keys/</th>
    <th>terraform/</th>
    <th>.github/workflows/</th>
  </tr>
  <tr>
    <td><code>app.py</code><br><code>requirements.txt</code> <em>(optional)</em></td>
    <td><code>app.py</code><br><code>requirements.txt</code> <em>(optional)</em></td>
    <td>
      <code>providers.tf</code><br>
      <code>variables.tf</code><br>
      <code>iam.tf</code><br>
      <code>secrets.tf</code><br>
      <code>sns.tf</code><br>
      <code>events.tf</code><br>
      <code>env/dev.tfvars</code> <em>(optional)</em>
    </td>
    <td>
      <code>infra-provision.yml</code><br>
      <code>ci-cd-lambda.yml</code>
    </td>
  </tr>
</table>


---

## Quick Start

1. **Create/confirm Terraform remote backend** (S3 + DynamoDB) and set these repo secrets:
   - `TF_STATE_BUCKET`, `TF_STATE_TABLE`, `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
2. **Pick target IAM user & secret name**
   - `TARGET_USERNAME` → IAM user to rotate (e.g., `my-service-user`)
   - `SECRET_NAME` → Secrets Manager name (e.g., `iam/my-service-user/keys`)
3. **Run infra workflow**
   - `Actions → Infra Provisioning → Run workflow → action=apply` (or push to `main` if you enabled auto-apply)
   - Confirm SNS subscription email sent to your configured address.
4. **Copy Terraform outputs to GitHub secrets (if not already set)**
   - `ROTATE_LAMBDA_ROLE_ARN`, `PURGE_LAMBDA_ROLE_ARN`, `SNS_TOPIC_ARN`
5. **Push a change under `lambdas/`** to trigger CI:
   - Pipeline runs **lint → test → build → deploy** (deploy on push to `main` or manual dispatch).
6. **Invoke Lambdas** (CLI or Console) and verify:
   - IAM keys, Secrets Manager value, CloudWatch logs, and SNS email.

---

## Prerequisites

- AWS account & IAM permissions to create IAM roles/policies, Lambda, Secrets Manager, SNS, EventBridge.
- GitHub repository with Actions enabled.
- (Recommended) A **non-production** IAM user for end-to-end tests (e.g., `key-rotation-e2e`).

---

## Required GitHub Secrets

| Secret                  | Purpose                                                                 |
|-------------------------|-------------------------------------------------------------------------|
| `AWS_ACCESS_KEY_ID`     | Deployer credentials for Terraform & Lambda deploy                      |
| `AWS_SECRET_ACCESS_KEY` | Deployer credentials for Terraform & Lambda deploy                      |
| `AWS_REGION`            | Region for all resources (e.g., `us-east-1`)                            |
| `TF_STATE_BUCKET`       | S3 bucket name for Terraform state                                      |
| `TF_STATE_TABLE`        | DynamoDB table name for Terraform state locking                         |
| `TARGET_USERNAME`       | IAM user whose keys are rotated (e.g., `my-service-user`)               |
| `SECRET_NAME`           | Secrets Manager name to store keys (e.g., `iam/my-service-user/keys`)   |
| `SECRET_JSON_KEY`       | (Optional) JSON key inside the secret; default is `current`             |
| `ROTATE_LAMBDA_ROLE_ARN`| IAM role ARN for `rotate-and-deactivate-keys` Lambda                    |
| `PURGE_LAMBDA_ROLE_ARN` | IAM role ARN for `purge-deactivated-keys` Lambda                        |
| `SNS_TOPIC_ARN`         | SNS topic ARN used for notifications                                    |

> If you use **GitHub Environments** (e.g., `dev`, `stage`, `prod`), add the secrets at the environment level used by your workflow.

---

## Workflows

### 1) Infra Provisioning — `.github/workflows/infra-provision.yml`
- **Triggers**: PR, push to `main`, manual (`workflow_dispatch` with `action=plan|apply`)
- **Backend**: S3 (`TF_STATE_BUCKET`) + DynamoDB (`TF_STATE_TABLE`)
- **Variables passed from secrets**:
  - `aws_region`, `target_username`, `secret_name`, `secret_json_key`
  - `enable_eventbridge_targets=true` to wire schedules automatically
- **Jobs**
  - `lint-validate` → init + normalize line endings + fmt (write + check) + validate
  - `plan` (PRs & manual plan)
  - `apply` (manual apply; optionally on push to `main`)
- **Outputs (also printed in logs)**
  - `ROTATE_LAMBDA_ROLE_ARN`, `PURGE_LAMBDA_ROLE_ARN`, `SNS_TOPIC_ARN`, `TARGET_USERNAME`, `SECRET_NAME`, `SECRET_JSON_KEY`

### 2) Lambda CI/CD — `.github/workflows/ci-cd-lambda.yml`
- **Multi-job order**: `lint` → `test` → `build` → `deploy`
- **Deploy** runs on push to `main` and manual dispatch; PRs stop after `build`.
- **Key features**
  - Robust zipping (works even with no `requirements.txt`)
  - AWS waiters (`function-active`, `function-updated`) to avoid conflict errors
  - Lambda environment variables injected from secrets

---

## Terraform Details

### Remote Backend
Configured at init time:
- S3 bucket: `${TF_STATE_BUCKET}`
- Key: `key-rotation/<env>.tfstate`
- DynamoDB table: `${TF_STATE_TABLE}`

### Important Variables
- `aws_region` (string) — from secrets
- `target_username` (string) — from secrets (no default)
- `secret_name` (string) — from secrets (no default; allowed chars: `A–Z a–z 0–9 / _ + = . @ -`)
- `secret_json_key` (string, default `current`)
- `enable_eventbridge_targets` (bool, default `false`; workflow sets `true`)
- `rotate_lambda_name` (default `rotate-and-deactivate-keys`)
- `purge_lambda_name` (default `purge-deactivated-keys`)

### What Terraform Creates
- **IAM**
  - `rotate_lambda_exec`: can list/create/update target user’s keys; write to the configured secret; publish to SNS; write logs.
  - `purge_lambda_exec`: can list/delete target user’s keys; write logs.
- **Secrets Manager**
  - Secret with name = `var.secret_name`
  - Lambda writes:
    ```json
    {
      "<secret_json_key>": {
        "aws_access_key_id": "...",
        "aws_secret_access_key": "..."
      }
    }
    ```
- **SNS**
  - Topic `iam-key-rotation-topic`
  - Email subscription (default `akupheaws@gmail.com` in `sns.tf`) → **confirm the subscription email**.
- **EventBridge (optional)**
  - Looks up Lambda **by function name** (no manual ARN passing)
  - Schedules enabled with `enable_eventbridge_targets = true`

---

## Lambda Functions

### `rotate-and-deactivate-keys`
- **Env Vars**: `TARGET_USERNAME`, `SECRET_NAME`, `SNS_TOPIC_ARN`, `SECRET_JSON_KEY` (default `current`)
- **Flow**:
  1. List existing keys for `TARGET_USERNAME`.
  2. Create a **new** key; deactivate the previous key (respecting IAM max of **2 keys**).
  3. Put secret value in Secrets Manager (under `SECRET_JSON_KEY`).
  4. Publish SNS notification.
  5. Log outcomes to CloudWatch.

### `purge-deactivated-keys`
- **Env Vars**: same set (SNS optional unless you add reporting)
- **Flow**:
  1. List keys for `TARGET_USERNAME`.
  2. Delete keys with status `Inactive`.
  3. Log outcomes to CloudWatch.

---

## EventBridge Schedules

Enabled via Terraform var `enable_eventbridge_targets = true`.

**Defaults (UTC):**
- Rotate: `cron(0 3 ? * MON *)` → every Monday 03:00 UTC
- Purge:  `cron(30 3 * * ? *)` → daily 03:30 UTC

> For testing, temporarily switch to `rate(5 minutes)` and watch CloudWatch logs.

---

## End-to-End Test Guide

> Use a **sandbox IAM user**; do not test on production credentials.

**Create a test user & starting key**
```bash
aws iam create-user --user-name key-rotation-e2e
aws iam create-access-key --user-name key-rotation-e2e

