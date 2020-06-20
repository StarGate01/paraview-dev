# ParaView Development Environment

This image builds ParaView with a fork of VTK (https://gitlab.kitware.com/ChristophHonal/vtk/-/tree/xdmf3-highorder), which aims to enable high-order finite-element functions in XDMF.

### Create Debug Environment

```
UID=$UID GID=$GID docker-compose run paraview_dev bash
```

### Build and Copy Release Package

```
UID=$UID GID=$GID docker-compose build paraview_release

UID=$UID GID=$GID docker-compose run --rm paraview_release
```

## FE Config

DG_X_Y

- X: Point order, CV = Continuous VTK, CR = Continuous Row, EV, ER = Explicit
- Y: DOFs, CV = Continuous VTK, CR = Continuous Row, EV, ER = Explicit, D = Default equidistant

## Useful Resources

- https://www.paraview.org/
- https://github.com/michalhabera/gsoc-summary
- https://gitlab.kitware.com/xdmf/xdmf/-/issues/18
- https://blog.kitware.com/modeling-arbitrary-order-lagrange-finite-elements-in-the-visualization-toolkit/