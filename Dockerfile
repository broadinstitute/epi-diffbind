ARG R_VERSION=4.0.0

FROM r-base:${R_VERSION} AS r

COPY scripts/install.R .

RUN ./install.R

ENTRYPOINT []
