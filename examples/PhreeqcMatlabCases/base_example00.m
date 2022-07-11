%% Introduction
% This script demonstrates the functionalities of PhreeqcMatlab classes and
% how to use them in practice.
%% 1- Solution
% Working with solutions is easy if you are already familiar with the
% Phreeqc input files. The constructor for the solution calss creates a 1
% liter pure water at 25 degree Celcius and 1.0 atmosphere. The solution
% object can then be modified by assigning components and compositions to
% its properties. Some default solutions are also predefined and can be
% accessed by running their static methods fromt he solution class, e.g. 
% Solution.seawater().
s1 = Solution();
sw = Solution.seawater();

% The solution class can be then converted to a phreeqc string by:
s1.phreeqc_string();

% The other option for creating a solution object is to read a decoded
% solution definition from a JSON file.
% NOTE: the keywords for writing the JSON file is not documented. Use the
% example files (TODO)
s = fileread('..\..\examples\data\json_sample.json'); % read JSON to a string
sd = jsondecode(s); % decode the JSON string to a structure
s2 = sd.Solution.Seawater;
s2_sol = Solution.read_json(s2);

% It is also possible to run the solution in Phreeqc and see the output in
% Matlab:
res = s1.run_in_phreeqc();
display(res);

% The above call uses the default database. One can also use another 
% database to run the file:
res = s1.run_in_phreeqc('pitzer.dat');
display(res);
% NOTE: currently, all the databases including the user-modified
% databasesmust be copied in the database folder of the package to be
% accessible by PhreeqcMatlab.


