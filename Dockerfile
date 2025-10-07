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

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
	curl \
	git \
    zip \
    unzip \
	jq \
    yq \
    docker.io \
    ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    ARCH=$( [ "$(arch)" = x86_64 ] && echo amd64 || echo arm64 ); \
	curl -fsSL -o ovhcloud.tar.gz "https://github.com/ovh/ovhcloud-cli/releases/download/${OVHCLOUD_CLI_VERSION}/ovhcloud-cli_Linux_${ARCH}.tar.gz" && \
	tar -xf ovhcloud.tar.gz && \
	chmod +x ovhcloud && \
	mv ovhcloud /usr/local/bin

RUN set -eux; \
    ARCH=$( [ "$(arch)" = x86_64 ] && echo amd64 || echo arm64 ); \
	curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin

RUN set -eux; \
    ARCH=$( [ "$(arch)" = x86_64 ] && echo amd64 || echo arm64 ); \
	curl -fsSL -o helm.tar.gz "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz" && \
    tar -xf helm.tar.gz && \
    chmod +x "linux-${ARCH}/helm" && \
    mv "linux-${ARCH}/helm" /usr/local/bin

RUN set -eux; \
    ARCH=$( [ "$(arch)" = x86_64 ] && echo amd64 || echo arm64 ); \
	curl -fsSL -o terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" && \
    unzip terraform.zip && \
	chmod +x terraform && \
	mv terraform /usr/local/bin

WORKDIR /opt
COPY ./entrypoint.sh .
RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]

