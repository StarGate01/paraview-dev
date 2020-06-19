#!/bin/bash

cd /app/paraview-build
rm -f superbuild/paraview/stamp/paraview-build
make -j$(nproc)
