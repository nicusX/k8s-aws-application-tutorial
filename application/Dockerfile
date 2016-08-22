FROM ubuntu:16.04

# Based on https://github.com/dockerfile/java
# Built images are not available https://forums.docker.com/t/dockerfile-java-oracle-java7-repo-not-found-issue/1472 Thanks, Oracle ;)
MAINTAINER Lorenzo Nicora <lorenzo.nicora@opencredo.com>

# Install Java.
# I have to install add-apt-repository, apparently missing in Ubuntu 16.04 http://lifeonubuntu.com/ubuntu-missing-add-apt-repository-command/
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  apt-get update && \
  apt-get install -y software-properties-common python-software-properties && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# (Fat) jar file of the application
ENV JARFILE spring-hateoas-sample-0.0.1-SNAPSHOT.jar

# Copy the application (fat) jar (the application must be already packaged)
COPY spring-hateoas-sample/target/${JARFILE} /opt/spring/

# Spring profile
ENV SPRING_PROFILE kubernetes

# Load Sample data
ENV SAMPLE_DATA false

# Start the java application
ENTRYPOINT java \
  -Dspring.profiles.active=${SPRING_PROFILE} \
  -Dloadsampledata=${SAMPLE_DATA} \
  -Dexternaldb=true \
  -Dendpoints.jmx.enabled=false \
  -Djava.security.egd=file:/dev/./urandom \
  -jar /opt/spring/${JARFILE} \
  --spring.config.location=file:/etc/spring/

# Volume for Spring configuration
VOLUME /etc/spring

EXPOSE 8080
