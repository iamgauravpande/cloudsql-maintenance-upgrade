# CLOUDSQL MAINTENANCE UPGRADE

This repo automates performing of Cloud SQL Postgres Maintenance Upgrades(Minor/Patch Upgrade) when they are made available by GCP.

### Pre-requisite:
- The Github Action workflow uses GCP Workload Identity Federation thus would need a WIF Pool and Github OIDC provider setup along with a GCP Service Account with `Cloud SQL Admin` role. Check [How to enable Github Action to use WIF for GCP](https://dev.to/iamgauravpande/enabling-workload-identity-federation-for-github-actions-on-gcp-h8g)

- A Self Hosted Github Runner on your GCP Environment. Example can be Bastion GCE VM having gcloud cli installed can be used for this purpose.

### Workflow:

- The Github Action will run every day at 12:15 PM IST , it is being run on a self hosted runner.

- It there is a version change detected from the present Maintenance Version , it will place a 90 days Exclusion Window on the Postgres Instance and will also notify on slack the Window start and End timings being set.

- Then it will patch the Postgres Instance with the New Maintenance version and once the Instance is Patched it will notify again on Slack that the Instance is Patched with Latest Maintenance Version .



