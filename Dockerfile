ARG VERSION=v2.18.2

# --- Base

FROM docker.io/library/python:3.8-slim AS base

# hadolint ignore=DL3008,DL3042,DL3013
RUN set -eux \
  ; useradd \
    --create-home \
    --home-dir /home/kubespray \
    --uid 1042 \
    --user-group \
    --shell /bin/bash \
    kubespray \
  ; mkdir -p \
    /home/kubespray/.ssh \
    /home/kubespray/.local/bin \
    /opt/kubespray \
  ; chown -R kubespray:kubespray \
    /home/kubespray \
    /opt/kubespray \
  ; chmod 0700 /home/kubespray/.ssh \
  ; apt-get update -qq \
  ; apt-get install -yq --no-install-recommends \
            curl \
            git \
            jq \
            openssh-client \
            make \
            rsync \
            sudo \
            unzip \
  ; apt-get -yq clean \
  ; echo 'kubespray ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/kubespray \
  ; chown root:root /etc/sudoers.d/kubespray \
  ; chmod 0644 /etc/sudoers.d/kubespray \
  ; su -c 'sudo whoami' kubespray \
  ; export PYTHONDONTWRITEBYTECODE=1 \
  ; export PYTHONUNBUFFERED=1 \
  ; export PIP_NO_COLOR=1 \
  ; export PIP_CACHE_DIR="/tmp/pip-cache" \
  ; mkdir -p "$PIP_CACHE_DIR" \
  ; pip install --upgrade \
        pip \
  ; pip --version \
  ; find /usr/local -depth \
    '(' \
      '(' -type d -a \
        '(' -name test -o -name tests ')' \
      ')' \
      -o \
      '(' -type f -a \
        '(' -name '*.pyc' -o -name '*.pyo' ')' \
      ')' \
    ')' \
    -exec rm -rf '{}' + \
  ; rm -rf \
    "$PIP_CACHE_DIR" \
    /tmp/* \
    /var/tmp/* \
    /var/lib/apt/lists/* \
    ~/.cache \
    ~/.config \
  ; rm -f \
    /home/kubespray/.bash_logout \
    ~/.bash_history \
    ~/.python_history \
    ~/.wget-hsts

COPY --chown=root:root docker-entrypoint.sh /usr/bin/docker-entrypoint

RUN chmod 0755 /usr/bin/docker-entrypoint

USER 1042:1042

ENV PATH="/home/kubespray/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

WORKDIR /opt/kubespray

ARG VERSION=v2.18.2

# hadolint ignore=DL4006
RUN set -eux \
  ; git clone \
    --branch "$VERSION" \
    --single-branch \
    https://github.com/kubernetes-sigs/kubespray.git \
    . \
  ; git describe | tee .kubespray-git-describe \
  ; echo "$VERSION" | tee .kubespray-version \
  ; rm -rf \
    .git \
    .github \
    .gitlab-ci \
  ; rm -f \
    .editorconfig \
    .gitignore \
    .gitlab-ci.yml \
    .gitmodules \
    .markdownlint.yaml \
    .yamllint \
    code-of-conduct.md \
    CNAME \
    CONTRIBUTING.md \
    Dockerfile \
    OWNERS \
    OWNERS_ALIASES \
    Vagrantfile

# hadolint ignore=DL3004
RUN set -eux \
  ; pip install --no-cache-dir -r tests/requirements.txt \
  ; pip install --no-cache-dir -r requirements.txt \
  ; ansible --version \
  ; ansible-playbook --version \
  ; sudo rm -rf \
    /tmp/* \
    /var/tmp/* \
  ; rm -f \
    ~/.bash_history \
    ~/.python_history \
    ~/.wget-hsts

ENTRYPOINT ["docker-entrypoint"]

CMD ["bash"]
