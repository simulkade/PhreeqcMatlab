classdef PhreeqcRM

	properties
		id
		ncells
		nthreads
	end
	
	methods
        
        function phrm = PhreeqcRM(n_cells, n_threads)
            %{
            phrm = PhreeqcRM(n_cells, n_threads) 
            n_cells: number of reaction cells
            n_threads: number of CPU cores for OpenMP
            %}
            if ~libisloaded('libphreeqcrm')
                loadlibrary('libphreeqcrm','RM_interface_C.h');
            end
			phrm.ncells = n_cells;
			phrm.nthreads = n_threads;
        end
        
        function phrm = RM_Create(obj)
            %{
            phrm = RM_Create() 
            %}
            phrm = obj;
            if isempty(obj.id)
    			id_out= calllib('libphreeqcrm','RM_Create', obj.ncells, obj.nthreads);
                phrm.id = id_out;
            else
                warning('The PhreeqcRM object is already created. Please call this function with an empty PhreeqcRM object');
            end
		end
		
		function status = RM_Abort(obj, result, err_str)
            %{
            Abort the program. Result will be interpreted as an IRM_RESULT value and decoded; err_str will be printed; and the reaction module will be destroyed. If using MPI, an MPI_Abort message will be sent before the reaction module is destroyed. If the id is an invalid instance, RM_Abort will return a value of IRM_BADINSTANCE, otherwise the program will exit with a return code of 4.

            Parameters
            id	The instance id returned from RM_Create.
            result	Integer treated as an IRM_RESULT return code.
            err_str	String to be printed as an error message.
            Return values
            IRM_RESULT	Program will exit before returning unless id is an invalid reaction module id.
            See also
            RM_Destroy, RM_ErrorMessage.
            C Example:
                iphreeqc_id = RM_Concentrations2Utility(id, c_well, 1, tc, p_atm);
                strcpy(str, "SELECTED_OUTPUT 5; -pH; RUN_CELLS; -cells 1");
                status = RunString(iphreeqc_id, str);
                if (status != 0) status = RM_Abort(id, status, "IPhreeqc RunString failed");
            %}
			status = calllib('libphreeqcrm', 'RM_Abort', obj.id, result, err_str);
        end
        
        function status = RM_CloseFiles(obj)
            % Close the output and log files.
            status = calllib('libphreeqcrm','RM_CloseFiles', obj.id);
        end
        
        function status = RM_Concentrations2Utility(obj, c,	n, tc, p_atm)
            %{
            N sets of component concentrations are converted to SOLUTIONs numbered 1-n in the Utility IPhreeqc. The solutions can be reacted and manipulated with the methods of IPhreeqc. If solution concentration units (RM_SetUnitsSolution) are per liter, one liter of solution is created in the Utility instance; if solution concentration units are mass fraction, one kilogram of solution is created in the Utility instance. The motivation for this method is the mixing of solutions in wells, where it may be necessary to calculate solution properties (pH for example) or react the mixture to form scale minerals. The code fragments below make a mixture of concentrations and then calculate the pH of the mixture.

            Parameters
            id	The instance id returned from RM_Create.
            c	Array of concentrations to be made SOLUTIONs in Utility IPhreeqc. Array storage is equivalent to Fortran (n,ncomps).
            n	The number of sets of concentrations.
            tc	Array of temperatures to apply to the SOLUTIONs, in degree C. Array of size n.
            p_atm	Array of pressures to apply to the SOLUTIONs, in atm. Array of size n.
            
            C Example:
                c_well = (double *) malloc((size_t) ((size_t) (1 * ncomps * sizeof(double))));
                for (i = 0; i < ncomps; i++)
                {
                  c_well[i] = 0.5 * c[0 + nxyz*i] + 0.5 * c[9 + nxyz*i];
                }
                tc = (double *) malloc((size_t) (1 * sizeof(double)));
                p_atm = (double *) malloc((size_t) (1 * sizeof(double)));
                tc[0] = 15.0;
                p_atm[0] = 3.0;
                iphreeqc_id = RM_Concentrations2Utility(id, c_well, 1, tc, p_atm);
                strcpy(str, "SELECTED_OUTPUT 5; -pH; RUN_CELLS; -cells 1");
                status = RunString(iphreeqc_id, str);
                status = SetCurrentSelectedOutputUserNumber(iphreeqc_id, 5);
                status = GetSelectedOutputValue2(iphreeqc_id, 1, 0, &vtype, &pH, svalue, 100);
            %}
            status = calllib('libphreeqcrm','RM_Concentrations2Utility', ...
                obj.id, c, n, tc, p_atm);
        end
        
        
        function status = RM_CreateMapping(obj, grid2chem)
            %{
            id	The instance id returned from RM_Create.
            grid2chem	An array of integers: Nonnegative is a reaction cell number (0 based), negative is an inactive cell. Array of size nxyz (number of grid cells). 
            %}
            status = calllib('libphreeqcrm','RM_CreateMapping', ...
                obj.id, grid2chem);
        end
        
        function status = RM_DecodeError(obj, e)
            status = calllib('libphreeqcrm','RM_DecodeError', obj.id, e);
        end
        
        
        function status = RM_Destroy(obj)
            status = calllib('libphreeqcrm','RM_Destroy', obj.id);
        end
        
        function status = RM_DumpModule(obj, dump_on, appnd)
            %{
            id	The instance id returned from RM_Create.
            dump_on	Signal for writing the dump file: 1 true, 0 false.
            appnd	Signal to append to the contents of the dump file: 1 true, 0 false. 
            %}
            
            status = calllib('libphreeqcrm','RM_DumpModule', obj.id, dump_on, appnd);
        end
        
        function status = RM_ErrorMessage(obj, errstr)
            %{
            errstr	String to be printed. 
            %}
            status = calllib('libphreeqcrm','RM_ErrorMessage', obj.id, errstr);
        end
        
        function ncomps = RM_FindComponents(obj)
            %{
            ncomps number of components currently in the list, or IRM_RESULT error code (see RM_DecodeError). 
            %}
            ncomps = calllib('libphreeqcrm','RM_FindComponents', obj.id);
        end
        
        function status = RM_GetBackwardMapping(obj, n, list, list_size)
            %{
            n	A cell number in the PhreeqcRM numbering system (0 <= n < RM_GetChemistryCellCount).
            list	Array to store the user cell numbers mapped to PhreeqcRM cell n.
            list_size	Input, the allocated size of list; it is an error if the array is too small. Output, the number of cells mapped to cell n. 
            %}
            status = calllib('libphreeqcrm','RM_GetBackwardMapping', ...
                obj.id, n, list, list_size);
        end
        
        function n = RM_GetChemistryCellCount(obj)
            %{
            n	of chemistry cells, or IRM_RESULT error code (see RM_DecodeError). 
            %}
            n = calllib('libphreeqcrm','RM_GetChemistryCellCount', obj.id);
        end
        
        function [status, chem_name_out] = RM_GetComponent(obj, num, chem_name, l)
            %{
            num	The number of the component to be retrieved. C, 0 based.
            chem_name	The string value associated with component num.
            l	The length of the maximum number of characters for chem_name. 
            %}
            [status, chem_name_out] = calllib('libphreeqcrm','RM_GetComponent', ...
                obj.id, num, chem_name, l);
        end
        
        function components = GetComponents(obj)
           %{
            Get all the components name and return as a cell vector
            %}
            ncomps = obj.RM_FindComponents();
            components = cell(ncomps, 1);
            s_name = '000000000000000000000000000'; % untill I find a more elegant solution
            for i=1:ncomps
                [~, components{i}] = obj.RM_GetComponent(i-1, s_name, length(s_name));
            end
        end
        
        function n = RM_GetComponentCount(obj)
            %{
            Returns the number of components in the reaction-module component list. The component list is generated by calls to RM_FindComponents. The return value from the last call to RM_FindComponents is equal to the return value from RM_GetComponentCount. 
            %}
            n = calllib('libphreeqcrm','RM_GetComponentCount', obj.id);
        end
        
        function [status, c_out] = RM_GetConcentrations(obj, c)
            %{
            Transfer solution concentrations from each reaction cell to the concentration array given in the argument list (c). Units of concentration for c are defined by RM_SetUnitsSolution. For concentration units of per liter, the solution volume is used to calculate the concentrations for c. For mass fraction concentration units, the solution mass is used to calculate concentrations for c. Two options are available for the volume and mass of solution that are used in converting to transport concentrations: (1) the volume and mass of solution are calculated by PHREEQC, or (2) the volume of solution is the product of saturation (RM_SetSaturation), porosity (RM_SetPorosity), and representative volume (RM_SetRepresentativeVolume), and the mass of solution is volume times density as defined by RM_SetDensity. RM_UseSolutionDensityVolume determines which option is used. For option 1, the databases that have partial molar volume definitions needed to accurately calculate solution volume are phreeqc.dat, Amm.dat, and pitzer.dat.

            Parameters
            id	The instance id returned from RM_Create.
            c	Array to receive the concentrations. Dimension of the array is equivalent to Fortran (nxyz, ncomps), where nxyz is the number of user grid cells and ncomps is the result of RM_FindComponents or RM_GetComponentCount. Values for inactive cells are set to 1e30. 
            %}
            [status, c_out] = calllib('libphreeqcrm','RM_GetConcentrations', obj.id, c);
        end
        
        function c = GetConcentrations(obj)
            %{
            Transfer solution concentrations from each reaction cell to the concentration array given in the argument list (c). Units of concentration for c are defined by RM_SetUnitsSolution. For concentration units of per liter, the solution volume is used to calculate the concentrations for c. For mass fraction concentration units, the solution mass is used to calculate concentrations for c. Two options are available for the volume and mass of solution that are used in converting to transport concentrations: (1) the volume and mass of solution are calculated by PHREEQC, or (2) the volume of solution is the product of saturation (RM_SetSaturation), porosity (RM_SetPorosity), and representative volume (RM_SetRepresentativeVolume), and the mass of solution is volume times density as defined by RM_SetDensity. RM_UseSolutionDensityVolume determines which option is used. For option 1, the databases that have partial molar volume definitions needed to accurately calculate solution volume are phreeqc.dat, Amm.dat, and pitzer.dat.

            c	returns the concentrations in each cell [nxyz x ncomps]
            matrix
            %}
            nxyz = obj.ncells;
            ncomps = obj.RM_FindComponents();
            c = zeros(nxyz, ncomps);
            [~, c] = calllib('libphreeqcrm','RM_GetConcentrations', obj.id, c);
        end
        
        
        function [status, density_out] = RM_GetDensity(obj, density)
            %{
            density	Array to receive the densities. Dimension of the array is nxyz, where nxyz is the number of user grid cells (RM_GetGridCellCount). Values for inactive cells are set to 1e30. 
            %}
            [status, density_out] = calllib('libphreeqcrm','RM_GetDensity', obj.id, density);
        end
        
        function density = GetDensity(obj)
            %{
            density	Array to receive the densities. Dimension of the array is nxyz, where nxyz is the number of user grid cells (RM_GetGridCellCount). Values for inactive cells are set to 1e30. 
            %}
            density = zeros(obj.ncells, 1);
            density = calllib('libphreeqcrm','RM_GetDensity', obj.id, density);
        end
        
        function [status, ec_out] = RM_GetEndCell(obj, ec)
            %{
            Returns an array with the ending cell numbers from the range of cell numbers assigned to each worker.

            Parameters
                id	The instance id returned from RM_Create.
                ec	Array to receive the ending cell numbers. Dimension of the array is the number of threads (OpenMP) or the number of processes (MPI). 
            %}
            [status, ec_out] = calllib('libphreeqcrm','RM_GetEndCell', obj.id, ec);
        end
        
        function n = RM_GetEquilibriumPhasesCount(obj)
            %{
            Returns the number of equilibrium phases in the initial-phreeqc module. RM_FindComponents must be called before RM_GetEquilibriumPhasesCount. This method may be useful when generating selected output definitions related to equilibrium phases. 
            %}
            n = calllib('libphreeqcrm','RM_GetEquilibriumPhasesCount', obj.id);
        end
        
        
        function [status, chem_name_out] = RM_GetEquilibriumPhasesName(obj, num, chem_name, l)
            %{
            Retrieves an item from the equilibrium phase list. The list includes all phases included in any EQUILIBRIUM_PHASES definitions in the initial-phreeqc module. RM_FindComponents must be called before RM_GetEquilibriumPhasesName. This method may be useful when generating selected output definitions related to equilibrium phases.

            Parameters
                id	The instance id returned from RM_Create.
                num	The number of the equilibrium phase name to be retrieved. Fortran, 1 based.
                name	The equilibrium phase name at number num.
                l1	The length of the maximum number of characters for name. 
            %}
            [status, chem_name_out] = calllib('libphreeqcrm','RM_GetEquilibriumPhasesName', ...
                obj.id, num, chem_name, l);
        end
        
        function components = GetEquilibriumPhasesName(obj)
           %{
            Get all the EQUILIBRIUM PHASES NAME name and return as a cell vector
            %}
            % ncomps = obj.RM_FindComponents();
            n_eq_phases = obj.RM_GetEquilibriumPhasesCount();
            components = cell(n_eq_phases, 1);
            s_name = '000000000000000000000000000'; % untill I find a more elegant solution
            for i=1:n_eq_phases
                [~, components{i}] = obj.RM_GetEquilibriumPhasesName(i-1, s_name, length(s_name));
            end
        end
        
        function [status, msg_out] = RM_GetErrorString(obj, errstr, l)
            %{
            Returns a string containing error messages related to the last call to a PhreeqcRM method to the character argument (errstr).

            Parameters
                id	The instance id returned from RM_Create.
                errstr	The error string related to the last call to a PhreeqcRM method.
                l	Maximum number of characters that can be written to the argument (errstr). 
            %}
            [status, msg_out] = calllib('libphreeqcrm','RM_GetErrorString', obj.id, errstr, l);
        end
        
        function l = RM_GetErrorStringLength(obj)
            %{
            
            %}
            l = calllib('libphreeqcrm','RM_GetErrorStringLength', obj.id);
        end
        
        function n = RM_GetExchangeSpeciesCount(obj)
            %{
            Returns the number of exchange species in the initial-phreeqc module. RM_FindComponents must be called before RM_GetExchangeSpeciesCount. This method may be useful when generating selected output definitions related to exchangers. 
            %}
            n = calllib('libphreeqcrm','RM_GetExchangeSpeciesCount', obj.id);
        end
        
        
        function [status, chem_name_out] = RM_GetExchangeName(obj, num, chem_name, l)
            %{
            Retrieves an item from the exchange name list. RM_FindComponents must be called before RM_GetExchangeName. The exchange names vector is the same length as the exchange species names vector and provides the corresponding exchange site (for example, X corresponing to NaX). This method may be useful when generating selected output definitions related to exchangers.

            Parameters
                id	The instance id returned from RM_Create.
                num	The number of the exchange name to be retrieved. Fortran, 1 based.
                name	The exchange name associated with exchange species num.
                l1	The length of the maximum number of characters for name. 
            %}
            [status, chem_name_out] = calllib('libphreeqcrm','RM_GetExchangeName', ...
                obj.id, num, chem_name, l);
        end
        
        function [status, chem_name_out] = RM_GetExchangeSpeciesName(obj, num, chem_name, l)
            %{
            Retrieves an item from the exchange species list. The list of exchange species (such as "NaX") is derived from the list of components (RM_FindComponents) and the list of all exchange names (such as "X") that are included in EXCHANGE definitions in the initial-phreeqc module. RM_FindComponents must be called before RM_GetExchangeSpeciesName. This method may be useful when generating selected output definitions related to exchangers.

            Parameters
                id	The instance id returned from RM_Create.
                num	The number of the exchange species to be retrieved. Fortran, 1 based.
                name	The exchange species name at number num.
                l1	The length of the maximum number of characters for name. 
            %}
            [status, chem_name_out] = calllib('libphreeqcrm','RM_GetExchangeSpeciesName', ...
                obj.id, num, chem_name, l);
        end
        
        function components = GetExchangeSpeciesNames(obj)
           %{
            Get all the EQUILIBRIUM PHASES NAME name and return as a cell vector
            %}
            % ncomps = obj.RM_FindComponents();
            n_ex_phases = obj.RM_GetExchangeSpeciesCount();
            components = cell(n_ex_phases, 1);
            s_name = '000000000000000000000000000'; % untill I find a more elegant solution
            s_name2 = '000000000000000000000000000';
            for i=1:n_ex_phases
                [~, s1] = obj.RM_GetExchangeSpeciesName(i-1, s_name, length(s_name));
                [~, s2] = obj.RM_GetExchangeName(i-1, s_name2, length(s_name));
                components{i} = [s1 s2];
            end
        end
        
        function [status, prefix_out] = RM_GetFilePrefix(obj, prefix, l)
            %{
            Returns the reaction-module file prefix to the character argument (prefix).

            Parameters
                id	The instance id returned from RM_Create.
                prefix	Character string where the prefix is written.
                l	Maximum number of characters that can be written to the argument (prefix). 
            C Example:

                char str[100], str1[200];
                status = RM_GetFilePrefix(id, str, 100);
                strcpy(str1, "File prefix: ");
                strcat(str1, str);
                strcat(str1, "\n");
                status = RM_OutputMessage(id, str1);


            %}
            [status, prefix_out] = calllib('libphreeqcrm','RM_GetFilePrefix', obj.id, prefix, l);
        end
        
        function [status, c_out] = RM_GetGasCompMoles(obj, c)
            %{
            Transfer moles of gas components from each reaction cell to the vector given in the argument list (gas_moles).

            Parameters
                id	The instance id returned from RM_Create.
                gas_moles	Vector to receive the moles of gas components. Dimension of the vector must be ngas_comps times nxyz, where, ngas_comps is the result of RM_GetGasComponentsCount, and nxyz is the number of user grid cells (RM_GetGridCellCount). If a gas component is not defined for a cell, the number of moles is set to -1. Values for inactive cells are set to 1e30. 
            %}
            [status, c_out] = calllib('libphreeqcrm','RM_GetGasCompMoles', obj.id, c);
        end
        
        function [status, c_out] = RM_SetGasCompMoles(obj, c)
            %{
            Transfer moles of gas components from the vector given in the argument list (gas_moles) to each reaction cell.

            Parameters
                id	The instance id returned from RM_Create.
                gas_moles	Vector of moles of gas components. Dimension of the vector must be ngas_comps times nxyz, where, ngas_comps is the result of RM_GetGasComponentsCount, and nxyz is the number of user grid cells (RM_GetGridCellCount). If the number of moles is set to a negative number, the gas component will not be defined for the GAS_PHASE of the reaction cell. 
            %}
            [status, c_out] = calllib('libphreeqcrm','RM_SetGasCompMoles', obj.id, c);
        end
        
        function n = RM_GetGasComponentsCount(obj)
            %{
            Returns the number of gas phase components in the initial-phreeqc module. RM_FindComponents must be called before RM_GetGasComponentsCount. This method may be useful when generating selected output definitions related to gas phases. 
            %}
            n = calllib('libphreeqcrm','RM_GetGasComponentsCount', obj.id);
        end
        
        function c = GetGasCompMoles(obj)
            %{
            Transfer moles of gas components from each reaction cell to the vector given in the argument list (gas_moles).
            %}
            nxyz = obj.ncells;
            obj.RM_FindComponents(); % need to call it first
            n_gas_comp = obj.RM_GetGasComponentsCount();
            c = zeros(nxyz, n_gas_comp);
            [~, c] = calllib('libphreeqcrm','RM_GetGasCompMoles', obj.id, c);
        end
        
        function [status, chem_name_out] = RM_GetGasComponentsName(obj, num, chem_name, l)
            %{
            Retrieves an item from the gas components list. The list includes all gas components included in any GAS_PHASE definitions in the initial-phreeqc module. RM_FindComponents must be called before RM_GetGasComponentsName. This method may be useful when generating selected output definitions related to gas phases.

            Parameters
                id	The instance id returned from RM_Create.
                num	The number of the gas component name to be retrieved. Fortran, 1 based.
                name	The gas component name at number num.
                l1	The length of the maximum number of characters for name. 
            %}
            [status, chem_name_out] = calllib('libphreeqcrm','RM_GetGasComponentsName', ...
                obj.id, num, chem_name, l);
        end
        
        function components = GetGasComponentsNames(obj)
           %{
            Get all the gas components name and return as a cell vector
            %}
            ncomps = obj.RM_FindComponents();
            n_gas_comp = obj.RM_GetGasComponentsCount();
            components = cell(n_gas_comp, 1);
            s_name = '000000000000000000000000000'; % untill I find a more elegant solution
            for i=1:ncomps
                [~, components{i}] = obj.RM_GetGasComponentsName(i-1, s_name, length(s_name));
            end
        end
        
        
        function [status, c_out] = RM_GetGasCompPhi(obj, c)
            %{
            Transfer fugacity coefficients (phi) of gas components from each reaction cell to the vector given in the argument list (gas_phi). Fugacity of a gas component is equal to its pressure times the fugacity coefficient.

            Parameters
                id	The instance id returned from RM_Create.
                gas_phi	Vector to receive the fugacity coefficients of gas components. Dimension of the vector must be ngas_comps times nxyz, where, ngas_comps is the result of RM_GetGasComponentsCount, and nxyz is the number of user grid cells (RM_GetGridCellCount). If a gas component is not defined for a cell, the fugacity coefficient is set to -1. Values for inactive cells are set to 1e30. 
           %}
            [status, c_out] = calllib('libphreeqcrm','RM_GetGasCompPhi', obj.id, c);
        end
        
        function c = GetGasCompPhi(obj)
            %{
             Transfer fugacity coefficients (phi) of gas components from each reaction cell to the vector given in the argument list (gas_phi). Fugacity of a gas component is equal to its pressure times the fugacity coefficient.

            Parameters
                id	The instance id returned from RM_Create.
                gas_phi	Vector to receive the fugacity coefficients of gas components. Dimension of the vector must be ngas_comps times nxyz, where, ngas_comps is the result of RM_GetGasComponentsCount, and nxyz is the number of user grid cells (RM_GetGridCellCount). If a gas component is not defined for a cell, the fugacity coefficient is set to -1. Values for inactive cells are set to 1e30. 
           %}
            nxyz = obj.ncells;
            obj.RM_FindComponents(); % need to call it first
            n_gas_comp = obj.RM_GetGasComponentsCount();
            c = zeros(nxyz, n_gas_comp);
            [~, c] = calllib('libphreeqcrm','RM_GetGasCompPhi', obj.id, c);
        end
        
        function [status, c_out] = RM_GetGasCompPressures(obj, c)
            %{
            Transfer pressures of gas components from each reaction cell to the vector given in the argument list (gas_pressure).

            Parameters
                id	The instance id returned from RM_Create.
                gas_pressure	Vector to receive the pressures of gas components. Dimension of the vector must be ngas_comps times nxyz, where, ngas_comps is the result of RM_GetGasComponentsCount, and nxyz is the number of user grid cells (RM_GetGridCellCount). If a gas component is not defined for a cell, the pressure is set to -1. Values for inactive cells are set to 1e30. 
            %}
            [status, c_out] = calllib('libphreeqcrm','RM_GetGasCompPressures', obj.id, c);
        end
        
        function c = GetGasCompPressures(obj)
            %{
             Transfer pressures of gas components from each reaction cell to the vector given in the argument list (gas_pressure).
            %}
            nxyz = obj.ncells;
            obj.RM_FindComponents(); % need to call it first
            n_gas_comp = obj.RM_GetGasComponentsCount();
            c = zeros(nxyz, n_gas_comp);
            [~, c] = calllib('libphreeqcrm','RM_GetGasCompPressures', obj.id, c);
        end
        
        function [status, c_out] = RM_GetGasPhaseVolume(obj, c)
            %{
            Transfer volume of gas from each reaction cell to the vector given in the argument list (gas_volume).

            Parameters
                id	The instance id returned from RM_Create.
                gas_volume	Array to receive the gas phase volumes. Dimension of the vector must be nxyz, where, nxyz is the number of user grid cells (RM_GetGridCellCount). If a gas phase is not defined for a cell, the volume is set to -1. Values for inactive cells are set to 1e30. 
            %}
            [status, c_out] = calllib('libphreeqcrm','RM_GetGasPhaseVolume', obj.id, c);
        end
        
        function [status, c_out] = RM_SetGasPhaseVolume(obj, c)
            %{
            Transfer volumes of gas phases from the array given in the argument list (gas_volume) to each reaction cell. The gas-phase volume affects the pressures calculated for fixed-volume gas phases. If a gas-phase volume is defined with this method for a GAS_PHASE in a cell, the gas phase is forced to be a fixed-volume gas phase.

            Parameters
                id	The instance id returned from RM_Create.
                gas_volume	Vector of volumes for each gas phase. Dimension of the vector must be nxyz, where, nxyz is the number of user grid cells (RM_GetGridCellCount). If the volume is set to a negative number for a cell, the gas-phase volume for that cell is not changed. 
            %}
            [status, c_out] = calllib('libphreeqcrm','RM_SetGasPhaseVolume', obj.id, c);
        end
        
        function c = GetGasPhaseVolume(obj)
            %{
            Transfer volume of gas from each reaction cell to the vector given in the argument list (gas_volume).
            gas_volume	Array to receive the gas phase volumes. Dimension of the vector must be nxyz, where, nxyz is the number of user grid cells (RM_GetGridCellCount). If a gas phase is not defined for a cell, the volume is set to -1. Values for inactive cells are set to 1e30. 
            %}
            nxyz = obj.ncells;
            c = zeros(nxyz, 1);
            [~, c] = calllib('libphreeqcrm','RM_GetGasPhaseVolume', obj.id, c);
        end
        
        function [status, gfw_out] = RM_GetGfw(obj, gfw)
            %{
            Returns the gram formula weights (g/mol) for the components in the reaction-module component list.

            Parameters
                id	The instance id returned from RM_Create.
                gfw	Array to receive the gram formula weights. Dimension of the array is ncomps, where ncomps is the number of components in the component list. 
            %}
            [status, gfw_out] = calllib('libphreeqcrm','RM_GetGfw', obj.id, gfw);
        end
        
        function gfw = GetGfw(obj)
            %{
            Returns the gram formula weights (g/mol) for the components in the reaction-module component list.

            Parameters
                id	The instance id returned from RM_Create.
                gfw	Array to receive the gram formula weights. Dimension of the array is ncomps, where ncomps is the number of components in the component list. 
            %}
            ncomps = obj.RM_FindComponents();
            gfw = zeros(ncomps, 1);
            [~, gfw] = calllib('libphreeqcrm','RM_GetGfw', obj.id, gfw);
        end
        
        function n = RM_GetGridCellCount(obj)
            %{
            Returns the number of grid cells in the user's model, which is defined in the call to RM_Create. The mapping from grid cells to reaction cells is defined by RM_CreateMapping. The number of reaction cells may be less than the number of grid cells if there are inactive regions or symmetry in the model definition. 
            %}
            n = calllib('libphreeqcrm','RM_GetGridCellCount', obj.id);
        end
        
        function status = RM_GetIPhreeqcId(obj, l)
            %{
            Returns an IPhreeqc id for the ith IPhreeqc instance in the reaction module.

            For the threaded version, there are nthreads + 2 IPhreeqc instances, where nthreads is defined in the constructor (RM_Create). The number of threads can be determined by RM_GetThreadCount. The first nthreads (0 based) instances will be the workers, the next (nthreads) is the InitialPhreeqc instance, and the next (nthreads + 1) is the Utility instance. Getting the IPhreeqc pointer for one of these instances allows the user to use any of the IPhreeqc methods on that instance. For MPI, each process has exactly three IPhreeqc instances, one worker (number 0), one InitialPhreeqc instance (number 1), and one Utility instance (number 2).

            Parameters
                id	The instance id returned from RM_Create.
                l	The number of the IPhreeqc instance to be retrieved (0 based). 
            %}
            status = calllib('libphreeqcrm','RM_GetIPhreeqcId', obj.id, l);
        end
        
        function status = RM_GetNthSelectedOutputUserNumber(obj, n)
            %{
            Returns the user number for the nth selected-output definition. Definitions are sorted by user number. Phreeqc allows multiple selected-output definitions, each of which is assigned a nonnegative integer identifier by the user. The number of definitions can be obtained by RM_GetSelectedOutputCount. To cycle through all of the definitions, RM_GetNthSelectedOutputUserNumber can be used to identify the user number for each selected-output definition in sequence. RM_SetCurrentSelectedOutputUserNumber is then used to select that user number for selected-output processing.

            Parameters
                id	The instance id returned from RM_Create.
                n	The sequence number of the selected-output definition for which the user number will be returned. C, 0 based.

            Return values
                The	user number of the nth selected-output definition, negative is failure (See RM_DecodeError). 
            %}
            status = calllib('libphreeqcrm','RM_GetNthSelectedOutputUserNumber', obj.id, n);
        end
        
        function [status, sat_out] = RM_GetSaturation(obj, sat_calc)
            %{
            Returns a vector of saturations (sat) as calculated by the reaction module. Reactions will change the volume of solution in a cell. The transport code must decide whether to ignore or account for this change in solution volume due to reactions. Following reactions, the cell saturation is calculated as solution volume (RM_GetSolutionVolume) divided by the product of representative volume (RM_SetRepresentativeVolume) and the porosity (RM_SetPorosity). The cell saturation returned by RM_GetSaturation may be less than or greater than the saturation set by the transport code (RM_SetSaturation), and may be greater than or less than 1.0, even in fully saturated simulations. Only the following databases distributed with PhreeqcRM have molar volume information needed to accurately calculate solution volume and saturation: phreeqc.dat, Amm.dat, and pitzer.dat.

            Parameters
                id	The instance id returned from RM_Create.
                sat_calc	Vector to receive the saturations. Dimension of the array is set to nxyz, where nxyz is the number of user grid cells (RM_GetGridCellCount). Values for inactive cells are set to 1e30. 
            %}
            [status, sat_out] = calllib('libphreeqcrm','RM_GetSaturation', obj.id, sat_calc);
        end
        
        function sat = GetSaturation(obj)
            %{
            Returns a vector of saturations (sat) as calculated by the reaction module. Reactions will change the volume of solution in a cell. The transport code must decide whether to ignore or account for this change in solution volume due to reactions. Following reactions, the cell saturation is calculated as solution volume (RM_GetSolutionVolume) divided by the product of representative volume (RM_SetRepresentativeVolume) and the porosity (RM_SetPorosity). The cell saturation returned by RM_GetSaturation may be less than or greater than the saturation set by the transport code (RM_SetSaturation), and may be greater than or less than 1.0, even in fully saturated simulations. Only the following databases distributed with PhreeqcRM have molar volume information needed to accurately calculate solution volume and saturation: phreeqc.dat, Amm.dat, and pitzer.dat.

            Parameters
                id	The instance id returned from RM_Create.
                sat_calc	Vector to receive the saturations. Dimension of the array is set to nxyz, where nxyz is the number of user grid cells (RM_GetGridCellCount). Values for inactive cells are set to 1e30. 
            %}
            sat = zeros(obj.ncells, 1);
            [~, sat] = calllib('libphreeqcrm','RM_GetSaturation', obj.id, sat);
        end
        
        function [status, s_out] = RM_GetSelectedOutput(obj, so)
            %{
            Populates an array with values from the current selected-output definition. RM_SetCurrentSelectedOutputUserNumber determines which of the selected-output definitions is used to populate the array.

            Parameters
                id	The instance id returned from RM_Create.
                so	An array to contain the selected-output values. Size of the array is equivalent to Fortran (nxyz, col), where nxyz is the number of grid cells in the user's model (RM_GetGridCellCount), and col is the number of columns in the selected-output definition (RM_GetSelectedOutputColumnCount). 
            C Example:

                for (isel = 0; isel < RM_GetSelectedOutputCount(id); isel++)
                {
                  n_user = RM_GetNthSelectedOutputUserNumber(id, isel);
                  status = RM_SetCurrentSelectedOutputUserNumber(id, n_user);
                  col = RM_GetSelectedOutputColumnCount(id);
                  selected_out = (double *) malloc((size_t) (col * nxyz * sizeof(double)));
                  status = RM_GetSelectedOutput(id, selected_out);
                  // Process results here
                  free(selected_out);
                }
            %}
            [status, s_out] = calllib('libphreeqcrm','RM_GetSelectedOutput', obj.id, so);
        end
        
        function s_out = GetSelectedOutput(obj, n_user)
            %{
            Populates an array with values from the current selected-output definition. RM_SetCurrentSelectedOutputUserNumber determines which of the selected-output definitions is used to populate the array.

            s_out the output matrix of of selected output with selected
            output number n_user
            C Example:

                for (isel = 0; isel < RM_GetSelectedOutputCount(id); isel++)
                {
                  n_user = RM_GetNthSelectedOutputUserNumber(id, isel);
                  status = RM_SetCurrentSelectedOutputUserNumber(id, n_user);
                  col = RM_GetSelectedOutputColumnCount(id);
                  selected_out = (double *) malloc((size_t) (col * nxyz * sizeof(double)));
                  status = RM_GetSelectedOutput(id, selected_out);
                  // Process results here
                  free(selected_out);
                }
            %}
            obj.RM_SetCurrentSelectedOutputUserNumber(n_user);
            col = obj.RM_GetSelectedOutputColumnCount();
            nxyz = obj.ncells;
            s_out = zeros(nxyz, col);
            [~, s_out] = calllib('libphreeqcrm','RM_GetSelectedOutput', obj.id, s_out);
        end
        
        function n = RM_GetSelectedOutputColumnCount(obj)
            %{
            Returns the number of columns in the current selected-output definition. RM_SetCurrentSelectedOutputUserNumber determines which of the selected-output definitions is used. 
            %}
            n = calllib('libphreeqcrm','RM_GetSelectedOutputColumnCount', obj.id);
        end
        
        function n = RM_GetSelectedOutputCount(obj)
            %{
            Returns the number of selected-output definitions. RM_SetCurrentSelectedOutputUserNumber determines which of the selected-output definitions is used. 
            %}
            n = calllib('libphreeqcrm','RM_GetSelectedOutputCount', obj.id);
        end
        
        function [status, h_out] = RM_GetSelectedOutputHeading(obj, icol, heading, l)
            %{
            Returns a selected output heading. The number of headings is determined by RM_GetSelectedOutputColumnCount. RM_SetCurrentSelectedOutputUserNumber determines which of the selected-output definitions is used.

            Parameters
                id	The instance id returned from RM_Create.
                icol	The sequence number of the heading to be retrieved. C, 0 based.
                heading	A string buffer to receive the heading.
                length	The maximum number of characters that can be written to the string buffer. 
            C Example:

                char heading[100];
                for (isel = 0; isel < RM_GetSelectedOutputCount(id); isel++)
                {
                  n_user = RM_GetNthSelectedOutputUserNumber(id, isel);
                  status = RM_SetCurrentSelectedOutputUserNumber(id, n_user);
                  col = RM_GetSelectedOutputColumnCount(id);
                  for (j = 0; j < col; j++)
                  {
                    status = RM_GetSelectedOutputHeading(id, j, heading, 100);
                    fprintf(stderr, "          %2d %10s\n", j, heading);
                  }
                }
            %}
            [status, h_out] = calllib('libphreeqcrm','RM_GetSelectedOutputHeading', obj.id, icol, heading, l);
        end
        
        function headings = GetSelectedOutputHeadings(obj, n_user)
            %{
            Returns a selected output heading. The number of headings is determined by RM_GetSelectedOutputColumnCount. RM_SetCurrentSelectedOutputUserNumber determines which of the selected-output definitions is used.

            n_user   selected output user number
            C Example:

                char heading[100];
                for (isel = 0; isel < RM_GetSelectedOutputCount(id); isel++)
                {
                  n_user = RM_GetNthSelectedOutputUserNumber(id, isel);
                  status = RM_SetCurrentSelectedOutputUserNumber(id, n_user);
                  col = RM_GetSelectedOutputColumnCount(id);
                  for (j = 0; j < col; j++)
                  {
                    status = RM_GetSelectedOutputHeading(id, j, heading, 100);
                    fprintf(stderr, "          %2d %10s\n", j, heading);
                  }
                }
            %}
            obj.RM_SetCurrentSelectedOutputUserNumber(n_user);
            col = obj.RM_GetSelectedOutputColumnCount();
            headings = cell(col, 1);
            
            for j = 1:col
                headings{j} = '000000000000000000000';
                [~, headings{j}] = calllib('libphreeqcrm','RM_GetSelectedOutputHeading', obj.id, j-1, headings{j}, length(headings{j}));
            end
        end
        
        function tab_out = GetSelectedOutputTable(obj, n_user)
            % GetSelectedOutputTable returns the selected output with user
            % number n_user in the form of a container map
            %SEE ALSO GetSelectedOutput, GetSelectedOutputHeadings
            h_out = obj.GetSelectedOutputHeadings(n_user);
            s_out = obj.GetSelectedOutput(n_user);
            [~, n] = size(s_out);
            S_out_cell = cell(n, 1);
            for i=1:n
                S_out_cell{i}= s_out(:, i);
            end
            tab_out = containers.Map(h_out, S_out_cell);
        end
        
        function n = RM_GetSelectedOutputRowCount(obj)
            %{
            Returns the number of rows in the current selected-output definition. However, the method is included only for convenience; the number of rows is always equal to the number of grid cells in the user's model, and is equal to RM_GetGridCellCount. 
            Return values
                Number	of rows in the current selected-output definition, negative is failure (See RM_DecodeError). 
            C Example:

                for (isel = 0; isel < RM_GetSelectedOutputCount(id); isel++)
                {
                  n_user = RM_GetNthSelectedOutputUserNumber(id, isel);
                  status = RM_SetCurrentSelectedOutputUserNumber(id, n_user);
                  col = RM_GetSelectedOutputColumnCount(id);
                  selected_out = (double *) malloc((size_t) (col * nxyz * sizeof(double)));
                  status = RM_GetSelectedOutput(id, selected_out);
                  // Print results
                  for (i = 0; i < RM_GetSelectedOutputRowCount(id)/2; i++)
                  {
                    fprintf(stderr, "Cell number %d\n", i);
                    fprintf(stderr, "     Selected output: \n");
                    for (j = 0; j < col; j++)
                    {
                      status = RM_GetSelectedOutputHeading(id, j, heading, 100);
                      fprintf(stderr, "          %2d %10s: %10.4f\n", j, heading, selected_out[j*nxyz + i]);
                    }
                  }
                  free(selected_out);
                }
            %}
            n = calllib('libphreeqcrm','RM_GetSelectedOutputRowCount', obj.id);
        end
        
        function [status, v_out] = RM_GetSolutionVolume(obj, vol)
            %{
            Transfer solution volumes from the reaction cells to the array given in the argument list (vol). Solution volumes are those calculated by the reaction module. Only the following databases distributed with PhreeqcRM have molar volume information needed to accurately calculate solution volume: phreeqc.dat, Amm.dat, and pitzer.dat.
            %}
            [status, v_out] = calllib('libphreeqcrm','RM_GetSolutionVolume', obj.id, vol);
        end
        
        function v_out = GetSolutionVolume(obj)
            %{
            Transfer solution volumes from the reaction cells to the array given in the argument list (vol). Solution volumes are those calculated by the reaction module. Only the following databases distributed with PhreeqcRM have molar volume information needed to accurately calculate solution volume: phreeqc.dat, Amm.dat, and pitzer.dat.
            %}
            v_out = zeros(obj.ncells, 1);
            v_out = calllib('libphreeqcrm','RM_GetSolutionVolume', obj.id, v_out);
        end
        
        function [status, c_out] = RM_GetSpeciesConcentrations(obj, species_conc)
            %{
            Transfer concentrations of aqueous species to the array argument (species_conc) This method is intended for use with multicomponent-diffusion transport calculations, and RM_SetSpeciesSaveOn must be set to true. The list of aqueous species is determined by RM_FindComponents and includes all aqueous species that can be made from the set of components. Solution volumes used to calculate mol/L are calculated by the reaction module. Only the following databases distributed with PhreeqcRM have molar volume information needed to accurately calculate solution volume: phreeqc.dat, Amm.dat, and pitzer.dat.

            Parameters
                id	The instance id returned from RM_Create.
                species_conc	Array to receive the aqueous species concentrations. Dimension of the array is (nxyz, nspecies), where nxyz is the number of user grid cells (RM_GetGridCellCount), and nspecies is the number of aqueous species (RM_GetSpeciesCount). Concentrations are moles per liter. Values for inactive cells are set to 1e30. 
            %}
            [status, c_out] = calllib('libphreeqcrm','RM_GetSpeciesConcentrations', obj.id, species_conc);
        end
        
        function c_out = GetSpeciesConcentrations(obj)
            %{
            Transfer concentrations of aqueous species to the array argument (species_conc) This method is intended for use with multicomponent-diffusion transport calculations, and RM_SetSpeciesSaveOn must be set to true. The list of aqueous species is determined by RM_FindComponents and includes all aqueous species that can be made from the set of components. Solution volumes used to calculate mol/L are calculated by the reaction module. Only the following databases distributed with PhreeqcRM have molar volume information needed to accurately calculate solution volume: phreeqc.dat, Amm.dat, and pitzer.dat.

            Parameters
                id	The instance id returned from RM_Create.
                species_conc	Array to receive the aqueous species concentrations. Dimension of the array is (nxyz, nspecies), where nxyz is the number of user grid cells (RM_GetGridCellCount), and nspecies is the number of aqueous species (RM_GetSpeciesCount). Concentrations are moles per liter. Values for inactive cells are set to 1e30. 
            %}
            
            obj.RM_SetSpeciesSaveOn(1); % to make sure that it is on
            obj.RM_FindComponents(); % must run to update species list
            nspecies = obj.RM_GetSpeciesCount();
            c_out = zeros(obj.ncells, nspecies);
            c_out = calllib('libphreeqcrm','RM_GetSpeciesConcentrations', obj.id, c_out);
        end
        
        function status = RM_GetSpeciesCount(obj)
            %{
            The number of aqueous species used in the reaction module. This method is intended for use with multicomponent-diffusion transport calculations, and RM_SetSpeciesSaveOn must be set to true. The list of aqueous species is determined by RM_FindComponents and includes all aqueous species that can be made from the set of components.
            %}
            status = calllib('libphreeqcrm','RM_GetSpeciesCount', obj.id);
        end
        
        function [status, d_out] = RM_GetSpeciesD25(obj, diffc)
            %{
            Transfers diffusion coefficients at 25C to the array argument (diffc). This method is intended for use with multicomponent-diffusion transport calculations, and RM_SetSpeciesSaveOn must be set to true. Diffusion coefficients are defined in SOLUTION_SPECIES data blocks, normally in the database file. Databases distributed with the reaction module that have diffusion coefficients defined are phreeqc.dat, Amm.dat, and pitzer.dat.
            Parameters
                id	The instance id returned from RM_Create.
                diffc	Array to receive the diffusion coefficients at 25 C, m^2/s. Dimension of the array is nspecies, where nspecies is is the number of aqueous species (RM_GetSpeciesCount). 
            %}
            [status, d_out] = calllib('libphreeqcrm','RM_GetSpeciesD25', obj.id, diffc);
        end
        
        function [status, name] = RM_GetSpeciesName(obj, i, name, l)
            %{
            Transfers the name of the ith aqueous species to the character argument (name). This method is intended for use with multicomponent-diffusion transport calculations, and RM_SetSpeciesSaveOn must be set to true. The list of aqueous species is determined by RM_FindComponents and includes all aqueous species that can be made from the set of components.

            Parameters
                id	The instance id returned from RM_Create.
                i	Sequence number of the species in the species list. C, 0 based.
                name	Character array to receive the species name.
                length	Maximum length of string that can be stored in the character array. 
            
            C Example:

                char name[100];
                ...
                status = RM_SetSpeciesSaveOn(id, 1);
                ncomps = RM_FindComponents(id);
                nspecies = RM_GetSpeciesCount(id);
                for (i = 0; i < nspecies; i++)
                {
                  status = RM_GetSpeciesName(id, i, name, 100);
                  fprintf(stderr, "%s\n", name);
                }
            %}
            [status, name] = calllib('libphreeqcrm','RM_GetSpeciesName', obj.id, i, name, l);
        end
        
        function name = GetSpeciesNames(obj)
            %{
            Transfers the name of the ith aqueous species to the character argument (name). This method is intended for use with multicomponent-diffusion transport calculations, and RM_SetSpeciesSaveOn must be set to true. The list of aqueous species is determined by RM_FindComponents and includes all aqueous species that can be made from the set of components.

            Parameters
                id	The instance id returned from RM_Create.
                i	Sequence number of the species in the species list. C, 0 based.
                name	Character array to receive the species name.
                length	Maximum length of string that can be stored in the character array. 
            
            C Example:

                char name[100];
                ...
                status = RM_SetSpeciesSaveOn(id, 1);
                ncomps = RM_FindComponents(id);
                nspecies = RM_GetSpeciesCount(id);
                for (i = 0; i < nspecies; i++)
                {
                  status = RM_GetSpeciesName(id, i, name, 100);
                  fprintf(stderr, "%s\n", name);
                }
            %}
            obj.RM_SetSpeciesSaveOn(1);
            obj.RM_FindComponents(); % must run to update species list
            nspecies = obj.RM_GetSpeciesCount();
            name = cell(nspecies, 1);
            for i=1:nspecies
                name{i} = '00000000000000000000';
                [~, name{i}] = calllib('libphreeqcrm','RM_GetSpeciesName', obj.id, i-1, name{i}, length(name{i}));
            end
        end
        
        function status = RM_GetSpeciesSaveOn(obj)
            %{
            Returns the value of the species-save property. By default, concentrations of aqueous species are not saved. Setting the species-save property to true allows aqueous species concentrations to be retrieved with RM_GetSpeciesConcentrations, and solution compositions to be set with RM_SpeciesConcentrations2Module.

            Parameters
                id	The instance id returned from RM_Create.

            Return values
                IRM_RESULT	0, species are not saved; 1, species are saved; negative is failure (See RM_DecodeError). 
            %}
            status = calllib('libphreeqcrm','RM_GetSpeciesSaveOn', obj.id);
        end
        
        function [status, z_out] = RM_GetSpeciesZ(obj, z)
            %{
            Transfers the charge of each aqueous species to the array argument (z). This method is intended for use with multicomponent-diffusion transport calculations, and RM_SetSpeciesSaveOn must be set to true.

            Parameters
                id	The instance id returned from RM_Create.
                z	Array that receives the charge for each aqueous species. Dimension of the array is nspecies, where nspecies is is the number of aqueous species (RM_GetSpeciesCount).

            Return values
                IRM_RESULT	0 is success, negative is failure (See RM_DecodeError). 
            %}
            [status, z_out] = calllib('libphreeqcrm','RM_GetSpeciesZ', obj.id, z);
        end
        
        function [status, sc_out] = RM_GetStartCell(obj, sc)
            %{
            Returns an array with the starting cell numbers from the range of cell numbers assigned to each worker.

            Parameters
                id	The instance id returned from RM_Create.
                sc	Array to receive the starting cell numbers. Dimension of the array is the number of threads (OpenMP) or the number of processes (MPI). 
            %}
            [status, sc_out] = calllib('libphreeqcrm','RM_GetStartCell', obj.id, sc);
        end
        
        function n = RM_GetThreadCount(obj)
            %{
            Returns the number of threads, which is equal to the number of workers used to run in parallel with OPENMP. For the OPENMP version, the number of threads is set implicitly or explicitly with RM_Create. For the MPI version, the number of threads is always one for each process. 
            %}
            n = calllib('libphreeqcrm','RM_GetThreadCount', obj.id);
        end
        
        function t = RM_GetTime(obj)
            %{
            Returns the current simulation time in seconds. The reaction module does not change the time value, so the returned value is equal to the default (0.0) or the last time set by RM_SetTime. 
            %}
            t = calllib('libphreeqcrm','RM_GetTime', obj.id);
        end
        
        function tc = RM_GetTimeConversion(obj)
            %{
            Returns a multiplier to convert time from seconds to another unit, as specified by the user. The reaction module uses seconds as the time unit. The user can set a conversion factor (RM_SetTimeConversion) and retrieve it with RM_GetTimeConversion. The reaction module only uses the conversion factor when printing the long version of cell chemistry (RM_SetPrintChemistryOn), which is rare. Default conversion factor is 1.0. 
            Return values
                Multiplier	to convert seconds to another time unit. 
            %}
            tc = calllib('libphreeqcrm','RM_GetTimeConversion', obj.id);
        end
        
        function ts = RM_GetTimeStep(obj)
            %{
            Returns the current simulation time step in seconds. This is the time over which kinetic reactions are integrated in a call to RM_RunCells. The reaction module does not change the time step value, so the returned value is equal to the default (0.0) or the last time step set by RM_SetTimeStep.

            Parameters
                id	The instance id returned from RM_Create.

            Return values
                The	current simulation time step in seconds. 
            %}
            ts = calllib('libphreeqcrm','RM_GetTimeStep', obj.id);
        end
        
        function [status, c_out] = RM_InitialPhreeqc2Concentrations(obj, ...
                c, n_boundary, boundary_solution1, boundary_solution2, fraction1)
            %{
            Fills an array (c) with concentrations from solutions in the InitialPhreeqc instance. The method is used to obtain concentrations for boundary conditions. If a negative value is used for a cell in boundary_solution1, then the highest numbered solution in the InitialPhreeqc instance will be used for that cell. Concentrations may be a mixture of two solutions, boundary_solution1 and boundary_solution2, with a mixing fraction for boundary_solution1 1 of fraction1 and mixing fraction for boundary_solution2 of (1 - fraction1). A negative value for boundary_solution2 implies no mixing, and the associated value for fraction1 is ignored. If boundary_solution2 and fraction1 are NULL, no mixing is used; concentrations are derived from boundary_solution1 only.

            Parameters
                id	The instance id returned from RM_Create.
                c	Array of concentrations extracted from the InitialPhreeqc instance. The dimension of c is equivalent to Fortran allocation (n_boundary, ncomp), where ncomp is the number of components returned from RM_FindComponents or RM_GetComponentCount.
                n_boundary	The number of boundary condition solutions that need to be filled.
                boundary_solution1	Array of solution index numbers that refer to solutions in the InitialPhreeqc instance. Size is n_boundary.
                boundary_solution2	Array of solution index numbers that that refer to solutions in the InitialPhreeqc instance and are defined to mix with boundary_solution1. Size is n_boundary. May be NULL in C.
                fraction1	Fraction of boundary_solution1 that mixes with (1-fraction1) of boundary_solution2. Size is (n_boundary). May be NULL in C. 
            C Example:

                nbound = 1;
                bc1 = (int *) malloc((size_t) (nbound * sizeof(int)));
                bc2 = (int *) malloc((size_t) (nbound * sizeof(int)));
                bc_f1 = (double *) malloc((size_t) (nbound * sizeof(double)));
                bc_conc = (double *) malloc((size_t) (ncomps * nbound * sizeof(double)));
                for (i = 0; i < nbound; i++)
                {
                  bc1[i]          = 0;       // Solution 0 from InitialPhreeqc instance
                  bc2[i]          = -1;      // no bc2 solution for mixing
                  bc_f1[i]        = 1.0;     // mixing fraction for bc1
                }
                status = RM_InitialPhreeqc2Concentrations(id, bc_conc, nbound, bc1, bc2, bc_f1);
            %}
            [status, c_out] = calllib('libphreeqcrm','RM_InitialPhreeqc2Concentrations', obj.id, ...
                c, n_boundary, boundary_solution1, boundary_solution2, fraction1);
        end
        
        function c_out = InitialPhreeqc2Concentrations(obj, ...
                n_boundary, boundary_solution1, boundary_solution2, fraction1)
            ncomps = obj.RM_FindComponents();
            c_out = zeros(n_boundary*ncomps, 1);
            [~, c_out] = calllib('libphreeqcrm','RM_InitialPhreeqc2Concentrations', obj.id, ...
                c_out, n_boundary, boundary_solution1, boundary_solution2, fraction1);
        end
        
        function status = RM_InitialPhreeqc2Module(obj, ...
                initial_conditions1, initial_conditions2, fraction1)
            %{
            Transfer solutions and reactants from the InitialPhreeqc instance to the reaction-module workers, possibly with mixing. In its simplest form, initial_conditions1 is used to select initial conditions, including solutions and reactants, for each cell of the model, without mixing. Initial_conditions1 is dimensioned (nxyz, 7), where nxyz is the number of grid cells in the user's model (RM_GetGridCellCount). The dimension of 7 refers to solutions and reactants in the following order: (1) SOLUTIONS, (2) EQUILIBRIUM_PHASES, (3) EXCHANGE, (4) SURFACE, (5) GAS_PHASE, (6) SOLID_SOLUTIONS, and (7) KINETICS. In C, initial_solution1[3*nxyz + 99] = 2, indicates that cell 99 (0 based) contains the SURFACE definition with user number 2 that has been defined in the InitialPhreeqc instance (either by RM_RunFile or RM_RunString).

            It is also possible to mix solutions and reactants to obtain the initial conditions for cells. For mixing, initials_conditions2 contains numbers for a second entity that mixes with the entity defined in initial_conditions1. Fraction1 contains the mixing fraction for initial_conditions1, whereas (1 - fraction1) is the mixing fraction for initial_conditions2. In C, initial_solution1[3*nxyz + 99] = 2, initial_solution2[3*nxyz + 99] = 3, fraction1[3*nxyz + 99] = 0.25 indicates that cell 99 (0 based) contains a mixture of 0.25 SURFACE 2 and 0.75 SURFACE 3, where the surface compositions have been defined in the InitialPhreeqc instance. If the user number in initial_conditions2 is negative, no mixing occurs. If initials_conditions2 and fraction1 are NULL, no mixing is used, and initial conditions are derived solely from initials_conditions1.

            Parameters
                id	The instance id returned from RM_Create.
                initial_conditions1	Array of solution and reactant index numbers that refer to definitions in the InitialPhreeqc instance. Size is (nxyz,7). The order of definitions is given above. Negative values are ignored, resulting in no definition of that entity for that cell.
                initial_conditions2	Array of solution and reactant index numbers that refer to definitions in the InitialPhreeqc instance. Nonnegative values of initial_conditions2 result in mixing with the entities defined in initial_conditions1. Negative values result in no mixing. Size is (nxyz,7). The order of definitions is given above. May be NULL in C; setting to NULL results in no mixing.
                fraction1	Fraction of initial_conditions1 that mixes with (1-fraction1) of initial_conditions2. Size is (nxyz,7). The order of definitions is given above. May be NULL in C; setting to NULL results in no mixing. 
            C Example:

                ic1 = (int *) malloc((size_t) (7 * nxyz * sizeof(int)));
                ic2 = (int *) malloc((size_t) (7 * nxyz * sizeof(int)));
                f1 = (double *) malloc((size_t) (7 * nxyz * sizeof(double)));
                for (i = 0; i < nxyz; i++)
                {
                  ic1[i]          = 1;       // Solution 1
                  ic1[nxyz + i]   = -1;      // Equilibrium phases none
                  ic1[2*nxyz + i] = 1;       // Exchange 1
                  ic1[3*nxyz + i] = -1;      // Surface none
                  ic1[4*nxyz + i] = -1;      // Gas phase none
                  ic1[5*nxyz + i] = -1;      // Solid solutions none
                  ic1[6*nxyz + i] = -1;      // Kinetics none

                  ic2[i]          = -1;      // Solution none
                  ic2[nxyz + i]   = -1;      // Equilibrium phases none
                  ic2[2*nxyz + i] = -1;      // Exchange none
                  ic2[3*nxyz + i] = -1;      // Surface none
                  ic2[4*nxyz + i] = -1;      // Gas phase none
                  ic2[5*nxyz + i] = -1;      // Solid solutions none
                  ic2[6*nxyz + i] = -1;      // Kinetics none

                  f1[i]          = 1.0;      // Mixing fraction ic1 Solution
                  f1[nxyz + i]   = 1.0;      // Mixing fraction ic1 Equilibrium phases
                  f1[2*nxyz + i] = 1.0;      // Mixing fraction ic1 Exchange 1
                  f1[3*nxyz + i] = 1.0;      // Mixing fraction ic1 Surface
                  f1[4*nxyz + i] = 1.0;      // Mixing fraction ic1 Gas phase
                  f1[5*nxyz + i] = 1.0;      // Mixing fraction ic1 Solid solutions
                  f1[6*nxyz + i] = 1.0;      // Mixing fraction ic1 Kinetics
                }
                status = RM_InitialPhreeqc2Module(id, ic1, ic2, f1);
                // No mixing is defined, so the following is equivalent
                status = RM_InitialPhreeqc2Module(id, ic1, NULL, NULL);
            %}
            status = calllib('libphreeqcrm','RM_InitialPhreeqc2Module', obj.id, ...
                initial_conditions1, initial_conditions2, fraction1);
        end
        
        function [status, c_out] = RM_InitialPhreeqc2SpeciesConcentrations(obj, ...
                species_c, n_boundary, boundary_solution1, boundary_solution2, fraction1)
            %{
            Fills an array (species_c) with aqueous species concentrations from solutions in the InitialPhreeqc instance. This method is intended for use with multicomponent-diffusion transport calculations, and RM_SetSpeciesSaveOn must be set to true. The method is used to obtain aqueous species concentrations for boundary conditions. If a negative value is used for a cell in boundary_solution1, then the highest numbered solution in the InitialPhreeqc instance will be used for that cell. Concentrations may be a mixture of two solutions, boundary_solution1 and boundary_solution2, with a mixing fraction for boundary_solution1 1 of fraction1 and mixing fraction for boundary_solution2 of (1 - fraction1). A negative value for boundary_solution2 implies no mixing, and the associated value for fraction1 is ignored. If boundary_solution2 and fraction1 are NULL, no mixing is used; concentrations are derived from boundary_solution1 only.

            Parameters
                id	The instance id returned from RM_Create.
                species_c	Array of aqueous concentrations extracted from the InitialPhreeqc instance. The dimension of species_c is equivalent to Fortran allocation (n_boundary, nspecies), where nspecies is the number of aqueous species returned from RM_GetSpeciesCount.
                n_boundary	The number of boundary condition solutions that need to be filled.
                boundary_solution1	Array of solution index numbers that refer to solutions in the InitialPhreeqc instance. Size is n_boundary.
                boundary_solution2	Array of solution index numbers that that refer to solutions in the InitialPhreeqc instance and are defined to mix with boundary_solution1. Size is n_boundary. May be NULL in C.
                fraction1	Fraction of boundary_solution1 that mixes with (1-fraction1) of boundary_solution2. Size is n_boundary. May be NULL in C. 
            C Example:

                nbound = 1;
                nspecies = RM_GetSpeciesCount(id);
                bc1 = (int *) malloc((size_t) (nbound * sizeof(int)));
                bc2 = (int *) malloc((size_t) (nbound * sizeof(int)));
                bc_f1 = (double *) malloc((size_t) (nbound * sizeof(double)));
                bc_conc = (double *) malloc((size_t) (nspecies * nbound * sizeof(double)));
                for (i = 0; i < nbound; i++)
                {
                  bc1[i]          = 0;       // Solution 0 from InitialPhreeqc instance
                  bc2[i]          = -1;      // no bc2 solution for mixing
                  bc_f1[i]        = 1.0;     // mixing fraction for bc1
                }
                status = RM_InitialPhreeqc2SpeciesConcentrations(id, bc_conc, nbound, bc1, bc2, bc_f1);
            %}
            [status, c_out] = calllib('libphreeqcrm','RM_InitialPhreeqc2SpeciesConcentrations', obj.id, ...
                species_c, n_boundary, boundary_solution1, boundary_solution2, fraction1);
        end
        
        function status = RM_InitialPhreeqcCell2Module(obj, ...
                n, module_numbers, dim_module_numbers)
            %{
            A cell numbered n in the InitialPhreeqc instance is selected to populate a series of cells. All reactants with the number n are transferred along with the solution. If MIX n exists, it is used for the definition of the solution. If n is negative, n is redefined to be the largest solution or MIX number in the InitialPhreeqc instance. All reactants for each cell in the list module_numbers are removed before the cell definition is copied from the InitialPhreeqc instance to the workers.

            Parameters
                id	The instance id returned from RM_Create.
                n	Cell number refers to a solution or MIX and associated reactants in the InitialPhreeqc instance. A negative number indicates the largest solution or MIX number in the InitialPhreeqc instance will be used.
                module_numbers	A list of cell numbers in the user's grid-cell numbering system that will be populated with cell n from the InitialPhreeqc instance.
                dim_module_numbers	The number of cell numbers in the module_numbers list. 
            C Example:

                module_cells = (int *) malloc((size_t) (2 * sizeof(int)));
                module_cells[0] = 18;
                module_cells[1] = 19;
                // n will be the largest SOLUTION number in InitialPhreeqc instance
                // copies solution and reactants to cells 18 and 19
                status = RM_InitialPhreeqcCell2Module(id, -1, module_cells, 2);
            %}
            status = calllib('libphreeqcrm','RM_InitialPhreeqcCell2Module', obj.id, ...
                n, module_numbers, dim_module_numbers);
        end
        
        function status = RM_LoadDatabase(obj, db_name)
            %{
            Load a database for all IPhreeqc instances???workers, InitialPhreeqc, and Utility. All definitions of the reaction module are cleared (SOLUTION_SPECIES, PHASES, SOLUTIONs, etc.), and the database is read. 
            %}
            status = calllib('libphreeqcrm','RM_LoadDatabase', obj.id, db_name);
        end
        
        function status = RM_LogMessage(obj, msg_str)
            %{
            Print a message to the log file. 
            %}
            status = calllib('libphreeqcrm','RM_LogMessage', obj.id, msg_str);
        end
        
        function status = RM_OpenFiles(obj)
            %{
            Opens the output and log files. Files are named prefix.chem.txt and prefix.log.txt based on the prefix defined by RM_SetFilePrefix. 
            %}
            status = calllib('libphreeqcrm','RM_OpenFiles', obj.id);
        end
        
        function status = RM_OutputMessage(obj, msg_str)
            %{
            Print a message to the output file. 
            C Example:

                sprintf(str1, "Number of threads:                                %d\n", RM_GetThreadCount(id));
                status = RM_OutputMessage(id, str1);
                sprintf(str1, "Number of MPI processes:                          %d\n", RM_GetMpiTasks(id));
                status = RM_OutputMessage(id, str1);
                sprintf(str1, "MPI task number:                                  %d\n", RM_GetMpiMyself(id));
                status = RM_OutputMessage(id, str1);
                status = RM_GetFilePrefix(id, str, 100);
                sprintf(str1, "File prefix:                                      %s\n", str);
                status = RM_OutputMessage(id, str1);
                sprintf(str1, "Number of grid cells in the user's model:         %d\n", RM_GetGridCellCount(id));
                status = RM_OutputMessage(id, str1);
                sprintf(str1, "Number of chemistry cells in the reaction module: %d\n", RM_GetChemistryCellCount(id));
                status = RM_OutputMessage(id, str1);
                sprintf(str1, "Number of components for transport:               %d\n", RM_GetComponentCount(id));
                status = RM_OutputMessage(id, str1);
            %}
            status = calllib('libphreeqcrm','RM_OutputMessage', obj.id, msg_str);
        end
        
        function status = RM_RunCells(obj)
            %{
            Runs a reaction step for all of the cells in the reaction module. Normally, tranport concentrations are transferred to the reaction cells (RM_SetConcentrations) before reaction calculations are run. The length of time over which kinetic reactions are integrated is set by RM_SetTimeStep. Other properties that may need to be updated as a result of the transport calculations include porosity (RM_SetPorosity), saturation (RM_SetSaturation), temperature (RM_SetTemperature), and pressure (RM_SetPressure). 
            C Example:

                status = RM_SetPorosity(id, por);              // If porosity changes
                status = RM_SetSaturation(id, sat);            // If saturation changes
                status = RM_SetTemperature(id, temperature);   // If temperature changes
                status = RM_SetPressure(id, pressure);         // If pressure changes
                status = RM_SetConcentrations(id, c);          // Transported concentrations
                status = RM_SetTimeStep(id, time_step);        // Time step for kinetic reactions
                status = RM_RunCells(id);
                status = RM_GetConcentrations(id, c);          // Concentrations after reaction
                status = RM_GetDensity(id, density);           // Density after reaction
                status = RM_GetSolutionVolume(id, volume);     // Solution volume after reaction
            %}
            status = calllib('libphreeqcrm','RM_RunCells', obj.id);
        end
        
        function status = RM_RunFile(obj, workers, ...
                initial_phreeqc, utility, chem_name)
            %{
            Run a PHREEQC input file. The first three arguments determine which IPhreeqc instances will run the file???the workers, the InitialPhreeqc instance, and (or) the Utility instance. Input files that modify the thermodynamic database should be run by all three sets of instances. Files with SELECTED_OUTPUT definitions that will be used during the time-stepping loop need to be run by the workers. Files that contain initial conditions or boundary conditions should be run by the InitialPhreeqc instance.

            Parameters
                id	The instance id returned from RM_Create.
                workers	1, the workers will run the file; 0, the workers will not run the file.
                initial_phreeqc	1, the InitialPhreeqc instance will run the file; 0, the InitialPhreeqc will not run the file.
                utility	1, the Utility instance will run the file; 0, the Utility instance will not run the file.
                chem_name	Name of the file to run. 
            %}
            status = calllib('libphreeqcrm','RM_RunFile', obj.id, workers, ...
                initial_phreeqc, utility, chem_name);
        end
        
        function status = RM_RunString(obj, workers, ...
                initial_phreeqc, utility, input_string)
            %{
            Run a PHREEQC input string. The first three arguments determine which IPhreeqc instances will run the string???the workers, the InitialPhreeqc instance, and (or) the Utility instance. Input strings that modify the thermodynamic database should be run by all three sets of instances. Strings with SELECTED_OUTPUT definitions that will be used during the time-stepping loop need to be run by the workers. Strings that contain initial conditions or boundary conditions should be run by the InitialPhreeqc instance.

            Parameters
                id	The instance id returned from RM_Create.
                workers	1, the workers will run the string; 0, the workers will not run the string.
                initial_phreeqc	1, the InitialPhreeqc instance will run the string; 0, the InitialPhreeqc will not run the string.
                utility	1, the Utility instance will run the string; 0, the Utility instance will not run the string.
                input_string	String containing PHREEQC input.


            %}
            status = calllib('libphreeqcrm','RM_RunString', obj.id, workers, ...
                initial_phreeqc, utility, input_string);
        end
        
        function status = RM_ScreenMessage(obj, msg_str)
            %{
            Print message to the screen. 
            %}
            status = calllib('libphreeqcrm','RM_ScreenMessage', obj.id, msg_str);
        end
        
        function status = RM_SetErrorOn(obj, tf)
            %{
            Set the property that controls whether error messages are generated and displayed. Messages include PHREEQC "ERROR" messages, and any messages written with RM_ErrorMessage.

            Parameters
                id	The instance id returned from RM_Create.
                tf	1, enable error messages; 0, disable error messages. Default is 1. 
            %}
            status = calllib('libphreeqcrm','RM_SetErrorOn', obj.id, tf);
        end
        
        function status = RM_SetComponentH2O(obj, tf)
            %{
            Select whether to include H2O in the component list. The concentrations of H and O must be known accurately (8 to 10 significant digits) for the numerical method of PHREEQC to produce accurate pH and pe values. Because most of the H and O are in the water species, it may be more robust (require less accuracy in transport) to transport the excess H and O (the H and O not in water) and water. The default setting (true) is to include water, excess H, and excess O as components. A setting of false will include total H and total O as components. RM_SetComponentH2O must be called before RM_FindComponents.

            Parameters
                id	The instance id returned from RM_Create.
                tf	0, total H and O are included in the component list; 1, excess H, excess O, and water are included in the component list. 
            %}
            status = calllib('libphreeqcrm','RM_SetComponentH2O', obj.id, tf);
        end
        
        function status = RM_SetConcentrations(obj, c)
            %{
            Use the vector of concentrations (c) to set the moles of components in each reaction cell. The volume of water in a cell is the product of porosity (RM_SetPorosity), saturation (RM_SetSaturation), and reference volume (RM_SetRepresentativeVolume). The moles of each component are determined by the volume of water and per liter concentrations. If concentration units (RM_SetUnitsSolution) are mass fraction, the density (as specified by RM_SetDensity) is used to convert from mass fraction to per mass per liter.

            Parameters
                id	The instance id returned from RM_Create.
                c	Array of component concentrations. Size of array is equivalent to Fortran (nxyz, ncomps), where nxyz is the number of grid cells in the user's model (RM_GetGridCellCount), and ncomps is the number of components as determined by RM_FindComponents or RM_GetComponentCount. 
            %}
            status = calllib('libphreeqcrm','RM_SetConcentrations', obj.id, c);
        end
        
        function status = RM_SetCurrentSelectedOutputUserNumber(obj, n_user)
            %{
            Select the current selected output by user number. The user may define multiple SELECTED_OUTPUT data blocks for the workers. A user number is specified for each data block. The value of the argument n_user selects which of the SELECTED_OUTPUT definitions will be used for selected-output operations.

            Parameters
                id	The instance id returned from RM_Create.
                n_user	User number of the SELECTED_OUTPUT data block that is to be used. 
            
            C example:
            for (isel = 0; isel < RM_GetSelectedOutputCount(id); isel++)
            {
              n_user = RM_GetNthSelectedOutputUserNumber(id, isel);
              status = RM_SetCurrentSelectedOutputUserNumber(id, n_user);
              col = RM_GetSelectedOutputColumnCount(id);
              selected_out = (double *) malloc((size_t) (col * nxyz * sizeof(double)));
              status = RM_GetSelectedOutput(id, selected_out);
              // Process results here
              free(selected_out);
}

            %}
            status = calllib('libphreeqcrm','RM_SetCurrentSelectedOutputUserNumber', obj.id, n_user);
        end
        
        function status = RM_SetDensity(obj, density)
            %{
            Set the density for each reaction cell. These density values are used when converting from transported mass fraction concentrations (RM_SetUnitsSolution) to produce per liter concentrations during a call to RM_SetConcentrations. They are also used when converting from module concentrations to transport concentrations of mass fraction (RM_GetConcentrations), if RM_UseSolutionDensityVolume is set to false.

            Parameters
                id	The instance id returned from RM_Create.
                density	Array of densities. Size of array is nxyz, where nxyz is the number of grid cells in the user's model (RM_GetGridCellCount). 
            %}
            status = calllib('libphreeqcrm','RM_SetDensity', obj.id, density);
        end
        
        function status = RM_SetDumpFileName(obj, dump_name)
            %{
            Set the name of the dump file. It is the name used by RM_DumpModule. 
            %}
            status = calllib('libphreeqcrm','RM_SetDumpFileName', obj.id, dump_name);
        end
        
        function status = RM_SetErrorHandlerMode(obj, err_mode)
            %{
            Set the action to be taken when the reaction module encounters an error. Options are 0, return to calling program with an error return code (default); 1, throw an exception, in C++, the exception can be caught, for C and Fortran, the program will exit; or 2, attempt to exit gracefully.

            Parameters
                id	The instance id returned from RM_Create.
                mode	Error handling mode: 0, 1, or 2. 
            %}
            status = calllib('libphreeqcrm','RM_SetErrorHandlerMode', obj.id, err_mode);
        end
        
        function status = RM_SetFilePrefix(obj, prefix)
            %{
            Set the prefix for the output (prefix.chem.txt) and log (prefix.log.txt) files. These files are opened by RM_OpenFiles. 
            %}
            status = calllib('libphreeqcrm','RM_SetFilePrefix', obj.id, prefix);
        end
        
        function status = RM_SetPartitionUZSolids(obj, tf)
            %{
            Sets the property for partitioning solids between the saturated and unsaturated parts of a partially saturated cell.

            The option is intended to be used by saturated-only flow codes that allow a variable water table. The value has meaning only when saturations less than 1.0 are encountered. The partially saturated cells may have a small water-to-rock ratio that causes reactions to proceed differently relative to fully saturated cells. By setting RM_SetPartitionUZSolids to true, the amounts of solids and gases are partioned according to the saturation. If a cell has a saturation of 0.5, then the water interacts with only half of the solids and gases; the other half is unreactive until the water table rises. As the saturation in a cell varies, solids and gases are transferred between the saturated and unsaturated (unreactive) reservoirs of the cell. Unsaturated-zone flow and transport codes will probably use the default (false), which assumes all gases and solids are reactive regardless of saturation.

            Parameters
                id	The instance id returned from RM_Create.
                tf	True, the fraction of solids and gases available for reaction is equal to the saturation; False (default), all solids and gases are reactive regardless of saturation. 
            %}
            status = calllib('libphreeqcrm','RM_SetPartitionUZSolids', obj.id, tf);
        end
        
        function status = RM_SetPorosity(obj, por)
            %{
            Set the porosity for each reaction cell. The volume of water in a reaction cell is the product of the porosity, the saturation (RM_SetSaturation), and the representative volume (RM_SetRepresentativeVolume).

            Parameters
                id	The instance id returned from RM_Create.
                por	Array of porosities, unitless. Default is 0.1. Size of array is nxyz, where nxyz is the number of grid cells in the user's model (RM_GetGridCellCount). 
            %}
            status = calllib('libphreeqcrm','RM_SetPorosity', obj.id, por);
        end
        
        function status = RM_SetPressure(obj, p)
            %{
            Set the pressure for each reaction cell. Pressure effects are considered only in three of the databases distributed with PhreeqcRM: phreeqc.dat, Amm.dat, and pitzer.dat.

            Parameters
                id	The instance id returned from RM_Create.
                p	Array of pressures, in atm. Size of array is nxyz, where nxyz is the number of grid cells in the user's model (RM_GetGridCellCount). 
            %}
            status = calllib('libphreeqcrm','RM_SetPressure', obj.id, p);
        end
        
        function status = RM_SetPrintChemistryMask(obj, cell_mask)
            %{
            Enable or disable detailed output for each reaction cell. Printing for a cell will occur only when the printing is enabled with RM_SetPrintChemistryOn and the cell_mask value is 1.

            Parameters
                id	The instance id returned from RM_Create.
                cell_mask	Array of integers. Size of array is nxyz, where nxyz is the number of grid cells in the user's model (RM_GetGridCellCount). A value of 0 will disable printing detailed output for the cell; a value of 1 will enable printing detailed output for a cell. 
            %}
            status = calllib('libphreeqcrm','RM_SetPrintChemistryMask', obj.id, cell_mask);
        end
        
        function status = RM_SetPrintChemistryOn(obj, ...
                workers, initial_phreeqc, utility)
            %{
            Setting to enable or disable printing detailed output from reaction calculations to the output file for a set of cells defined by RM_SetPrintChemistryMask. The detailed output prints all of the output typical of a PHREEQC reaction calculation, which includes solution descriptions and the compositions of all other reactants. The output can be several hundred lines per cell, which can lead to a very large output file (prefix.chem.txt, RM_OpenFiles). For the worker instances, the output can be limited to a set of cells (RM_SetPrintChemistryMask) and, in general, the amount of information printed can be limited by use of options in the PRINT data block of PHREEQC (applied by using RM_RunFile or RM_RunString). Printing the detailed output for the workers is generally used only for debugging, and PhreeqcRM will run significantly faster when printing detailed output for the workers is disabled.

            Parameters
                id	The instance id returned from RM_Create.
                workers	0, disable detailed printing in the worker instances, 1, enable detailed printing in the worker instances.
                initial_phreeqc	0, disable detailed printing in the InitialPhreeqc instance, 1, enable detailed printing in the InitialPhreeqc instances.
                utility	0, disable detailed printing in the Utility instance, 1, enable detailed printing in the Utility instance. 
            %}
            status = calllib('libphreeqcrm','RM_SetPrintChemistryOn', obj.id,  workers, initial_phreeqc, utility);
        end
        
        function status = RM_SetRebalanceByCell(obj, method)
            %{
            Set the load-balancing algorithm. PhreeqcRM attempts to rebalance the load of each thread or process such that each thread or process takes the same amount of time to run its part of a RM_RunCells calculation. Two algorithms are available; one uses individual times for each cell and accounts for cells that were not run because saturation was zero (default), and the other assigns an average time to all cells. The methods are similar, but limited testing indicates the default method performs better.

        Parameters
            id	The instance id returned from RM_Create.
            method	0, indicates average times are used in rebalancing; 1 indicates individual cell times are used in rebalancing (default). 
            %}
            status = calllib('libphreeqcrm','RM_SetRebalanceByCell', obj.id, method);
        end
        
        function status = RM_SetRebalanceFraction(obj, f)
            %{
            Sets the fraction of cells that are transferred among threads or processes when rebalancing. PhreeqcRM attempts to rebalance the load of each thread or process such that each thread or process takes the same amount of time to run its part of a RM_RunCells calculation. The rebalancing transfers cell calculations among threads or processes to try to achieve an optimum balance. RM_SetRebalanceFraction adjusts the calculated optimum number of cell transfers by a fraction from 0 to 1.0 to determine the actual number of cell transfers. A value of zero eliminates load rebalancing. A value less than 1.0 is suggested to slow the approach to the optimum cell distribution and avoid possible oscillations when too many cells are transferred at one iteration, requiring reverse transfers at the next iteration. Default is 0.5.

        Parameters
            id	The instance id returned from RM_Create.
            f	Fraction from 0.0 to 1.0. 
            %}
            status = calllib('libphreeqcrm','RM_SetRebalanceFraction', obj.id, f);
        end
        
        function status = RM_SetRepresentativeVolume(obj, rv)
            %{
            Set the representative volume of each reaction cell. By default the representative volume of each reaction cell is 1 liter. The volume of water in a reaction cell is determined by the procuct of the representative volume, the porosity (RM_SetPorosity), and the saturation (RM_SetSaturation). The numerical method of PHREEQC is more robust if the water volume for a reaction cell is within a couple orders of magnitude of 1.0. Small water volumes caused by small porosities and (or) small saturations (and (or) small representative volumes) may cause non-convergence of the numerical method. In these cases, a larger representative volume may help. Note that increasing the representative volume also increases the number of moles of the reactants in the reaction cell (minerals, surfaces, exchangers, and others), which are defined as moles per representative volume.

            Parameters
                id	The instance id returned from RM_Create.
                rv	Vector of representative volumes, in liters. Default is 1.0 liter. Size of array is nxyz, where nxyz is the number of grid cells in the user's model (RM_GetGridCellCount). 
            %}
            status = calllib('libphreeqcrm','RM_SetRepresentativeVolume', obj.id, rv);
        end
        
        function status = RM_SetSaturation(obj, sat)
            %{
            Set the saturation of each reaction cell. Saturation is a fraction ranging from 0 to 1. The volume of water in a cell is the product of porosity (RM_SetPorosity), saturation (RM_SetSaturation), and representative volume (RM_SetRepresentativeVolume). As a result of a reaction calculation, solution properties (density and volume) will change; the databases phreeqc.dat, Amm.dat, and pitzer.dat have the molar volume data to calculate these changes. The methods RM_GetDensity, RM_GetSolutionVolume, and RM_GetSaturation can be used to account for these changes in the succeeding transport calculation. RM_SetRepresentativeVolume should be called before initial conditions are defined for the reaction cells.

            Parameters
                id	The instance id returned from RM_Create.
                sat	Array of saturations, unitless. Size of array is nxyz, where nxyz is the number of grid cells in the user's model (RM_GetGridCellCount). 
            %}
            status = calllib('libphreeqcrm','RM_SetSaturation', obj.id, sat);
        end
        
        function status = RM_SetScreenOn(obj, tf)
            %{
            Set the property that controls whether messages are written to the screen. Messages include information about rebalancing during RM_RunCells, and any messages written with RM_ScreenMessage.

            Parameters
                id	The instance id returned from RM_Create.
                tf	1, enable screen messages; 0, disable screen messages. Default is 1. 
            %}
            status = calllib('libphreeqcrm','RM_SetScreenOn', obj.id, tf);
        end
        
        function status = RM_SetSelectedOutputOn(obj, selected_output)
            %{
            Setting determines whether selected-output results are available to be retrieved with RM_GetSelectedOutput. 1 indicates that selected-output results will be accumulated during RM_RunCells and can be retrieved with RM_GetSelectedOutput; 0 indicates that selected-output results will not be accumulated during RM_RunCells.

            Parameters
                id	The instance id returned from RM_Create.
                selected_output	0, disable selected output; 1, enable selected output. 
            %}
            status = calllib('libphreeqcrm','RM_SetSelectedOutputOn', ...
                obj.id, selected_output);
        end
        
        function status = RM_SetSpeciesSaveOn(obj, save_on)
            %{
            Sets the value of the species-save property. This method enables use of PhreeqcRM with multicomponent-diffusion transport calculations. By default, concentrations of aqueous species are not saved. Setting the species-save property to 1 allows aqueous species concentrations to be retrieved with RM_GetSpeciesConcentrations, and solution compositions to be set with RM_SpeciesConcentrations2Module. RM_SetSpeciesSaveOn must be called before calls to RM_FindComponents.

            Parameters
                id	The instance id returned from RM_Create.
                save_on	0, indicates species concentrations are not saved; 1, indicates species concentrations are saved. 
            %}
            status = calllib('libphreeqcrm','RM_SetSpeciesSaveOn', obj.id, save_on);
        end
        
        function status = RM_SetTemperature(obj, t)
            %{
            Set the temperature for each reaction cell. If RM_SetTemperature is not called, worker solutions will have temperatures as defined by initial conditions (RM_InitialPhreeqc2Module and RM_InitialPhreeqcCell2Module).

            Parameters
                id	The instance id returned from RM_Create.
                t	Array of temperatures, in degrees C. Size of array is nxyz, where nxyz is the number of grid cells in the user's model (RM_GetGridCellCount). 
            %}
            status = calllib('libphreeqcrm','RM_SetTemperature', obj.id, t);
        end
        
        function status = RM_SetTime(obj, t)
            %{
            Set current simulation time for the reaction module. 
            t: Current simulation time, in seconds. 
            %}
            status = calllib('libphreeqcrm','RM_SetTime', obj.id, t);
        end
        
        function status = RM_SetTimeConversion(obj, conv_factor)
            %{
            Set a factor to convert to user time units. Factor times seconds produces user time units. 
            conv_factor	Factor to convert seconds to user time units. 
            %}
            status = calllib('libphreeqcrm','RM_SetTimeConversion', obj.id, conv_factor);
        end
        
        function status = RM_SetTimeStep(obj, time_step)
            %{
            Set current time step for the reaction module. This is the length of time over which kinetic reactions are integrated. 
            time_step	Current time step, in seconds. 
            %}
            status = calllib('libphreeqcrm','RM_SetTimeStep', obj.id, time_step);
        end
        
        function status = RM_SetUnitsExchange(obj, option)
            %{
            Sets input units for exchangers. In PHREEQC input, exchangers are defined by moles of exchange sites (Mp). RM_SetUnitsExchange specifies how the number of moles of exchange sites in a reaction cell (Mc) is calculated from the input value (Mp).

            Options are 0, Mp is mol/L of RV (default), Mc = Mp*RV, where RV is the representative volume (RM_SetRepresentativeVolume); 1, Mp is mol/L of water in the RV, Mc = Mp*P*RV, where P is porosity (RM_SetPorosity); or 2, Mp is mol/L of rock in the RV, Mc = Mp*(1-P)*RV.

            If a single EXCHANGE definition is used for cells with different initial porosity, the three options scale quite differently. For option 0, the number of moles of exchangers will be the same regardless of porosity. For option 1, the number of moles of exchangers will be vary directly with porosity and inversely with rock volume. For option 2, the number of moles of exchangers will vary directly with rock volume and inversely with porosity.

            Parameters
                id	The instance id returned from RM_Create.
                option	Units option for exchangers: 0, 1, or 2. 
            %}
            status = calllib('libphreeqcrm','RM_SetUnitsExchange', obj.id, option);
        end
        
        function status = RM_SetUnitsGasPhase(obj, option)
            %{
            Set input units for gas phases. In PHREEQC input, gas phases are defined by moles of component gases (Mp). RM_SetUnitsGasPhase specifies how the number of moles of component gases in a reaction cell (Mc) is calculated from the input value (Mp).

            Options are 0, Mp is mol/L of RV (default), Mc = Mp*RV, where RV is the representative volume (RM_SetRepresentativeVolume); 1, Mp is mol/L of water in the RV, Mc = Mp*P*RV, where P is porosity (RM_SetPorosity); or 2, Mp is mol/L of rock in the RV, Mc = Mp*(1-P)*RV.

            If a single GAS_PHASE definition is used for cells with different initial porosity, the three options scale quite differently. For option 0, the number of moles of a gas component will be the same regardless of porosity. For option 1, the number of moles of a gas component will be vary directly with porosity and inversely with rock volume. For option 2, the number of moles of a gas component will vary directly with rock volume and inversely with porosity.

            Parameters
                id	The instance id returned from RM_Create.
                option	Units option for gas phases: 0, 1, or 2. 
            %}
            status = calllib('libphreeqcrm','RM_SetUnitsGasPhase', obj.id, option);
        end
        
        function status = RM_SetUnitsKinetics(obj, option)
            %{
            Set input units for kinetic reactants.

            In PHREEQC input, kinetics are defined by moles of kinetic reactants (Mp). RM_SetUnitsKinetics specifies how the number of moles of kinetic reactants in a reaction cell (Mc) is calculated from the input value (Mp).

            Options are 0, Mp is mol/L of RV (default), Mc = Mp*RV, where RV is the representative volume (RM_SetRepresentativeVolume); 1, Mp is mol/L of water in the RV, Mc = Mp*P*RV, where P is porosity (RM_SetPorosity); or 2, Mp is mol/L of rock in the RV, Mc = Mp*(1-P)*RV.

            If a single KINETICS definition is used for cells with different initial porosity, the three options scale quite differently. For option 0, the number of moles of kinetic reactants will be the same regardless of porosity. For option 1, the number of moles of kinetic reactants will be vary directly with porosity and inversely with rock volume. For option 2, the number of moles of kinetic reactants will vary directly with rock volume and inversely with porosity.

            Note that the volume of water in a cell in the reaction module is equal to the product of porosity (RM_SetPorosity), the saturation (RM_SetSaturation), and representative volume (RM_SetRepresentativeVolume), which is usually less than 1 liter. It is important to write the RATES definitions for homogeneous (aqueous) kinetic reactions to account for the current volume of water, often by calculating the rate of reaction per liter of water and multiplying by the volume of water (Basic function SOLN_VOL).

            Rates that depend on surface area of solids, are not dependent on the volume of water. However, it is important to get the correct surface area for the kinetic reaction. To scale the surface area with the number of moles, the specific area (m^2 per mole of reactant) can be defined as a parameter (KINETICS; -parm), which is multiplied by the number of moles of reactant (Basic function M) in RATES to obtain the surface area.

            Parameters
                id	The instance id returned from RM_Create.
                option	Units option for kinetic reactants: 0, 1, or 2. 
            %}
            status = calllib('libphreeqcrm','RM_SetUnitsKinetics', obj.id, option);
        end
        
        function status = RM_SetUnitsPPassemblage(obj, option)
            %{
            Set input units for pure phase assemblages (equilibrium phases). In PHREEQC input, equilibrium phases are defined by moles of each phase (Mp). RM_SetUnitsPPassemblage specifies how the number of moles of phases in a reaction cell (Mc) is calculated from the input value (Mp).

            Options are 0, Mp is mol/L of RV (default), Mc = Mp*RV, where RV is the representative volume (RM_SetRepresentativeVolume); 1, Mp is mol/L of water in the RV, Mc = Mp*P*RV, where P is porosity (RM_SetPorosity); or 2, Mp is mol/L of rock in the RV, Mc = Mp*(1-P)*RV.

            If a single EQUILIBRIUM_PHASES definition is used for cells with different initial porosity, the three options scale quite differently. For option 0, the number of moles of a mineral will be the same regardless of porosity. For option 1, the number of moles of a mineral will be vary directly with porosity and inversely with rock volume. For option 2, the number of moles of a mineral will vary directly with rock volume and inversely with porosity.

            Parameters
                id	The instance id returned from RM_Create.
                option	Units option for equilibrium phases: 0, 1, or 2. 
            %}
            status = calllib('libphreeqcrm','RM_SetUnitsPPassemblage', ...
                obj.id, option);
        end
        
        function status = RM_SetUnitsSolution(obj, option)
            %{
            Solution concentration units used by the transport model. Options are 1, mg/L; 2 mol/L; or 3, mass fraction, kg/kgs. PHREEQC defines solutions by the number of moles of each element in the solution.

            To convert from mg/L to moles of element in the representative volume of a reaction cell, mg/L is converted to mol/L and multiplied by the solution volume, which is the product of porosity (RM_SetPorosity), saturation (RM_SetSaturation), and representative volume (RM_SetRepresentativeVolume). To convert from mol/L to moles of element in the representative volume of a reaction cell, mol/L is multiplied by the solution volume. To convert from mass fraction to moles of element in the representative volume of a reaction cell, kg/kgs is converted to mol/kgs, multiplied by density (RM_SetDensity) and multiplied by the solution volume.

            To convert from moles of element in the representative volume of a reaction cell to mg/L, the number of moles of an element is divided by the solution volume resulting in mol/L, and then converted to mg/L. To convert from moles of element in a cell to mol/L, the number of moles of an element is divided by the solution volume resulting in mol/L. To convert from moles of element in a cell to mass fraction, the number of moles of an element is converted to kg and divided by the total mass of the solution. Two options are available for the volume and mass of solution that are used in converting to transport concentrations: (1) the volume and mass of solution are calculated by PHREEQC, or (2) the volume of solution is the product of porosity (RM_SetPorosity), saturation (RM_SetSaturation), and representative volume (RM_SetRepresentativeVolume), and the mass of solution is volume times density as defined by RM_SetDensity. Which option is used is determined by RM_UseSolutionDensityVolume.

            Parameters
                id	The instance id returned from RM_Create.
                option	Units option for solutions: 1, 2, or 3, default is 1, mg/L. 
            %}
            status = calllib('libphreeqcrm','RM_SetUnitsSolution', ...
                obj.id, option);
        end
        
        function status = RM_SetUnitsSSassemblage(obj, option)
            %{
            Set input units for solid-solution assemblages. In PHREEQC, solid solutions are defined by moles of each component (Mp). RM_SetUnitsSSassemblage specifies how the number of moles of solid-solution components in a reaction cell (Mc) is calculated from the input value (Mp).

            Options are 0, Mp is mol/L of RV (default), Mc = Mp*RV, where RV is the representative volume (RM_SetRepresentativeVolume); 1, Mp is mol/L of water in the RV, Mc = Mp*P*RV, where P is porosity (RM_SetPorosity); or 2, Mp is mol/L of rock in the RV, Mc = Mp*(1-P)*RV.

            If a single SOLID_SOLUTION definition is used for cells with different initial porosity, the three options scale quite differently. For option 0, the number of moles of a solid-solution component will be the same regardless of porosity. For option 1, the number of moles of a solid-solution component will be vary directly with porosity and inversely with rock volume. For option 2, the number of moles of a solid-solution component will vary directly with rock volume and inversely with porosity.
            Parameters
                id	The instance id returned from RM_Create.
                option	Units option for solid solutions: 0, 1, or 2. 
            %}
            status = calllib('libphreeqcrm','RM_SetUnitsSSassemblage', ...
                obj.id, option);
        end
        
        function status = RM_SetUnitsSurface(obj, option)
            %{
            Set input units for surfaces. In PHREEQC input, surfaces are defined by moles of surface sites (Mp). RM_SetUnitsSurface specifies how the number of moles of surface sites in a reaction cell (Mc) is calculated from the input value (Mp).

            Options are 0, Mp is mol/L of RV (default), Mc = Mp*RV, where RV is the representative volume (RM_SetRepresentativeVolume); 1, Mp is mol/L of water in the RV, Mc = Mp*P*RV, where P is porosity (RM_SetPorosity); or 2, Mp is mol/L of rock in the RV, Mc = Mp*(1-P)*RV.

            If a single SURFACE definition is used for cells with different initial porosity, the three options scale quite differently. For option 0, the number of moles of surface sites will be the same regardless of porosity. For option 1, the number of moles of surface sites will be vary directly with porosity and inversely with rock volume. For option 2, the number of moles of surface sites will vary directly with rock volume and inversely with porosity.

            Parameters
                id	The instance id returned from RM_Create.
                option	Units option for surfaces: 0, 1, or 2. 
            %}
            status = calllib('libphreeqcrm','RM_SetUnitsSurface', ...
                obj.id, option);
        end
        
        function status = RM_SpeciesConcentrations2Module(obj, c)
            %{
            Set solution concentrations in the reaction cells based on the vector of aqueous species concentrations (species_conc). This method is intended for use with multicomponent-diffusion transport calculations, and RM_SetSpeciesSaveOn must be set to true. The list of aqueous species is determined by RM_FindComponents and includes all aqueous species that can be made from the set of components. The method determines the total concentration of a component by summing the molarities of the individual species times the stoichiometric coefficient of the element in each species. Solution compositions in the reaction cells are updated with these component concentrations.

            Parameters
                id	The instance id returned from RM_Create.
                species_conc	Array of aqueous species concentrations. Dimension of the array is (nxyz, nspecies), where nxyz is the number of user grid cells (RM_GetGridCellCount), and nspecies is the number of aqueous species (RM_GetSpeciesCount). Concentrations are moles per liter. 
            C Example:

                status = RM_SetSpeciesSaveOn(id, 1);
                ncomps = RM_FindComponents(id);
                nspecies = RM_GetSpeciesCount(id);
                nxyz = RM_GetGridCellCount(id);
                species_c = (double *) malloc((size_t) (nxyz * nspecies * sizeof(double)));
                ...
                status = RM_SpeciesConcentrations2Module(id, species_c);
                status = RM_RunCells(id);
            %}
            status = calllib('libphreeqcrm','RM_SpeciesConcentrations2Module', ...
                obj.id, c);
        end
        
        function status = RM_UseSolutionDensityVolume(obj, tf)
            %{
            Determines the volume and density to use when converting from the reaction-module concentrations to transport concentrations (RM_GetConcentrations). Two options are available to convert concentration units: (1) the density and solution volume calculated by PHREEQC are used, or (2) the specified density (RM_SetDensity) and solution volume are defined by the product of saturation (RM_SetSaturation), porosity (RM_SetPorosity), and representative volume (RM_SetRepresentativeVolume). Transport models that consider density-dependent flow will probably use the PHREEQC-calculated density and solution volume (default), whereas transport models that assume constant-density flow will probably use specified values of density and solution volume. Only the following databases distributed with PhreeqcRM have molar volume information needed to accurately calculate density and solution volume: phreeqc.dat, Amm.dat, and pitzer.dat. Density is only used when converting to transport units of mass fraction.

            Parameters
                id	The instance id returned from RM_Create.
                tf	True indicates that the solution density and volume as calculated by PHREEQC will be used to calculate concentrations. False indicates that the solution density set by RM_SetDensity and the volume determined by the product of RM_SetSaturation, RM_SetPorosity, and RM_SetRepresentativeVolume, will be used to calculate concentrations retrieved by RM_GetConcentrations. 
            %}
            status = calllib('libphreeqcrm','RM_UseSolutionDensityVolume', ...
                obj.id, tf);
        end
        
        function status = RM_WarningMessage(obj, warn_str)
            %{
            Print a warning message to the screen and the log file. 
            %}
            status = calllib('libphreeqcrm','RM_WarningMessage', obj.id, warn_str);
        end
        
 % New methods:
%         function status = RM_GetExchangeSpeciesCount(obj)
%             %{
%             	Returns the number of exchange species in the initial-phreeqc module. RM_FindComponents must be called before RM_GetExchangeSpeciesCount. This method may be useful when generating selected output definitions related to exchangers. 
%             %}
%             status = calllib('libphreeqcrm','RM_GetExchangeSpeciesCount', obj.id);
%         end
%         
%         function [status, ex_name] = RM_GetExchangeSpeciesName(obj, num, name, l)
%             %{
%             Retrieves an item from the exchange species list. The list of exchange species (such as "NaX") is derived from the list of components (RM_FindComponents) and the list of all exchange names (such as "X") that are included in EXCHANGE definitions in the initial-phreeqc module. RM_FindComponents must be called before RM_GetExchangeSpeciesName. This method may be useful when generating selected output definitions related to exchangers.
% 
%             Parameters
%                 id	The instance id returned from RM_Create.
%                 num	The number of the exchange species to be retrieved. Fortran, 1 based.
%                 name	The exchange species name at number num.
%                 l1	The length of the maximum number of characters for name. 
%             %}
%             [status, ex_name] = calllib('libphreeqcrm','RM_GetExchangeSpeciesName', ...
%                 obj.id, num, name, l);
%         end
        
%         function ex_name = GetExchangeSpeciesNames(obj)
%             %{
%             Retrieves an item from the exchange species list. The list of exchange species (such as "NaX") is derived from the list of components (RM_FindComponents) and the list of all exchange names (such as "X") that are included in EXCHANGE definitions in the initial-phreeqc module. RM_FindComponents must be called before RM_GetExchangeSpeciesName. This method may be useful when generating selected output definitions related to exchangers.
% 
%             Parameters
%                 id	The instance id returned from RM_Create.
%                 num	The number of the exchange species to be retrieved. Fortran, 1 based.
%                 name	The exchange species name at number num.
%                 l1	The length of the maximum number of characters for name. 
%             %}
%             n_ex_species = obj.RM_GetExchangeSpeciesCount();
%             ex_name = cell(n_ex_species, 1);
%             for i = 1:n_ex_species
%                 ex_name{i} = '00000000000000000000';
%                 [status, ex_name{i}] = calllib('libphreeqcrm','RM_GetExchangeSpeciesName', ...
%                     obj.id, i, ex_name{i}, length(ex_name{i}));
%             end
%         end
        
%         function [status, ex_name] = RM_GetExchangeName(obj, num, name, l)
%             %{
%             Retrieves an item from the exchange name list. RM_FindComponents must be called before RM_GetExchangeName. The exchange names vector is the same length as the exchange species names vector and provides the corresponding exchange site (for example, X corresponing to NaX). This method may be useful when generating selected output definitions related to exchangers.
% 
%             Parameters
%                 id	The instance id returned from RM_Create.
%                 num	The number of the exchange name to be retrieved. Fortran, 1 based.
%                 name	The exchange name associated with exchange species num.
%                 l1	The length of the maximum number of characters for name. 
%             %}
%             [status, ex_name] = calllib('libphreeqcrm','RM_GetExchangeName', ...
%                 obj.id, num, name, l);
%         end
        
        function ex_name = GetExchangeNames(obj)
            %{
            Retrieves an item from the exchange name list. RM_FindComponents must be called before RM_GetExchangeName. The exchange names vector is the same length as the exchange species names vector and provides the corresponding exchange site (for example, X corresponing to NaX). This method may be useful when generating selected output definitions related to exchangers.

            Parameters
                id	The instance id returned from RM_Create.
                num	The number of the exchange name to be retrieved. Fortran, 1 based.
                name	The exchange name associated with exchange species num.
                l1	The length of the maximum number of characters for name. 
            %}
            n_ex_species = obj.RM_GetExchangeSpeciesCount();
            ex_name = cell(n_ex_species, 1);
            for i = 1:n_ex_species
                ex_name{i} = '00000000000000000000';
                [~, ex_name{i}] = calllib('libphreeqcrm','RM_GetExchangeName', ...
                    obj.id, i, ex_name{i}, length(ex_name{i}));
            end
        end

        
%         function status = RM_GetEquilibriumPhasesCount(obj)
%             %{
%             Returns the number of equilibrium phases in the initial-phreeqc module. RM_FindComponents must be called before RM_GetEquilibriumPhasesCount. This method may be useful when generating selected output definitions related to equilibrium phases. 
%             %}
%             status = calllib('libphreeqcrm','RM_GetEquilibriumPhasesCount', obj.id);
%         end
        
%         function [status, phase_name] = RM_GetEquilibriumPhasesName(obj, num, name, l)
%             %{
%             Retrieves an item from the equilibrium phase list. The list includes all phases included in any EQUILIBRIUM_PHASES definitions in the initial-phreeqc module. RM_FindComponents must be called before RM_GetEquilibriumPhasesName. This method may be useful when generating selected output definitions related to equilibrium phases.
% 
%             Parameters
%                 id	The instance id returned from RM_Create.
%                 num	The number of the equilibrium phase name to be retrieved. Fortran, 1 based.
%                 name	The equilibrium phase name at number num.
%                 l1	The length of the maximum number of characters for name. 
%             %}
%             [status, phase_name] = calllib('libphreeqcrm','RM_GetEquilibriumPhasesName', ...
%                 obj.id, num, name, l);
%         end
        
%         function status = RM_GetGasComponentsCount(obj)
%             %{
%             Returns the number of gas phase components in the initial-phreeqc module. RM_FindComponents must be called before RM_GetGasComponentsCount. This method may be useful when generating selected output definitions related to gas phases. 
%             %}
%             status = calllib('libphreeqcrm','RM_GetGasComponentsCount', obj.id);
%         end
%         
%         function [status, gas_name] = RM_GetGasComponentsName(obj, num, name, l)
%             %{
%             Retrieves an item from the gas components list. The list includes all gas components included in any GAS_PHASE definitions in the initial-phreeqc module. RM_FindComponents must be called before RM_GetGasComponentsName. This method may be useful when generating selected output definitions related to gas phases.
% 
%             Parameters
%                 id	The instance id returned from RM_Create.
%                 num	The number of the gas component name to be retrieved. Fortran, 1 based.
%                 name	The gas component name at number num.
%                 l1	The length of the maximum number of characters for name. 
%             %}
%             [status, gas_name] = calllib('libphreeqcrm','RM_GetGasComponentsName', obj.id, ...
%                 num, name, l);
%         end
        
        function status = RM_GetKineticReactionsCount(obj)
            %{
            Returns the number of kinetic reactions in the initial-phreeqc module. RM_FindComponents must be called before RM_GetKineticReactionsCount. This method may be useful when generating selected output definitions related to kinetic reactions. 
            %}
            status = calllib('libphreeqcrm','RM_GetKineticReactionsCount', obj.id);
        end
        
        function [status, name_out] = RM_GetKineticReactionsName(obj, num, name, l)
            %{
            Retrieves an item from the kinetic reactions list. The list includes all kinetic reactions included in any KINETICS definitions in the initial-phreeqc module. RM_FindComponents must be called before RM_GetKineticReactionsName. This method may be useful when generating selected output definitions related to kinetic reactions.

            Parameters
                id	The instance id returned from RM_Create.
                num	The number of the kinetic reaction name to be retrieved. Fortran, 1 based.
                name	The kinetic reaction name at number num.
                l1	The length of the maximum number of characters for name. 
            %}
            [status, name_out] = calllib('libphreeqcrm','RM_GetKineticReactionsName', ...
                obj.id, num, name, l);
        end
        
        function status = RM_GetSICount(obj)
            %{
            Returns the number of phases in the initial-phreeqc module for which saturation indices can be calculated. RM_FindComponents must be called before RM_GetSICount. This method may be useful when generating selected output definitions related to saturation indices. 
            %}
            status = calllib('libphreeqcrm','RM_GetSICount', obj.id);
        end
        
        function [status, name_out] = RM_GetSIName(obj, num, name, l)
            %{
            Retrieves an item from the list of all phases for which saturation indices can be calculated. The list includes all phases that contain only elements included in the components in the initial-phreeqc module. The list assumes that all components are present to be able to calculate the entire list of SIs; it may be that one or more components are missing in any specific cell. RM_FindComponents must be called before RM_GetSIName. This method may be useful when generating selected output definitions related to saturation indices. 
            Parameters
                id	The instance id returned from RM_Create.
                num	The number of the saturation-index-phase name to be retrieved. Fortran, 1 based.
                name	The saturation-index-phase name at number num.
                l1	The length of the maximum number of characters for name.

            %}
            [status, name_out] = calllib('libphreeqcrm','RM_GetSIName', ...
                obj.id, num, name, l);
        end
        
        function status = RM_GetSolidSolutionComponentsCount(obj)
            %{
            Returns the number of solid solution components in the initial-phreeqc module. RM_FindComponents must be called before RM_GetSolidSolutionComponentsCount. This method may be useful when generating selected output definitions related to solid solutions. 
            %}
            status = calllib('libphreeqcrm','RM_GetSolidSolutionComponentsCount', obj.id);
        end
        
        function [status, name_out] = RM_GetSolidSolutionComponentsName(obj, num, name, l)
            %{
            Retrieves an item from the solid solution components list. The list includes all solid solution components included in any SOLID_SOLUTIONS definitions in the initial-phreeqc module. RM_FindComponents must be called before RM_GetSolidSolutionComponentsName. This method may be useful when generating selected output definitions related to solid solutions.

            Parameters
                id	The instance id returned from RM_Create.
                num	The number of the solid solution components name to be retrieved. Fortran, 1 based.
                name	The solid solution compnent name at number num.
                l1	The length of the maximum number of characters for name. 
            %}
            [status, name_out] = calllib('libphreeqcrm','RM_GetSolidSolutionComponentsName', ...
                obj.id, num, name, l);
        end
        
        function [status, name_out] = RM_GetSolidSolutionName(obj, num, name, l)
            %{
            Retrieves an item from the solid solution names list. The list includes solid solution names included in SOLID_SOLUTIONS definitions in the initial-phreeqc module. The solid solution names vector is the same length as the solid solution components vector and provides the corresponding name of solid solution containing the component. RM_FindComponents must be called before RM_GetSolidSolutionName. This method may be useful when generating selected output definitions related to solid solutions.

            Parameters
                id	The instance id returned from RM_Create.
                num	The number of the solid solution name to be retrieved. Fortran, 1 based.
                name	The solid solution name at number num.
                l1	The length of the maximum number of characters for name. 
            %}
            [status, name_out] = calllib('libphreeqcrm','RM_GetSolidSolutionName', ...
                obj.id, num, name, l);
        end
        
        function [status, log10_gamma] = RM_GetSpeciesLog10Gammas(obj, species_log10gammas)
            %{
            Transfer aqueous-species log10 activity coefficients to the array argument (species_log10gammas) This method is intended for use with multicomponent-diffusion transport calculations, and RM_SetSpeciesSaveOn must be set to true. The list of aqueous species is determined by RM_FindComponents and includes all aqueous species that can be made from the set of components.

            Parameters
                id	The instance id returned from RM_Create.
                species_log10gammas	Array to receive the aqueous species concentrations. Dimension of the array is (nxyz, nspecies), where nxyz is the number of user grid cells (RM_GetGridCellCount), and nspecies is the number of aqueous species (RM_GetSpeciesCount). Values for inactive cells are set to 1e30. 
            %}
            [status, log10_gamma] = calllib('libphreeqcrm','RM_GetSpeciesLog10Gammas', ...
                obj.id, species_log10gammas);
        end
        
        function log10_gamma = GetSpeciesLog10Gammas(obj)
            %{
            Transfer aqueous-species log10 activity coefficients to the array argument (species_log10gammas) This method is intended for use with multicomponent-diffusion transport calculations, and RM_SetSpeciesSaveOn must be set to true. The list of aqueous species is determined by RM_FindComponents and includes all aqueous species that can be made from the set of components.

            Parameters
                id	The instance id returned from RM_Create.
                species_log10gammas	Array to receive the aqueous species concentrations. Dimension of the array is (nxyz, nspecies), where nxyz is the number of user grid cells (RM_GetGridCellCount), and nspecies is the number of aqueous species (RM_GetSpeciesCount). Values for inactive cells are set to 1e30. 
            %}
            nspecies = obj.RM_GetSpeciesCount();
            log10_gamma = zeros(obj.ncells, nspecies);
            [~, log10_gamma] = calllib('libphreeqcrm','RM_GetSpeciesLog10Gammas', ...
                obj.id, log10_gamma);
        end
        
        function [status, log10_gamma] = RM_GetSpeciesLog10Molalities(obj, species_log10gammas)
            %{
            Transfer aqueous-species log10 molalities to the array argument (species_log10molalities) To use this method RM_SetSpeciesSaveOn must be set to true. The list of aqueous species is determined by RM_FindComponents and includes all aqueous species that can be made from the set of components.

            Parameters
                id	The instance id returned from RM_Create.
                species_log10molalities	Array to receive the aqueous species log10 molalities. Dimension of the array is (nxyz, nspecies), where nxyz is the number of user grid cells (RM_GetGridCellCount), and nspecies is the number of aqueous species (RM_GetSpeciesCount). Values for inactive cells are set to 1e30. 
            %}
            [status, log10_gamma] = calllib('libphreeqcrm','RM_GetSpeciesLog10Molalities', ...
                obj.id, species_log10gammas);
        end
        
        function log10_gamma = GetSpeciesLog10Molalities(obj)
            %{
            Transfer aqueous-species log10 molalities to the array argument (species_log10molalities) To use this method RM_SetSpeciesSaveOn must be set to true. The list of aqueous species is determined by RM_FindComponents and includes all aqueous species that can be made from the set of components.

            Parameters
                id	The instance id returned from RM_Create.
                species_log10molalities	Array to receive the aqueous species log10 molalities. Dimension of the array is (nxyz, nspecies), where nxyz is the number of user grid cells (RM_GetGridCellCount), and nspecies is the number of aqueous species (RM_GetSpeciesCount). Values for inactive cells are set to 1e30. 
            %}
            nspecies = obj.RM_GetSpeciesCount();
            log10_gamma = zeros(obj.ncells, nspecies);
            [~, log10_gamma] = calllib('libphreeqcrm','RM_GetSpeciesLog10Molalities', ...
                obj.id, log10_gamma);
        end
        
        function [status, name_out] = RM_GetSurfaceName(obj, num, name, l)
            %{
            Retrieves the surface name (such as "Hfo") that corresponds with the surface species name. The lists of surface species names and surface names are the same length. RM_FindComponents must be called before RM_GetSurfaceName. This method may be useful when generating selected output definitions related to surfaces.

            Parameters
                id	The instance id returned from RM_Create.
                num	The number of the surface name to be retrieved. Fortran, 1 based.
                name	The surface name associated with surface species num.
                l1	The length of the maximum number of characters for name. 
            C Example:

                for (i = 0; i < RM_GetSurfaceSpeciesCount(id); i++)
                {
                status = RM_GetSurfaceSpeciesName(id, i, line1, 100);
                status = RM_GetSurfaceType(id, i, line2, 100);
                status = RM_GetSurfaceName(id, i, line3, 100);
                sprintf(line, "%4s%20s%3s%20s%20s\n", "    ", line1, " # ", line2, line3);
                strcat(input, line);
                }
            %}
            [status, name_out] = calllib('libphreeqcrm','RM_GetSurfaceName', ...
                obj.id, num, name, l);
        end
        
        function status = RM_GetSurfaceSpeciesCount(obj)
            %{
            Returns the number of surface species (such as "Hfo_wOH") in the initial-phreeqc module. RM_FindComponents must be called before RM_GetSurfaceSpeciesCount. This method may be useful when generating selected output definitions related to surfaces. 
            %}
            status = calllib('libphreeqcrm','RM_GetSurfaceSpeciesCount', obj.id);
        end
        
        function [status, name_out] = RM_GetSurfaceSpeciesName(obj, num, name, l)
            %{
            Retrieves an item from the surface species list. The list of surface species (for example, "Hfo_wOH") is derived from the list of components (RM_FindComponents) and the list of all surface types (such as "Hfo_w") that are included in SURFACE definitions in the initial-phreeqc module. RM_FindComponents must be called before RM_GetSurfaceSpeciesName. This method may be useful when generating selected output definitions related to surfaces.

            Parameters
                id	The instance id returned from RM_Create.
                num	The number of the surface type to be retrieved. Fortran, 1 based.
                name	The surface species name at number num.
                l1	The length of the maximum number of characters for name.
            C Example:

                for (i = 0; i < RM_GetSurfaceSpeciesCount(id); i++)
                {
                status = RM_GetSurfaceSpeciesName(id, i, line1, 100);
                status = RM_GetSurfaceType(id, i, line2, 100);
                status = RM_GetSurfaceName(id, i, line3, 100);
                sprintf(line, "%4s%20s%3s%20s%20s\n", "    ", line1, " # ", line2, line3);
                strcat(input, line);
                }
            %}
            [status, name_out] = calllib('libphreeqcrm','RM_GetSurfaceSpeciesName', ...
                obj.id, num, name, l);
        end
        
        function name_out = GetSurfaceSpeciesNames(obj)
            %{
            Retrieves an item from the surface species list. The list of surface species (for example, "Hfo_wOH") is derived from the list of components (RM_FindComponents) and the list of all surface types (such as "Hfo_w") that are included in SURFACE definitions in the initial-phreeqc module. RM_FindComponents must be called before RM_GetSurfaceSpeciesName. This method may be useful when generating selected output definitions related to surfaces.
            %}
            n_surf_species = obj.RM_GetSurfaceSpeciesCount();
            name_out = cell(n_surf_species, 1);
            for i=1:n_surf_species
                name_out{i} = '00000000000000000000';
                [~, name_out{i}] = calllib('libphreeqcrm','RM_GetSurfaceSpeciesName', ...
                obj.id, i, name_out{i}, length(name_out{i}));
            end
        end
        
        function [status, name_out] = RM_GetSurfaceType(obj, num, name, l)
            %{
            Retrieves the surface site type (such as "Hfo_w") that corresponds with the surface species name. The lists of surface species names and surface species types are the same length. RM_FindComponents must be called before RM_GetSurfaceType. This method may be useful when generating selected output definitions related to surfaces.

            Parameters
                id	The instance id returned from RM_Create.
                num	The number of the surface type to be retrieved. Fortran, 1 based.
                name	The surface type associated with surface species num.
                l1	The length of the maximum number of characters for name. 
            %}
            [status, name_out] = calllib('libphreeqcrm','RM_GetSurfaceType', ...
                obj.id, num, name, l);
        end
        
        function name_out = GetSurfaceTypes(obj)
            %{
            Retrieves the surface site type (such as "Hfo_w") that corresponds with the surface species name. The lists of surface species names and surface species types are the same length. RM_FindComponents must be called before RM_GetSurfaceType. This method may be useful when generating selected output definitions related to surfaces.
            %}
            n_surf_species = obj.RM_GetSurfaceSpeciesCount();
            name_out = cell(n_surf_species, 1);
            for i=1:n_surf_species
                name_out{i} = '00000000000000000000';
                [~, name_out{i}] = calllib('libphreeqcrm','RM_GetSurfaceType', ...
                obj.id, i, name_out{i}, length(name_out{i}));
            end
        end
% Helper functions: will be added soon               
        
    end
	
end
