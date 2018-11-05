FROM oraclelinux:7-slim

### Install latest Oracle OCI CLI ###

RUN yum-config-manager --enable ol7_developer
RUN yum -y install terraform oci-utils

### Install Oracle Terraform and OCI Provider ###

VOLUME ["/data"]
WORKDIR /data
CMD ["/bin/bash", "-l"]
