FROM nfcore/base
LABEL authors="Marc Hoeppner" \
      description="Docker image containing all requirements for IKMB QC pipeline"

COPY environment.yml /

RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/ngs-qc-1.6/bin:/opt/fastq_screen:$PATH

RUN apt-get update && apt-get -y install procps wget 

RUN cd /opt && cd /opt && wget https://github.com/StevenWingett/FastQ-Screen/archive/refs/tags/v0.15.2.tar.gz \
	&& tar -xvf v0.15.2.tar.gz && mv FastQ-Screen-0.15.2 fastq_screen && rm *.tar.gz
