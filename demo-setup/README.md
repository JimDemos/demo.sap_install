Demo Setup
==========

This directory contains the configuration of a container
which starts lighttpd with a web form that collects your cloud credentials.
Then it calls a playbook that creates a vm in you cloud, installs k3s, deploys the awx operator and awx via helm

Due to changes in AWX development the HELM operator has moved here:
https://github.com/ansible-community/awx-operator-helm

## Quickstart

Go to .... to launch the container

## How to run the container locally

If you are uncertain and do not want to enter your cloud credentials on the above website, you can run everything the container locally in your networj

-> using podman 

-> using docker (untested)

-> using kubernetes