# Base image with dependencies
FROM ubuntu:18.04 AS base

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=Europe/Berlin

# Package dependencies
RUN apt-get -y update && apt-get -y upgrade && \
    apt-get -y install \
        bash git \
        cmake build-essential autotools-dev autoconf pkg-config \
        g++ gfortran gdb gdbserver \
        libpthread-stubs0-dev qt5-default qttools5-dev qttools5-dev-tools libqt5svg5-dev libqt5xmlpatterns5-dev qtxmlpatterns5-dev-tools \
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

# GDB server # -DSUPERBUILD_ALLOW_DEBUG=1 -DCMAKE_BUILD_TYPE_paraview=Debug
EXPOSE 2000


# Image for automatic compiling
FROM base AS release

# Compile components
RUN mkdir -p /app/paraview-build
WORKDIR /app/paraview-build
RUN cmake ../paraview-superbuild -DENABLE_xdmf3=1 -DENABLE_python3=1 -DENABLE_matplotlib=1 -DENABLE_numpy=1 \
        -DENABLE_qt5=1 -DENABLE_mpi=1 -DENABLE_hdf5=1 -DUSE_SYSTEM_qt5=1 -DCMAKE_BUILD_TYPE=Release && \
    make download-all && \
    rm -rf superbuild/paraview/src/VTK && \
    git clone --single-branch --branch="xdmf3-highorder" --depth=1 https://gitlab.kitware.com/ChristophHonal/vtk.git superbuild/paraview/src/VTK && \
    make
  
# Update VTK and recompile paraview
ARG VTK_TAG="d03ecb1f25d1d94840280bc678150175f8879ecb"
RUN cd superbuild/paraview/src/VTK && \
    git pull && \
    git checkout "$VTK_TAG" && \
    cd /app/paraview-build && \
    rm -f superbuild/paraview/stamp/paraview-build && \
    make

# Pack assets
RUN cd /app/paraview-build/install && \
    tar -zcvf /app/paraview-5.8.0-xdmf3-highorder-release.tar.gz .