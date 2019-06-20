# PhreeqcMatlab
[Documents (work in progress)](https://github.com/simulkade/PhreeqcMatlab/wiki)

## Easily calling PhreeqcRM from Matlab  
`PhreeqcMatlab` is a wrapper for the [PhreeqcRM](https://www.usgs.gov/software/phreeqc-version-3) [C interface](https://wwwbrr.cr.usgs.gov/projects/GWC_coupled/phreeqcrm/_r_m__interface___c_8h.html). Most of the functions are wrapped, with the exception of MPI function (that I neither use nor know how to wrap). In general, the C++ interface of PhreeqcRM has more functionality and is easier to call. Therefore, I have implemented several functions to make the usage of this package more convenient. All the original PhreeqcRM functions start with `RM_`. The additional utility functions that I have added do not have this extra `RM_`.

# Installation
`PhreeqcMatlab` automatically downloads the latest compiled phreeqcRM `.dll` on Windows and `.so` on Linux machines, from [this](https://github.com/simulkade/PhreeqcRM) repository. I don't have access to macOS; hence, no library there and you'll have to compile PhreeqcRM yourself for mac. On Windows, you will need to have [Visual C++ Redistributable for VC 2015](https://www.microsoft.com/en-us/download/details.aspx?id=48145) installed. All you need to do is to download or clone this repository and run the `startup.m` file. Please let me know if you have any error message when running the file.  

# Test cases
Go to the [examples](https://github.com/simulkade/PhreeqcMatlab/tree/master/examples/basetest) folder and run the files. Don't forget to run the `startup` file before running the examples.  

# Reactive transport
I'm writing several examples that calls this package from my finite volume package [FVTool](https://github.com/simulkade/FVTool). You can help me by providing reactive transport cases with analytical solutions.

# Other packages you might like
There are at least two more packages that have some of the functionalities of `PhreeqcMatlab`, and inspired me to write this package.

  + [TReacLab](https://github.com/TReacLab/TReacLab)
  + [CRP](https://github.com/nbengdahl/CRP)

# To do list
This package probably won't be broken by sudden changes. So you can start using it. Here's a list of near future activities. You contributions/suggestions are more than welcome :-)  

  + Wrap IPhreeqc functions
  + More utility/helper functions
  + More tests
  + Documentation (please help)

# Author
This package is written by [Ali A. Eftekhari](https://www.oilgas.dtu.dk/service/telefonbog/person?id=112240&cpid=203787&tab=2&qt=dtupublicationquery) in his free time. It is/will be used in some of the projects/publications at the [Danish Hydrocarbon Research and Technology Centre](https://www.oilgas.dtu.dk/) at the [Technical University of Denmark](https://www.dtu.dk/).
