# Ammonia-Driven Multi-Energy System

## Overview

This repository contains the source code and supporting parameter definitions for the research paper *Unlock the potential of power-to-ammonia in future multi-energy transition pathways*. The core of this project is a risk-aware power-to-ammonia (P2A)-driven multi-energy system expansion planning model, developed as a mixed-integer optimization framework on the MATLAB platform with the YALMIP Toolbox and Gurobi Solver. The model jointly represents endogenous investment in renewable generation, thermal generation, power transmission, ammonia production, combined heat and power, storage, and inter-regional energy exchange. Conditional value-at-risk (CVaR) is used to quantify techno-economic uncertainty, while the risk layer includes multi-stakeholder loss allocation and individual-rationality participation conditions.

## Model components

The repository is organized into two model cores:

- `Endogenous_Investment_Carbon_Scenarios` contains the provincial multi-energy expansion model and its scenario-analysis workflow. Its primary function is `P2A_Full_Model()`.
- `Country_Energy_Model` contains the national energy-system model and its country-level data transformation and rolling-horizon workflow. Its primary function is `Country_main()`.

Each model directory contains an embedded `risk` folder. The risk layer is therefore part of the corresponding model and is not maintained as a separate standalone module.

## P2A representation

The P2A conversion block uses the thermodynamic RC formulation from the SI model rather than a simplified linear electricity-to-ammonia relation. The formulation tracks electrolyzer-cell temperature, wall temperature, temperature-dependent Faradaic and electrolytic efficiencies, ammonia production, electricity demand, heat demand, and transient thermal states.

## Optimization structure

The model preserves the physical and operational constraints required for multi-energy expansion planning, including:

- electricity, heat, and ammonia balances;
- investment, capacity, lifetime, and degradation relationships;
- renewable generation, thermal generation, storage, ramping, and operating limits;
- transmission and gas-network flow constraints;
- carbon-cap accounting and embodied-emission terms; and
- scenario-dependent investment and risk-sharing constraints.

Renewable and thermal deployment outcomes are not prescribed by exogenous technology-growth paths. Capacity decisions are determined by the optimization model subject to resource, network, operational, budget, and policy constraints.

## Publication-oriented code scope

The MATLAB files are curated core-code copies for publication and peer review. External file-reading and file-writing interfaces, plotting routines, checkpoint management, result exporters, and command-window wrappers have been removed. The displayed initial-state routine does not embed historical wind or solar capacity vintages; wind and solar profiles, candidate-resource limits, and other quantities retained in the source are model parameters.

The main functions intentionally expose no top-level input or output interface. Reusable child functions retain their explicit interfaces so that the model call graph and mathematical formulation remain visible to readers.

## Software requirements

- MATLAB with the YALMIP Toolbox
- Gurobi Optimizer configured as the selected solver

The files in this repository are intended to document the model formulation and core computational structure. They are not distributed as a standalone one-click execution package.
