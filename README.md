# ammonia-driven-multi-energy-system
# Overview
This repository contains the source code and supporting parameter specifications for the research paper *Unlock the potential of power-to-ammonia in future multi-energy transition pathways*. The core of this project is a **risk-aware power-to-ammonia (P2A)-driven multi-energy system expansion planning model**, developed as a mixed-integer linear programming (MILP) framework on the MATLAB platform with the YALMIP Toolbox and Gurobi Solver.
﻿
# Code Structure
The code is organized into six sequential functional modules
﻿
## 1. Parameter Set Definition Module
This module centralizes the definition of all numerical parameters required for model operation, covering:
- Basic system parameters: time resolution, operation scenarios, planning horizon, discount rate, and risk preference coefficients
- Device-level technical and economic parameters: thermal power units, hydropower units, battery energy storage, PEM electrolyzers (P2A units), CHP units, electric boilers, gas boilers, and ammonia storage tanks
- Network parameters: transmission line and ammonia pipeline parameters for existing and candidate infrastructures
- Load and renewable generation data: nodal electric/thermal load profiles, wind and solar power theoretical output time series under multiple scenarios
- CVaR risk model parameters: scenario sampling data, confidence levels, and volatility characteristics for iridium price fluctuation, energy system financial risk, and electrolyzer investment risk
﻿
## 2. Incidence Matrix Construction Module
This module builds the network topology foundation for the multi-energy system, including the node-branch incidence matrix for the power transmission network (existing and candidate lines) and the node-pipeline incidence matrix for the ammonia transportation network (existing and candidate pipelines). The incidence matrices support nodal balance calculation and power/ammonia flow constraints in subsequent modules.
﻿
## 3. Decision Variables Definition Module
This module defines all decision variables for the planning and operation optimization problem, classified by attribute:
- Planning variables: integer/binary variables for transmission line construction, ammonia pipeline deployment, electrolyzer capacity configuration, and CHP unit installation
- Operation variables: continuous and binary variables for the real-time operation of generation, conversion, storage, and load devices, covering power output, energy consumption, state of charge (SOC), startup/shutdown status, etc.
- Risk model variables: auxiliary variables for CVaR calculation, utility function variables for multi-stakeholder risk-sharing, and risk compensation variables
- Nodal aggregation variables: aggregated variables at each system node for the construction of multi-energy balance constraints
﻿
## 4. Objective Function Definition Module
This module constructs the total cost minimization objective function for the full life cycle of the multi-energy system, which consists of five core components:
Annualized fixed investment cost: capital expenditure for transmission lines, ammonia pipelines, electrolyzers, and CHP units, converted by the capital recovery coefficient
Annualized operation & maintenance cost: fuel cost, startup/shutdown cost, and routine operation cost of all energy devices, weighted by scenario occurrence probability
Annualized equipment degradation cost: cycle life degradation cost and startup/shutdown degradation cost of batteries, electrolyzers, and CHP units
Reliability penalty cost: economic penalty for load shedding and renewable energy curtailment to ensure system operation reliability
CVaR risk term: total conditional value-at-risk of the system, quantifying the tail risk of techno-economic uncertainties

## 5. System Constraints Definition Module
This module establishes the complete constraint system for the multi-energy planning model, divided into seven sub-modules:
Nodal Aggregation Constraints: Mapping device-level variables to node-level variables to support the construction of system-level balance constraints
Power System Constraints: Nodal active power balance, linearized DC power flow, transmission line capacity limit, renewable generation output limit, and load shedding constraints
Ammonia Network Constraints: Nodal ammonia mass balance, pipeline transmission capacity limit, and candidate pipeline deployment constraints
Thermal System Constraints: Nodal thermal power balance to match the thermal load demand of the system
Device-Level Operation Constraints: Operation characteristic constraints for each energy device, including power output limit, ramp rate, minimum on/off duration, efficiency piecewise linearization, and thermo-electrochemical dynamic model of PEM electrolyzers
Energy Storage Constraints: SOC dynamic balance, charge/discharge power limit, and mutual exclusion constraint for battery energy storage and ammonia storage tanks
CVaR Risk Model & Risk-Sharing Constraints: CVaR calculation for technical and financial risks, exponential utility function modeling for stakeholders with different risk preferences, and Pareto optimal constraints for multi-party risk-sharing agreements

## 6. Solver Configuration Module
This module sets the core parameters of the Gurobi solver for MILP problem solving, including MIP optimality gap, maximum solution time limit, number of parallel threads, and verbose output level, to balance the solution accuracy and computational efficiency.
