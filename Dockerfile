FROM nfcore/base
LABEL authors="Marc Hoeppner" \
      description="Docker image containing all requirements for IKMB QC pipeline"

COPY environment.yml /

RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/ngs-qc-1.6/bin:$PATH

RUN apt-get update && apt-get -y install procps
