[![DOI](https://zenodo.org/badge/187366776.svg)](https://zenodo.org/badge/latestdoi/187366776)
[![View PhreeqcMatlab on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://se.mathworks.com/matlabcentral/fileexchange/99394-phreeqcmatlab)
# PhreeqcMatlab
[Documents (work in progress)](https://github.com/simulkade/PhreeqcMatlab/wiki)

## Easily calling PhreeqcRM and IPhreeqc from Matlab  
`PhreeqcMatlab` is a wrapper for the [PhreeqcRM](https://www.usgs.gov/software/phreeqc-version-3) [C interface](https://wwwbrr.cr.usgs.gov/projects/GWC_coupled/phreeqcrm/_r_m__interface___c_8h.html) and [IPhreeqc](https://wwwbrr.cr.usgs.gov/projects/GWC_coupled/iphreeqc/IPhreeqc_8h.html). Most of the functions are wrapped, with the exception of MPI function (that I neither use nor know how to wrap). In general, the C++ interface of PhreeqcRM has more functionality and is easier to call. Therefore, I have implemented several classes and functions to make the usage of this package more convenient, similar to its c++ interface and better. All the original PhreeqcRM functions start with `RM_`. The additional utility functions that I have added do not have this extra `RM_`.

# Installation
`PhreeqcMatlab` automatically downloads the latest compiled phreeqcRM `.dll` on Windows and `.so` on Linux machines, from [this](https://github.com/simulkade/PhreeqcRM) repository. I don't have access to macOS; hence, no library there and you'll have to compile PhreeqcRM yourself for mac. On Windows, you will need to have [Visual C++ Redistributable for VC 2019](https://www.microsoft.com/en-us/download/details.aspx?id=48145) installed. All you need to do is to download or clone this repository and run the `startup.m` file. Before running the example, make sure that [C/C++ compiler](https://www.mathworks.com/matlabcentral/fileexchange/52848-matlab-support-for-mingw-w64-c-c-compiler) is already installed in your Matlab. Please let me know if you have any error messages when running the file.  

# Test cases
Go to the [examples](https://github.com/simulkade/PhreeqcMatlab/tree/master/examples/basetest) folder and run the files. Don't forget to run the `startup` file before running the examples.  

## Simple cases
### Running a Phreeqc input file or string:
```matlab
iph = IPhreeqc(); % load the library
iph = iph.CreateIPhreeqc(); % create an IPhreeqc instance
iph_string = ['SOLUTION 1 brine \n' ...
    'pH      7.0 \n' ...
    'temp    25.0 \n' ...
    'Na    1.0 \n' ...
    'Cl    1.0 \n' ...
    'END \n' ...
    'SELECTED_OUTPUT 1 \n'...
    '-reset false \n'...
    '-totals Na Cl \n'...
    'END']; % create the Phreeqc string
out_string = iph.RunPhreeqcString(iph_string, database_file('phreeqc.dat')); % Run the string
disp(out_string)       % display the results
iph.DestroyIPhreeqc(); % kill the phreeqc instance
```  
Alternatively, you can save the string in a file and call it with `RunPhreeqcFile` function as shown [here](https://github.com/simulkade/PhreeqcMatlab/tree/master/examples/IPhreeqc).  

## Sensitivity analysis
In [this folder](https://github.com/simulkade/PhreeqcMatlab/tree/master/examples/batch), there are a couple of examples that shows how to investigate the effect of temperature on the dissolution of anhydrite and gypsum. Save the following Phreeqc input in a file named `ex2_input.pqc` (example 2 of Phreeqc manual) 
```phreeqc
#TITLE Example 2.--Temperature dependence of solubility of gypsum and anhydrite
SOLUTION 1 Pure water
        pH      7.0
        temp    25.0                
EQUILIBRIUM_PHASES 1
        Gypsum          0.0     1.0
        Anhydrite       0.0     1.0
END

SELECTED_OUTPUT 1
        -reset false
        -si     Anhydrite  Gypsum
USER_PUNCH
        -headings equi_anhydrite
        10 PUNCH EQUI("Anhydrite")

END
```  
and run the following script to calculate and plot the solubility in different temperatures:  
```matlab
phreeqc_rm = PhreeqcSingleCell('ex2_input.pqc', 'phreeqc.dat');
n_data = 51;
h_out = phreeqc_rm.GetSelectedOutputHeadings(1);
temperature = linspace(25.0, 75.0, n_data); % degree C
s_out = zeros(n_data, length(h_out));
for i = 1:length(temperature)
    phreeqc_rm.RM_SetTemperature(temperature(i));
    status = phreeqc_rm.RM_RunCells();
    c_out = phreeqc_rm.GetConcentrations();
    s_out(i, :) = phreeqc_rm.GetSelectedOutput(1);
end
plot(temperature, s_out, '-s');
legend(string(h_out));
xlabel('T (C)');
ylabel('SI');
status = phreeqc_rm.RM_Destroy();
```  

## And more
Look at the [example folder](https://github.com/simulkade/PhreeqcMatlab/tree/master/examples) for many more examples of batch and transport geochemical calculations.  

# Reactive transport
I'm writing several examples that calls this package from my finite volume package [FVTool](https://github.com/simulkade/FVTool). You can help me by providing reactive transport cases with analytical solutions.

# Other packages you might like
There are at least two more packages that have some of the functionalities of `PhreeqcMatlab`, and inspired me to write this package.

  + [TReacLab](https://github.com/TReacLab/TReacLab)
  + [CRP](https://github.com/nbengdahl/CRP)

# To do list
This package probably won't be broken by sudden changes. So you can start using it. Here's a list of near future activities. You contributions/suggestions are more than welcome :-)  

  + ~~Wrap IPhreeqc functions~~
  + ~~More utility/helper functions~~
  + ~~More tests~~
  + Documentation (please help)
  + New classes for solution, phases, surfaces, etc (in progress)
  + Utility functions for the IPhreeqc wrapper
  + More examples for both IPhreeqc and PhreeqcRM
  + More keywords in the new input file specific to PhreeqcMatlab
  + Simple GUI (in progress as part of a DHRTC project)

# Author
The original package was written by [Ali A. Eftekhari](https://www.oilgas.dtu.dk/service/telefonbog/person?id=112240&cpid=203787&tab=2&qt=dtupublicationquery) in his free time. It is/will be used in some of the projects/publications at the [Danish Hydrocarbon Research and Technology Centre](https://www.oilgas.dtu.dk/) (DHRTC) at the [Technical University of Denmark](https://www.dtu.dk/). Some of the current development is done as part of an ongoing project at the DHRTC.

# Citation
Please cite as
```
Eftekhari, Ali A., and Behzad Hosseinzadeh. Simulkade/PhreeqcMatlab: Preliminary Release of PhreeqcMatlab. Zenodo, 2021, doi:10.5281/ZENODO.5513713.
```
