# FROM jboss/base-jdk:8
# 生产时，建议用商用版.
FROM registry.redhat.io/redhat-openjdk-18/openjdk18-openshift:latest
# FROM jboss/openjdk18-rhel7
ENV EAP_VERSION 7.2.0
ENV JDBC_MYSQL_VERSION 5.1.46

ENV LAUNCH_JBOSS_IN_BACKGROUND 1
ENV PROXY_ADDRESS_FORWARDING false
ENV JBOSS_HOME /opt/jboss/eap
ENV LANG en_US.UTF-8


ARG EAP_DIST=jboss-eap-7.2.0.zip
ARG EAP_PATCH=jboss-eap-7.2.3-patch.zip

USER root

# RUN yum update -y && yum install -y epel-release git && yum install -y jq openssl which && yum clean all
# ADD $EAP_DIST /tmp/
# ADD $EAP_PATCH /tmp/

ADD tools /opt/jboss/tools
ADD drivers /opt/jboss/drivers

RUN /opt/jboss/tools/build-eap.sh

USER 185

EXPOSE 8080
EXPOSE 8443

ENTRYPOINT [ "/opt/jboss/tools/docker-entrypoint.sh" ]

CMD ["-b", "0.0.0.0"]
