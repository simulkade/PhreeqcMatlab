% A script that tests the functionality of the IPhreeqc wrapper
% Note that IPhree
iph = IPhreeqc(); % load the library
iph = iph.CreateIPhreeqc(); % create an IPhreeqc instance
iph.SetOutputStringOn(true);
iph.LoadDatabase(database_file('phreeqc.dat'));
iph.RunFile('ex2_input.pqc');
out_string = iph.GetOutputString();
disp(out_string); % display the phreeqc output string
iph.DestroyIPhreeqc();