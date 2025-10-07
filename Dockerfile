FROM ubuntu:24.04 AS builder

ARG OVHCLOUD_CLI_VERSION=v0.5.0
ARG KUBECTL_VERSION=v1.34.1
ARG HELM_VERSION=v3.19.0
ARG TERRAFORM_VERSION=1.13.3
ARG GITHUB_CLI_VERSION=2.81.0
ARG ANSIBLE_VERSION=12.0.0

ENV DEBIAN_FRONTEND=noninteractive
ENV OVHCLOUD_CLI_VERSION=${OVHCLOUD_CLI_VERSION}
ENV KUBECTL_VERSION=${KUBECTL_VERSION}
ENV HELM_VERSION=${HELM_VERSION}
ENV TERRAFORM_VERSION=${TERRAFORM_VERSION}
ENV GITHUB_CLI_VERSION=${GITHUB_CLI_VERSION}
ENV ANSIBLE_VERSION=${ANSIBLE_VERSION}

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv build-essential \
    ca-certificates \
	curl \
	git \
    zip \
    unzip \
	jq \
    yq \
    docker.io \
	&& rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    ARCH=$( [ "$(arch)" = x86_64 ] && echo x86_64 || echo arm64 ); \
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
    tar --strip-components=1 -xf helm.tar.gz && \
    chmod +x helm && \
    mv helm /usr/local/bin

RUN set -eux; \
    ARCH=$( [ "$(arch)" = x86_64 ] && echo amd64 || echo arm64 ); \
	curl -fsSL -o terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" && \
    unzip terraform.zip && \
	chmod +x terraform && \
	mv terraform /usr/local/bin

RUN set -eux; \
    ARCH=$( [ "$(arch)" = x86_64 ] && echo amd64 || echo arm64 ); \
    curl -fsSL -o github-cli.tar.gz  "https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_${ARCH}.tar.gz" && \
    tar --strip-components=1 -xf github-cli.tar.gz && \
    chmod +x bin/gh && \
    mv bin/gh /usr/local/bin

RUN set -eux; \
    python3 -m venv /opt/ansible-venv; \
    . /opt/ansible-venv/bin/activate; \
    pip install --no-cache-dir ansible==${ANSIBLE_VERSION}

FROM alpine:3.22

# hadolint ignore=DL3018
RUN apk add --no-cache python3 py3-pip py3-virtualenv ca-certificates bash curl git unzip

COPY --from=builder \
  /usr/local/bin/ovhcloud \
  /usr/local/bin/kubectl \
  /usr/local/bin/helm \
  /usr/local/bin/terraform \
  /usr/local/bin/gh \
  /usr/local/bin/

COPY --from=builder /opt/ansible-venv /opt/ansible-venv

ENV PATH="/opt/ansible-venv/bin:/usr/local/bin:$PATH"

WORKDIR /opt
COPY ./entrypoint.sh .
RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]

