FROM chbrandt/heasoft

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh           && \
    URL='https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh' && \
    wget --quiet $URL -O ~/miniconda.sh       && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

ENV PATH /opt/conda/bin:$PATH

RUN yum install -y bc &&\
    yum clean all     &&\
    conda install -y -q astropy pandas &&\
    curl -L https://cpanmin.us | perl - App::cpanminus &&\
    cpanm WWW::Mechanize &&\
    cpanm Carp::Assert &&\
    cpanm Archive::Tar
