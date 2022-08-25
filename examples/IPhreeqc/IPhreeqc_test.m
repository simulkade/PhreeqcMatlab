% A script that tests the functionality of the IPhreeqc wrapper
% Note that IPhree
iph = IPhreeqc(); % load the library
iph = iph.CreateIPhreeqc(); % create an IPhreeqc instance
iph.LoadDatabase(database_file('phreeqc.dat'));
iph.SetOutputStringOn(true);
iph.SetSelectedOutputStringOn(1);
iph.RunFile('ex2_input_mod.pqc');
out_string = iph.GetOutputString();
disp(out_string); % display the phreeqc output string
% for i=1:iph.GetSelectedOutputCount
n_so =1;
iph.SetCurrentSelectedOutputUserNumber(n_so);
n_row = iph.GetSelectedOutputRowCount();
n_col = iph.GetSelectedOutputColumnCount();
val = zeros(n_row-1, n_col);

s_out = iph.GetSelectedOutputString()
n=0;
nPtr=libpointer('int32Ptr', n);
c = 0;
cPtr = libpointer('doublePtr', c);
h = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
hPtr = libpointer('stringPtr', h);
[aa, bb, cc, dd] = iph.GetSelectedOutputValue2(1, 0, nPtr, cPtr, h, length(h))
% for 
% for i=1:n_col
%     iph.GetSelectedOutputValue2()
% end

[a,b] = iph.GetSelectedOutputTable(1)

iph.DestroyIPhreeqc();