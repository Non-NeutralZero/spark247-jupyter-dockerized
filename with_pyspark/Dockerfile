# Some components are taken from the Jupyter stack
# https://github.com/jupyter/docker-stacks for more details

FROM ubuntu:20.04 AS builder

# SET OS environment
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# INSTALL OS dependencies
RUN echo "**** Installing OS dependencies ****" && \
   apt-get update --yes && \
   # - apt-get upgrade is run to patch known vulnerabilities in apt-get packages as
   #   the ubuntu base image is rebuilt too seldom sometimes (less than once a month)
   apt-get upgrade --yes && \
   apt-get install --yes --no-install-recommends \
   apt-utils \
   # - bzip2 is necessary to extract executables
   bzip2 \
   ca-certificates \
   # - software-properties-common is necessary in order to use apt-add-repository
   software-properties-common \
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
   openssh-server \
   iputils-ping && \
   apt-get clean && rm -rf /var/lib/apt/lists/* && \
   echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
   locale-gen

# INSTALL Python 3.6 and
# SET python env
# SEE: http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

RUN  echo "**** Installing Python ****" && \
    apt-get update && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.6 python3.6-dev python3-pip python3.6-distutils python-apt && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.6 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# INSTALL openjdk
ARG JAVA_MAJOR_VERSION=8
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64
ENV PATH=$JAVA_HOME/bin:$PATH

RUN echo "**** Installing JAVA ****" && \
    apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
     openjdk-8-jdk \
    ca-certificates-java && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN update-alternatives --set java /usr/lib/jvm/java-${JAVA_MAJOR_VERSION}-openjdk-arm64/jre/bin/java && \
    update-alternatives --set javac /usr/lib/jvm/java-${JAVA_MAJOR_VERSION}-openjdk-arm64/bin/javac && \
    export JAVA_HOME

# INSTALL Spark
# INSTALL all dependencies for Spark
ENV SPARK_VERSION 2.4.0
ENV APACHE_SPARK_VERSION="${SPARK_VERSION}"
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-hadoop2.7
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info"

RUN apt-get update && \
    rm -rf /var/lib/apt/lists/*

RUN echo "**** Installing Spark ****" && \
    wget "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz"
RUN tar -xvzf ${SPARK_PACKAGE}.tgz -C /usr/ && \
    mv /usr/$SPARK_PACKAGE $SPARK_HOME && \
   chown -R root:root $SPARK_HOME

RUN wget https://repo1.maven.org/maven2/org/slf4j/slf4j-api/1.7.30/slf4j-api-1.7.30.jar -P $SPARK_HOME/jars/ && \
    wget https://repo1.maven.org/maven2/org/slf4j/slf4j-log4j12/1.7.30/slf4j-log4j12-1.7.30.jar -P $SPARK_HOME/jars/

EXPOSE 5040 4040

# INSTALL workflow tools
RUN apt-get update --fix-missing && apt-get install -y \
   git \
   openssh-server \
   krb5-user &&\
   rm -rf /var/lib/apt/lists/*

# CACHE PIP Dependencies
COPY requirements.txt /tmp/
RUN echo "**** PIP Installing librairies ****" && \
    pip3 install -r /tmp/requirements.txt


FROM ubuntu:20.04

COPY --from=builder /usr/local /usr/local
COPY --from=builder /usr/lib /usr/lib
COPY --from=builder /usr/bin /usr/bin
COPY --from=builder /usr/spark-2.4.0 /usr/spark-2.4.0
COPY --from=builder /etc/locale.gen /etc/locale.gen
COPY --from=builder /etc/ssh /etc/ssh


ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64
ENV PATH=$JAVA_HOME/bin:$PATH
ENV SPARK_VERSION 2.4.0
ENV APACHE_SPARK_VERSION="${SPARK_VERSION}"
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info"
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    locales \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && locale-gen

EXPOSE 5040 4040


RUN export PYSPARK_SUBMIT_ARGS="--master local[3] pyspark-shell"

ENTRYPOINT ["tini", "-g", "--"]
CMD ["/bin/bash"]