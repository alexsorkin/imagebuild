################################################################################################################
FROM alpine as alpine-glibc

LABEL MAINTENANER="Alex Sorkin"

# Install common packages
RUN echo "ipv6" >> /etc/modules && \
    ln -s /var/cache/apk /etc/apk/cache && \
    apk --no-progress update && \
    apk --no-progress upgrade && \
    apk --no-progress add \
      bash openssl linux-pam ca-certificates \
      wget curl bc tar gzip libarchive-tools \
      openssh-client jq make tzdata gettext \
      busybox-extras shadow libsasl libltdl \
      util-linux coreutils binutils findutils grep && \
    export TINI_VERSION=`curl -s https://github.com/krallin/tini/releases/latest|grep -Eo "[[:digit:]]{1,2}"|xargs|sed 's/\ /./g'` && \
    echo "Tini Supervisor Version: ${TINI_VERSION}" && \
    curl -o /bin/tini -fsSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static-amd64 && \
    chmod +x /bin/tini

# Download glibc packages
RUN export GLIBC_RELEASE_URL=https://github.com/sgerrand/alpine-pkg-glibc/releases && \
    curl -sSL -o /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    export GLIBC_MAJOR=`curl -sS ${GLIBC_RELEASE_URL}/latest|grep -Eo "[[:digit:]]{1,2}"|head -2|xargs|sed "s#\ #.#g"` && \
    export GLIBC_MINOR=`curl -sS ${GLIBC_RELEASE_URL}/latest|grep -Eo "[[:digit:]]{1,2}"|head -3|tail -1|xargs echo r|sed "s#\ ##g"` && \
    export GLIBC_VERSION="${GLIBC_MAJOR}-${GLIBC_MINOR}" && \
    echo "Glibc Version: ${GLIBC_VERSION}" && \
    wget -q -O /tmp/glibc.apk ${GLIBC_RELEASE_URL}/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk && \
    wget -q -O /tmp/glibc-bin.apk ${GLIBC_RELEASE_URL}/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk && \
    wget -q -O /tmp/glibc-i18n.apk ${GLIBC_RELEASE_URL}/download/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk && \
    apk --no-progress add /tmp/glibc.apk /tmp/glibc-bin.apk /tmp/glibc-i18n.apk && \
    rm -rf /tmp/glibc.apk /tmp/glibc-bin.apk /tmp/glibc-i18n.apk

ENTRYPOINT [ "/bin/tini", "--" ]

################################################################################################################
FROM jenkins/inbound-agent:alpine as blueocean-slave-glibc-jnlp

LABEL MAINTENANER="Alex Sorkin"

USER root

COPY --from=alpine-glibc /bin/tini /bin/tini
COPY --from=alpine-glibc /etc/apk/keys/sgerrand.rsa.pub /etc/apk/keys/sgerrand.rsa.pub
COPY --from=alpine-glibc /var/cache/apk /var/cache/apk

RUN \
    echo "ipv6" >> /etc/modules && \
    ln -s /var/cache/apk /etc/apk/cache && \
    apk --no-progress update && \
    apk --no-progress add \
      bash openssl linux-pam ca-certificates \
      wget curl bc tar gzip libarchive-tools \
      openssh-client jq make tzdata gettext \
      busybox-extras shadow libsasl libltdl \
      util-linux coreutils binutils findutils grep \
      git git-svn git-subtree bind perl-git subversion ruby && \
    rm -rf /etc/apk/cache && \
    rm -rf /var/cache/apk

COPY build/files/jenkins-slave /usr/local/bin/jenkins-slave
RUN \
    mkdir -p /var/lib/tls/ca && \
    chmod -R 777 /var/lib/tls && \
    chmod 666 $JAVA_HOME/jre/lib/security/cacerts && \
    chmod 755 /usr/local/bin/jenkins-slave

USER jenkins

################################################################################################################
FROM alpine-glibc as blueocean-slave-glibc-docker

# Docker Client
RUN \
    DOCKER_TGZ_REPO=https://download.docker.com/linux/static/stable/x86_64 && \
    DOCKER_VERSION=$(curl -sSL https://download.docker.com/linux/static/stable/x86_64|grep -v blank|grep href|grep "\-ce"|tail -1|grep -Eo "[[:digit:]]{1,2}"|head -3|xargs|sed 's/\ /./g') && \
    echo "Docker Version: v${DOCKER_VERSION}-ce" && \
    curl -fsSLO ${DOCKER_TGZ_REPO}/docker-${DOCKER_VERSION}-ce.tgz && \
    tar xzvf docker-${DOCKER_VERSION}-ce.tgz --strip 1 \
       -C /usr/local/bin docker/docker && \
    rm docker-${DOCKER_VERSION}-ce.tgz && \
    export HABITUS_VERSION=$(curl -s https://github.com/cloud66-oss/habitus/releases/latest \
      |grep -Eo "[[:digit:]]{1,2}"|grep -v 66|xargs|sed 's/\ /./g') && \
    echo "Habitus Version: v${HABITUS_VERSION}" && \
    curl -o /usr/local/bin/habitus -sSL https://github.com/cloud66-oss/habitus/releases/download/${HABITUS_VERSION}/habitus_linux_386 && \
    chmod +x /usr/local/bin/habitus && \
    rm -rf /etc/apk/cache && \
    rm -rf /var/cache/apk

################################################################################################################
FROM alpine-glibc as blueocean-slave-glibc-consul-template

# Consul Template
RUN export HASHICORP_RELEASES=https://releases.hashicorp.com && \
    export CONSUL_TMPL_VERSION=`curl -s ${HASHICORP_RELEASES}/consul-template/|grep -v beta|grep -v rc|grep -v title|grep consul-template|head -1|sed 's/[^"]*"\([^"]*\).*/\1/'|grep -Eo "[[:digit:]]{1,2}"|xargs|sed 's#\ #.#g'` && \
    echo "Consul Template Version: ${CONSUL_TMPL_VERSION}" && \
    curl -sSL ${HASHICORP_RELEASES}/consul-template/${CONSUL_TMPL_VERSION}/consul-template_${CONSUL_TMPL_VERSION}_linux_amd64.zip | bsdtar -xf- && \
    chmod +x consul-template && \
    mv consul-template /usr/local/bin/consul-template && \
    rm -rf /etc/apk/cache && \
    rm -rf /var/cache/apk

################################################################################################################
FROM alpine-glibc as blueocean-slave-glibc-kubectl

# Kubernetes Client
RUN export KUBE_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt \
      |grep -Eo "[[:digit:]]{1,2}"|xargs|sed 's#\ #.#g') && \
    echo "Kubectl version: v${KUBE_VERSION}" && \
    curl -o /usr/local/bin/kubectl -sSL https://storage.googleapis.com/kubernetes-release/release/v${KUBE_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    rm -rf /etc/apk/cache && \
    rm -rf /var/cache/apk

################################################################################################################
FROM alpine-glibc as blueocean-slave-glibc-python

# Python
RUN \
    echo "ipv6" >> /etc/modules && \
    ln -s /var/cache/apk /etc/apk/cache && \
    apk --no-progress update && \
    apk --no-progress add \
      openssl ca-certificates \
      shadow libsasl libltdl  \
      python3 python3-dev py3-pip libxml2 libxslt && \
    pip3 install --upgrade pip wheel

################################################################################################################
FROM blueocean-slave-glibc-python as blueocean-slave-glibc-ansible

ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1

# Ansible
RUN \
    apk --no-progress add \
      sudo sshpass openssh-client rsync libxml2 libxslt \
      git git-svn git-subtree bind perl-git subversion && \
    apk --no-progress add --virtual build-dependencies \
      build-base libffi-dev openssl-dev \
      linux-headers libtool groff icu-dev libxml2-dev libxslt-dev && \
    pip3 install --upgrade pip wheel && \
    pip3 install --upgrade cffi jmespath lxml && \
    pip3 install ansible-runner ansible-runner-http \
      ansible openshift pycrypto pywinrm && \
    apk del build-dependencies  && \
    rm -rf /etc/apk/cache && \
    rm -rf /var/cache/apk && \
    ln -sf /usr/bin/python3 /usr/bin/python

#      'ansible>=2.7.0,<2.8.0' openshift pycrypto pywinrm && \

RUN \
    mkdir -p /etc/ansible && \
    echo "localhost ansible_connection=local" > /etc/ansible/hosts && \
    echo '[defaults]' > /etc/ansible/ansible.cfg && \
    echo 'library = /usr/share/ansible/openshift' >> /etc/ansible/ansible.cfg && \
    mkdir -p /usr/share/ansible/openshift

#COPY --from=quay.io/water-hole/ansible-operator:working /usr/share/ansible/openshift/k8s_status.py /usr/share/ansible/openshift/k8s_status.py

################################################################################################################
FROM blueocean-slave-glibc-ansible as blueocean-slave-glibc-all

# Add docker cli
COPY --from=blueocean-slave-glibc-docker /usr/local/bin/docker /usr/local/bin/
COPY --from=blueocean-slave-glibc-docker /usr/local/bin/habitus /usr/local/bin/
# Add kubectl
COPY --from=blueocean-slave-glibc-kubectl /usr/local/bin/kubectl /usr/local/bin/kubectl
# Add vault consule-template
COPY --from=blueocean-slave-glibc-consul-template /usr/local/bin/consul-template /usr/local/bin/consul-template
COPY --from=hashicorp/vault-enterprise:1.6.3_ent /bin/vault /usr/local/bin/vault

COPY --from=docker.bintray.io/jfrog/jfrog-cli-go:latest /usr/local/bin/jfrog /usr/local/bin/jfrog

#RUN \
#    curl -sSfL https://getcli.jfrog.io | sh 2>&1

################################################################################################################
#FROM blueocean-slave-glibc-ansible as devops-tools-operator

#COPY --from=quay.io/water-hole/ansible-operator:working /usr/local/bin/entrypoint /usr/local/bin/entrypoint
#COPY --from=quay.io/water-hole/ansible-operator:working  /usr/local/bin/ansible-operator /usr/local/bin/ansible-operator

#RUN \
#    echo 'roles_path = /opt/ansible/roles' >> /etc/ansible/ansible.cfg && \
#    chmod +x /usr/local/bin/entrypoint

#ENV OPERATOR=/usr/local/bin/ansible-operator \
#    USER_UID=1001 \
#    USER_NAME=ansible-operator \
#    HOME=/opt/ansible

#RUN \
#    mkdir -p ${HOME}/.ansible/tmp && \
#    chown -R ${USER_UID}:0 ${HOME} && \
#    chmod -R ug+rwx ${HOME} && \
#    chmod g+rw /etc/passwd

#ENTRYPOINT [ "/bin/tini", "--", "/usr/local/bin/entrypoint"]

#USER ${USER_UID} 

#COPY roles/ ${HOME}/roles/
#COPY blueocean.yaml ${HOME}/blueocean.yaml
#COPY ldapproxy.yaml ${HOME}/ldapproxy.yaml
#COPY watches.yaml ${HOME}/watches.yaml

################################################################################################################
#FROM jenkins/jenkins:2.190.2-alpine as blueocean-server-glibc
FROM jenkins/jenkins:lts-alpine as blueocean-server-glibc

LABEL MAINTENANER="Alex Sorkin"

USER root

COPY --from=alpine-glibc /etc/apk/keys/sgerrand.rsa.pub /etc/apk/keys/sgerrand.rsa.pub
COPY --from=alpine-glibc /var/cache/apk /var/cache/apk

ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1

RUN \
    echo "ipv6" >> /etc/modules && \
    ln -s /var/cache/apk /etc/apk/cache && \
    apk --no-progress update && \
    apk --no-progress upgrade && \
    apk --no-progress add \
      bash openssl linux-pam ca-certificates \
      wget curl bc tar gzip libarchive-tools \
      openssh-client jq make tzdata gettext git git-lfs \
      busybox-extras shadow libsasl libltdl git-subtree \
      util-linux coreutils binutils findutils grep \
      python3 python3-dev py3-pip libxml2 libxslt && \
    apk --no-progress add --virtual build-dependencies \
      build-base python3-dev libffi-dev openssl-dev \
      linux-headers libtool groff icu-dev libxml2-dev libxslt-dev && \
    pip3 install --upgrade pip wheel && \
    pip3 install --upgrade cffi jmespath lxml && \
    pip3 install --upgrade ansible openshift pycrypto pywinrm && \
    apk del build-dependencies  && \
    rm -rf /etc/apk/cache && \
    rm -rf /var/cache/apk && \
    ln -sf /usr/bin/python3 /usr/bin/python

USER jenkins

#RUN \
#    /usr/local/bin/install-plugins.sh \
#        ws-cleanup

RUN \
    /usr/local/bin/install-plugins.sh \
        blueocean pipeline-stage-view git \
        keycloak role-strategy \
        kubernetes ssh-agent ansicolor \
        skip-certificate-check timestamper locale \
        build-token-root email-ext \
        folder-properties junit prometheus \
        permissive-script-security git-changelog \
        logstash htmlpublisher cucumber-reports \
        bitbucket hubot-steps greenballs \
        ws-cleanup authorize-project

        # hidden-parameter  oic-auth matrix-auth  \
        # basic-branch-build-strategies build-token-root
        #workflow-scm-step ws-cleanup authorize-project

#  workflow-scm-step workflow-cps:2.71 ws-cleanup 

USER root
COPY build/files/jenkins_health_check.sh /usr/local/bin/jenkins_health_check.sh
COPY build/files/jenkins-entrypoint.sh /entrypoint.sh
RUN \
    chmod +x /entrypoint.sh && \
    chmod +x /usr/local/bin/jenkins_health_check.sh && \
    chmod 666 ${JAVA_HOME}/jre/lib/security/cacerts && \
    mkdir -p /etc/ansible && \
    echo "localhost ansible_connection=local" > /etc/ansible/hosts && \
    echo '[defaults]' > /etc/ansible/ansible.cfg

USER jenkins

ENV JENKINS_REF_DIR=/usr/share/jenkins/ref \
    JAVA_OPTS="-Djenkins.install.runSetupWizard=false \
      -Dhudson.model.DirectoryBrowserSupport.CSP='' \
      -Dhudson.slaves.NodeProvisioner.initialDelay=0 \
      -Dhudson.slaves.NodeProvisioner.MARGIN=50 \
      -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85 \
      -Dhudson.model.UpdateCenter.never=true \
      -Djenkins.CLI.disabled=true \
      -Dpermissive-script-security.enabled=true" \
    JENKINS_ADMIN_USER=admin \
    JENKINS_ADMIN_PASSWORD=admin \
    JENKINS_CONSOLE_URL="http://localhost:8080" \
    JENKINS_ADMIN_EMAIL="admin@localhost" \
    ANSIBLE_FORCE_COLOR=true

COPY build/files/jenkins.CLI.xml ${JENKINS_REF_DIR}/jenkins.CLI.xml
COPY build/files/setup-admin.groovy ${JENKINS_REF_DIR}/init.groovy.d/setup-admin.groovy
COPY build/files/kubernetes-cloud.groovy ${JENKINS_REF_DIR}/init.groovy.d/kubernetes-cloud.groovy

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
CMD [ "/usr/local/bin/jenkins.sh" ]
