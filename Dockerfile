FROM debian:bullseye AS builder

ENV PIAWARE_VERSION 8.2
ENV MLAT yes

RUN apt update && apt install -y \
  autoconf \
  build-essential \
  debhelper \
  devscripts \
  patchelf \
  git \
  libboost-filesystem-dev \
  libboost-program-options-dev \
  libboost-regex-dev \
  libboost-system-dev \
  libz-dev \
  python3-dev \
  python3-venv \
  python3-setuptools \
  socat \
  tcl8.6-dev \
  wget

# Workaround from version 3.8.1. Should be removed in the future. 
# Still open with 8.2. Affects debian package tcl-tls at least up to 1.7.22.
RUN apt install -y libssl-dev tcl-dev chrpath
RUN git clone http://github.com/flightaware/tcltls-rebuild.git /tcltls-rebuild
WORKDIR /tcltls-rebuild
RUN ./prepare-build.sh bullseye
WORKDIR /tcltls-rebuild/package-bullseye
RUN dpkg-buildpackage -b

RUN git clone https://github.com/flightaware/piaware_builder.git /piaware_builder
WORKDIR /piaware_builder
RUN git fetch --all --tags && git checkout tags/v${PIAWARE_VERSION}
RUN ./sensible-build.sh bullseye
WORKDIR /piaware_builder/package-bullseye
RUN dpkg-buildpackage -b


FROM debian:bullseye

COPY --from=builder /tcltls-rebuild/tcl-tls_*.deb /tmp
COPY --from=builder /piaware_builder/piaware_*.deb /tmp

RUN apt update \
 && apt install -y \
        /tmp/*.deb \
        socat \
 && rm -rf /var/lib/apt/lists/* \
 && rm /tmp/*.deb

WORKDIR /
COPY start.sh /
RUN chmod +x /start.sh

ENTRYPOINT [ "/start.sh" ]
