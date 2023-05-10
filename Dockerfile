# Some components are taken from the Jupyter stack
# https://github.com/jupyter/docker-stacks for details
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

FROM ubuntu:20.04

# SET OS environment 
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# INSTALL OS dependencies
RUN apt-get update --yes && \
   # - apt-get upgrade is run to patch known vulnerabilities in apt-get packages as
   #   the ubuntu base image is rebuilt too seldom sometimes (less than once a month)
   apt-get upgrade --yes && \
   apt-get install --yes --no-install-recommends \
   apt-utils \
   # - bzip2 is necessary to extract executables
   bzip2 \
   ca-certificates \
   locales \
   sudo \
   fonts-liberation \
   pandoc \
   curl \
   unzip \
   # - tini is installed as a helpful container entrypoint that reaps zombie
   #   processes and such of the actual executable we want to start, see
   #   https://github.com/krallin/tini#why-tini for details.
   tini \
   wget \
   curl \
   unzip \
   iputils-ping \
   openssh-server \
   iputils-ping && \
   apt-get clean && rm -rf /var/lib/apt/lists/* && \
   echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
   locale-gen
 
# INSTALL python and 
# SET python env
# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

RUN apt-get update && \
    apt-get install -y python3 python3-setuptools python3-pip && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    pip3 install py4j && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# INSTALL openjdk
ARG JAVA_MAJOR_VERSION=8

ENV PATH $PATH:$JAVA_HOME/bin
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    openjdk-8-jre openjdk-8-jdk \
    ca-certificates-java && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# INSTALL spark
# INSTALL Spark
# INSTALL all OS dependencies for Spark
ENV SPARK_VERSION 2.4.7
ENV APACHE_SPARK_VERSION="${spark_version}"
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin

RUN apt-get update && \
   apt-get install -y software-properties-common && \
   rm -rf /var/lib/apt/lists/*

RUN curl -sL --retry 3 \
   "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
   | gunzip \
   | tar x -C /usr/ && \
    mv /usr/$SPARK_PACKAGE $SPARK_HOME && \
   chown -R root:root $SPARK_HOME

EXPOSE 5040 4040

# INSTALL Conda
RUN wget --quiet --no-check-certificate https://repo.anaconda.com/archive/Anaconda3-2019.10-Linux-x86_64.sh -O ~/anaconda.sh && \
   /bin/bash ~/anaconda.sh -b -p /opt/conda  && \
   rm ~/anaconda.sh && \
   ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
   echo ". /opt/conda/etc/profile.d/conda.sh" >>  /etc/profile && \
   echo "conda activate base" >>  /etc/profile

# INSTALL ds workflow tools
RUN apt-get update --fix-missing && apt-get install -y \
   git \
   openssh-server \
   krb5-user &&\
   rm -rf /var/lib/apt/lists/*

# Install Jupyter
RUN pip3 install virtualenv jupyter notebook

EXPOSE 4040 8889

# FIX: Notebook not starting
# see: https://stackoverflow.com/questions/25366106/anaconda-ipython-notebook-not-starting-in-server-setup
COPY ./jupyter_notebook_config.py  /root/.jupyter/jupyter_notebook_config.py
COPY ./start_jupyternotebook.sh /app/start_jupyternotebook.sh

WORKDIR /app

CMD [ "jupyter", "notebook" , "--ip=0.0.0.0", "--no-browser", "--port=8889",  "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]


