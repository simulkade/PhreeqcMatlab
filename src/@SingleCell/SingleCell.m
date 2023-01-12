classdef SingleCell
    %SINGLECELL is a class that contains a mixture of different components.
    % it contains at least an aqueous solution. It can contain solid and
    % gas phases too, which are defined as PhreeqcMatlab objects. It also
    % has fields for temperature and pressure.
    % The reaction rate field can also be specified to run the cell for a
    % certain specified time. Running a cell does not update its fields
    % (i.e. equilibrate aqueous solutions with other specified phases, etc)
    % but one can get a copy of an aqueous cell after running it with
    % PhreeqcRM. The copy is saved as a PhreeqcCell class.
    
    properties
        name(1,1) string
        temperature(1,1) double
        pressure(1,1) double
        aqueous_solution(1,1) Solution
        equilibrium_phase(1,1) Phase
        surface_specie(1,1) Surface
        exchanger(1,1) Exchange
        kinetics(1,1) Kinetics
        gas_phase(1,1) Gas
        data_base(1,1) string
    end
    
    methods
        function obj = SingleCell(aq_solution, varargin)
            %SINGLECELL constructs a single cell that contains an aqueous
            %liquid and other phases, e.g. soluble minerals, surfaces,
            %exchangers, gas phases, etc. At least, a solution must be
            %provided for the calculations to take place
            obj.temperature = aq_solution.temperature;
            obj.pressure = aq_solution.pressure;
            obj.aqueous_solution = aq_solution;
        end
        
        function cell_result = run(obj)
            %cell_result = run(obj)
            % Runs the simulation defined by a mixture of the aqueous
            % solution with other phase, surface, exchanger, etc. in a
            % phreeqcRM cell
            phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread
            phreeqc_rm = phreeqc_rm.RM_Create(); % create a PhreeqcRM instance
            status = phreeqc_rm.RM_SetComponentH2O(true);
            status = phreeqc_rm.RM_SetUnitsSolution(2);           % 1, mg/L; 2, mol/L; 3, kg/kgs
            status = phreeqc_rm.RM_SetUnitsPPassemblage(1);       % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
            status = phreeqc_rm.RM_SetUnitsExchange(1);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
            status = phreeqc_rm.RM_SetUnitsSurface(1);            % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
            status = phreeqc_rm.RM_SetUnitsGasPhase(1);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
            status = phreeqc_rm.RM_SetUnitsSSassemblage(1);       % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
            status = phreeqc_rm.RM_SetUnitsKinetics(1);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
            phreeqc_rm.RM_UseSolutionDensityVolume(true);
            
            status = phreeqc_rm.RM_SetPorosity(1.0);             % If pororosity changes due to compressibility
            status = phreeqc_rm.RM_SetSaturation(1.0);           % If saturation changes
                
            status = phreeqc_rm.RM_LoadDatabase(database_file(obj.data_base)); % load the database

            % create the input phreeqc string

            status = phreeqc_rm.RM_RunFile(true, true, true, iph_string); % run the input file
            
            ncomps = phreeqc_rm.RM_FindComponents();
            comp_name = phreeqc_rm.GetComponents();

            ic1 = -1*ones(7, 1);
            ic2 = -1*ones(7, 1);
            f1 = ones(7, 1);


            cell_result = [];
        end
    end
end

