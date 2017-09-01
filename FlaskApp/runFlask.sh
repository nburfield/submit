#!/bin/bash

export SUBMIT_COMPILE_PATH=/root/submit/FlaskApp/submit_build_folder
export C_FORCE_ROOT=true
source my_env/bin/activate

nohup celery worker -A app.celery --loglevel=info&

nohup python3.4 app.py&
