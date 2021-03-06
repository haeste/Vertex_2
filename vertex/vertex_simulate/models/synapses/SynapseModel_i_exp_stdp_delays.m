classdef SynapseModel_i_exp_stdp_delays < SynapseModel_i_exp & STDPModel_delays
  %SynapseModel_g_exp Conductance-based single exponential synapses
  %   Parameters to set in ConnectionParams:
  %   - E_reversal, the reversal potential (in mV)
  %   - tau, the synaptic decay time constant (in ms)

  
  methods
    function SM = SynapseModel_i_exp_stdp_delays(Neuron, CP, SimulationSettings, ...
                                     postID, number_in_post,number_in_pre,pre_group_ids,~)
      SM = SM@SynapseModel_i_exp(Neuron, CP, SimulationSettings,postID, number_in_post,number_in_pre,pre_group_ids );
      SM = SM@STDPModel_delays(CP, SimulationSettings, postID, number_in_post,number_in_pre,pre_group_ids);

    end

    
    
    
    function SM = updateSynapses(SM, NM, dt)
        
      updateSynapses@SynapseModel_i_exp(SM, NM, dt);
      updateSynapses@STDPModel_delays(SM,dt);      
      
    end

    

  end % methods
  
  methods(Static)
      function params = getRequiredParams()
          params = [SynapseModel_i_exp.getRequiredParams STDPModel.getSTDPParams()];
      end
           
  end

end % classdef
