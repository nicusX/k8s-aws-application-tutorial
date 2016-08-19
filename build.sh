#!/bin/bash

(cd application/spring-hateoas-sample; mvn package)

(cd application; docker build  -t k8s-sample:sample-app .)

(cd h2db; docker build -t k8s-sample:h2db .)
