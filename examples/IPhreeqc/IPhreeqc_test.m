% A script that tests the functionality of the IPhreeqc wrapper
% Note that IPhree
iph = IPhreeqc(); % load the library
iph = iph.CreateIPhreeqc(); % create an IPhreeqc instance
iph.SetSelectedOutputStringOn(1);
iph.SetOutputStringOn(true);
iph.LoadDatabase(database_file('phreeqc.dat'));
iph.RunFile('ex2_input.pqc');
out_string = iph.GetOutputString();
disp(out_string); % display the phreeqc output string
% for i=1:iph.GetSelectedOutputCount
n_so =1;
iph.SetCurrentSelectedOutputUserNumber(n_so);
n_row = iph.GetSelectedOutputRowCount();
n_col = iph.GetSelectedOutputColumnCount();
val = zeros(n_row-1, n_col);

iph.GetSelectedOutputString()
n=2;
nPtr=libpointer('int64Ptr', n);
c = 0;
cPtr = libpointer('doublePtr', c);
h = "aaaaaaaaaa";
hPtr = libpointer('stringPtr', h);
iph.GetSelectedOutputValue2(1, 1, nPtr, cPtr, hPtr, uint32(length(h)));
% for 
% for i=1:n_col
%     iph.GetSelectedOutputValue2()
% end

% iph.DestroyIPhreeqc();