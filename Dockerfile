ARG R_VERSION=4.0.0

FROM r-base:${R_VERSION} AS r

RUN ./install.R

ENTRYPOINT []