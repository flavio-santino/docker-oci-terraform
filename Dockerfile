FROM oraclelinux:7-slim

### Install latest Oracle OCI CLI, Terraform and OCI-UTILS ###

RUN yum-config-manager --enable ol7_developer
RUN yum-config-manager --enable ol7_developer_EPEL
RUN yum -y install terraform python-oci-cli oci-utils

VOLUME ["/data"]
WORKDIR /data
CMD ["/bin/bash", "-l"]
