#!/bin/bash
# This script installs Open OnDemand (OOD) on AlmaLinux 8.7 and Ubuntu 22.04.
# It supports different authentication methods (Basic, LDAP, Entra) and configures the necessary settings for each.
# The script performs the following steps:
# 1. Replaces values in the vars.yml file with user-configured values.
# 2. Installs necessary packages and dependencies based on the platform (AlmaLinux or Ubuntu).
# 3. Runs an Ansible playbook to configure OOD.
#set -x  # Uncomment to enable debugging

### User config values start ######
auth_method=$(jetpack config ood.auth_method Basic) # [Basic, LDAP, Entra] Select Authentication method. Basic auth will use local accounts that have a password set.

## LDAP config - add values here if using LDAP
LDAP_host=$(jetpack config ood.ldap_host)  # LDAP server host and port
bindDN=$(jetpack config ood.ldap_bind_dn)  # Bind DN for LDAP
bindPW=$(jetpack config ood.ldap_bind_pwd)  # Password for the bind DN
user_baseDN=$(jetpack config ood.ldap_user_base_dn)  # Base DN for user entries
group_baseDN=$(jetpack config ood.ldap_group_base_dn)  # Base DN for group entries

# Entra config - add values here if using Entra
ClientID=$(jetpack config ood.entra_client_id)  # Client ID for Entra
ClientSecret=$(jetpack config ood.entra_client_secret)  # Client Secret for Entra
tenant=$(jetpack config ood.entra_tenant_id)  # Tenant ID for Entra

### User config values end #########

# OOD connection app settings. GIT URL to the OOD connection application to install in OOD.
# Point these variables to your GIT repo that has the OOD connection app
git_url="https://github.com/xpillons/oodconnect4cc.git"
git_branch="main"

# Do not edit below
### Node config values from OHAI and IP
platform=$(jetpack config platform)  # Get the platform information
# FQDN could be used here but by default uses the IP
#IP=$(curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-08-01&format=text")
server_name=$(jetpack config ood.server_name `hostname -f`)

# Replace values in the vars.yml
sed -i "s/AUTH/$auth_method/g" "$CYCLECLOUD_SPEC_PATH"/files/vars.yml
sed -i "s/LDAPHOST/$LDAP_host/g" "$CYCLECLOUD_SPEC_PATH"/files/vars.yml
sed -i "s/BINDDN/$bindDN/g" "$CYCLECLOUD_SPEC_PATH"/files/vars.yml
sed -i "s/BINDPW/$bindPW/g" "$CYCLECLOUD_SPEC_PATH"/files/vars.yml
sed -i "s/USERBASE/$user_baseDN/g" "$CYCLECLOUD_SPEC_PATH"/files/vars.yml
sed -i "s/GROUPBASE/$group_baseDN/g" "$CYCLECLOUD_SPEC_PATH"/files/vars.yml
sed -i "s/CLIENT_ID/$ClientID/g" "$CYCLECLOUD_SPEC_PATH"/files/vars.yml
sed -i "s/CLIENT_SECRET/$ClientSecret/g" "$CYCLECLOUD_SPEC_PATH"/files/vars.yml
sed -i "s/TENANT_ID/$tenant/g" "$CYCLECLOUD_SPEC_PATH"/files/vars.yml
sed -i "s,GITURL,$git_url,g" "$CYCLECLOUD_SPEC_PATH"/files/vars.yml
sed -i "s/GITBRANCH/$git_branch/g" "$CYCLECLOUD_SPEC_PATH"/files/vars.yml
sed -i "s/Server_IP/$server_name/g" "$CYCLECLOUD_SPEC_PATH"/files/vars.yml
sed -i "s/PLATFORM/$platform/g" "$CYCLECLOUD_SPEC_PATH"/files/vars.yml

# Supported platforms AlmaLinux 8, Ubuntu 22
# If statements check explicitly for supported OS
if [ "$platform" == "ubuntu" ]; then
    apt install -y apt-transport-https ca-certificates  # Install necessary packages
    wget -O /tmp/ondemand-release-web_3.1.1-jammy_all.deb https://apt.osc.edu/ondemand/3.1/ondemand-release-web_3.1.1-jammy_all.deb  # Download OOD package
    DEBIAN_FRONTEND=noninteractive apt install -y /tmp/ondemand-release-web_3.1.1-jammy_all.deb  # Install OOD package
    DEBIAN_FRONTEND=noninteractive apt update -y  # Update package list
    DEBIAN_FRONTEND=noninteractive apt install -y ondemand ondemand-dex nfs-kernel-server python-is-python3 python3-pip libapache2-mod-authnz-pam libapache2-mod-authnz-external pwauth # Install OOD and dependencies
    /usr/bin/pip install --upgrade pip  # Upgrade pip
    /usr/bin/pip install flask requests ansible distro --ignore-installed  # Install Python packages
fi

if [ "$platform" == "almalinux" ]; then
    dnf config-manager --set-enabled powertools  # Enable powertools repository
    dnf install -y epel-release  # Install EPEL repository
    dnf module enable -y ruby:3.1 nodejs:18  # Enable Ruby and Node.js modules
    dnf install -y https://yum.osc.edu/ondemand/3.1/ondemand-release-web-3.1-1.el8.noarch.rpm  # Install OOD package
    dnf install -y ondemand ondemand-selinux ondemand-dex nano nfs-utils git python39 python3-pip sssd sssd-tools sssd-ldap openldap-clients oddjob-mkhomedir perl-Switch pwauth mod_authnz_pam mod_authnz_external  # Install OOD and dependencies
    alternatives --set python /usr/bin/python3  # Set Python 3 as the default
    /bin/pip3 install flask requests ansible distro  # Install Python packages
fi

ansible-galaxy collection install community.crypto  # Install Ansible Galaxy collection

ansible-playbook "$CYCLECLOUD_SPEC_PATH"/files/OOD_config.yml  # Run Ansible playbook to configure OOD
