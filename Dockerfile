FROM nfcore/base
LABEL authors="Marc Hoeppner" \
      description="Docker image containing all requirements for IKMB QC pipeline"

COPY environment.yml /

RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/ngs-qc-1.7/bin:/opt/biobloom/bin:$PATH

RUN apt-get -y update && apt-get -y install procps make gcc  git build-essential autotools-dev automake libsparsehash-dev libboost-all-dev \
cmake zlib1g-dev coreutils g++  zlib1g-dev libyaml-dev xml2 libjson-c-dev libssl-dev

RUN cd /opt && \
        git clone https://github.com/simongog/sdsl-lite.git && \
        cd sdsl-lite && \
        ./install.sh /usr/local/

RUN cd /opt && \
        wget https://github.com/bcgsc/biobloom/releases/download/2.3.1/biobloomtools-2.3.1.tar.gz && \
        tar -xvf biobloomtools-2.3.1.tar.gz && rm biobloomtools-2.3.1.tar.gz && cd  biobloomtools-2.3.1 && \
        ./configure --prefix=/opt/biobloom && make install && \
        cd /opt && rm -Rf biobloomtools-2.3.1

RUN cd /opt && wget https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.2.tar.gz && tar -xvf ruby-3.2.2.tar.gz && cd ruby-3.2.2 && ./configure && make && make install
RUN cd /opt && rm -Rf ruby*

RUN gem install rubyXL
RUN gem install json
RUN gem install rest-client
