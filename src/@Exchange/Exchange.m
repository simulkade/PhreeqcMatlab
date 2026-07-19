classdef Exchange
    % Exchange defines an ion exchanger that can be equilibrated with an
    % aqueous solution

    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        exchange_master_species(:, 1) string
        exchange_species_reactions(:, 1) string
        log_k(:,1) double
        dh(:,1) double
    end

    methods
        function obj = Exchange()
            % Exchange constructs an empty ion-exchanger definition.
            % phreeqc_string()/run()/read_json() are implemented in the
            % Milestone 3 object-model work (see ROADMAP.md).
            obj.name = "exchange 1";
            obj.number = 1;
        end
    end
end