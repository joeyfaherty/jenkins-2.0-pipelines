FROM jenkins/jenkins:lts

MAINTAINER joeyfaherty@live.ie

USER root
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY jobs/multibranch-pipeline-demo/config.xml /var/jenkins_home/jobs/multibranch-pipeline-demo/config.xml
USER jenkins

# install plugins in plugins.txt and dependant plugins
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt