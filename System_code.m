% =========================================================================
% P2A-Driven Multi-Energy System Planning Model
% Unlock the potential of power-to-ammonia in future multi-energy transition pathways in China
% Supplemental Information: Nature Portfolio Submission
% Model Type: Mixed-Integer Linear Programming (MILP)
% Platform: MATLAB + YALMIP + Gurobi
clc
clear
close all
tic
% -------------------------- PARAMETER SET DEFINITION --------------------------
% All numerical values are centralized in this parameter set for calibration
% No hard-coded values appear in the main model body
%% System Basic Parameters
% T: Number of time periods in a single operation day
% S: Number of typical operation scenarios
% N_bus: Number of system nodes
% Y: Planning horizon (years)
% r: Discount rate
% sigma: Number of annual operating days
% lambda: Risk preference coefficient (0 = risk neutral, larger = higher risk aversion)
% c_Ir: Confidence level for iridium price volatility risk
% c_Fin_IES: Confidence level for IES financial risk
% c_Fin_ele: Confidence level for electrolyzer financial risk
% M: Big-M constant for linearization
% ref_bus: Reference bus number for power flow calculation
% total_budget: Total investment budget for system expansion
% Capital recovery coefficient
f_inv = ((r+1)^Y - 1) / (r*(r+1)^Y);
%% Thermal Power Unit Parameters 
% N_TH: Number of thermal power units
% TH_data: Thermal unit parameter matrix [bus_id, P_TH_max, P_TH_min, c_TH, Ru_TH, Rd_TH, T_on_TH, T_off_TH, CST_unit_TH, CSD_unit_TH]
% Column Definition:
% 1: Bus connection number
% 2: Maximum power output (MW)
% 3: Minimum power output (MW)
% 4: Unit generation cost ($/MWh)
% 5: Upward ramp rate (MW/h)
% 6: Downward ramp rate (MW/h)
% 7: Minimum ON duration (h)
% 8: Minimum OFF duration (h)
% 9: Unit startup cost ($/start)
% 10: Unit shutdown cost ($/shutdown)
%% Hydropower Unit Parameters
% N_HY: Number of hydropower units
% HY_data: Hydropower unit parameter matrix [bus_id, P_HY_max, P_HY_min, c_HY, Ru_HY, Rd_HY, T_on_HY, T_off_HY, CST_unit_HY, CSD_unit_HY]
% Column Definition:
% 1: Bus connection number
% 2: Maximum power output (MW)
% 3: Minimum power output (MW)
% 4: Unit generation cost ($/MWh)
% 5: Upward ramp rate (MW/h)
% 6: Downward ramp rate (MW/h)
% 7: Minimum ON duration (h)
% 8: Minimum OFF duration (h)
% 9: Unit startup cost ($/start)
% 10: Unit shutdown cost ($/shutdown)
%% Battery Energy Storage Parameters
% N_B: Number of battery energy storage units
% B_data: Battery parameter matrix [bus_id, E_rated, mu_B, P_ch_max, P_dis_max, eta_ch, eta_dis, SOC_min, SOC_max, SOC_init]
% Column Definition:
% 1: Bus connection number
% 2: Rated capacity (MWh)
% 3: Unit degradation cost ($/MWh)
% 4: Maximum charging power (MW)
% 5: Maximum discharging power (MW)
% 6: Charging efficiency (p.u.)
% 7: Discharging efficiency (p.u.)
% 8: Minimum state of charge (p.u.)
% 9: Maximum state of charge (p.u.)
% 10: Initial state of charge (p.u.)
%% Electrolyzer (P2A) Parameters
% N_EL: Number of electrolyzer candidate nodes
% EL_data: Electrolyzer parameter matrix [bus_id, V_EL_max, V_EL_min, c_EL, mu_cyc_EL, mu_ST_EL, mu_SD_EL, R_EL, I_rated, N_e, F, Q_gas, C_EL, n_EL_max]
% Column Definition:
% 1: Bus connection number
% 2: Maximum ammonia production capacity (m³/h)
% 3: Minimum ammonia production capacity (m³/h)
% 4: Unit operation cost ($/m³) 
% 5: Unit cycle degradation cost ($/m³ of ammonia produced) 
% 6: Unit startup degradation cost ($/start) 
% 7: Unit shutdown degradation cost ($/shutdown)
% 8: Ammonia production ramp rate (m³/h)
% 9: Rated current (A)
% 10: Number of transferred electrons
% 11: Faraday constant (C/mol)
% 12: Ammonia calorific value (kWh/m³)
% 13: Unit investment cost ($/module)
% 14: Maximum number of series modules
% Electrolyzer Efficiency Piecewise Linearization Parameters
% u1: Faraday efficiency piecewise matrix [slope, T_min, T_max]
% ue1: Cumulative value of piecewise Faraday efficiency
% u2: Electrolysis efficiency piecewise matrix [slope, T_min, T_max]
% ue2: Cumulative value of piecewise electrolysis efficiency
% o1: Number of segments for Faraday efficiency
% o2: Number of segments for electrolysis efficiency
% Electrolyzer Thermal Dynamic Parameters
% T_EL_min: Minimum reaction temperature (°C)
% T_EL_max: Maximum reaction temperature (°C)
% delta_T_EL_max: Maximum temperature change rate (°C/h)
% delta_T_Wall_max: Maximum wall temperature change rate (°C/h)
% T_out: Ambient temperature time series (°C)
% AW, AZ: Temperature coefficient matrices for thermal dynamics
% Eb: Electric energy conversion coefficient
%% CHP Unit Parameters 
% N_CHP: Number of CHP candidate nodes
% CHP_data: CHP parameter matrix [bus_id, V_CHP_max, V_CHP_min, eta_CHP_e, eta_CHP_h, c_CHP, mu_run_CHP, mu_ST_CHP, mu_SD_CHP, C_CHP]
% Column Definition:
% 1: Bus connection number
% 2: Maximum ammonia consumption (m³/h)
% 3: Minimum ammonia consumption (m³/h)
% 4: Electricity generation efficiency (p.u.)
% 5: Heat generation efficiency (p.u.)
% 6: Unit operation cost ($/m³ of ammonia consumed)
% 7: Unit running degradation cost ($/MWh of power output) 
% 8: Unit startup degradation cost ($/start) 
% 9: Unit shutdown degradation cost ($/shutdown)
% 10: Unit investment cost ($/unit)
%% Electric Boiler Parameters
% N_EB: Number of electric boiler units
% EB_data: Electric boiler parameter matrix [bus_id, P_EB_max, eta_EB, c_EB]
% Column Definition:
% 1: Bus connection number
% 2: Maximum power consumption (MW)
% 3: Heat generation efficiency (p.u.)
% 4: Unit operation cost ($/MWh of electricity consumed)
%% Gas Boiler Parameters
% N_GB: Number of gas boiler units
% GB_data: Gas boiler parameter matrix [bus_id, V_GB_max, eta_GB, c_GB]
% Column Definition:
% 1: Bus connection number
% 2: Maximum ammonia consumption (m³/h)
% 3: Heat generation efficiency (p.u.)
% 4: Unit operation cost ($/m³ of ammonia consumed)
%% Ammonia Storage Tank Parameters
% N_amm_sto: Number of ammonia storage tanks
% Amm_sto_data: Ammonia storage parameter matrix [bus_id, E_amm_rated, V_sto_min, V_sto_max, SOC_amm_min, SOC_amm_max, SOC_amm_init]
% Column Definition:
% 1: Bus connection number
% 2: Rated capacity (m³)
% 3: Minimum injection/withdrawal rate (m³/h)
% 4: Maximum injection/withdrawal rate (m³/h)
% 5: Minimum state of charge (p.u.)
% 6: Maximum state of charge (p.u.)
% 7: Initial state of charge (p.u.)
%% Transmission Network Parameters
% N_line: Number of existing transmission lines
% Line_data: Existing line parameter matrix [bus_from, bus_to, B_i, P_line_max]
% Column Definition:
% 1: From bus number
% 2: To bus number
% 3: Line susceptance (S)
% 4: Maximum active power flow (MW)
% N_candi_line: Number of candidate transmission lines
% Candi_line_data: Candidate line parameter matrix [bus_from, bus_to, B_i, P_line_max, C_L, n_L_max]
% Column Definition:
% 1: From bus number
% 2: To bus number
% 3: Line susceptance (S)
% 4: Maximum active power flow (MW)
% 5: Unit investment cost ($/line)
% 6: Maximum construction quantity
%% Ammonia Pipeline Network Parameters 
% N_pipe: Number of existing ammonia pipelines
% Pipe_data: Existing pipeline parameter matrix [bus_from, bus_to, V_pipe_max]
% Column Definition:
% 1: From bus number
% 2: To bus number
% 3: Maximum ammonia flow (m³/h)
% N_candi_pipe: Number of candidate ammonia pipelines
% Candi_pipe_data: Candidate pipeline parameter matrix [bus_from, bus_to, V_pipe_max, C_G, n_G_max]
% Column Definition:
% 1: From bus number
% 2: To bus number
% 3: Maximum ammonia flow (m³/h)
% 4: Unit investment cost ($/pipeline)
% 5: Maximum construction quantity
%% System Load & Renewable Generation Parameters
% Load_data: Node electrical load matrix [N_bus, T] (MW)
% Heat_load_data: Node thermal load matrix [N_bus, T] (MW)
% P_wind_max: Wind power theoretical generation matrix [N_bus, T, S] (MW)
% P_solar_max: Solar power theoretical generation matrix [N_bus, T, S] (MW)
% c_LS: Unit load shedding penalty cost vector [N_bus, 1] ($/MWh)
% c_cur: Unit renewable curtailment penalty cost vector [N_bus, 1] ($/MWh)
%% CVaR Risk Model Parameters
%N_risk_scen: Total number of risk scenarios 
%c_Ir: Confidence level of iridium price fluctuation risk
%c_Fin_IES: Confidence level of IES financial risk
%c_Fin_ele: Confidence level of electrolyzer financial risk
%rho_risk: Occurrence probability of each risk scenario (dimension: N_risk_scen × 1, matching the probability of operation scenarios)
%E_C_Iridium: Expected value of iridium price
%sigma_Ir: Standard deviation of iridium price fluctuation
%C_Iridium_min: Lower limit of iridium price in risk scenarios
%C_Iridium_max: Upper limit of iridium price in risk scenarios
%C_Iridium: Pre-sampled iridium price scenario values (dimension: N_risk_scen × 1)
%E_I_Fin_IES: Expected value of IES investment cost
%sigma_Fin_IES: Standard deviation of IES investment cost fluctuation
%I_Fin_IES_min: Lower limit of IES investment cost in risk scenarios
%I_Fin_IES_max: Upper limit of IES investment cost in risk scenarios
%I_Fin_IES: Pre-sampled IES investment cost scenario values (dimension: N_risk_scen × 1)
%E_I_Fin_ele: Expected value of electrolyzer investment cost
%sigma_Fin_ele: Standard deviation of electrolyzer investment cost fluctuation
%I_Fin_ele_min: Lower limit of electrolyzer investment cost in risk scenarios
%I_Fin_ele_max: Upper limit of electrolyzer investment cost in risk scenarios
%I_Fin_ele: Pre-sampled electrolyzer investment cost scenario values (dimension: N_risk_scen × 1)
%lambda_ele: Risk preference coefficient of electrolyzer investor
%lambda_IES: Risk preference coefficient of IES operator
%beta_Ir: Proportion of iridium price risk borne by IES (0~1)
%beta_Fin_ele: Proportion of electrolyzer financial risk borne by IES (0~1)
%beta_Fin_IES: Proportion of IES financial risk borne by electrolyzer (0~1)
%phi_Ir: Quantification coefficient of iridium price risk uncertainty
%phi_Fin_IES: Quantification coefficient of IES financial risk uncertainty
%phi_Fin_ele: Quantification coefficient of electrolyzer financial risk uncertainty
% -------------------------- INCIDENCE MATRIX CONSTRUCTION --------------------------
%% Power Network Node-Branch Incidence Matrix
K1 = zeros(N_bus, N_line); % Incidence matrix for existing lines
K2 = zeros(N_bus, N_candi_line); % Incidence matrix for candidate lines
for i = 1:N_line
    K1(Line_data(i,1), i) = 1;
    K1(Line_data(i,2), i) = -1;
end
for i = 1:N_candi_line
    K2(Candi_line_data(i,1), i) = 1;
    K2(Candi_line_data(i,2), i) = -1;
end
%% Ammonia Network Node-Pipeline Incidence Matrix
G1 = zeros(N_bus, N_pipe); % Incidence matrix for existing pipelines
G2 = zeros(N_bus, N_candi_pipe); % Incidence matrix for candidate pipelines
for i = 1:N_pipe
    G1(Pipe_data(i,1), i) = 1;
    G1(Pipe_data(i,2), i) = -1;
end
for i = 1:N_candi_pipe
    G2(Candi_pipe_data(i,1), i) = 1;
    G2(Candi_pipe_data(i,2), i) = -1;
end
%% -------------------------- PLANNING VARIABLES (Integer/Binary) --------------------------
M = 1e6;
% Transmission line construction variables 
x_L = binvar(N_candi_line, max(Candi_line_data(:,6)), 'full'); % Binary: 1 = line constructed
% Ammonia pipeline construction variables
x_G = binvar(N_candi_pipe, max(Candi_pipe_data(:,5)), 'full'); % Binary: 1 = pipeline constructed
% Electrolyzer planning variables
n_EL = intvar(N_EL, 1, 'full'); % Number of series modules for electrolyzer 
x_CHP = binvar(N_CHP, 1, 'full'); % Binary: 1 = CHP unit installed 
CHP_cap = intvar(N_CHP, 1, 'full'); % Installed capacity of CHP unit 
%% -------------------------- OPERATION VARIABLES (Continuous) --------------------------
% Thermal power unit variables 
P_TH = sdpvar(N_TH, T, S, 'full'); % Power output of thermal unit g at time t under scenario s
CST_TH = sdpvar(N_TH, T, S, 'full'); % Startup cost of thermal unit g
CSD_TH = sdpvar(N_TH, T, S, 'full'); % Shutdown cost of thermal unit g
% Hydropower unit variables
P_HY = sdpvar(N_HY, T, S, 'full'); %Hydroelectric output
CST_HY = sdpvar(N_HY, T, S, 'full'); %Hydroelectric start-up cost
CSD_HY = sdpvar(N_HY, T, S, 'full'); %Cost of Water and Electricity Shutdown
x_HY = binvar(N_HY, T, S, 'full'); %Binary variable for water and electricity start stop status
% Battery energy storage variables
P_ch = sdpvar(N_B, T, S, 'full'); % Charging power of battery b
P_dis = sdpvar(N_B, T, S, 'full'); % Discharging power of battery b
SOC = sdpvar(N_B, T, S, 'full'); % State of charge of battery b
C_DEG_B = sdpvar(N_B, T, S, 'full'); % Degradation cost of battery b
% Electrolyzer (P2A) variables
V_EL = sdpvar(N_EL, T, S, 'full'); % Ammonia production of electrolyzer k
P_EL = sdpvar(N_EL, T, S, 'full'); % Power consumption of electrolyzer k
P_reqP = sdpvar(N_EL, T, S, 'full'); % Electric power for electrolyzer thermochemical heating
P_reqH = sdpvar(N_EL, T, S, 'full'); % Thermal power for electrolyzer thermochemical heating
T_EL = sdpvar(N_EL, T, S, 'full'); % Reaction temperature of electrolyzer k
T_Wall = sdpvar(N_EL, T, S, 'full'); % Wall temperature of electrolyzer k
eta_fld = sdpvar(N_EL, T, S, 'full'); % Faraday efficiency of electrolyzer k
eta_ele = sdpvar(N_EL, T, S, 'full'); % Electrolysis efficiency of electrolyzer k
mol_EL = sdpvar(N_EL, T, S, 'full'); % Molar volume of electrolyzer k
u_ST_EL = binvar(N_EL, T, S, 'full'); %Start status of electrolytic cell
u_SD_EL = binvar(N_EL, T, S, 'full'); %Electrolytic cell shutdown status
% CHP unit variables
V_CHP = sdpvar(N_CHP, T, S, 'full'); % Ammonia consumption of CHP unit p
P_CHP = sdpvar(N_CHP, T, S, 'full'); % Power output of CHP unit p
H_CHP = sdpvar(N_CHP, T, S, 'full'); % Heat output of CHP unit p
u_ST_CHP = binvar(N_CHP, T, S, 'full'); %CHP startup status
u_SD_CHP = binvar(N_CHP, T, S, 'full'); %CHP shutdown status
% Electric boiler variables 
P_EB = sdpvar(N_EB, T, S, 'full'); % Power consumption of electric boiler m
H_EB = sdpvar(N_EB, T, S, 'full'); % Heat output of electric boiler m
% Gas boiler variables 
V_GB = sdpvar(N_GB, T, S, 'full'); % Ammonia consumption of gas boiler n
H_GB = sdpvar(N_GB, T, S, 'full'); % Heat output of gas boiler n
% Ammonia storage variables 
V_sto = sdpvar(N_amm_sto, T, S, 'full'); % Net ammonia injection/withdrawal of storage tank r
SOC_amm = sdpvar(N_amm_sto, T, S, 'full'); % State of charge of ammonia storage tank r
% Power system operation variables (Power System Constraints)
P_line = sdpvar(N_line, T, S, 'full'); % Active power flow on existing line i
P_candiLine = sdpvar(N_candi_line, max(Candi_line_data(:,6)), T, S, 'full'); % Active power flow on candidate line ic
P_LS = sdpvar(N_bus, T, S, 'full'); % Load shedding amount at node o
P_wind_disp = sdpvar(N_bus, T, S, 'full'); % Dispatched wind power at node o
P_solar_disp = sdpvar(N_bus, T, S, 'full'); % Dispatched solar power at node o
theta = sdpvar(N_bus, T, S, 'full'); % Voltage phase angle at node o
% Ammonia network operation variables (Ammonia Network Constraints)
V_pipe = sdpvar(N_pipe, T, S, 'full'); % Ammonia flow on existing pipeline j
V_candiPipe = sdpvar(N_candi_pipe, max(Candi_pipe_data(:,5)), T, S, 'full'); % Ammonia flow on candidate pipeline jc
% CVaR Risk Model Variables 
VaR_Ir = sdpvar(1,1);              % VaR of iridium price fluctuation risk
VaR_Fin_IES = sdpvar(1,1);         % VaR of IES financial risk
VaR_Fin_ele = sdpvar(1,1);         % VaR of electrolyzer financial risk
z_Ir = sdpvar(N_risk_scen, 1, 'full');         % Auxiliary variable for iridium price CVaR
z_Fin_IES = sdpvar(N_risk_scen, 1, 'full');    % Auxiliary variable for IES financial CVaR
z_Fin_ele = sdpvar(N_risk_scen, 1, 'full');    % Auxiliary variable for electrolyzer financial CVaR
CVaR_Ir = sdpvar(1,1);              % CVaR of iridium price fluctuation
CVaR_Fin_IES = sdpvar(1,1);         % CVaR of IES financial risk
CVaR_Fin_ele = sdpvar(1,1);         % CVaR of electrolyzer financial risk
CVaR_total = sdpvar(1,1);           % Total system CVaR (for objective function)
U_ele_Ir = sdpvar(N_risk_scen, 1, 'full');     % Utility of electrolyzer under iridium price risk
U_IES_Ir = sdpvar(N_risk_scen, 1, 'full');      % Utility of IES under iridium price risk
EU_ele_Ir = sdpvar(1,1);                        % Expected utility of electrolyzer for iridium price risk
EU_IES_Ir = sdpvar(1,1);                        % Expected utility of IES for iridium price risk
U_ele_Fin_IES = sdpvar(N_risk_scen, 1, 'full'); % Utility of electrolyzer under IES financial risk
U_IES_Fin_IES = sdpvar(N_risk_scen, 1, 'full'); % Utility of IES under IES financial risk
EU_ele_Fin_IES = sdpvar(1,1);                   % Expected utility of electrolyzer for IES financial risk
EU_IES_Fin_IES = sdpvar(1,1);                   % Expected utility of IES for IES financial risk
U_ele_Fin_ele = sdpvar(N_risk_scen, 1, 'full'); % Utility of electrolyzer under electrolyzer financial risk
U_IES_Fin_ele = sdpvar(N_risk_scen, 1, 'full'); % Utility of IES under electrolyzer financial risk
EU_ele_Fin_ele = sdpvar(1,1);                   % Expected utility of electrolyzer for electrolyzer financial risk
EU_IES_Fin_ele = sdpvar(1,1);                   % Expected utility of IES for electrolyzer financial risk
p_RSC_Ir = sdpvar(1,1);             % Risk compensation for iridium price fluctuation (IES → Electrolyzer)
p_RSC_Fin_ele = sdpvar(1,1);        % Risk compensation for IES financial risk (Electrolyzer → IES)
p_RSC_Fin_IES = sdpvar(1,1);        % Risk compensation for electrolyzer financial risk (IES → Electrolyzer)
%% -------------------------- OPERATION VARIABLES (Binary) --------------------------
% Thermal power unit status variables 
x_TH = binvar(N_TH, T, S, 'full'); % Binary: 1 = thermal unit g is online
% Battery status variables
u_ch = binvar(N_B, T, S, 'full'); % Binary: 1 = battery b is charging
u_dis = binvar(N_B, T, S, 'full'); % Binary: 1 = battery b is discharging
% Electrolyzer efficiency piecewise binary variables
u_fld = binvar(N_EL, T, o1, S, 'full'); % Binary for Faraday efficiency piecewise selection
u_elec = binvar(N_EL, T, o2, S, 'full'); % Binary for electrolysis efficiency piecewise selection
%% -------------------------- NODE AGGREGATION VARIABLES --------------------------
% Aggregate variables for node balance constraints
P_TH_node = sdpvar(N_bus, T, S, 'full'); % Aggregated thermal power output at each node
P_HY_node = sdpvar(N_bus, T, S, 'full'); % Aggregated hydropower output at each node
P_CHP_node = sdpvar(N_bus, T, S, 'full'); % Aggregated CHP power output at each node
P_EL_node = sdpvar(N_bus, T, S, 'full'); % Aggregated electrolyzer power consumption at each node
P_reqP_node = sdpvar(N_bus, T, S, 'full'); % Aggregated electrolyzer heating power consumption at each node
P_EB_node = sdpvar(N_bus, T, S, 'full'); % Aggregated electric boiler power consumption at each node
P_ch_node = sdpvar(N_bus, T, S, 'full'); % Aggregated battery charging power at each node
P_dis_node = sdpvar(N_bus, T, S, 'full'); % Aggregated battery discharging power at each node
V_EL_node = sdpvar(N_bus, T, S, 'full'); % Aggregated ammonia production at each node
V_sto_node = sdpvar(N_bus, T, S, 'full'); % Aggregated storage tank net flow at each node
V_CHP_node = sdpvar(N_bus, T, S, 'full'); % Aggregated CHP ammonia consumption at each node
V_GB_node = sdpvar(N_bus, T, S, 'full'); % Aggregated gas boiler ammonia consumption at each node
H_CHP_node = sdpvar(N_bus, T, S, 'full'); % Aggregated CHP heat output at each node
H_EB_node = sdpvar(N_bus, T, S, 'full'); % Aggregated electric boiler heat output at each node
H_GB_node = sdpvar(N_bus, T, S, 'full'); % Aggregated gas boiler heat output at each node
P_reqH_node = sdpvar(N_bus, T, S, 'full'); % Aggregated electrolyzer heating demand at each node
% Aggregate candidate line/pipeline flow variables
P_candiLine_sum = sdpvar(N_candi_line, T, S, 'full'); % Total flow on candidate lines
V_candiPipe_sum = sdpvar(N_candi_pipe, T, S, 'full'); % Total flow on candidate pipelines
%% -------------------------- OBJECTIVE FUNCTION DEFINITION --------------------------
% -------------------------- Annualized Fixed Investment Cost (F_INV) --------------------------
% Investment cost for transmission lines, pipelines, electrolyzers and CHP units
F_INV_line = sum(sum(x_L,2) .* Candi_line_data(:,5)); % Transmission line investment
F_INV_pipe = sum(sum(x_G,2) .* Candi_pipe_data(:,4)); % Ammonia pipeline investment
F_INV_EL = sum(n_EL .* EL_data(:,10), 1); % Electrolyzer investment
F_INV_CHP = sum(x_CHP .* CHP_data(:,6), 1); % CHP unit investment
F_INV = f_inv * (F_INV_line + F_INV_pipe + mean(F_INV_EL + F_INV_CHP) * S);
% -------------------------- Annualized Operation & Maintenance Cost (F_OPE) --------------------------
% Thermal fuel cost, startup/shutdown cost, electrolyzer operation cost
F_OPE = 0;
for s = 1:S
    % Thermal power generation cost + startup/shutdown cost
    F_OPE_TH = sum(sum(P_TH(:,:,s),2) .* TH_data(:,4));
    F_OPE_TH_startstop = sum(sum(CST_TH(:,:,s) + CSD_TH(:,:,s),2));
    % Hydropower generation cost + startup/shutdown cost
    F_OPE_HY = sum(sum(P_HY(:,:,s),2) .* HY_data(:,4));
    F_OPE_HY_startstop = sum(sum(CST_HY(:,:,s) + CSD_HY(:,:,s),2));  
    % Electrolyzer operation cost
    F_OPE_EL = sum(sum(V_EL(:,:,s),2) .* EL_data(:,4)); 
    % CHP operation cost
    F_OPE_CHP = sum(sum(V_CHP(:,:,s),2) .* CHP_data(:,6));
    % Electric boiler operation cost
    F_OPE_EB = sum(sum(P_EB(:,:,s),2) .* EB_data(:,4));
    % Gas boiler operation cost
    F_OPE_GB = sum(sum(V_GB(:,:,s),2) .* GB_data(:,4));
    % Scenario-weighted annual operation cost
    F_OPE = F_OPE + rho_s(s) * sigma * (...
            F_OPE_TH + F_OPE_TH_startstop + ...
            F_OPE_HY + F_OPE_HY_startstop + ...
            F_OPE_EL + F_OPE_CHP + F_OPE_EB + F_OPE_GB);
end
% -------------------------- Annualized Equipment Degradation Cost (F_DEG) --------------------------
% Battery degradation cost
F_DEG = 0;
for s = 1:S
    % 1.  Battery degradation cost
    F_DEG_B = sum(sum(C_DEG_B(:,:,s),2));
    % 2.  Electrolyzer degradation cost
    F_DEG_EL_cyc = sum(sum(V_EL(:,:,s),2) .* EL_data(:,5)); %Cyclic degradation
    F_DEG_EL_startstop = sum(sum(u_ST_EL(:,:,s),2) .* EL_data(:,6) + sum(u_SD_EL(:,:,s),2) .* EL_data(:,7)); %Start stop degradation
    % 3.  CHP degradation cost
    F_DEG_CHP_run = sum(sum(P_CHP(:,:,s),2) .* CHP_data(:,7)); %Run degradation μ _run_CHP, p * P_CHP, p, t, s
    F_DEG_CHP_startstop = sum(sum(u_ST_CHP(:,:,s),2) .* CHP_data(:,8) + sum(u_SD_CHP(:,:,s),2) .* CHP_data(:,9)); %Start stop degradation
    % Scenario-weighted annual degradation cost
    F_DEG = F_DEG + rho_s(s) * sigma * (...
        F_DEG_B + ...
        F_DEG_EL_cyc + F_DEG_EL_startstop + ...
        F_DEG_CHP_run + F_DEG_CHP_startstop);
end
% -------------------------- Annualized Reliability Penalty Cost (F_REL) --------------------------
% Load shedding and renewable curtailment penalty
F_REL = 0;
for s = 1:S
    % Load shedding penalty
    F_REL_LS = sum(sum(P_LS(:,:,s),2) .* c_LS);
    % Renewable curtailment penalty
    P_wind_cur = P_wind_max(:,:,s) - P_wind_disp(:,:,s);
    P_solar_cur = P_solar_max(:,:,s) - P_solar_disp(:,:,s);
    F_REL_cur = sum(sum(P_wind_cur + P_solar_cur,2) .* c_cur);
    % Scenario-weighted reliability cost
    F_REL = F_REL + rho_s(s) * sigma * (F_REL_LS + F_REL_cur);
end
% -------------------------- CVaR Risk Term  --------------------------
CVaR_total = CVaR_Ir + CVaR_Fin_IES + CVaR_Fin_ele;
% -------------------------- Total Objective Function --------------------------
F_total = F_INV + F_OPE + F_DEG + F_REL + lambda * CVaR_total;
Objective = F_total;
% -------------------------- CONSTRAINTS DEFINITION --------------------------
Constraints = [];
%% -------------------------- NODE AGGREGATION CONSTRAINTS --------------------------
% Map device-level variables to node-level variables for balance constraints
for s = 1:S
    for t = 1:T
        % Thermal power node aggregation
        P_TH_node(TH_data(:,1),t,s) = P_TH(:,t,s);
        P_TH_node(setdiff(1:N_bus, TH_data(:,1)),t,s) = 0;
        % CHP node aggregation
        P_CHP_node(CHP_data(:,1),t,s) = P_CHP(:,t,s);
        H_CHP_node(CHP_data(:,1),t,s) = H_CHP(:,t,s);
        V_CHP_node(CHP_data(:,1),t,s) = V_CHP(:,t,s);
        P_CHP_node(setdiff(1:N_bus, CHP_data(:,1)),t,s) = 0;
        H_CHP_node(setdiff(1:N_bus, CHP_data(:,1)),t,s) = 0;
        V_CHP_node(setdiff(1:N_bus, CHP_data(:,1)),t,s) = 0;
        % Electrolyzer node aggregation
        P_EL_node(EL_data(:,1),t,s) = P_EL(:,t,s);
        P_reqP_node(EL_data(:,1),t,s) = P_reqP(:,t,s);
        P_reqH_node(EL_data(:,1),t,s) = P_reqH(:,t,s);
        V_EL_node(EL_data(:,1),t,s) = V_EL(:,t,s);
        P_EL_node(setdiff(1:N_bus, EL_data(:,1)),t,s) = 0;
        P_reqP_node(setdiff(1:N_bus, EL_data(:,1)),t,s) = 0;
        P_reqH_node(setdiff(1:N_bus, EL_data(:,1)),t,s) = 0;
        V_EL_node(setdiff(1:N_bus, EL_data(:,1)),t,s) = 0;
        % Electric boiler node aggregation
        P_EB_node(EB_data(:,1),t,s) = P_EB(:,t,s);
        H_EB_node(EB_data(:,1),t,s) = H_EB(:,t,s);
        P_EB_node(setdiff(1:N_bus, EB_data(:,1)),t,s) = 0;
        H_EB_node(setdiff(1:N_bus, EB_data(:,1)),t,s) = 0;
        % Gas boiler node aggregation
        V_GB_node(GB_data(:,1),t,s) = V_GB(:,t,s);
        H_GB_node(GB_data(:,1),t,s) = H_GB(:,t,s);
        V_GB_node(setdiff(1:N_bus, GB_data(:,1)),t,s) = 0;
        H_GB_node(setdiff(1:N_bus, GB_data(:,1)),t,s) = 0;
        % Battery node aggregation
        P_ch_node(B_data(:,1),t,s) = P_ch(:,t,s);
        P_dis_node(B_data(:,1),t,s) = P_dis(:,t,s);
        P_ch_node(setdiff(1:N_bus, B_data(:,1)),t,s) = 0;
        P_dis_node(setdiff(1:N_bus, B_data(:,1)),t,s) = 0;
        % Ammonia storage node aggregation
        V_sto_node(Amm_sto_data(:,1),t,s) = V_sto(:,t,s);
        V_sto_node(setdiff(1:N_bus, Amm_sto_data(:,1)),t,s) = 0;
        % Candidate line/pipeline flow aggregation
        P_candiLine_sum(:,t,s) = sum(P_candiLine(:,:,t,s),2);
        V_candiPipe_sum(:,t,s) = sum(V_candiPipe(:,:,t,s),2);
    end
end
%% -------------------------- POWER SYSTEM CONSTRAINTS  --------------------------
% Node Power Balance Constraint
for s = 1:S
    for t = 1:T
        Constraints = [Constraints, ...
            P_wind_disp(:,t,s) + P_solar_disp(:,t,s) + P_TH_node(:,t,s) + P_HY_node(:,t,s) + P_CHP_node(:,t,s) + P_dis_node(:,t,s) ...
            - P_EL_node(:,t,s) - P_reqP_node(:,t,s) - P_EB_node(:,t,s) - P_ch_node(:,t,s) - Load_data(:,t) + P_LS(:,t,s) ...
            == K1*P_line(:,t,s) + K2*P_candiLine_sum(:,t,s)];
    end
end
% Existing Line Power Flow Constraints 
for s = 1:S
    % Line power flow calculation
    Constraints = [Constraints, ...
        P_line(:,:,s) == repmat(Line_data(:,3),1,T) .* (theta(Line_data(:,1),:,s) - theta(Line_data(:,2),:,s))];
    % Line flow limit
    for t = 1:T
        Constraints = [Constraints, ...
            -Line_data(:,4) <= P_line(:,t,s) <= Line_data(:,4)];
    end
end
% Candidate Line Power Flow Constraints 
n_L_max = max(Candi_line_data(:,6));
for s = 1:S
    for t = 1:T
        % Candidate line flow limit (big-M linearization)
        Constraints = [Constraints, ...
            -x_L.*repmat(Candi_line_data(:,4),1,n_L_max) <= P_candiLine(:,:,t,s) <= x_L.*repmat(Candi_line_data(:,4),1,n_L_max)];
        % Candidate line power flow equation (big-M linearization)
        Constraints = [Constraints, ...
            -(1-x_L)*M <= P_candiLine(:,:,t,s) - repmat(Candi_line_data(:,3).*(theta(Candi_line_data(:,1),t,s)-theta(Candi_line_data(:,2),t,s)),1,n_L_max) <= (1-x_L)*M];
    end
end
% Candidate line construction quantity limit
Constraints = [Constraints, sum(x_L,2) <= Candi_line_data(:,6)];

% Node Voltage Phase Angle Constraints
for s = 1:S
    Constraints = [Constraints, theta(ref_bus,:,s) == 0]; % Reference bus angle = 0
    Constraints = [Constraints, -pi <= theta(setdiff(1:N_bus, ref_bus),:,s) <= pi]; % Angle limit
end
% Renewable Generation Constraints
for s = 1:S
    Constraints = [Constraints, 0 <= P_wind_disp(:,:,s) <= P_wind_max(:,:,s)];
    Constraints = [Constraints, 0 <= P_solar_disp(:,:,s) <= P_solar_max(:,:,s)];
end
% Load Shedding Constraints
for s = 1:S
    Constraints = [Constraints, 0 <= P_LS(:,:,s) <= Load_data];
end
%% -------------------------- AMMONIA NETWORK CONSTRAINTS  --------------------------
% Node Ammonia Balance Constraint 
for s = 1:S
    for t = 1:T
        Constraints = [Constraints, ...
            V_EL_node(:,t,s) == V_sto_node(:,t,s) + V_CHP_node(:,t,s) + V_GB_node(:,t,s) + G1*V_pipe(:,t,s) + G2*V_candiPipe_sum(:,t,s)];
    end
end
% Existing Pipeline Flow Constraints
for s = 1:S
    for t = 1:T
        Constraints = [Constraints, -Pipe_data(:,3) <= V_pipe(:,t,s) <= Pipe_data(:,3)];
    end
end
% Candidate Pipeline Flow Constraints
n_G_max = max(Candi_pipe_data(:,5));
for s = 1:S
    for t = 1:T
        Constraints = [Constraints, ...
            -x_G.*repmat(Candi_pipe_data(:,3),1,n_G_max) <= V_candiPipe(:,:,t,s) <= x_G.*repmat(Candi_pipe_data(:,3),1,n_G_max)];
    end
end
% Candidate pipeline construction quantity limit
Constraints = [Constraints, sum(x_G,2) <= Candi_pipe_data(:,5)];
%% -------------------------- THERMAL SYSTEM CONSTRAINTS  --------------------------
% Node Thermal Balance Constraint 
for s = 1:S
    for t = 1:T
        Constraints = [Constraints, ...
            P_reqH_node(:,t,s) + Heat_load_data(:,t) == H_CHP_node(:,t,s) + H_EB_node(:,t,s) + H_GB_node(:,t,s)];
    end
end
%% -------------------------- THERMAL POWER UNIT CONSTRAINTS --------------------------
for s = 1:S
    % Initial State Constraint
    Constraints = [Constraints, x_TH(:,1,s) == x_TH(:,T,s)];
    % Power Output Limit Constraint
    for t = 1:T
        Constraints = [Constraints, ...
            x_TH(:,t,s).*TH_data(:,3) <= P_TH(:,t,s) <= x_TH(:,t,s).*TH_data(:,2)];
    end
    % Ramp Rate Constraints
    for t = 2:T
        Constraints = [Constraints, ...
            P_TH(:,t,s) - P_TH(:,t-1,s) <= x_TH(:,t-1,s).*TH_data(:,5) + TH_data(:,2).*(1 - x_TH(:,t-1,s))];
        Constraints = [Constraints, ...
            P_TH(:,t-1,s) - P_TH(:,t,s) <= x_TH(:,t,s).*TH_data(:,6) + TH_data(:,2).*(1 - x_TH(:,t,s))];

    end
    % Initial time ramp constraint
    Constraints = [Constraints, P_TH(:,1,s) <= (TH_data(:,2)+TH_data(:,3))/2];
    % Minimum ON/OFF Duration Constraints
    for i = 1:N_TH
        T_on = TH_data(i,7);
        T_off = TH_data(i,8);
        for t = 2:T
            % Minimum ON duration
            indicator_on = x_TH(i,t,s) - x_TH(i,t-1,s);
            range_on = t:min(T, t + T_on - 1);
            Constraints = [Constraints, x_TH(i,range_on,s) >= indicator_on];
            % Minimum OFF duration
            indicator_off = x_TH(i,t-1,s) - x_TH(i,t,s);
            range_off = t:min(T, t + T_off - 1);
            Constraints = [Constraints, x_TH(i,range_off,s) <= 1 - indicator_off];
        end
    end
    % Startup/Shutdown Cost Constraints
    Constraints = [Constraints, CST_TH(:,:,s) >= 0, CSD_TH(:,:,s) >= 0];
    for t = 2:T
        Constraints = [Constraints, ...
            CST_TH(:,t,s) >= TH_data(:,9).*(x_TH(:,t,s) - x_TH(:,t-1,s))];
        Constraints = [Constraints, ...
            CSD_TH(:,t,s) >= TH_data(:,10).*(x_TH(:,t-1,s) - x_TH(:,t,s))];
    end
end
%% -------------------------- HYDROELECTRIC SYSTEM CONSTRAINTS --------------------------
for s = 1:S
    % Initial State Constraint
    Constraints = [Constraints, x_HY(:,1,s) == x_HY(:,T,s)];
    % Power Output Limit Constraint
    for t = 1:T
        Constraints = [Constraints, ...
            x_HY(:,t,s).*HY_data(:,3) <= P_HY(:,t,s) <= x_HY(:,t,s).*HY_data(:,2)];
    end
    % Ramp Rate Constraints
    for t = 2:T
        Constraints = [Constraints, ...
            P_HY(:,t,s) - P_HY(:,t-1,s) <= x_HY(:,t-1,s).*HY_data(:,5) + (HY_data(:,2)+HY_data(:,3))/2.*(1 - x_HY(:,t-1,s))];
        Constraints = [Constraints, ...
            P_HY(:,t-1,s) - P_HY(:,t,s) <= x_HY(:,t,s).*HY_data(:,6) + (HY_data(:,2)+HY_data(:,3))/2.*(1 - x_HY(:,t,s))];
    end
    Constraints = [Constraints, P_HY(:,1,s) <= (HY_data(:,2)+HY_data(:,3))/2];
    % Minimum ON/OFF Duration Constraints
    for i = 1:N_HY
        T_on = HY_data(i,7);
        T_off = HY_data(i,8);
        for t = 2:T
            indicator_on = x_HY(i,t,s) - x_HY(i,t-1,s);
            range_on = t:min(T, t + T_on - 1);
            Constraints = [Constraints, x_HY(i,range_on,s) >= indicator_on];
            indicator_off = x_HY(i,t-1,s) - x_HY(i,t,s);
            range_off = t:min(T, t + T_off - 1);
            Constraints = [Constraints, x_HY(i,range_off,s) <= 1 - indicator_off];
        end
    end
    % Startup/Shutdown Cost Constraints
    Constraints = [Constraints, CST_HY(:,:,s) >= 0, CSD_HY(:,:,s) >= 0];
    for t = 2:T
        Constraints = [Constraints, ...
            CST_HY(:,t,s) >= HY_data(:,9).*(x_HY(:,t,s) - x_HY(:,t-1,s))];
        Constraints = [Constraints, ...
            CSD_HY(:,t,s) >= HY_data(:,10).*(x_HY(:,t-1,s) - x_HY(:,t,s))];
    end
end
%% -------------------------- BATTERY ENERGY STORAGE CONSTRAINTS  --------------------------
for s = 1:S
    % Charging/Discharging Mutual Exclusion Constraint
    Constraints = [Constraints, u_ch(:,:,s) + u_dis(:,:,s) <= 1];
    % Charging/Discharging Power Limit Constraint
    for t = 1:T
        Constraints = [Constraints, ...
            0 <= P_ch(:,t,s) <= u_ch(:,t,s).*B_data(:,4)];
        Constraints = [Constraints, ...
            0 <= P_dis(:,t,s) <= u_dis(:,t,s).*B_data(:,5)];
    end
    % SOC Dynamic Balance Constraint
    for i = 1:N_B
        E_rated = B_data(i,2);
        eta_ch = B_data(i,6);
        eta_dis = B_data(i,7);
        for t = 2:T
            Constraints = [Constraints, ...
                SOC(i,t,s)*E_rated == SOC(i,t-1,s)*E_rated + P_ch(i,t-1,s)*eta_ch - P_dis(i,t-1,s)/eta_dis];
        end
        % Daily cycle constraint (end of day = initial state)
        Constraints = [Constraints, SOC(i,T,s) == SOC(i,1,s)];
    end
    % SOC Limit Constraint
    Constraints = [Constraints, ...
        repmat(B_data(:,8),1,T) <= SOC(:,:,s) <= repmat(B_data(:,9),1,T)];
    % Initial SOC constraint
    Constraints = [Constraints, SOC(:,1,s) == B_data(:,10)];
    % Degradation Cost Calculation
    Constraints = [Constraints, C_DEG_B(:,:,s) == repmat(B_data(:,3),1,T).*(P_ch(:,:,s) + P_dis(:,:,s))];
end
%% -------------------------- AMMONIA STORAGE CONSTRAINTS  --------------------------
for s = 1:S
    % SOC Limit Constraint
    Constraints = [Constraints, ...
        repmat(Amm_sto_data(:,5),1,T) <= SOC_amm(:,:,s) <= repmat(Amm_sto_data(:,6),1,T)];
    % Injection/Withdrawal Rate Limit Constraint
    for t = 1:T
        Constraints = [Constraints, ...
            repmat(Amm_sto_data(:,3),1,1) <= V_sto(:,t,s) <= repmat(Amm_sto_data(:,4),1,1)];
    end
    % SOC Dynamic Balance Constraint
    for i = 1:N_amm_sto
        E_rated = Amm_sto_data(i,2);
        for t = 2:T
            Constraints = [Constraints, ...
                SOC_amm(i,t,s) == SOC_amm(i,t-1,s) + V_sto(i,t,s)/E_rated];
        end
        % Initial SOC constraint
        Constraints = [Constraints, SOC_amm(i,1,s) == Amm_sto_data(i,7)];
    end
end
%% -------------------------- ELECTROLYZER (P2A) CONSTRAINTS  --------------------------
for s = 1:S
    % Ammonia Production Capacity Constraint
    for i = 1:N_EL
        Constraints = [Constraints, ...
            EL_data(i,3) <= V_EL(i,:,s) <= n_EL(i,s).*EL_data(i,2)];
        Constraints = [Constraints, 0 <= n_EL(i,s) <= EL_data(i,11)];
    end
    % Ammonia Production Ramp Rate Constraint
    for t = 2:T
        Constraints = [Constraints, ...
            abs(V_EL(:,t,s) - V_EL(:,t-1,s)) <= EL_data(:,5)];
    end
    % Faraday Efficiency Piecewise Linear Constraint
    for i = 1:N_EL
        for t = 1:T
            Constraints = [Constraints, sum(u_fld(i,t,:,s)) == 1];
            cache_fld = 0;
            for z = 1:o1
                Constraints = [Constraints, u_fld(i,t,z,s)*u1(z,3) >= u_fld(i,t,z,s)*T_EL(i,t,s)];
                Constraints = [Constraints, u_fld(i,t,z,s)*u1(z,2) <= u_fld(i,t,z,s)*T_EL(i,t,s)];
                cache_fld = cache_fld + u_fld(i,t,z,s)*(ue1(z) - (u1(z,3)-T_EL(i,t,s))*u1(z,1));
            end
            Constraints = [Constraints, eta_fld(i,t,s) == cache_fld];
        end
    end
    % Electrolysis Efficiency Piecewise Linear Constraint
    for i = 1:N_EL
        for t = 1:T
            Constraints = [Constraints, sum(u_elec(i,t,:,s)) == 1];
            cache_ele = 0;
            for z = 1:o2
                Constraints = [Constraints, u_elec(i,t,z,s)*u2(z,3) >= u_elec(i,t,z,s)*T_EL(i,t,s)];
                Constraints = [Constraints, u_elec(i,t,z,s)*u2(z,2) <= u_elec(i,t,z,s)*T_EL(i,t,s)];
                cache_ele = cache_ele + u_elec(i,t,z,s)*(ue2(z) - (u2(z,3)-T_EL(i,t,s))*u2(z,1));
            end
            Constraints = [Constraints, eta_ele(i,t,s) == cache_ele];
        end
    end
    % Ammonia Production Calculation
    for i = 1:N_EL
        N_e = EL_data(i,7);
        F = EL_data(i,8);
        I_rated = EL_data(i,6);
        for t = 1:T
            Constraints = [Constraints, mol_EL(i,t,s) == T_EL(i,t,s)*constante];
            Constraints = [Constraints, V_EL(i,t,s) == n_EL(i,s) * eta_fld(i,t,s) * mol_EL(i,t,s) * I_rated / (N_e * F)];
        end
    end
    
    for i = 1:N_EL
        for t = 2:T
        %Startup state: Only when switching from shutdown to operation, u_ST_EL=1
            Constraints = [Constraints, V_EL(i,t,s) - V_EL(i,t-1,s) <= M * u_ST_EL(i,t,s)];
            Constraints = [Constraints, V_EL(i,t,s) - V_EL(i,t-1,s) >= -M * (1 - u_ST_EL(i,t,s))];
            Constraints = [Constraints, 0 <= u_ST_EL(i,t,s) <= 1];
            %Shutdown status: Only when switching from operation to shutdown, u_SD_EL=1
            Constraints = [Constraints, V_EL(i,t-1,s) - V_EL(i,t,s) <= M * u_SD_EL(i,t,s)];
            Constraints = [Constraints, V_EL(i,t-1,s) - V_EL(i,t,s) >= -M * (1 - u_SD_EL(i,t,s))];
            Constraints = [Constraints, 0 <= u_SD_EL(i,t,s) <= 1];
        end
    end
    % Electrolyzer Power Balance 
    Constraints = [Constraints, eta_ele .* P_EL == V_EL * EL_data(i,9)];
    % Temperature Dynamic Constraints
    Constraints = [Constraints, T_EL_min <= T_EL <= T_EL_max];
    Constraints = [Constraints, 0 <= P_reqP, 0 <= P_reqH];
    for i = 1:N_EL
        for t = 2:T
            % Wall temperature dynamic
            Constraints = [Constraints, ...
                T_Wall(i,t,s) == T_Wall(i,t-1,s) + AW(1)*(T_EL(i,t-1,s) - T_Wall(i,t-1,s)) + AW(2)*(T_out(t) - T_Wall(i,t-1,s))];
            % Reaction temperature dynamic
            Constraints = [Constraints, ...
                T_EL(i,t,s) == T_EL(i,t-1,s) + AZ(1)*(T_Wall(i,t-1,s) - T_EL(i,t-1,s)) + AZ(2)*(T_out(t) - T_EL(i,t-1,s)) + ...
                AZ(3)*(Eb*P_reqP(i,t-1,s) + P_reqH(i,t-1,s)) + AZ(4)*(P_EL(i,t,s) - V_EL(i,t,s)*EL_data(i,9))];
        end
    end
    % Temperature Change Rate Limit
    for t = 2:T
        Constraints = [Constraints, abs(T_EL(:,t,s) - T_EL(:,t-1,s)) <= delta_T_EL_max];
        Constraints = [Constraints, abs(T_Wall(:,t,s) - T_Wall(:,t-1,s)) <= delta_T_Wall_max];
    end
end
%% -------------------------- CHP UNIT CONSTRAINTS  --------------------------
for s = 1:S
    for i = 1:N_CHP
        for t = 1:T
            % Ammonia Consumption Limit Constraint
            Constraints = [Constraints, ...
                x_CHP(i,s)*CHP_data(i,3) <= V_CHP(i,t,s) <= x_CHP(i,s)*CHP_cap(i,s)];
            Constraints = [Constraints, CHP_cap(i,s) <= x_CHP(i,s)*CHP_data(i,2)];
            % Energy Conversion Constraints
            Constraints = [Constraints, P_CHP(i,t,s) == V_CHP(i,t,s)*CHP_data(i,4)*Qgas];
            Constraints = [Constraints, H_CHP(i,t,s) == V_CHP(i,t,s)*CHP_data(i,5)*Qgas];
        end
    end
end
for s = 1:S
    for i = 1:N_CHP
        for t = 2:T
            %Startup state: Only when switching from shutdown to operation, u_ST_CHP=1
            Constraints = [Constraints, u_ST_CHP(i,t,s) >= (V_CHP(i,t,s) - V_CHP(i,t-1,s))/V_CHP(i,t,s) - (1 - 1e-6)];
            Constraints = [Constraints, u_ST_CHP(i,t,s) <= (V_CHP(i,t,s) - V_CHP(i,t-1,s))/V_CHP(i,t,s) + (1 - 1e-6)];
            Constraints = [Constraints, 0 <= u_ST_CHP(i,t,s) <= 1];
            %Shutdown status: Only when switching from operation to shutdown, u_SD_CHP=1
            Constraints = [Constraints, u_SD_CHP(i,t,s) >= (V_CHP(i,t-1,s) - V_CHP(i,t,s))/V_CHP(i,t-1,s) - (1 - 1e-6)];
            Constraints = [Constraints, u_SD_CHP(i,t,s) <= (V_CHP(i,t-1,s) - V_CHP(i,t,s))/V_CHP(i,t-1,s) + (1 - 1e-6)];
            Constraints = [Constraints, 0 <= u_SD_CHP(i,t,s) <= 1];
        end
    end
end
%% -------------------------- ELECTRIC BOILER CONSTRAINTS  --------------------------
for s = 1:S
    for i = 1:N_EB
        for t = 1:T
            Constraints = [Constraints, 0 <= P_EB(i,t,s) <= EB_data(i,2)];
            Constraints = [Constraints, H_EB(i,t,s) == P_EB(i,t,s)*EB_data(i,3)];
        end
    end
end
%% -------------------------- GAS BOILER CONSTRAINTS --------------------------
for s = 1:S
    for i = 1:N_GB
        for t = 1:T
            Constraints = [Constraints, 0 <= V_GB(i,t,s) <= GB_data(i,2)];
            Constraints = [Constraints, H_GB(i,t,s) == V_GB(i,t,s)*GB_data(i,3)*Qgas];
        end
    end
end
%% -------------------------- CVaR RISK MODEL CONSTRAINTS --------------------------
% CVaR Model for Iridium Price Fluctuation Technical Risk
Constraints = [Constraints, z_Ir >= 0]; % Non-negativity constraint for auxiliary variables
for k = 1:N_risk_scen
    Constraints = [Constraints, z_Ir(k) >= C_Iridium(k) - VaR_Ir];  
end
Constraints = [Constraints, CVaR_Ir == VaR_Ir + 1/(1 - c_Ir) * sum(rho_risk .* z_Ir)];  % CVaR calculation formula for iridium price risk
%   CVaR Model for IES Financial Risk
Constraints = [Constraints, z_Fin_IES >= 0];    % Non-negativity constraint for auxiliary variables
for k = 1:N_risk_scen
    Constraints = [Constraints, z_Fin_IES(k) >= I_Fin_IES(k) - VaR_Fin_IES];
end
Constraints = [Constraints, CVaR_Fin_IES == VaR_Fin_IES + 1/(1 - c_Fin_IES) * sum(rho_risk .* z_Fin_IES)];  % CVaR calculation formula for IES financial risk
%   CVaR Model for Electrolyzer Financial Risk
Constraints = [Constraints, z_Fin_ele >= 0]; % Non-negativity constraint for auxiliary variables
for k = 1:N_risk_scen
    Constraints = [Constraints, z_Fin_ele(k) >= I_Fin_ele(k) - VaR_Fin_ele];
end
Constraints = [Constraints, CVaR_Fin_ele == VaR_Fin_ele + 1/(1 - c_Fin_ele) * sum(rho_risk .* z_Fin_ele)];  % CVaR calculation formula for electrolyzer financial risk
% Risk Sharing Strategy Constraints
N_seg_utility = 10;
%   Iridium Price Risk Sharing Constraints
x_Ir_seg = linspace(0, 1, N_seg_utility+1); % Normalized iridium price [0,1]
y_ele_Ir_seg = (1 - exp(-lambda_ele * (1 - beta_Ir) * x_Ir_seg * phi_Ir)) / (1 - exp(-lambda_ele)); % Piecewise utility values for electrolyzer
y_IES_Ir_seg = (1 - exp(-lambda_IES * beta_Ir * x_Ir_seg * phi_Ir)) / (1 - exp(-lambda_IES)); % Piecewise utility values for IES
for k = 1:N_risk_scen
    %   Normalize the iridium price for the current scenario
    x_Ir_k = (C_Iridium(k) - C_Iridium_min) / (C_Iridium_max - C_Iridium_min);
    %   SOS2 piecewise linearization variables
    lambda_Ir_seg = sdpvar(N_seg_utility+1, 1);
    bin_Ir_seg = binvar(N_seg_utility, 1);
    %   SOS2 constraints (ensure validity of piecewise linearization)
    Constraints = [Constraints, sum(lambda_Ir_seg) == 1, lambda_Ir_seg >= 0];
    for i = 1:N_seg_utility
        Constraints = [Constraints, lambda_Ir_seg(i) <= bin_Ir_seg(i), lambda_Ir_seg(i+1) <= bin_Ir_seg(i)];
    end
    Constraints = [Constraints, sum(bin_Ir_seg) == 1];
    %   Linearized utility calculation
    Constraints = [Constraints, x_Ir_k == sum(lambda_Ir_seg .* x_Ir_seg)];
    v_ele_Ir_k = sum(lambda_Ir_seg .* y_ele_Ir_seg);
    v_IES_Ir_k = sum(lambda_Ir_seg .* y_IES_Ir_seg);
    % Scenario-weighted utility function
    Constraints = [Constraints, U_ele_Ir(k) == rho_risk(k) * v_ele_Ir_k];
    Constraints = [Constraints, U_IES_Ir(k) == rho_risk(k) * v_IES_Ir_k];
end
%   Risk sharing agreement condition (non-negative expected utility for both parties)
Constraints = [Constraints, EU_ele_Ir == sum(U_ele_Ir), EU_IES_Ir == sum(U_IES_Ir)];
Constraints = [Constraints, EU_ele_Ir >= 0, EU_IES_Ir >= 0];
% IES Financial Risk Sharing Constraints
x_Fin_IES_seg = linspace(0, 1, N_seg_utility+1); % Normalized IES investment cost [0,1]
y_ele_Fin_IES_seg = -exp(-lambda_ele * beta_Fin_IES * x_Fin_IES_seg * phi_Fin_IES);
y_IES_Fin_IES_seg = -exp(-lambda_IES * (1 - beta_Fin_IES) * x_Fin_IES_seg * phi_Fin_IES);
for k = 1:N_risk_scen
    %   Normalize the IES investment cost for the current scenario
    x_Fin_IES_k = (I_Fin_IES(k) - I_Fin_IES_min) / (I_Fin_IES_max - I_Fin_IES_min);
    %   SOS2 piecewise linearization variables
    lambda_Fin_IES_seg = sdpvar(N_seg_utility+1, 1);
    bin_Fin_IES_seg = binvar(N_seg_utility, 1);
    %   SOS2 constraints
    Constraints = [Constraints, sum(lambda_Fin_IES_seg) == 1, lambda_Fin_IES_seg >= 0];
    for i = 1:N_seg_utility
        Constraints = [Constraints, lambda_Fin_IES_seg(i) <= bin_Fin_IES_seg(i), lambda_Fin_IES_seg(i+1) <= bin_Fin_IES_seg(i)];
    end
    Constraints = [Constraints, sum(bin_Fin_IES_seg) == 1];
    %   Linearized utility calculation
    Constraints = [Constraints, x_Fin_IES_k == sum(lambda_Fin_IES_seg .* x_Fin_IES_seg)];
    v_ele_Fin_IES_k = sum(lambda_Fin_IES_seg .* y_ele_Fin_IES_seg);
    v_IES_Fin_IES_k = sum(lambda_Fin_IES_seg .* y_IES_Fin_IES_seg);
    %   Scenario-weighted utility function
    Constraints = [Constraints, U_ele_Fin_IES(k) == rho_risk(k) * v_ele_Fin_IES_k];
    Constraints = [Constraints, U_IES_Fin_IES(k) == rho_risk(k) * v_IES_Fin_IES_k];
end
%   Risk sharing agreement condition
Constraints = [Constraints, EU_ele_Fin_IES == sum(U_ele_Fin_IES), EU_IES_Fin_IES == sum(U_IES_Fin_IES)];
Constraints = [Constraints, EU_ele_Fin_IES >= 0, EU_IES_Fin_IES >= 0];
% Electrolyzer Financial Risk Sharing Constraints
%   Precompute piecewise points for the exponential utility function
x_Fin_ele_seg = linspace(0, 1, N_seg_utility+1); % Normalized electrolyzer investment cost [0,1]
y_ele_Fin_ele_seg = -exp(-lambda_ele * (1 - beta_Fin_ele) * x_Fin_ele_seg * phi_Fin_ele);
y_IES_Fin_ele_seg = -exp(-lambda_IES * beta_Fin_ele * x_Fin_ele_seg * phi_Fin_ele);
for k = 1:N_risk_scen
    %   Normalize the electrolyzer investment cost for the current scenario
    x_Fin_ele_k = (I_Fin_ele(k) - I_Fin_ele_min) / (I_Fin_ele_max - I_Fin_ele_min);
    %   SOS2 piecewise linearization variables
    lambda_Fin_ele_seg = sdpvar(N_seg_utility+1, 1);
    bin_Fin_ele_seg = binvar(N_seg_utility, 1);
    %   SOS2 constraints
    Constraints = [Constraints, sum(lambda_Fin_ele_seg) == 1, lambda_Fin_ele_seg >= 0];
    for i = 1:N_seg_utility
        Constraints = [Constraints, lambda_Fin_ele_seg(i) <= bin_Fin_ele_seg(i), lambda_Fin_ele_seg(i+1) <= bin_Fin_ele_seg(i)];
    end
    Constraints = [Constraints, sum(bin_Fin_ele_seg) == 1];
    %   Linearized utility calculation
    Constraints = [Constraints, x_Fin_ele_k == sum(lambda_Fin_ele_seg .* x_Fin_ele_seg)];
    v_ele_Fin_ele_k = sum(lambda_Fin_ele_seg .* y_ele_Fin_ele_seg);
    v_IES_Fin_ele_k = sum(lambda_Fin_ele_seg .* y_IES_Fin_ele_seg);
    %   Scenario-weighted utility function
    Constraints = [Constraints, U_ele_Fin_ele(k) == rho_risk(k) * v_ele_Fin_ele_k];
    Constraints = [Constraints, U_IES_Fin_ele(k) == rho_risk(k) * v_IES_Fin_ele_k];
end
%   Risk sharing agreement condition
Constraints = [Constraints, EU_ele_Fin_ele == sum(U_ele_Fin_ele), EU_IES_Fin_ele == sum(U_IES_Fin_ele)];
Constraints = [Constraints, EU_ele_Fin_ele >= 0, EU_IES_Fin_ele >= 0];
% Risk Compensation Model Constraints
%   Risk compensation for iridium price fluctuation
Constraints = [Constraints, p_RSC_Ir == beta_Ir * sum(rho_risk .* (C_Iridium - E_C_Iridium))];
%   IES financial risk compensation (Electrolyzer → IES)
Constraints = [Constraints, p_RSC_Fin_ele == beta_Fin_IES * sum(rho_risk .* (I_Fin_IES - E_I_Fin_IES))];
%   Electrolyzer financial risk compensation (IES → Electrolyzer)
Constraints = [Constraints, p_RSC_Fin_IES == beta_Fin_ele * sum(rho_risk .* (I_Fin_ele - E_I_Fin_ele))];
% -------------------------- SOLVER CONFIGURATION & SOLUTION --------------------------
%% Solver options 
ops = sdpsettings('solver', 'gurobi', ...
    'verbose', 2, ...
    'gurobi.MIPGap', 1e-4, ...
    'gurobi.TimeLimit', 7200, ...
    'gurobi.Threads', 8, ...
    'debug', 1);
toc