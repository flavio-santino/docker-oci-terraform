# Docker image and Terraform Examples for OCI

This guide was inspired on this awesome [article](https://medium.com/oracledevs/containerized-terraform-for-oci-provider-2deb917783fa) created by Lucas Gomes. This explains how to create and build your own docker image.
I have used the steps from this article to create a docker image with terraform oci provider along with oci command line. From this docker image, you will be able to have both tools ready to use along with few terraform examples.


----
## Installation

### MacOSX / Linux
1. Download docker for MacOSX. You can download installers from this [link](https://download.docker.com/mac/stable/Docker.dmg)
2. Double-click **Docker.dmg** to run the installer and follow the instructions.
3. Install git from this [link](https://git-scm.com/download/mac)
4. Open terminal and clone my repo with this command:

   `git clone https://github.com/flavio-santino/docker-oci-terraform.git`
5. Now you are ready to pull the docker image with this command:

   `docker pull flaviosantino/docker-oci-terraform`
6. Now you can access your docker image along with your terraform examples by executing:

   `docker run --interactive --tty --rm --volume "$PWD":/data flaviosantino/docker-oci-terraform "$@"`

