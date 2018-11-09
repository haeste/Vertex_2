function[RecVar] =  runSimulation(params, connections, electrodes)
%RUNSIMULATION Run the simulation given the model generated by initNetwork().
%   RUNSIMULATION(PARAMS, CONNECTIONS, ELECTRODES) runs the simulation
%   given the model generated by initNetwork(). PARAMS, CONNECTIONS and
%   ELECTRODES are the PARAMS, CONNECTIONS and ELECTRODES outputs from the
%   initNetwork() function. RUNSIMULATION automatically saves the simulation
%   results in the directory specified by the user in the recording
%   settings structure given to initNetwork().

% Create shorthand names for the parameter structures in params
TP = params.TissueParams;
NP = params.NeuronParams;
CP = params.ConnectionParams;
RS = params.RecordingSettings;
SS = params.SimulationSettings;

% Get the directory to save files to (and create it if necessary)
outputDirectory = RS.saveDir;
if ~strcmpi(outputDirectory(end), '/')
    outputDirectory = [outputDirectory '/'];
end
if exist(outputDirectory, 'dir') ~= 7
    mkdir(outputDirectory);
end
RS.saveDir = outputDirectory;

% If loading spikes from a previous simulation, and spikeLoadDir is not
% specified in params.SimulationSettings, assume that we are loading spikes
% from the output directory
if isfield(SS,'spikeLoad')
    if SS.spikeLoad
        if ~isfield(SS, 'spikeLoadDir')
            inputDirectory = outputDirectory;
            SS.spikeLoadDir = inputDirectory;
        end
    end
end



SS.recordingI_syn = false;
if isfield(RS, 'I_syn') && ~isempty(RS.I_syn)
  SS.recordingI_syn = true;
end

%NP = NeuronParams;
% Calculate passive neuron properties in correct units
NP = calculatePassiveProperties(NP, TP);


% If using pre-calculated spike times with the loadspiketimes neuron model,
% check the stored spike times can be found, then load them and convert
% into units of timeStep
loadedSpikeTimeCell = cell(TP.numGroups, 1);
for iGroup = 1:TP.numGroups
    if strcmpi(NP(iGroup).neuronModel, 'loadspiketimes')
        spkfile = NP(iGroup).spikeTimeFile; % check spikeTimeDir is a field
        if exist(spkfile,'file') ~= 2
            errMsg = ['The specified spike time file for neuron group ' ...
                num2str(iGroup) ' does not exist.'];
            error('vertex:runSimulation:spikeTimeDirError', errMsg);
        else
            loadedSpikeTimes = load(spkfile);
            fName = fields(loadedSpikeTimes);
            loadedSpikeTimeCell{iGroup} = loadedSpikeTimes.(fName{1});
            for ii = 1:length(loadedSpikeTimeCell{iGroup})
                loadedSpikeTimeCell{iGroup}{ii} = ...
                    sort(round(loadedSpikeTimeCell{iGroup}{ii} ./ SS.timeStep));
            end
        end
    end
end

% Setup the neuron ID mapping for routing spikes, saving variables etc.
[NeuronIDMap] = setupNeuronIDMapping(TP, SS);
% Initialise the neuron models
[NeuronModelArr] = ...
    setupNeuronDynamicVars(TP, NP, SS, NeuronIDMap, loadedSpikeTimeCell);
% Initialise the synapse models
[SynapseModelArr, synMapCell] = setupSynapseDynamicVars(TP, NP, CP, SS, RS);

% Initialise the input models (if any)
if isfield(NP, 'Input')
    [InputModelArr] = setupInputDynamicVars(TP, NP, SS);
else
    InputModelArr = [];
end


% Prepare synapses and synaptic weights.
[synapsesArrSim, weightArr] = prepareSynapsesAndWeights(TP,CP,SS,connections);
% Initialise the recording variables

[RS, RecordingVars, lineSourceModCell] = ...
    setupRecordingVars(TP, NP, SS, RS, NeuronIDMap, electrodes, weightArr,synapsesArrSim, SynapseModelArr);

%Setting the stimulation field v_ext for each neuron compartment
%Get_V_ext returns the extracellular potential specified by
%TP.StimulationsField at each of the compartment midpoints.
%setVext is a function attached to the NeuronModel object.

%It will assign the values passed to it to the v_ext field of the neuron.
if isfield(TP, 'StimulationField')

    if SS.parallelSim
        compartments = TP.compartmentlocations;
        spmd
            subsetInLab = find(SS.neuronInLab==labindex());
            NeuronModelArr = get_compartment_midpoints(TP,NeuronModelArr, SS,compartments);
            if isa(TP.StimulationField,'pde.TimeDependentResults')
                for iGroup = 1:length(NeuronModelArr)
                    for iStimTime = 1:size(TP.StimulationField.NodalSolution,2)
                        paraStimParam(iGroup).V_ext_mat(:,:,iStimTime) = get_V_ext(NeuronModelArr{iGroup}.midpoints, TP.StimulationField,iStimTime);
                    end
                    setVext(NeuronModelArr{iGroup},paraStimParam(iGroup).V_ext_mat(:,:,1));
                end
                nsaves = 0;
            else
                for iGroup = 1:length(NeuronModelArr)
                    setVext(NeuronModelArr{iGroup},get_V_ext(NeuronModelArr{iGroup}.midpoints, TP.StimulationField,1));
                end
                if isfield(TP,'tRNS')
                    setVext(NeuronModelArr{iGroup},NeuronModelArr{iGroup}.v_ext*TP.tRNS);
                end
            end
        end
    else
        NeuronModelArr = get_compartment_midpoints(TP,NeuronModelArr, SS, TP.compartmentlocations);
        if isa(TP.StimulationField,'pde.TimeDependentResults')
            for iGroup = 1:length(NeuronModelArr)
                 if isfield(SS, 'RotateField')
                    NeuronModelArr{iGroup}.midpoints = rotloc(NeuronModelArr{iGroup}.midpoints,SS.RotateField.angle,SS.RotateField.axis);
                 end
                for iStimTime = 1:size(TP.StimulationField.NodalSolution,2)
                    NP(iGroup).V_ext_mat(:,:,iStimTime) = get_V_ext(NeuronModelArr{iGroup}.midpoints, TP.StimulationField,iStimTime);
                end
                setVext(NeuronModelArr{iGroup},NP(iGroup).V_ext_mat(:,:,1));
            end
        else
            for iGroup = 1:length(NeuronModelArr)
                if isfield(SS, 'RotateField')
                    locs = rotlocs(NeuronModelArr{iGroup}.midpoints,SS.RotateField.angle,SS.RotateField.axis);
                    disp('Rotating neurons in the field')
                    setVext(NeuronModelArr{iGroup},get_V_ext(locs, TP.StimulationField,1));
                
                else
                setVext(NeuronModelArr{iGroup},get_V_ext(NeuronModelArr{iGroup}.midpoints, TP.StimulationField,1));
                end
                
            end
        end
    end
    
end
disp('Simulating..')
% Run the simulation. This stores the results in the specified folder at
% the specified time intervals.
if SS.parallelSim
    % IF IN PARALLEL MODE:
    % If you want to run several simulations within runSimulation(), for
    % example, changing parameters between runs (see tutorials at
    % www.vertexsimulator.org), then uncomment the next line to get the
    % dynamic variables at the end of simulateParallel()
    %[NeuronModelArr, SynapseModelArr, InputModelArr, numSaves] = ...
    
    parameterCell = {TP, NP, CP, RS, SS,SynapseModelArr};
    fname = [outputDirectory 'parameters.mat'];
    save(fname, 'parameterCell','-v7.3');
    
    if isfield(TP, 'StimulationField') && isa(TP.StimulationField,'pde.TimeDependentResults')
        
        if isfield(SS, 'optimisation')
            disp('using optimisation variant of simulate parallel')
            [~,~,~,~,RecVar]= simulateParallelOpt(TP, NP, SS, RS, NeuronIDMap, NeuronModelArr, ...
                SynapseModelArr, InputModelArr, RecordingVars, lineSourceModCell, ...
                synapsesArrSim, weightArr, synMapCell,nsaves,paraStimParam);
        else
            simulateParallel(TP, NP, SS, RS, NeuronIDMap, NeuronModelArr, ...
                SynapseModelArr, InputModelArr, RecordingVars, lineSourceModCell, ...
                synapsesArrSim, weightArr, synMapCell,nsaves,paraStimParam);
        end
    else
        if isfield(SS, 'optimisation')
            disp('using optimisation variant of simulate parallel')
            [~,~,~,~,RecVar]= simulateParallelOpt(TP, NP, SS, RS, NeuronIDMap, NeuronModelArr, ...
                SynapseModelArr, InputModelArr, RecordingVars, lineSourceModCell, ...
                synapsesArrSim, weightArr, synMapCell);
        else
            simulateParallel(TP, NP, SS, RS, NeuronIDMap, NeuronModelArr, ...
                SynapseModelArr, InputModelArr, RecordingVars, lineSourceModCell, ...
                synapsesArrSim, weightArr, synMapCell);
        end
    end
    
    % You can now alter the parameters in NP to change neuron or input
    % properties, then rerun simulateParallel() to run the next stage of the
    % simulation for another SS.simulationTime milliseconds. Passing numSaves
    % back into simulateParallel() ensures that the save files carry on from the
    % correct save number.
    %
    % REMEMBER: if you change the neurons' passive properties, you need to run:
    %   NP = calculatePassiveProperties(NP, TP);
    % REMEMBER: if you are using Ornstein-Uhlenbeck process type inputs and
    % change the Inputs' parameters, you need to run:
    %   InputModelArr = recalculateInputObjectPars(InputModelArr, TP, NP, SS);
    %
    % ... ... do parameter modification here ... ...
    %[NeuronModelArr, SynapseModelArr, InputModelArr, numSaves] = ...
    %simulateParallel(TP, NP, SS, RS, NeuronIDMap, NeuronModelArr, ...
    %SynapseModelArr, InputModelArr, RecordingVars, lineSourceModCell, ...
    %synapsesArrSim, weightArr, synMapCell, numSaves);
    
    % ... and so on as many times as you like.
else
    % IF IN SERIAL MODE:
    % If you want to run several simulations within runSimulation(), for
    % example, changing parameters between runs (see tutorials at
    % www.vertexsimulator.org), then uncomment the next line to get the
    % dynamic variables at the end of simulate()
    %[NeuronModelArr, SynapseModelArr, InputModelArr, numSaves] = ...
    
    if isfield(SS, 'optimisation')
        disp('using optimisation variant of simulate')
        [~,~,~,~,RecVar] = simulate(TP, NP, SS, RS, NeuronIDMap, NeuronModelArr, ...
            SynapseModelArr, InputModelArr, RecordingVars, lineSourceModCell, ...
            synapsesArrSim, weightArr, synMapCell);
        
    else
        
        simulate(TP, NP, SS, RS, NeuronIDMap, NeuronModelArr, ...
            SynapseModelArr, InputModelArr, RecordingVars, lineSourceModCell, ...
            synapsesArrSim, weightArr, synMapCell);
    end
    % You can now alter the parameters in NP to change neuron or input
    % properties, then rerun simulate() to run the next stage of the
    % simulation for another SS.simulationTime milliseconds. Passing numSaves
    % back into simulate() ensures that the save files carry on from the
    % correct save number.
    %
    % REMEMBER: if you change the neurons' passive properties, you need to run:
    %   NP = calculatePassiveProperties(NP, TP);
    % REMEMBER: if you are using Ornstein-Uhlenbeck process type inputs and
    % change the Inputs' parameters, you need to run:
    %   InputModelArr = recalculateInputObjectPars(InputModelArr, TP, NP, SS);
    %
    % ... ... do parameter modification here ... ...
    %[NeuronModelArr, SynapseModelArr, InputModelArr, numSaves] = ...
    %simulate(TP, NP, SS, RS, NeuronIDMap, NeuronModelArr, ...
    %SynapseModelArr, InputModelArr, RecordingVars, lineSourceModCell, ...
    %synapsesArrSim, weightArr, synMapCell, numSaves);
    
    % ... and so on as many times as you like.
end

% Store the parameters in the same folder, so we can reference them later
% during analysis (used by loadResults, as well as useful for tracking
% simulations). You may want to copy these lines to store each parameter
% set after every time you call simulate()/simulateParallel().
if ~isfield(SS,'optimisation')
    parameterCell = {TP, NP, CP, RS, SS,SynapseModelArr};
    fname = [outputDirectory 'parameters.mat'];
    save(fname, 'parameterCell','-v7.3'); % saving in version 7.3 to avoid errors from large files.
end