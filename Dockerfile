FROM ubuntu:24.04 AS builder

ARG OVHCLOUD_CLI_VERSION=v0.5.0
ARG KUBECTL_VERSION=v1.34.1
ARG HELM_VERSION=v3.19.0
ARG TERRAFORM_VERSION=1.13.3

ENV DEBIAN_FRONTEND=noninteractive
ENV OVHCLOUD_CLI_VERSION=${OVHCLOUD_CLI_VERSION}
ENV KUBECTL_VERSION=${KUBECTL_VERSION}
ENV HELM_VERSION=${HELM_VERSION}
ENV TERRAFORM_VERSION=${TERRAFORM_VERSION}

RUN apt-get update && apt-get install -y \
	curl \
	git \
    zip \
    unzip \
	jq \
    yq \
    docker.io \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o ovhcloud.tar.gz https://github.com/ovh/ovhcloud-cli/releases/download/${OVHCLOUD_CLI_VERSION}/ovhcloud-cli_Linux_$([ $(arch) = x86_64 ] && echo amd64 || echo arm64).tar.gz && \
	tar -xf ovhcloud.tar.gz && \
	chmod +x ovhcloud && \
	mv ovhcloud /usr/local/bin

RUN	curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/$([ $(arch) = x86_64 ] && echo amd64 || echo arm64)/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin

RUN curl -fsSL -o helm.tar.gz https://get.helm.sh/helm-${HELM_VERSION}-linux-$([ $(arch) = x86_64 ] && echo amd64 || echo arm64).tar.gz && \
    tar -xf helm.tar.gz && \
    chmod +x linux-$([ $(arch) = x86_64 ] && echo amd64 || echo arm64)/helm && \
    mv linux-$([ $(arch) = x86_64 ] && echo amd64 || echo arm64)/helm /usr/local/bin

RUN curl -fsSL -o terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_$([ $(arch) = x86_64 ] && echo amd64 || echo arm64).zip && \
    unzip terraform.zip && \
	chmod +x terraform && \
	mv terraform /usr/local/bin

COPY ./entrypoint.sh .
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

