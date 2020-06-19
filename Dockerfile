# Base image with dependencies
FROM ubuntu:18.04 AS base

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=Europe/Berlin

# Package dependencies
RUN apt-get -y update && apt-get -y upgrade && \
    apt-get -y install \
        rsync bash git wget fuse \
        cmake build-essential autotools-dev autoconf pkg-config \
        g++ gfortran gdb gdbserver \
        libpthread-stubs0-dev python \
        xorg mesa-common-dev libgl1-mesa-glx libgl1-mesa-dev libglu1-mesa-dev freeglut3-dev mesa-utils && \
    rm -rf /var/lib/apt/lists/*

# User and FUSE
ARG UID=1000
ARG GID=1000
RUN groupadd -g "${UID}" pvbuilder && \
    useradd -r -u "${GID}" -g pvbuilder pvbuilder && \
    mkdir -p /app && \
    chown -R pvbuilder:pvbuilder /app && \
    groupadd fuse && \
    usermod -a -G fuse pvbuilder
USER pvbuilder

# Paraview Superbuild
RUN cd /app && \
    git clone --recursive https://gitlab.kitware.com/paraview/paraview-superbuild.git && \
    cd paraview-superbuild && \
    git fetch origin && git checkout v5.8.0 && git submodule update

# Download and precompile sources
RUN mkdir -p /app/paraview-build && \
    cd /app/paraview-build && \
    cmake --parallel=$(nproc) ../paraview-superbuild -DENABLE_xdmf3=1 -DENABLE_python3=1 -DENABLE_matplotlib=1 -DENABLE_numpy=1 \
        -DENABLE_qt5=1 -DENABLE_mpi=1 -DENABLE_hdf5=1 && \
    make download-all && \
    find /app/paraview-build -mindepth 1 -maxdepth 1 ! -name 'downloads' -exec rm -rf {} \;


# Image for release image
FROM base AS release

# Dependencies
RUN cd /app && \
    wget "https://github.com/AppImage/AppImageKit/releases/download/12/appimagetool-x86_64.AppImage" && \
    chmod +x appimagetool-x86_64.AppImage

RUN cd /app/paraview-build && \
    cmake --parallel=$(nproc) ../paraview-superbuild -DENABLE_xdmf3=1 -DENABLE_python3=1 -DENABLE_matplotlib=1 -DENABLE_numpy=1 \
        -DENABLE_qt5=1 -DENABLE_mpi=1 -DENABLE_hdf5=1 -DCMAKE_BUILD_TYPE=Release && \
    make download-all && \
    rm -rf superbuild/paraview/src/VTK && \
    git clone --single-branch --branch="xdmf3-highorder" --depth=1 https://gitlab.kitware.com/ChristophHonal/vtk.git superbuild/paraview/src/VTK && \
    make -j$(nproc)

# Pack assets
COPY tools/AppRun tools/paraview-xdmf3-highorder.desktop tools/paraview-xdmf3-highorder.png /app/paraview-build/install/
COPY tools/paraview-xdmf3-highorder.appdata.xml /app/paraview-build/install/usr/share/metainfo/

# Update and repompile git VTK and pack AppImage
COPY tools/release.sh /app/
ENTRYPOINT [ "/app/release.sh" ] 


# Image for debugging
FROM base as debug

# Reconfigure and recompile for debugging
RUN cd /app/paraview-build && \
    cmake --parallel=$(nproc) ../paraview-superbuild -DENABLE_xdmf3=1 -DENABLE_python3=1 -DENABLE_matplotlib=1 -DENABLE_numpy=1 \
        -DENABLE_qt5=1 -DENABLE_mpi=1 -DENABLE_hdf5=1 -DSUPERBUILD_ALLOW_DEBUG=1 -DCMAKE_BUILD_TYPE_paraview=Debug && \
    make download-all && \
    rm -rf superbuild/paraview/src/VTK && \
    git clone --single-branch --branch="xdmf3-highorder" --depth=1 https://gitlab.kitware.com/ChristophHonal/vtk.git superbuild/paraview/src/VTK && \
    make -j$(nproc)

# GDB server
EXPOSE 2000

# Recompile sources
COPY tools/debug.sh /app/
ENTRYPOINT [ "/app/debug.sh" ]