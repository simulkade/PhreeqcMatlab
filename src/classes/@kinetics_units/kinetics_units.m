classdef kinetics_units
    % KINETICS_UNITS In PHREEQC input, kinetics are defined by moles of 
    % kinetic reactants (Mp). RM_SetUnitsKinetics specifies how the number 
    % of moles of kinetic reactants in a reaction cell (Mc) is calculated 
    % from the input value (Mp).
    % Options are 0, Mp is mol/L of RV (default), Mc = Mp*RV, where RV is 
    % the representative volume (RM_SetRepresentativeVolume); 1, Mp is mol/L 
    % of water in the RV, Mc = Mp*P*RV, where P is porosity (RM_SetPorosity); 
    % or 2, Mp is mol/L of rock in the RV, Mc = Mp*(1-P)*RV.
    % If a single KINETICS definition is used for cells with different 
    % initial porosity, the three options scale quite differently. For 
    % option 0, the number of moles of kinetic reactants will be the same 
    % regardless of porosity. For option 1, the number of moles of kinetic 
    % reactants will be vary directly with porosity and inversely with rock 
    % volume. For option 2, the number of moles of kinetic reactants will 
    % vary directly with rock volume and inversely with porosity.
    % Note that the volume of water in a cell in the reaction module is equal 
    % to the product of porosity (RM_SetPorosity), the saturation (RM_SetSaturation), 
    % and representative volume (RM_SetRepresentativeVolume), which is usually 
    % less than 1 liter. It is important to write the RATES definitions for 
    % homogeneous (aqueous) kinetic reactions to account for the current 
    % volume of water, often by calculating the rate of reaction per liter 
    % of water and multiplying by the volume of water (Basic function SOLN_VOL).
    % Rates that depend on surface area of solids, are not dependent on 
    % the volume of water. However, it is important to get the correct 
    % surface area for the kinetic reaction. To scale the surface area 
    % with the number of moles, the specific area (m^2 per mole of reactant) 
    % can be defined as a parameter (KINETICS; -parm), which is multiplied by 
    % the number of moles of reactant (Basic function M) in RATES to obtain 
    % the surface area.
    
    enumeration
        mol_per_L_RV, mol_per_L_W, mol_per_L_rock
    end
end

