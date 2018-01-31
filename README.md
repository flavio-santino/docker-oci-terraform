# Docker image and Terraform Examples for OCI

This guide was inspired on this awesome [article](https://medium.com/oracledevs/containerized-terraform-for-oci-provider-2deb917783fa) created by Lucas Gomes. This explains how to create and build your own docker image. 
I have used the steps from this article to create a docker image with terraform oci provider along with oci command line. From this docker image, you will be able to have both tools ready to use along with few terraform examples. 


----
## Installation
### Windows 10 
1. Download docker for Windows 10. You can download installers from this [link](https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe)
2. Double-click **Docker for Windows Installer.exe** to run the installer and follow the instructions.
3. Install Git-bash from this [link](https://github.com/git-for-windows/git/releases/download/v2.16.1.windows.1/Git-2.16.1-64-bit.exe)
4. Open gitbash and clone my repo with this command:
   `git clone git@github.com:flavio-santino/docker-oci-terraform.git`
5. Now you are ready to pull the docker image with this command: 
   `docker pull flaviosantino/docker-oci-terraform`
6. Now you can access your docker image along with your terraform examoles by executing:
   `docker run --interactive --tty --rm --volume "$PWD":/data flaviosantino/docker-oci-terraform "$@"`



----
## changelog
* 16-Jan-2018 first version
* 30-Jan-2018 Added more examples and oci config file.
