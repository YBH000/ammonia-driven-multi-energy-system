## Overview
This repository contains the source code and supporting parameter definitions for the research paper *Unlock the potential of power-to-ammonia in future multi-energy transition pathways*. The core of this project is a risk-aware power-to-ammonia (P2A)-driven multi-energy system expansion planning model, developed as a mixed-integer linear programming (MILP) framework on the MATLAB platform with the YALMIP Toolbox and Gurobi Solver. The model integrates conditional value-at-risk (CVaR) to quantify techno-economic uncertainties in low-carbon energy transition, and includes constraint sets for multi-stakeholder risk-sharing with individual rationality participation conditions.

## Code Structure
The code is organized into six sequential functional modules, strictly aligned with the actual implementation and standard MILP modeling workflow for multi-energy system planning:

### 1. Parameter Set Definition Module
This module centralizes all numerical parameters required for model operation, covering the following categories:
- Basic system parameters: Time resolution (number of time periods per operation day), typical operation scenarios, planning horizon (years), discount rate, annuity present value coefficient `f_inv` (for investment annualization, reciprocal of the standard capital recovery coefficient), risk preference coefficients for multi-stakeholders, Big-M constant for linearization, reference bus for power flow calculation, and total investment budget.
- Device-level technical and economic parameters: Thermal power units, hydropower units, battery energy storage, electrolyzers (P2A units), CHP units, electric boilers, ammonia-fueled gas boilers, and ammonia storage tanks, including capacity limits, efficiency, cost coefficients, ramp rates, and dynamic characteristic parameters.
- Network parameters: Topology, susceptance, transmission capacity, and investment cost parameters for existing and candidate transmission lines; topology, flow capacity, and investment cost parameters for existing and candidate ammonia pipelines.
- Load and renewable generation data: Nodal electric/thermal load time series, theoretical wind and solar power output time series across nodes, time periods and scenarios, and penalty cost coefficients for load shedding and renewable curtailment.
- CVaR risk model parameters: Pre-sampled scenario data, confidence levels, volatility bounds, expected values, occurrence probability of each risk scenario, and fixed risk-sharing proportion coefficients for iridium price fluctuation risk, system financial risk, and electrolyzer financial risk.

### 2. Incidence Matrix Construction Module
This module builds the network topology foundation for the coupled multi-energy system, which supports nodal balance calculation and power/ammonia flow constraints in subsequent modules:
- Node-branch incidence matrix for the power transmission network: `K1` for existing lines, `K2` for candidate lines
- Node-pipeline incidence matrix for the ammonia transportation network: `G1` for existing pipelines, `G2` for candidate pipelines

### 3. Decision Variables Definition Module
This module defines all decision variables for the two-layer planning-operation optimization problem, classified by variable attribute and dimension:
- Planning variables: Integer/binary decision variables for long-term infrastructure expansion, including binary variables for transmission line construction `x_L`, binary variables for ammonia pipeline deployment `x_G`, integer variables for electrolyzer capacity configuration (number of series modules `n_EL`), binary variables for CHP unit installation `x_CHP`, and integer variables for CHP installed capacity configuration `CHP_cap`.
- Operation variables: Continuous and binary variables for short-term system operation across all time periods and scenarios, including: power output/consumption of generation, conversion and load devices; state of charge (SOC) for battery and ammonia storage; startup/shutdown status binary variables for thermal/hydropower units, electrolyzers and CHP units; and P2A-specific variables (Faraday efficiency, electrolysis efficiency, reaction temperature, wall temperature, molar volume of ammonia production).
- Risk model variables: Auxiliary variables for CVaR calculation (VaR, auxiliary variables for tail loss), utility function variables for multi-stakeholder risk-sharing, and risk compensation variables between stakeholders.
- Nodal aggregation variables: Node-level aggregated variables for each scenario and time step, which map device-level variables to system nodes to simplify the construction of multi-energy balance constraints.

### 4. Objective Function Definition Module
This module constructs a composite optimization objective for minimizing the annualized full-life-cycle comprehensive cost of the multi-energy system, with a risk penalty term adjusted by the risk preference coefficient. The objective function consists of five core components:
- Annualized fixed investment cost: Capital expenditure for transmission lines, ammonia pipelines, electrolyzers, and CHP units, annualized via the pre-defined annuity present value coefficient `f_inv`. The investment cost of electrolyzers and CHP units is calculated as the mean value across scenarios multiplied by the number of scenarios.
- Annualized operation & maintenance cost: Fuel cost, startup/shutdown cost, and routine operation cost of all energy devices (thermal power, hydropower, electrolyzers, CHP, electric boilers, gas boilers), weighted by the occurrence probability of each typical operation scenario and annual operation days.
- Annualized equipment degradation cost: Cycle and startup-shutdown degradation cost of electrolyzers, operation and startup-shutdown degradation cost of CHP units, and charge-discharge degradation cost of battery energy storage, weighted by scenario occurrence probability and annual operation days.
- Reliability penalty cost: Economic penalty for load shedding and renewable energy curtailment to ensure system operation reliability, weighted by scenario occurrence probability and annual operation days.
- CVaR risk penalty term: The sum of CVaR values of three types of risks (iridium price fluctuation, system financial uncertainty, electrolyzer financial uncertainty), multiplied by the risk preference coefficient `lambda` to balance system economy and risk aversion.

### 5. System Constraints Definition Module
This module establishes the complete constraint system for the multi-energy planning model:
- Nodal Aggregation Constraints: Mapping device-level variables to node-level variables for each scenario and each time step, and aggregating the flow variables of candidate lines/pipelines, to support the construction of system-level multi-energy balance constraints.
- Power System Constraints: Nodal active power balance constraint; linearized DC power flow constraints; transmission line capacity limit; voltage phase angle constraint (reference bus angle fixed at 0, non-reference bus angle limited to -π ~ π); renewable generation output upper limit constraint; and load shedding upper limit constraint.
- Ammonia Network Constraints: Nodal ammonia mass balance constraint; transmission capacity limit for existing and candidate ammonia pipelines; and maximum construction quantity constraint for candidate pipelines.
- Thermal System Constraints: Nodal thermal power balance constraint, which covers both the thermal load demand of end users and the thermochemical reaction heat demand of electrolyzers, with heat supply from CHP units, electric boilers and ammonia-fueled gas boilers.
- Device-Level Operation Constraints: Operation characteristic constraints for each energy device, including: power output limit, ramp rate, minimum on/off duration, startup/shutdown cost, and daily cycle initial state constraint (consistent start/end state of the day) for thermal and hydropower units; ammonia production limit, ramp rate, efficiency piecewise linearization, thermo-electrochemical dynamic model, and startup/shutdown state constraints for electrolyzers; energy conversion and consumption limit constraints for CHP units, electric boilers and gas boilers.
- Energy Storage Constraints: For battery energy storage: SOC dynamic balance constraint, charge/discharge power limit, charge-discharge mutual exclusion constraint, and daily cycle SOC constraint (consistent start/end SOC of the day). For ammonia storage tanks: SOC dynamic balance constraint, injection/withdrawal rate limit, and SOC upper/lower limit constraint (no daily cycle SOC consistency constraint in the code).
- CVaR Risk Model & Risk-Sharing Constraints: CVaR calculation constraints for three types of risks; SOS2 piecewise linearization constraints for exponential utility function (to address nonlinearity of utility calculation); risk compensation calculation constraints between stakeholders; and individual rationality constraints for multi-party risk-sharing agreements.

### 6. Solver Configuration & Solution Module
This module implements the solver parameter configuration for the MILP model:
- Log and debug settings: Enable verbose output for the solution process, and turn on debug mode.
- Time statistics: The `tic/toc` function in the code only counts the elapsed time from code initialization to solver configuration completion, and does not cover the model solution process.
- Note: The current code does not include post-processing modules such as result extraction, visualization, and structured output of planning/operation indicators.
