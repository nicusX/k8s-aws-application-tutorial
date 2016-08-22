#!/bin/bash

(cd application/spring-hateoas-sample; mvn package)

(cd application; docker build  -t k8s-sample_application:0.1 .)

(cd h2db; docker build -t k8s-sample_h2db:0.1 .)
