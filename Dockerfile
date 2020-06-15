FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=Europe/Berlin

# Package dependencies
RUN apt-get -y update && apt-get -y upgrade && \
    apt-get -y install \
        bash git \
        cmake build-essential autotools-dev autoconf pkg-config \
        g++ gfortran gdb gdbserver \
        mpich libmpich-dev libpthread-stubs0-dev  \
        qt5-default qttools5-dev qttools5-dev-tools libqt5svg5-dev libqt5xmlpatterns5-dev qtxmlpatterns5-dev-tools \
        xorg mesa-common-dev libgl1-mesa-glx libgl1-mesa-dev libglu1-mesa-dev freeglut3-dev mesa-utils && \
    rm -rf /var/lib/apt/lists/*

# User
RUN groupadd -g 1000 pvbuilder && \
    useradd -r -u 1000 -g pvbuilder pvbuilder && \
    mkdir -p /app && \
    chown -R pvbuilder:pvbuilder /app
USER pvbuilder

# Paraview Superbuild
WORKDIR /app
RUN git clone --recursive https://gitlab.kitware.com/paraview/paraview-superbuild.git && \
    cd paraview-superbuild && \
    git fetch origin && git checkout v5.8.0 && git submodule update

# GDB server
EXPOSE 2000

# Recompilation and Debugging entrypoint
ENTRYPOINT [ "/bin/bash", "-c", "cd /app/paraview-build && rm -f superbuild/paraview/stamp/paraview-build && make && gdbserver :2000 ./install/bin/paraview" ]


# cmake ../paraview-superbuild -DENABLE_xdmf3=1 -DENABLE_qt5=1 -DENABLE_mpi=1 -DENABLE_hdf5=1 -DUSE_SYSTEM_qt5=1 -DUSE_SYSTEM_mpi=1 -DSUPERBUILD_ALLOW_DEBUG=1 -DCMAKE_BUILD_TYPE_paraview=Debug