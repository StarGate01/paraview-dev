#!/bin/bash

mkdir -p /app/paraview-build
if [ -z "$(ls -A /app/paraview-build)" ]; then
    cp -r /app/paraview-build.backup /app/paraview-build
fi
cd /app/paraview-build
rm -f superbuild/paraview/stamp/paraview-build
make -j$(nproc)
