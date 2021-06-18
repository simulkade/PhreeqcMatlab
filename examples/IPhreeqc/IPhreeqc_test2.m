% A script that tests the functionality of the IPhreeqc wrapper
% Note: IPhreeqc does not undeerstand salts as input to solutions
iph = IPhreeqc(); % load the library
iph = iph.CreateIPhreeqc(); % create an IPhreeqc instance
out_string = iph.RunPhreeqcFile('IPhreeqc_test2.pqc', database_file('phreeqc.dat'));
disp(out_string)
% the above function does the following:
% iph.SetOutputStringOn(true);
% iph.LoadDatabase(database_file('phreeqc.dat'));
% iph.RunFile('IPhreeqc_test2.pqc');
% out_string = iph.GetOutputString();
% disp(out_string); % display the phreeqc output string
iph.DestroyIPhreeqc();