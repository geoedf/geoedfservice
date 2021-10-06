# Standalone GeoEDF Service Container

This is a Docker container that is designed to function as a service backend for the GeoEDF workflow engine "client". The service 
includes Pegasus and BOSCO for processing workflows and submitting jobs to a HPC cluster.

Deployment of this container will typically be via the use of Kubernetes and the necessary SSH keys and BOSCO cluster configuration 
files will be mounted as volumes into this container.
