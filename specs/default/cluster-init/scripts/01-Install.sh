#!/bin/bash
# This script installs Open OnDemand (OOD) on AlmaLinux 8.7 and Ubuntu 22.04.
# It supports different authentication methods (Basic, LDAP, Entra) and configures the necessary settings for each.
# The script performs the following steps:
# 1. Replaces values in the vars.yml file with user-configured values from the CC template.
# 2. Install Ansible and other dependencies.
# 3. Runs the Ansible playbook to configure OOD.
#set -x  # Uncomment to enable debugging
set -e
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# OOD connection app settings. GIT URL to the OOD connection application to install in OOD.
# Point these variables to your GIT repo that has the OOD connection app
git_url="https://github.com/xpillons/oodconnect4cc.git"
git_branch="main"


# Install Ansible and other dependencies
chmod +x $script_dir/../files/*.sh
$script_dir/../files/prereqs_install.sh

# Replace values in the vars.yml file with user-configured values from the CC template
VARS_FILE=$script_dir/../files/playbooks/vars.yml
eval_expr='.auth_method |= "Basic"'

 # [Basic, LDAP, Entra] Select Authentication method. Basic auth will use local accounts that have a password set.
auth_method=$(jetpack config ood.auth_method Basic) yq -i '.auth_method |= strenv(auth_method)' $VARS_FILE 

## LDAP config - add values here if using LDAP
ldap_host=$(jetpack config ood.ldap_host) yq -i '.ldap_host |= strenv(ldap_host)' $VARS_FILE # LDAP server host and port
bind_DN=$(jetpack config ood.ldap_bind_dn) yq -i '.bind_DN |= strenv(bind_DN)' $VARS_FILE # Bind DN for LDAP
bind_PW=$(jetpack config ood.ldap_bind_pwd) yq -i '.bind_PW |= strenv(bind_PW)' $VARS_FILE # Password for the bind DN
user_base_DN=$(jetpack config ood.ldap_user_base_dn) yq -i '.user_base_DN |= strenv(user_base_DN)' $VARS_FILE # Base DN for user entries
group_base_DN=$(jetpack config ood.ldap_group_base_dn) yq -i '.group_base_DN |= strenv(group_base_DN)' $VARS_FILE # Base DN for group entries

# Entra config - add values here if using Entra
client_id=$(jetpack config ood.entra_client_id) yq -i '.client_id |= strenv(client_id)' $VARS_FILE # Client ID for Entra
client_secret=$(jetpack config ood.entra_client_secret) yq -i '.client_secret |= strenv(client_secret)' $VARS_FILE # Client Secret for Entra
tenant_id=$(jetpack config ood.entra_tenant_id) yq -i '.tenant_id |= strenv(tenant_id)' $VARS_FILE # Tenant ID for Entra

# OOD server name - this can be the FQDN or IP address of the OOD server or the hostname. This will be used to generate the self-signed SSL certificate.
server_name=$(jetpack config ood.server_name `hostname -f`) yq -i '.var_ood_fqdn |= strenv(server_name)' $VARS_FILE

# Install OOD
$script_dir/../files/install.sh