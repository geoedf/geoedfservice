FROM centos:centos7

RUN yum -y update | /bin/true

RUN groupadd --gid 808 geoedf
RUN useradd --gid 808 --uid 550 --create-home --password 'geoedf' geoedf

# Configure Sudo
RUN echo -e "geoedf ALL=(ALL)       NOPASSWD:ALL\n" >> /etc/sudoers

# Test requirements
RUN yum -y install epel-release
RUN yum -y install ant | /bin/true
RUN yum -y install \
     ant-apache-regexp \
     ant-junit \
     bc \
     bzip2-devel \
     ca-certificates \ 
     cryptsetup \
     epel-release \
     gcc \
     gcc-c++ \
     git \
     golang \
     iptables \ 
     java-1.8.0-openjdk-devel \
     libffi-devel \
     libseccomp-devel \
     libuuid-devel \
     lxc \
     make \
     mpich-devel \
     mysql-devel \
     openssl-devel \
     patch \
     postgresql-devel \
     python36-devel \
     python36-pip \
     python36-pyOpenSSL \
     python36-pytest \
     python36-PyYAML \
     python36-setuptools \
     R-devel \
     readline-devel \
     rpm-build \
     singularity \
     sqlite-devel \
     sudo \ 
     squashfs-tools \
     tar \
     vim \ 
     wget \
     which \
     yum-plugin-priorities \
     zlib-devel 

# Python packages
RUN pip3 install tox six sphinx recommonmark sphinx_rtd_theme sphinxcontrib-openapi javasphinx

# Set Timezone
RUN cp /usr/share/zoneinfo/America/Indianapolis /etc/localtime

# Get Condor yum repo
RUN curl -o /etc/yum.repos.d/condor.repo https://research.cs.wisc.edu/htcondor/yum/repo.d/htcondor-stable-rhel7.repo
RUN rpm --import https://research.cs.wisc.edu/htcondor/yum/RPM-GPG-KEY-HTCondor
RUN yum -y install condor minicondor
RUN sed -i 's/condor@/geoedf@/g' /etc/condor/config.d/00-minicondor

RUN usermod -a -G condor geoedf
RUN chmod -R g+w /var/{lib,log,lock,run}/condor

RUN chown -R geoedf /home/geoedf/

RUN echo -e "condor_master > /dev/null 2>&1" >> /home/geoedf/.bashrc

# User setup
USER geoedf

WORKDIR /home/geoedf

# install BOSCO
RUN curl -o condor.tar.gz https://research.cs.wisc.edu/htcondor/tarball/9.1/9.2.0/release/condor-9.2.0-x86_64_CentOS7-stripped.tar.gz && tar -xf condor.tar.gz

RUN cd condor-9.2.0-1-x86_64_CentOS7-stripped && ./bosco_install

# Set up config for ensemble manager
RUN mkdir /home/geoedf/.pegasus \
    && echo -e "#!/usr/bin/env python3\nUSERNAME='geoedf'\nPASSWORD='geoedf'\n" >> /home/geoedf/.pegasus/service.py \
    && chmod u+x /home/geoedf/.pegasus/service.py

# Get Pegasus 
# ver. is master from Aug 31
RUN git clone https://github.com/pegasus-isi/pegasus.git \
    && cd pegasus \
    && git checkout f9b9f63a42cc -b beta1 \
    && ant dist \
    && cd dist \
    && mv $(find . -type d -name "pegasus-*") pegasus

ENV PATH /home/geoedf/pegasus/dist/pegasus/bin:$HOME/.pyenv/bin:$PATH:/usr/lib64/mpich/bin
ENV PYTHONPATH /home/geoedf/pegasus/dist/pegasus/lib64/python3.6/site-packages

# Set up pegasus database
RUN /home/geoedf/pegasus/dist/pegasus/bin/pegasus-db-admin create

# Expose PATH and PYTHONPATH environment variables
RUN echo -e "export PATH=/home/geoedf/pegasus/dist/pegasus/bin:/home/geoedf/.pyenv/bin:\$PATH:/usr/lib64/mpich/bin" >> /home/geoedf/.bashrc
RUN echo -e "export PYTHONPATH=/home/geoedf/pegasus/dist/pegasus/lib64/python3.6/site-packages" >> /home/geoedf/.bashrc

# ------------------------------
# GeoEDF specific section begins
# ------------------------------

USER root

# Install hpccm 
# used to convert high-level container recipes into Singularity recipes

RUN pip3 install hpccm

# Install GeoEDF workflow engine

RUN cd /tmp && \
    git clone https://github.com/geoedf/engine.git && \
    cd engine && \
    git checkout pegasus-5.0 && \
    pip3 install . && \
    rm -rf /tmp/engine

# create folders to store job data and local Singularity images

RUN mkdir /data && \
    chown geoedf: /data && \
    chmod 777 /data && \
    mkdir /images && \
    chown geoedf: /images && \
    chmod 755 /images

# create remote registry configuration for Singularity 

RUN mkdir /home/geoedf/.singularity 

ADD ./config/remote.yaml /home/geoedf/.singularity/

RUN chown -R geoedf: /home/geoedf/.singularity && \
    chmod 600 /home/geoedf/.singularity/remote.yaml

RUN python3 -m pip install -U pip && pip install flask-restful

USER geoedf

# ------------------------------
# GeoEDF specific section ends
# ------------------------------

WORKDIR /home/geoedf/

ADD --chown=geoedf:geoedf runservice.sh /home/geoedf/

ADD --chown=geoedf:geoedf api.py /home/geoedf/

RUN chmod +x runservice.sh

CMD ["/home/geoedf/runservice.sh"]
