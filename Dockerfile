FROM bioconductor/release_core2:R3.4.2_Bioc3.6

RUN R -e 'biocLite("DiffBind")'

COPY pipeline.R /usr/local/bin/

CMD ["pipeline.R"]

WORKDIR /seq/epiprod/Data
