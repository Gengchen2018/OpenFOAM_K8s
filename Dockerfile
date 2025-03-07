# base
FROM ubuntu:20.04

# interactive
ENV DEBIAN_FRONTEND=noninteractive

# Set the timezone
ENV TZ=Asia/Beijing
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# install essentials
RUN apt-get update
RUN apt-get install -y gcc
RUN apt-get install -y g++
RUN apt-get install -y gdb
RUN apt-get install -y vim
RUN apt-get install -y iputils-ping
RUN apt-get install -y net-tools

# install ssh client
RUN apt-get install -y ssh

# install essentials
RUN apt-get install -y curl
RUN apt-get install -y nano
RUN apt-get install -y git
RUN apt-get install -y htop
RUN apt-get install -y build-essential
RUN apt-get install -y software-properties-common
RUN apt-get install ca-certificates

# clean
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
RUN apt-get update

# add user "foam"
RUN useradd --user-group --create-home --shell /bin/bash foam
RUN echo "foam ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# install useful openfoam tools
RUN apt-get install -y ffmpeg

# download openfoam and update repos
RUN wget -q -O - http://dl.openfoam.com/add-debian-repo.sh | bash
RUN apt-get update

# install latest openfoam
RUN apt-get install -y openfoam2212-default

# install ssh-server
RUN apt-get update && \
    apt-get install -y openssh-server && \
    # start ssh
    mkdir /var/run/sshd && \
    service ssh start

# make SSH key pair
USER foam
RUN mkdir -p /home/foam/.ssh && \
    chmod 700 /home/foam/.ssh && \
    ssh-keygen -t rsa -b 2048 -N "" -f /home/foam/.ssh/id_rsa && \
    cp /home/foam/.ssh/id_rsa.pub /home/foam/.ssh/authorized_keys && \
    chmod 600 /home/foam/.ssh/authorized_keys
USER root

# root login
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# skip config key
RUN echo "Host *\n    StrictHostKeyChecking no\n" >> ~foam/.ssh/config

# source openfoam and fix docker mpi
RUN sed -i '1s/^/source \/usr\/lib\/openfoam\/openfoam2212\/etc\/bashrc\nexport OMPI_MCA_btl_vader_single_copy_mechanism=none\n/' ~foam/.bashrc

# start ssh
RUN echo "service ssh start" >> /root/.bashrc
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

