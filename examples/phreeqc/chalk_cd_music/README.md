# CD-MUSIC surface-complexation models of calcite (chalk)

Two published charge-distribution multi-site complexation (**CD-MUSIC**) models
of the calcite surface, as PHREEQC input files, plus a MATLAB driver that runs
them through PhreeqcMatlab's IPhreeqc wrapper and reports the surface
composition.

| File | Model | Planes | Sites |
| --- | --- | --- | --- |
| `wolthers_cd_music.phr` | Wolthers, Charlet & Van Cappellen (2008), *Am. J. Sci.* **308**, 905–941 | 5 | `>Ca` (`Surf_ca`), `>CO3` (`Surf_co`) |
| `heberling_cd_music.phr` | Heberling et al. (2011), *J. Colloid Interface Sci.* **354**, 843–857 | 3 | `>Ca` (`Calc_ca_`), `>CO3` (`Calc_carb_`) |

Both use the CD-MUSIC convention: each surface reaction carries a `-cd_music`
line distributing the reaction's charge over the electrostatic planes, and the
`SURFACE` block declares `-cd_music` with the plane capacitances.

## Running

From the repository root (after `startup`):

```matlab
run('examples/phreeqc/chalk_cd_music/chalk_cd_music.m')
```

For each model the script runs the input in IPhreeqc, writes the complete
PHREEQC output to `<model>_output.txt` (git-ignored), and prints the per-plane
surface-charge summary, e.g. for the Wolthers model:

```
Surface charge, plane 0 = -1.232e-06 eq
Surface charge, plane 1 =  2.890e-06 eq
Surface charge, plane 2 =  0.000e+00 eq
Sum of surface charge   =  1.657e-06 eq
```

These per-plane charges are pinned as golden values by the `cdMusicChalkSurface`
regression test in `tests/PhreeqcMatlabTest.m` (a CD-MUSIC reference case).

## Source

The models are faithful reproductions of the chalk surface-complexation input
files used in DTU/DOTC chalk-wettability work. They run against the bundled
`phreeqc.dat` database.
