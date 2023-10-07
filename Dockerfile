 # TODO use smaller base image
FROM ubuntu:22.04
LABEL maintainer="jfloff@inesc-id.pt"

###################
# This Dockerfile was based on the following Dockerfiles
# - docker-lineageos: existing unoptimized image
#    https://github.com/AnthoDingo/docker-lineageos/blob/autobuild/Dockerfile
#

ENV \
    # base dir
    BASE_DIR=/home/lineageos \
    # device configuration dir
    DEVICE_CONFIGS_DIR=/home/device-config

# install packages
RUN set -ex ;\
    apt-get update && apt-get install -y --no-install-recommends \
          # install packages
          # https://wiki.lineageos.org/devices/klte/build#install-the-build-packages
          bc \
          bison \
          build-essential \
          ccache \
          curl \
          flex \
          g++-multilib \
          gcc-multilib \
          git \
          git-lfs \
          gnupg \
          gperf \
          imagemagick \
          lib32ncurses5-dev \
          lib32readline-dev \
          lib32z1-dev \
          libelf-dev \
          liblz4-tool \
          libncurses5 \
          libncurses5-dev \
          libsdl1.2-dev \
          libssl-dev \
          libxml2 \
          libxml2-utils \
          lzop \
          pngcrush \
          rsync \
          schedtool \
          squashfs-tools \
          xsltproc \
          zip \
          zlib1g-dev \
          # extra packages
          # for repo
          python3 \
          # for repo
          openssh-client \
          # for ps command
          procps \
          # no less on debian *gasp!*
          less \
          # so we have an editor inside the container
          vim \
          # has 'col' package needed for 'breakfast'
          bsdmainutils \
          # unzip is needed at least for Fairphone 4 build
          unzip \
          # we can't build kernel on root (like docker runs)
          # we add these so we have a non-root user
          fakeroot \
          sudo \
          # needed for downloading the platform-tools and the repo binary
          ca-certificates \
          ;\
    rm -rf /var/lib/apt/lists/*

# run config in a seperate layer so we cache it
RUN set -ex ;\
    # allow non-root user to remount fs
    # adding ALL permissions so they can do other stuff in the future, like sudo vim
    curl -L -O https://dl.google.com/android/repository/platform-tools-latest-linux.zip ;\
    unzip platform-tools-latest-linux.zip -d /usr/bin ;\
    # Android Setup
    # create paths: https://wiki.lineageos.org/devices/klte/build#create-the-directories
    curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/bin/repo ;\
    chmod a+x /usr/bin/repo ;\
    ln -s /usr/bin/python3 /usr/bin/python && \
    # config git coloring
    # check this link for things repo check:
    # https://gerrit.googlesource.com/git-repo/+/master/subcmds/init.py#328
    git config --global color.ui true ;\
    # source init when any bash is called (which includes the lineageos script)
    echo "source /etc/profile.d/init.sh" >> /etc/bash.bashrc

# copy default configuration into container
COPY default.env init.sh /etc/profile.d/
# copy script and config vars
COPY lineageos /bin
# copy dir with several PRed device configurations
COPY device-config $DEVICE_CONFIGS_DIR
# copy entrypoint wrapper script so the permissions on the host system are reset at the end
COPY entrypoint_wrapper.sh /entrypoint_wrapper.sh

# set volume and user home folder
RUN mkdir -p "$BASE_DIR" && chown "$USER:$USER" "$BASE_DIR"
USER $USER
WORKDIR $BASE_DIR

ENTRYPOINT ["/entrypoint_wrapper.sh"]
CMD /bin/bash
