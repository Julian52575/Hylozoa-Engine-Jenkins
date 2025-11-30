FROM jenkins/jenkins:latest
#image from the jenkins website

ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

USER root
RUN apt-get update && apt-get install -y lsb-release \
  xz-utils ca-certificates sudo lsb-release

#Installing Nix package manager
RUN mkdir -p /nix && chown root:root /nix
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux \
  --extra-conf "sandbox = false" \
  --init none \
  --no-confirm
RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && nix --version

#Adding the Jenkins automate installation Key to system
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg

#Add Jenkins APT Repository Entry
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

#Installing the needed dependensies
#USER root
#RUN apt-get install -y docker-ce-cli
#RUN apt-get install -y sudo make gcc file #ca-certificates curl gnupg

#Installing the plugins :
USER jenkins
RUN jenkins-plugin-cli --plugins cloudbees-folder
RUN jenkins-plugin-cli --plugins configuration-as-code
RUN jenkins-plugin-cli --plugins credentials
RUN jenkins-plugin-cli --plugins github
RUN jenkins-plugin-cli --plugins instance-identity
RUN jenkins-plugin-cli --plugins job-dsl
RUN jenkins-plugin-cli --plugins script-security
RUN jenkins-plugin-cli --plugins structs
RUN jenkins-plugin-cli --plugins role-strategy
RUN jenkins-plugin-cli --plugins ws-cleanup