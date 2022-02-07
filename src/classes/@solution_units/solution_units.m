classdef solution_units
    %  solution_units   Solution concentration units used by the transport model. 
    % Options are 1, mg/L; 2 mol/L; or 3, mass fraction, kg/kgs. PHREEQC 
    % defines solutions by the number of moles of each element in the solution.
    % 
    % To convert from mg/L to moles of element in the representative volume 
    % of a reaction cell, mg/L is converted to mol/L and multiplied by the 
    % solution volume, which is the product of porosity (RM_SetPorosity), 
    % saturation (RM_SetSaturation), and representative volume 
    % (RM_SetRepresentativeVolume). To convert from mol/L to moles of element 
    % in the representative volume of a reaction cell, mol/L is multiplied by 
    % the solution volume. To convert from mass fraction to moles of element 
    % in the representative volume of a reaction cell, kg/kgs is converted 
    % to mol/kgs, multiplied by density (RM_SetDensity) and multiplied by 
    % the solution volume.
    % To convert from moles of element in the representative volume of a 
    % reaction cell to mg/L, the number of moles of an element is divided 
    % by the solution volume resulting in mol/L, and then converted to mg/L. 
    % To convert from moles of element in a cell to mol/L, the number of 
    % moles of an element is divided by the solution volume resulting in mol/L. 
    % To convert from moles of element in a cell to mass fraction, the number 
    % of moles of an element is converted to kg and divided by the total 
    % mass of the solution. Two options are available for the volume and 
    % mass of solution that are used in converting to transport concentrations: 
    % (1) the volume and mass of solution are calculated by PHREEQC, or 
    % (2) the volume of solution is the product of porosity (RM_SetPorosity), 
    % saturation (RM_SetSaturation), and representative volume 
    % (RM_SetRepresentativeVolume), and the mass of solution is volume 
    % times density as defined by RM_SetDensity. Which option is used is 
    % determined by RM_UseSolutionDensityVolume.
    enumeration
       mg_per_L, mol_per_L, kg_per_kgs
    end
end

