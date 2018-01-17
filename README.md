# Docker image and Terraform Examples for OCI


## Docker image and terraform installation

> This guide was inspired on this awesome [article](https://medium.com/oracledevs/containerized-terraform-for-oci-provider-2deb917783fa) created by Lucas Gomes. This explains how to create and build your own docker image. I have used the steps from this article to create my docker image and added a few examples of terraform scripts here. 


----
## Usage
1. git clone git@github.com:flavio-santino/docker-oci-terraform.git
2. docker pull flaviosantino/docker-oci-terraform
3. docker run --interactive --tty --rm --volume "$PWD":/data flaviosantino/docker-oci-terraform "$@"

----
## changelog
* 16-Jan-2018 first version
