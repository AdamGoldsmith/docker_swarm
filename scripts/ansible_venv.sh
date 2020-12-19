#!/bin/bash

# Requirements
# * python3

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

command -v python3 || exit 1

[[ ! -d "${HOME}/venvs" ]] && mkdir "${HOME}/venvs"

# shellcheck source=/dev/null
python3 -m venv "${HOME}/venvs/ansible_ds" && source "${HOME}/venvs/ansible_ds/bin/activate"

pip install -r "${script_dir}/../files/requirements.txt" --upgrade

echo "Virtual env created - activate it by running:

source ${HOME}/venvs/ansible_ds/bin/activate

"

