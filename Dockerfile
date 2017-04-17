FROM debian:8.7
MAINTAINER David K. Jackson <david.jackson+YeastStrainsStudy@sanger.ac.uk>
RUN apt-get update
RUN apt-get install -y curl git python g++ make
#RUN apt-get install -y  libhdf5-dev libhdf5-cpp-8
RUN mkdir -p /tmp/build
RUN cd /tmp/build && \
git clone git://github.com/PacificBiosciences/pitchfork.git && \
cd pitchfork && \
echo PREFIX=/usr/local > settings.mk && \
make init && \
make blasr
RUN cd /tmp/build && \
git clone https://github.com/fenderglass/ABruijn.git && \
cd ABruijn && \
python setup.py install --prefix=/usr/local
RUN cd /tmp/build && \
git clone https://github.com/marbl/canu.git && \
cd /tmp/build/canu/src && TARGET_DIR=/usr/local/bin make
#RUN cd /tmp/build && \
#curl -L 'https://sourceforge.net/projects/wgs-assembler/files/wgs-assembler/wgs-8.3/wgs-8.3rc2.tar.bz2/download' | tar jxf - && \
#cd /tmp/build/wgs-8.3rc2/kmer  && ln -s /usr/local/ Linux-amd64 && make install && \
#cd /tmp/build/wgs-8.3rc2/src  && ln -s /usr/local ../Linux-amd64 && make
RUN curl -L 'https://sourceforge.net/projects/wgs-assembler/files/wgs-assembler/wgs-8.3/wgs-8.3rc2-Linux_amd64.tar.bz2/download' | tar jxf - -C /usr/local && \
ln -s ../wgs-8.3rc2/Linux-amd64/bin/runCA /usr/local/bin/runCA
RUN apt-get install -y python-dev python-pip && pip install --upgrade pip setuptools
RUN cd /tmp/build && \
git clone https://github.com/PacificBiosciences/FALCON-integrate.git && \
cd FALCON-integrate && \
git submodule update --init && \
export FALCON_PREFIX=/usr/local export FALCON_WORKSPACE=$PWD && make init && make config-standard && make all
RUN cd /tmp/build && \
git clone https://github.com/ruanjue/smartdenovo.git && cd smartdenovo && make && make install
RUN cd /tmp/build && \
git clone https://github.com/lh3/minimap.git && cd minimap && make && cp minimap /usr/local/bin/ && cp minimap.1 /usr/local/share/man/man1/
RUN cd /tmp/build && \
git clone https://github.com/lh3/miniasm.git && cd miniasm && make && cp miniasm /usr/local/bin/ && cp miniasm.1 /usr/local/share/man/man1/
RUN apt-get install -y wget
RUN cd /tmp/build && \
git clone --recursive https://github.com/jts/nanopolish.git && cd nanopolish && make && cp nanopolish /usr/local/bin/
RUN cd /tmp/build && \
git clone -b spades_3.10.1 https://github.com/ablab/spades.git  && cd spades/assembler && \
PREFIX=/usr/local ./spades_compile.sh
RUN cd /tmp/build && \
git clone https://github.com/isovic/racon.git  && cd racon && make modules && make tools && make -j && cp bin/racon /usr/local/bin/
RUN apt-get clean
#RUN rm -rf /tmp/build
