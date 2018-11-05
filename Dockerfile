FROM oraclelinux:7-slim

### Install latest Oracle OCI CLI, OCI-UTILS and Terraform ###
RUN yum-config-manager --enable ol7_developer
RUN yum -y install oci-utils terraform

VOLUME ["/data"]
WORKDIR /data
CMD ["/bin/bash", "-l"]
