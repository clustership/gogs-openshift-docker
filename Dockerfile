FROM golang:1.15 as builder

MAINTAINER Philippe Huet <phuet@redhat.com>

ARG GOGS_VERSION="0.12.2"

RUN mkdir /src

WORKDIR /src
RUN git clone --depth 1 --branch v${GOGS_VERSION} https://github.com/gogs/gogs.git gogs
WORKDIR /src/gogs
RUN CGO_ENABLED=0 GOOS=linux go build --tags "cert" -o gogs

FROM registry.redhat.io/ubi8

MAINTAINER Erik Jacobs <erikmjacobs@gmail.com>
# Copy the binary to the production image from the builder stage.
COPY --from=builder /src/gogs/gogs /usr/bin/gogs


LABEL name="Gogs - Go Git Service" \
      vendor="Gogs" \
      io.k8s.display-name="Gogs - Go Git Service" \
      io.k8s.description="The goal of this project is to make the easiest, fastest, and most painless way of setting up a self-hosted Git service." \
      summary="The goal of this project is to make the easiest, fastest, and most painless way of setting up a self-hosted Git service." \
      io.openshift.expose-services="3000,gogs" \
      io.openshift.tags="gogs" \
      build-date="2017-04-02" \
      version="${GOGS_VERSION}" \
      release="1"

ENV HOME=/var/lib/gogs
ENV GOGS_HOME=${HOME}
ENV GOGS_CUSTOM=/etc/gogs
ENV USER=gogs

COPY ./root/usr /usr

# RUN curl -L -o /etc/yum.repos.d/gogs.repo https://dl.packager.io/srv/pkgr/gogs/pkgr/installer/el/7.repo && \
#     rpm --import https://rpm.packager.io/key && \
#     yum -y install epel-release && \
#     yum -y --setopt=tsflags=nodocs install gogs-${GOGS_VERSION} nss_wrapper gettext && \
#     yum -y clean all && \
#     mkdir -p /var/lib/gogs
RUN dnf -y --setopt=tsflags=nodocs install nss_wrapper \
           git \
    && \
    dnf clean all

RUN mkdir -p \
  ${GOGS_HOME} \
  ${GOGS_CUSTOM} \
  /var/log/gogs && \
  /usr/bin/fix-permissions ${GOGS_HOME} && \
    /usr/bin/fix-permissions ${GOGS_CUSTOM} && \
    /usr/bin/fix-permissions /var/log/gogs

EXPOSE 3000
# USER 997

WORKDIR $GOGS_HOME
USER 1001

CMD ["/usr/bin/rungogs"]
