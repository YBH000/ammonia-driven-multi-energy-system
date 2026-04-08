# Overview
This repository contains the source code and supporting parameter definitions (centralized in code) for the research paper **Unlock the potential of power-to-ammonia in future multi-energy transition pathways**. The core of this project is a **risk-aware power-to-ammonia (P2A)-driven multi-energy system expansion planning model**, developed as a mixed-integer linear programming (MILP) framework on the MATLAB platform with the YALMIP Toolbox and Gurobi Solver. The model integrates multi-stakeholder risk-sharing mechanisms and conditional value-at-risk (CVaR) to quantify and mitigate techno-economic uncertainties in low-carbon energy transition.

---

# Code Structure
The code is organized into six sequential functional modules, following the standard MILP modeling workflow for energy system planning:

## 1. Parameter Set Definition Module
This module centralizes the definition of all numerical parameters required for model operation, covering multi-level time scales, dual scenario systems, and device/network/risk-related parameters:
- **Basic system parameters**: Time resolution, typical operation scenarios, risk scenarios, planning horizon, discount rate, capital recovery coefficient (for investment annualization), and risk preference coefficients for multi-stakeholders
- **Device-level technical and economic parameters**: Thermal power units, hydropower units, battery energy storage, electrolyzers (P2A units), CHP units, electric boilers, ammonia-fueled gas boilers, and ammonia storage tanks (including P2A-specific piecewise linear efficiency parameters and thermo-electrochemical dynamic parameters)
- **Network parameters**: Transmission line and ammonia pipeline parameters for existing and candidate infrastructures
- **Load and renewable generation data**: Nodal electric/thermal load profiles, wind and solar power theoretical output time series under multiple scenarios
- **CVaR risk model parameters**: Scenario sampling data, confidence levels, and volatility characteristics for iridium price fluctuation risk, multi-energy system financial risk, and electrolyzer financial risk

## 2. Incidence Matrix Construction Module
This module builds the network topology foundation for the multi-energy system, including:
- Node-branch incidence matrix for the power transmission network (existing lines: K1, candidate lines: K2)
- Node-pipeline incidence matrix for the ammonia transportation network (existing pipelines: G1, candidate pipelines: G2)
The incidence matrices support nodal balance calculation and power/ammonia flow constraints in subsequent modules.

## 3. Decision Variables Definition Module
This module defines all decision variables for the planning and operation optimization problem, classified by attribute:
- **Planning variables**: Integer/binary variables for transmission line construction, ammonia pipeline deployment, electrolyzer capacity configuration (number of series modules, integer), and CHP unit installation (binary) + installed capacity configuration (integer)
- **Operation variables**: Continuous and binary variables for the real-time operation of generation, conversion, storage, and load devices, covering power output, energy consumption, State of Charge (SOC) for battery/ammonia storage, startup/shutdown status, and P2A-specific variables (Faraday/electrolysis efficiency, reaction/wall temperature, molar volume)
- **Risk model variables**: Auxiliary variables for CVaR calculation, utility function variables for multi-stakeholder risk-sharing, and risk compensation variables
- **Nodal aggregation variables**: Aggregated variables at each system node (for each scenario and time step) for the construction of multi-energy balance constraints

## 4. Objective Function Definition Module
This module constructs the total cost minimization objective function for the full life cycle of the multi-energy system, consisting of five core components:
- **Annualized fixed investment cost**: Capital expenditure for transmission lines, ammonia pipelines, electrolyzers, and CHP units, converted by the capital recovery coefficient and weighted by the number of typical operation scenarios
- **Annualized operation & maintenance cost**: Fuel cost, startup/shutdown cost, and routine operation cost of all energy devices (thermal power, hydropower, etc.), weighted by scenario occurrence probability
- **Annualized equipment degradation cost**: Cycle/startup-shutdown degradation cost of electrolyzers, operation/startup-shutdown degradation cost of CHP units, and charge-discharge degradation cost of batteries
- **Reliability penalty cost**: Economic penalty for load shedding and renewable energy curtailment to ensure system operation reliability
- **CVaR risk term**: Total conditional value-at-risk (CVaR) of the system, quantifying the tail risk of iridium price fluctuation, multi-energy system financial uncertainty, and electrolyzer financial uncertainty

## 5. System Constraints Definition Module
This module establishes the complete constraint system for the multi-energy planning model, divided into seven sub-modules:
- **Nodal Aggregation Constraints**: Mapping device-level variables to node-level variables for each scenario and each time step, and aggregating flow variables of candidate lines/pipelines to support system-level balance constraints
- **Power System Constraints**: Nodal active power balance, linearized DC power flow with Big-M linearization for candidate lines, transmission line capacity limit, reference bus voltage phase angle = 0, phase angle limit (-π ~ π), renewable generation output limit, and load shedding constraints
- **Ammonia Network Constraints**: Nodal ammonia mass balance, pipeline transmission capacity limit, and candidate pipeline deployment constraints
- **Thermal System Constraints**: Nodal thermal power balance to match the thermal load demand of the system
- **Device-Level Operation Constraints**: Operation characteristic constraints for each energy device, including power output limit, ramp rate, minimum on/off duration, daily cycle initial state constraint (consistent start/end state), efficiency piecewise linearization, and thermo-electrochemical dynamic model of electrolyzers
- **Energy Storage Constraints**: SOC dynamic balance, charge/discharge power limit, charge-discharge mutual exclusion constraint, daily cycle SOC constraint (consistent start/end SOC) for battery energy storage, and ammonia storage tank operation constraints
- **CVaR Risk Model & Risk-Sharing Constraints**: CVaR calculation for three typical risks, SOS2 piecewise linearization for exponential utility function (solving nonlinearity), risk compensation calculation constraints, and Pareto optimal constraints for multi-party risk-sharing agreements (non-negative expected utility for all stakeholders)

## 6. Solver Configuration & Solution Module
This module is the implementation link of the model solution, which configures the solution parameters of the Gurobi solver for the MILP model, including:
- Solver core parameters: MIP gap tolerance, solution time limit, number of computing threads
- Log setting: Verbose output for solution process, debug mode enable
- Time statistics: Tic/toc for recording the total running time of the model
- Post-processing: Result extraction, visualization, and output for planning/operation indicators
