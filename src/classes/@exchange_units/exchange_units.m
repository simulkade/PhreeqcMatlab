classdef exchange_units
    %EXCHANGE_UNITS Sets input units for exchangers. In PHREEQC input, 
    % exchangers are defined by moles of exchange sites (Mp). 
    % RM_SetUnitsExchange specifies how the number of moles of exchange 
    % sites in a reaction cell (Mc) is calculated from the input value (Mp). 
    % Options are 0, Mp is mol/L of RV (default), Mc = Mp*RV, where RV is 
    % the representative volume (RM_SetRepresentativeVolume); 
    % 1, Mp is mol/L of water in the RV, Mc = Mp*P*RV, where P is porosity 
    % (RM_SetPorosity); or 2, Mp is mol/L of rock in the RV, Mc = Mp*(1-P)*RV. 
    % If a single EXCHANGE definition is used for cells with different 
    % initial porosity, the three options scale quite differently. For 
    % option 0, the number of moles of exchangers will be the same regardless 
    % of porosity. For option 1, the number of moles of exchangers will be 
    % vary directly with porosity and inversely with rock volume. 
    % For option 2, the number of moles of exchangers will vary directly 
    % with rock volume and inversely with porosity.
    
    enumeration
        mol_per_L_RV, mol_per_L_W, mol_per_L_rock
    end
        
end

