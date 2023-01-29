classdef Datafile
    %DATAFILE
    % datafile is a class that works with phreeqc data files
    % Currently, it is only used to extract the relevant data for the user
    % interface 
    
    properties
        datafile_abs_path % absolute path to the data file
    end
    
    methods
        function obj = Datafile(datafilepath)
            %DATAFILE accepts two arguments filename, that is the name of
            %the database and filepath that is the absolute path to the
            %datafile
            % use an empty path if the file will be provided as a strings
            % Example:
            % data_path = 'C:/project/phreeqc/';
            % file_name = 'phreeqc.dat';
            obj.datafile_abs_path = datafilepath;
        end
        
        function C = clean_up_data_file(obj)
            % This function cleans up the data file from all commented lines
            % and empty lines and returns it as a cell array
            % read the data file into a cell array
            fid = fopen(obj.datafile_abs_path);
            C = textscan(fid, '%s','Delimiter',''); % read the input file into a cell array
            fclose(fid);
            C = C{:}; % get rid of cells in cell C
            % clean the comments:
            ind_comment = cellfun(@(x)(x(1)=='#'), C);
            C(ind_comment) = []; % simply remove the comment lines
            % remove extra spaces and end of line comments
            for i=1:length(C)
                C{i}(strfind(C{i}, '#'):end) = '';
                C{i} = strtrim(C{i});
            end
        end
        function [primary_species, ps_table] = extract_primary_species(obj)
            % extract_primary_species extracts all the primary species from
            % a phreeqc datafile
            % ps_table is a table of primary species and associated data
            % such as molecular weight
            C= obj.clean_up_data_file();
            %ind_1 = find(strcmpi(C, 'SOLUTION_MASTER_SPECIES'), 1)+1;
            %ind_end = find(strcmpi(C, 'SOLUTION_SPECIES'), 1)-1;
            [ind_1, ind_end] = obj.find_data_block(C, 'SOLUTION_MASTER_SPECIES');
            p = C(ind_1:ind_end); % cut the cells 
            % element	species	alk	gfw_formula	element_gfw
            n_species = length(p);
            element = strings(n_species, 1);
            species = strings(n_species, 1);
            alk = zeros(n_species, 1);
            gfw_formula = strings(n_species, 1);
            element_gfw = zeros(n_species, 1);
            for i = 1:length(p)
                tmp = strtrim(strsplit(p{i}));
                element(i) = tmp{1};
                species(i) = tmp{2};
                alk(i) = str2double(tmp{3});
                gfw_formula(i) = tmp{4};
                try
                    element_gfw(i) = str2double(tmp{5});
                catch
                    element_gfw(i) = -1;
                end
                if element_gfw(i)==-1 && i>1
                    element_gfw(i) = element_gfw(i-1);
                end
            end
            % strtrim(cellfun(@strsplit, p, 'UniformOutput', false))
            primary_species = element;
            ps_table = table(element, species, alk, gfw_formula, element_gfw);
        end
        
        function phases = extract_phases(obj)
            % extracts the phases from the data file
            % between PHASES and EXCHANGE_MASTER_SPECIES keywords
            C= obj.clean_up_data_file();
            % ind_1 = find(strcmpi(C, 'PHASES'), 1)+1;
            % ind_end = find(strcmpi(C, 'EXCHANGE_MASTER_SPECIES'), 1)-1;
            [ind_1, ind_end] = obj.find_data_block(C, 'PHASES');
            p = C(ind_1:ind_end); % extract the phases block
            phases = strings(0);
            kw = obj.phase_keywords(); % key words in the PHASE block
            % go through each line
            % if the line starts with - or contains =, then ignore
            for i=1:length(p)
                if ~obj.check_keywords(p{i}, kw)
                    tmp = strtrim(strsplit(p{i}));
                    phases = [phases; tmp{1}]; % find an elegant solution later
                end
            end
            % extract the phase reactions and log_k for exporting to the
            % GUI tables TBD
        end
        
        function [secondary_species, species_charge, reactions] = extract_secondary_species(obj)
            % extracts all the secondary species, and the equilibrium
            % reactions
            C= obj.clean_up_data_file();
            %ind_1 = find(strcmpi(C, 'SOLUTION_SPECIES'), 1)+1;
            %ind_end = find(strcmpi(C, 'PHASES'), 1)-1;
            [ind_1, ind_end] = obj.find_data_block(C, 'SOLUTION_SPECIES');
            p = C(ind_1:ind_end); % extract the solution species block
            ind_reactions = contains(p, '=');
            reactions = p(ind_reactions);
            sp = cellfun(@(x)strsplit(x, {' = ', ' + '}), reactions, 'UniformOutput', false);
            secondary_species = unique(strtrim(regexprep([sp{:}], '^\d*', '')))';
            n_species = length(secondary_species);
            % find charge
            species_charge = zeros(n_species, 1);
            for i=1:n_species
                if contains(secondary_species{i}, '+')
                    ind_sign = strfind(secondary_species{i}, '+');
                    if ind_sign ~= length(secondary_species{i})
                        species_charge(i) = str2double(secondary_species{i}(ind_sign:end));
                    else
                        species_charge(i) = 1.0;
                    end
                elseif contains(secondary_species{i}, '-')
                    ind_sign = strfind(secondary_species{i}, '-');
                    if ind_sign ~= length(secondary_species{i})
                        species_charge(i) = str2double(secondary_species{i}(ind_sign:end));
                    else
                        species_charge(i) = -1.0;
                    end
                end      
            end
            
        end
        
        
    end
    
    methods (Static=true, Access = 'private')
        function status = check_keywords(string_line, key_words)
            status = false;
            for i = 1:length(key_words)
                status = (status || contains(string_line, key_words(i)));
            end
        end
        
        function kw = phase_keywords()
            kw = ["log_k"
                "delta_h"
                "delta_H"
                "Vm"
                "analytic"
                "T_c"
                "P_c"
                "Omega"
                "="];
        end
        
        function kw = species_keywords()
            % TBD
            kw = ["log_k" 
                "delta_h"
                "delta_H"];
        end
        
        function kw = secondary_species_keywords()
            % keywords from the secondary species definition in the phreeqc
            % databases
            kw = ["log_k"
                "delta_h"
                "delta_H"
                "analytic"
                "dw"
                "Vm"];
        end
        
        function kw = surface_keywords()
            % keywords from the surface and surface species 
            kw = ["log_k"
                "logk"
                "delta_h"
                "delta_H"
                "analytic"
                "analytical_expression"
                "cd_music"
                "-cd"
                "Vm"
                "mole_balance"
                "no_check"];
        end

        function kw = database_main_keywords()
            % keywords that define a block of phreeqc species
            kw = ["SOLUTION_MASTER_SPECIES"
            "SOLUTION_SPECIES"
            "EXCHANGE_MASTER_SPECIES"
            "EXCHANGE_SPECIES"
            "SURFACE_MASTER_SPECIES"
            "SURFACE_MASTER_SPECIES"
            "RATES"
            "PHASES"
            "PITZER"
            "SIT"];
        end
        
        function [ind1, ind2] = find_data_block(C, block_name)
            % finds the index of the the begining and the end of a data
            % block that shows the block of data representing the keyword
            % specified by block_name
            % returns 0 for both indices if the block name does not exist
            % C is a cleaned up data file
            % Example:
            % [ind1, ind2] = find_date_block(C, 'SOLUTION_SPECIES');
            ind1 = find(strcmpi(C, block_name), 1)+1;
            if isempty(ind1)
                ind1=0;
                ind2=0;
                return
            end
            kw = Datafile.database_main_keywords();
            ind2 = length(C);
            for i=1:length(kw)
                ind_end = find(strcmpi(C, kw{i}), 1)-1;
                if ~isempty(ind_end)
                    if ind_end>ind1 && ind_end<ind2
                        ind2 = ind_end-1;
                    end
                end
            end
        end
    end
            
end

