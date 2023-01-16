FROM debian:11 as build

RUN apt update -y && apt install -y build-essential \
        libcurl4-openssl-dev \
        liblzma-dev \
        libssl-dev \
        python-dev-is-python3 \
        python3-pip \
        curl \
    && rm -rf /var/lib/apt/lists/*

ARG MONGO_VERSION=5.0.12

RUN mkdir /src && \
    curl -o /tmp/mongo.tar.gz -L "https://github.com/mongodb/mongo/archive/refs/tags/r${MONGO_VERSION}.tar.gz" && \
    tar xaf /tmp/mongo.tar.gz --strip-components=1 -C /src && \
    rm /tmp/mongo.tar.gz

WORKDIR /src

COPY ./no-sandybridge-optimization.diff /no-sandybridge-optimization.diff
RUN patch -p0 < /no-sandybridge-optimization.diff

RUN python3 -m pip install requirements_parser && \
    python3 -m pip install -r etc/pip/compile-requirements.txt && \
    python3 buildscripts/scons.py install-core MONGO_VERSION="${MONGO_VERSION}" --release --disable-warnings-as-errors && \
    mv build/install /install && \
    strip --strip-debug /install/bin/mongo && \
    strip --strip-debug /install/bin/mongod && \
    strip --strip-debug /install/bin/mongos && \
    rm -rf build

FROM debian:11

RUN apt update -y && \
    apt install -y libcurl4 && \
    apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /install/bin/mongo* /usr/local/bin/
COPY ./entrypoint.sh /entrypoint.sh

RUN mkdir -p /data/db && \
    chmod -R 750 /data && \
    chown -R 999:999 /data && \
    chmod +x /entrypoint.sh

USER 999

ENTRYPOINT [ "/entrypoint.sh" ]
