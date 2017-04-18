%% Neocortical slice model from Tomsett et al. 2014

cvc_tissue;
cvc_neurons;
cvc_connectivity;
%cvc_neurons_gamma;
%cvc_connectivity_gamma;
cvc_recording;
cvc_simulation;
cvc_field_stimulation;

% Change this directory to where you would like to save the results of the
% simulation
RS.saveDir = '~/Documents/MATLAB/Vertex_Results/VERTEX_cvc_results/cvc_slow_compartstim_tdcs2mvcathodal';
% Change these settings if you need to use fewer cores or a different
% parallel profile, or if you want to run in serial mode (this will take a
% long time)
SS.parallelSim = true; 
SS.poolSize = 2; %was 12 in the original
SS.profileName = 'local';

%% Initialise the network
[params, connections, electrodes] = initNetwork(TP, NP, CP, RS, SS);

%% Run the simulation
tic
runSimulation(params, connections, electrodes);
toc
% Load the simulation results
Results = loadResults(RS.saveDir);
%%
% If you have experienced any problems when trying to run this code, please
% email Richard Tomsett: r _at_ autap _dot_ se

%% Reference
% Tomsett RJ, Ainsworth M, Thiele A, Sanayei M, Chen X et al. (2014)
% Virtual Electrode Recording Tool for EXtracellular potentials (VERTEX):
% comparing multi-electrode recordings from simulated and biological
% mammalian cortical tissue, Brain Structure and Function.
% doi:10.1007/s00429-014-0793-x