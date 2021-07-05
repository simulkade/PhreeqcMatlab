% This is an example of how to read a json file in matlab
% read the file as a text file
s = fileread('json_sample.json');
% decode to json structure
b = jsondecode(s);
% Then we can use fieldnames, getfield and isfield to extract the required information
comp = fieldnames(b.Solution.Seawater.Composition); % get the list of components
x = cellfun(@(x)getfield(b.Solution.Seawater.Composition, {1}, x), comp); % get the compositions

% it is safer to check for the existence of a field before using it
if isfield(b, 'Solution') % is solutions are defined
    sol = b.Solution; % assign all solutions to variable sol
end


