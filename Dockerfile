#https://hub.docker.com/_/openjdk
ARG OPENJDK_VERSION=11
FROM openjdk:${OPENJDK_VERSION}

# Reference default value
ARG OPENJDK_VERSION
#https://gradle.org/releases/
ARG GRADLE_VERSION=6.5
#https://www.npmjs.com/package/cordova?activeTab=versions
ARG CORDOVA_VERSION=12.0.0
#https://developer.android.com/studio#command-tools
ARG ANDROID_CMDTOOLS_VERSION=9477386
LABEL maintainer="Bryan Mena <mena97villalobos@gmail.info>"
WORKDIR /opt/src

ENV JAVA_HOME=/usr/local/openjdk-${OPENJDK_VERSION}/
ENV ANDROID_SDK_ROOT=/sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
ENV PATH=$PATH:$ANDROID_SDK_ROOT/emulator
ENV PATH=$PATH:$ANDROID_SDK_ROOT/tools
ENV PATH=$PATH:$ANDROID_SDK_ROOT/tools/bin
ENV PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/tools/bin
ENV GRADLE_USER_HOME=/opt/gradle
ENV PATH=$PATH:~/.linuxbrew/bin:~/.linuxbrew/sbin
ENV CORDOVA_ANDROID_GRADLE_DISTRIBUTION_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-all.zip"

# Gradle
RUN curl -so /tmp/gradle-${GRADLE_VERSION}-bin.zip https://downloads.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip -qd /opt /tmp/gradle-${GRADLE_VERSION}-bin.zip && \
    ln -s /opt/gradle-${GRADLE_VERSION} /opt/gradle

# Install dependencies
RUN apt-get update && apt-get install -y wget unzip

# Set environment variables
ENV ANDROID_SDK_ROOT=/sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools

# Create directory for Android SDK
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools

# Download and install Android command-line tools
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /sdk/cmdline-tools.zip \
    && unzip /sdk/cmdline-tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools \
    && rm /sdk/cmdline-tools.zip \
    && mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest

# Verify that sdkmanager exists
RUN ls -la $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/

# Accept licenses and install SDK components
RUN yes | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --licenses \
    && $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --install "platform-tools" "platforms;android-33"

# Initial Setup
RUN git config --global url."https://".insteadOf git://

# NVM
# Install NVM
ENV NVM_DIR=/root/.nvm
ENV NODE_VERSION=10.24.1

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \
    && ln -s "$NVM_DIR/versions/node/v$NODE_VERSION/bin/node" /usr/bin/node \
    && ln -s "$NVM_DIR/versions/node/v$NODE_VERSION/bin/npm" /usr/bin/npm

# Make nvm command available in the shell
RUN echo "export NVM_DIR=$NVM_DIR" >> /root/.bashrc \
    && echo "[ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\"" >> /root/.bashrc \
    && echo "[ -s \"$NVM_DIR/bash_completion\" ] && . \"$NVM_DIR/bash_completion\"" >> /root/.bashrc

RUN npm config set strict-ssl false

# Cordova
RUN npm i -g cordova@${CORDOVA_VERSION}
RUN npm i -g grunt
RUN npm i -g bower

CMD ["bash"]
