#!/bin/sh

# run BOSCO
source /home/geoedf/bosco/bosco_setenv

bosco_start

# change ownership
sudo chown -R geoedf:geoedf /home/geoedf/.ssh

sudo chown -R geoedf:geoedf /home/geoedf/.bosco

# run ssh-keyscan to enter host keys for target cluster

ssh-keyscan -H brown.rcac.purdue.edu >> /home/geoedf/.ssh/known_hosts

# run API

python3 api.py
