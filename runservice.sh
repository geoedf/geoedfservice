#!/bin/sh

# run BOSCO
source /home/geoedf/bosco/bosco_setenv

bosco_start

# run ssh-keyscan to enter host keys for target cluster

ssh-keyscan -H brown.rcac.purdue.edu >> /home/geoedf/.ssh/known_hosts

# run API

python api.py
