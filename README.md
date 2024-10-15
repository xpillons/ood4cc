# Open OnDemand CycleCloud Integration

## Introduction

This project installs and configures Open OnDemand on a VM managed by CycleCloud. By default, it configures Open OnDemand using Dex and Entra. Then it installs the OpenOnDemand CycleCloud connection app

## Supported OS

This project supports the following operating systems:

- AlmaLinux 8
- Ubuntu 22.04

## Prerequisites

- **Application registration setup for Entra authentication:**  - <https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad?tabs=workforce-configuration>
  - Set the redirect URL to `https://<FQDN/IP of OOD server>/dex/callback`.
  - Set the `email` and `preferred_username` optional claims for ID and Access.
- **CycleCloud SLURM cluster deployed.**
- **NFS home directories accessible** from both the cluster and the OOD VM (e.g., `/shared/home` export from the cluster scheduler).

## Deployment Steps

1. Clone the repository.
2. Modify variables in `specs/default/cluster-init/scripts/01-OODInstall.sh`.
3. Import the CycleCloud project and template: <https://learn.microsoft.com/en-us/azure/cyclecloud/cli?view=cyclecloud-8#cyclecloud-project-upload> <https://learn.microsoft.com/en-us/azure/cyclecloud/cli?view=cyclecloud-8#cyclecloud-import_template>
4. Create a cluster of type OOD.
5. Create user accounts in CycleCloud that match email addresses in Entra using the regex `^([^@]+)@.*$` (e.g., `John.Doe@company.co.uk` = `John.Doe`). <https://osc.github.io/ood-documentation/latest/authentication/overview/map-user.html>

Once the deployment steps are complete, you will have an OOD portal accessible at the IP of the deployed node, configured with Entra auth. Under the clusters tab, you will find an option to add a CycleCloud cluster. Details for this are at [Insert GITURL].

If more than one cluster is to be configured, the same home directories must be used on all, and users must exist in the same central auth service.

## Advanced

This CycleCloud project uses a combination of Bash and Ansible to deploy the OOD VM. Additions to the base image can be made in either. The main Ansible file is `specs/default/cluster-init/files/OOD_config.yml`.

This project disables SELinux for the purposes of using the connection app. Once a cluster is added, SELinux can be reenabled if needed.

If using Basic authentication, user accounts will require passwords creating. By default CycleCloud does not create passwords for local accounts.

### Authentication Flow

1. User goes to the IP of the OOD VM.
2. User logs in using the auth from the central service (e.g., Entra).
3. OOD maps the Entra user to a local user. User mapping uses the Dex default of checking the email attribute and applying the regex `^([^@]+)@.*$`. <https://osc.github.io/ood-documentation/latest/authentication/overview/map-user.html>
4. User successfully logs in and is mapped to a local Linux account.
