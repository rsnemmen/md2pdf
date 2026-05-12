---
title: Incompressible Fluid Dynamics
author: Jane Doe
date: May 2026
---

## Background

Fluid motion is governed by the Navier–Stokes equations — a set of nonlinear
partial differential equations expressing conservation of momentum and mass for
a viscous incompressible fluid. They were derived independently by Claude-Louis
Navier (1827) and George Gabriel Stokes (1845) and remain the foundation of
modern computational fluid dynamics (CFD).

## The Navier–Stokes Equations

For an incompressible Newtonian fluid with constant density $\rho$ and kinematic
viscosity $\nu$, the governing equations are:

**Momentum equation:**

$$
\frac{\partial \mathbf{u}}{\partial t}
+ (\mathbf{u} \cdot \nabla)\mathbf{u}
= -\frac{1}{\rho}\nabla p
+ \nu \nabla^2 \mathbf{u}
+ \mathbf{f}
$$

**Continuity (incompressibility constraint):**

$$
\nabla \cdot \mathbf{u} = 0
$$

Together these four scalar equations (three momentum components and one
continuity) determine the velocity field $\mathbf{u}$ and pressure $p$
throughout the domain.

## Notation

- $\mathbf{u}(\mathbf{x}, t)$ — fluid velocity vector field
- $p(\mathbf{x}, t)$ — pressure field (divided by $\rho$)
- $\rho$ — constant fluid density
- $\nu = \mu/\rho$ — kinematic viscosity
- $\mathbf{f}$ — body force per unit mass (e.g. gravity $-g\hat{z}$)
- $\nabla^2$ — Laplacian operator ($\partial_{xx} + \partial_{yy} + \partial_{zz}$)
