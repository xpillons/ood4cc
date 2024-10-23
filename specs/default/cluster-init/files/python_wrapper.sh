#!/bin/bash
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${THIS_DIR}/miniconda/bin/activate oodconnector

exec /bin/env python3 "$@"
