ARG R_VERSION=4.1.0

### R libraries

FROM r-base:${R_VERSION} AS r

RUN apt-get update -qq && \
    apt-get install -qq --no-install-recommends \
      libxml2-dev \
      libcurl4-openssl-dev \
      librsvg2-dev \
      libv8-dev \
      libssl-dev

COPY scripts/install.R .

RUN ./install.R

### Final image

FROM r

COPY diffBind.r .

ENTRYPOINT []