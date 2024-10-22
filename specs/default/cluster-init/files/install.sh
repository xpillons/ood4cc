#!/bin/bash
ANSIBLE_TAGS=$@
set -e
OOD_ANSIBLE_VERSION="v3.1.5"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLAYBOOKS_DIR=$THIS_DIR/playbooks

load_miniconda() {
  # Note: packaging this inside a function to avoid forwarding arguments to conda
  if [ -d ${THIS_DIR}/miniconda ]; then
    echo "Activating conda environment"
    source ${THIS_DIR}/miniconda/bin/activate
  else
    ./prereqs_install.sh
    echo "Activating conda environment"
    source ${THIS_DIR}/miniconda/bin/activate
  fi
}
load_miniconda

function run_playbook ()
{
  local playbook=$1
  shift
  local extra_vars_file=$@

  # If running all playbooks and playbook marker doesn't exists, run the playbook
  # If user requested specific playbook ignore marker file and force run
  if [ ! -e $PLAYBOOKS_DIR/$playbook.ok ] || [ "$TARGET" != "all" ]; then
    local options=""
    if [ "$extra_vars_file" != "" ]; then
      # Merge overrides variables in a single file
      yq eval-all '. as $item ireduce ({}; . *+ $item)' $extra_vars_file > $PLAYBOOKS_DIR/extra_vars.yml
      options+=" --extra-vars=@$PLAYBOOKS_DIR/extra_vars.yml"
    fi
    echo "Running playbook $PLAYBOOKS_DIR/$playbook.yml ..."
    ansible-playbook $PLAYBOOKS_DIR/$playbook.yml $options $ANSIBLE_TAGS || exit 1
    if [ -e $PLAYBOOKS_DIR/extra_vars.yml ]; then
      rm $PLAYBOOKS_DIR/extra_vars.yml
    fi
    touch $PLAYBOOKS_DIR/$playbook.ok
  else
    echo "Skipping playbook $PLAYBOOKS_DIR/$playbook.yml as it has been successfully run "
  fi
}

# Ensure submodule exists
if [ ! -d "${PLAYBOOKS_DIR}/roles/ood-ansible/.github" ]; then
    printf "Installing OOD Ansible submodule\n"
    git clone -b $OOD_ANSIBLE_VERSION https://github.com/OSC/ood-ansible.git $PLAYBOOKS_DIR/roles/ood-ansible
fi

export ANSIBLE_EXECUTABLE=/bin/bash
run_playbook ood $PLAYBOOKS_DIR/ood-overrides.yml
