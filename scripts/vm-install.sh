# !/bin/bash

curl -L https://tljh.jupyter.org/bootstrap.py \
| sudo -E python3 - \
    --admin ${1} \
    --user-requirements-txt-url https://raw.githubusercontent.com/crazy4pi314/littlest-jupyterhub-vm/main/requirements.txt
