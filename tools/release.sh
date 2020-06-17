#!/bin/bash

cd /app/paraview-build/superbuild/paraview/src/VTK
git pull
cd /app/paraview-build
rm -f superbuild/paraview/stamp/paraview-build
make -j$(nproc)

ARCH=x86_64 /app/appimagetool-x86_64.AppImage /app/paraview-build/install /app/release/paraview-5.8.0-xdmf3-highorder-release-x86_64.AppImage