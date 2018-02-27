FROM oraclelinux:7-slim

### Install Oracle OCI CLI - version 2.4.15 ###

RUN yum -y install gcc libffi-devel python-devel openssl-devel python-setuptools
RUN easy_install pip
RUN pip install oci-cli

### Install Oracle Terraform and OCI Provider ###

ARG TERRAFORM_VERSION=0.11.3-1.el7
ARG OCI_PROVIDER_VERSION=2.0.7-1.el7
RUN yum-config-manager --enable ol7_developer  \
    && yum -y install terraform-${TERRAFORM_VERSION} terraform-provider-oci-${OCI_PROVIDER_VERSION}  \
    && rm -rf /var/cache/yum/*
VOLUME ["/data"]
WORKDIR /data
CMD ["/bin/bash", "-l"]
