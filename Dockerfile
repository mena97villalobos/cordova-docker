#https://hub.docker.com/_/openjdk
ARG OPENJDK_VERSION=11
FROM openjdk:${OPENJDK_VERSION}

# Reference default value
ARG OPENJDK_VERSION
#https://gradle.org/releases/
ARG GRADLE_VERSION=7.6.3
#https://www.npmjs.com/package/cordova?activeTab=versions
ARG CORDOVA_VERSION=12.0.0
#https://developer.android.com/studio#command-tools
ARG ANDROID_CMDTOOLS_VERSION=9477386


LABEL maintainer="Bryan Mena <mena97villalobos@gmail.info>"

WORKDIR /opt/src

ENV JAVA_HOME /usr/local/openjdk-${OPENJDK_VERSION}/
ENV ANDROID_SDK_ROOT /usr/local/android-sdk-linux
ENV ANDROID_HOME $ANDROID_SDK_ROOT
ENV GRADLE_USER_HOME /opt/gradle
ENV PATH $PATH:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$GRADLE_USER_HOME/bin
ENV PATH=~/.linuxbrew/bin:~/.linuxbrew/sbin:$PATH

# Gradle
RUN curl -so /tmp/gradle-${GRADLE_VERSION}-bin.zip https://downloads.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip -qd /opt /tmp/gradle-${GRADLE_VERSION}-bin.zip && \
    ln -s /opt/gradle-${GRADLE_VERSION} /opt/gradle

# Android
RUN curl -so /tmp/commandlinetools-linux-${ANDROID_CMDTOOLS_VERSION}_latest.zip https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDTOOLS_VERSION}_latest.zip && \
    mkdir -p $ANDROID_SDK_ROOT/cmdline-tools/ && \
    unzip -qd $ANDROID_SDK_ROOT/cmdline-tools/ /tmp/commandlinetools-linux-${ANDROID_CMDTOOLS_VERSION}_latest.zip && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest


# Update and accept licences
COPY android.packages android.packages
RUN ( sleep 5 && while [ 1 ]; do sleep 1; echo y; done ) | sdkmanager --package_file=android.packages

# Initial Setup
RUN git config --global url."https://".insteadOf git://
RUN export CORDOVA_ANDROID_GRADLE_DISTRIBUTION_URL="https\://services.gradle.org/distributions/gradle-7.6.3-all.zip"

# BREW
RUN apt-get update && \
    apt-get install -y -q --allow-unauthenticated \
    git \
    sudo
RUN useradd -m -s /bin/zsh linuxbrew && \
    usermod -aG sudo linuxbrew &&  \
    mkdir -p /home/linuxbrew/.linuxbrew && \
    chown -R linuxbrew: /home/linuxbrew/.linuxbrew
USER linuxbrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

USER root
RUN chown -R $CONTAINER_USER: /home/linuxbrew/.linuxbrew

# ICON GEN
USER linuxbrew
RUN /home/linuxbrew/.linuxbrew/bin/brew install imagemagick
RUN /home/linuxbrew/.linuxbrew/bin/brew install ghostscript

# NVM
# Installing Node
USER root
SHELL ["/bin/bash", "--login", "-i", "-c"]
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
RUN source /root/.bashrc && nvm install 10.24.0 && nvm use 10.24.0
SHELL ["/bin/bash", "--login", "-c"]
RUN npm config set strict-ssl false

# Cordova
RUN npm i -g cordova@${CORDOVA_VERSION}