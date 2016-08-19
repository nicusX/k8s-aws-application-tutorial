FROM ubuntu:16.04

# Based on https://github.com/oscarfonts/docker-h2
# and on https://github.com/dockerfile/java

MAINTAINER Lorenzo Nicora <lorenzo.nicora@opencredo.com>

# Install Java.
# I have to install add-apt-repository, apparently missing in Ubuntu 16.04 http://lifeonubuntu.com/ubuntu-missing-add-apt-repository-command/
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  apt-get update && \
  apt-get install -y software-properties-common python-software-properties curl unzip && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# H2 download URL
ENV H2_DOWNLOAD http://www.h2database.com/h2-2014-04-05.zip

# Install H2
RUN curl ${H2_DOWNLOAD} -o h2.zip \
    && unzip h2.zip -d /opt/ \
    && rm h2.zip \
    && mkdir -p /var/h2-data

# Run H2 in server mode
ENTRYPOINT java -cp /opt/h2/bin/h2*.jar org.h2.tools.Server \
 	-web -webAllowOthers -webPort 81 \
 	-tcp -tcpAllowOthers -tcpPort 1521 \
 	-baseDir /var/h2-data

VOLUME /var/h2-data
EXPOSE 81 1521
