classdef solution_units
    %units --Indicates default concentration units are entered on this line. 
    % Optionally, -u [ nits ].
% concentration units --Default concentration units. Three groups of 
% concentration units are allowed, concentration 
% (1) per liter (“/L”), 
% (2) per kilogram solution (“/kgs”), or 
% (3) per kilogram water (“/kgw”). All concentration units for a solution 
% must be within the same group. Within a group, either 
% grams or moles may be used, and 
% prefixes milli (m) and micro (u) are acceptable. 
% The abbreviations for 
% parts per thousand, “ppt”; 
% parts per million, “ppm”; 
% and parts per billion, “ppb”, 
% are acceptable in the “per kilogram solution” group. 
% Default is mmol/kgw.
    enumeration
       mmol_per_L, umol_per_L, mol_per_L, ...
           mg_per_L, ug_per_L, g_per_L, ...
           mmol_per_kgs, umol_per_kgs, mol_per_kgs, ...
           mg_per_kgs, ug_per_kgs, g_per_kgs, ...
           mmol_per_kgw, umol_per_kgw, mol_per_kgw, ...
           mg_per_kgw, ug_per_kgw, g_per_kgw, ...
           ppt, ppm, ppb
    end
end

