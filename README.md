# Stopped-flow smFRET - kinetic analysis of data

Intro

## Requirements

### MATLAB
MATLAB and [SPARTAN](https://github.com/stjude-smc/SPARTAN). We are going to use MATLAB together with Python,
and there are some restrictions. MATLAB 2019 is compatible with Python up to 3.7, while MATLAB 2022 works with Python up to 3.10.

### Python
Due to MATLAB-Python compatibility issues described above, you'd have to create a python environment and install a specific version
of the interpreter. Open Anaconda terminal, and run:

```bash
conda create -n snake python=3.7
conda activate snake
pip install ipython scipy pandas plotnine snakemake pulp==2.7
```

After that, you need to install the [MATLAB engine for Python](https://www.mathworks.com/help/matlab/matlab_external/install-the-matlab-engine-for-python.html).
Most likely, you'd need admin rights for that. If this is the case, run Anaconda terminal as admin, activate **snake** environment again, then navigate to MATLAB
installation folder (adjust for your MATLAB version), and install MATLAB engine for Python:

```bash
conda activate snake
cd "c:\Program Files\MATLAB\R2019a\extern\engines\python"
pip install .
```

If this works, you should be able to start a matlab session and detect it from Python:

```matlab
# run this in MATLAB
matlab.engine.shareEngine
```

```python
# run this in Python
import matlab.engine as me
me.find_matlab()
>> ('MATLAB_123123')
```

## Data location and naming patterns


Save your smFRET TIFF files into folder `data/tif`. Use this naming pattern: `<PREFIX>_<C>_<rep>.tif`, where `<PREFIX>` is used to filter out files for analysis, and `<C>` is the ligand concentration in format `00uM` - two digits, and two symbols for units (nM, uM, pM, etc).

You can set `<PREFIX>` in `Snakefile`. If set, only matching files are processed.

Also, you can adjust names of your samples in `Snakefile`. Here are some examples:

```
SAMPLES = ["A", "B", "C", "D"]
SAMPLES = ["protein 1", "protein 2", "mutant 1", "mutant 2"]
SAMPLES = ["membrane protein"]
```

You can define either one or four (multiplexed experiment) names. If there are four samples, Snakemake will run `selectPrintedSpots` to extract them. If there is only one sample, this step is skipped.

Finally, you will need `autotrace` selection criteria (`.mat` file) and `batchkinetics` model (`.model` file) for each of your samples. Save them into `data/config` folder. Their names should match your sample names exactly.

Below is an example of the folder structure with `PREFIX="V2Rpp"` and `SAMPLES=["arrestin"]`:

```
data/
    tif/
        Stack_000.tif       # ignored due to PREFIX mismatch
        V2Rpp_02uM_000.tif
        V2Rpp_02uM_001.tif
        V2Rpp_10uM_000.tif
    config/
        arrestin.mat    # autotrace selection criteria
        arrestin.model  # batchKinetics model
    rawtraces/
        V2Rpp_02uM_000.rawtraces
        V2Rpp_02uM_001.rawtraces
        V2Rpp_10uM_000.rawtraces
    arrestin/
        rawtraces/      # .rawtraces (created using `selectPrintedSpots` if >1 sample)
            V2Rpp_02uM_000.rawtraces
            V2Rpp_02uM_001.rawtraces
            V2Rpp_10uM_000.rawtraces
        traces/         # traces combined and saved with `autotrace`
            V2Rpp_02uM.traces     # traces from  filtered by `autotrace`
            V2Rpp_10uM.traces
        idealization/
            V2Rpp_02uM.dwt     # dwell times of combined traces
            V2Rpp_02uM.idl     # idealization data for kinetic analysis in Python (CSV format)
            V2Rpp_10uM.dwt
            V2Rpp_10uM.idl
        kinetics/           # output of kinetic analysis in Python

```


## Data analysis steps

### Start MATLAB
To reduce overhead, we connect to a single running MATLAB session. Start MATLAB, then share it's session by running this in MATLAB terminal:

```
matlab.engine.shareEngine
```

### Run Snakemake
Open anaconda terminal, and from the root folder of this project run `Snakemake -j8`, where 8 is the number of parallel processes you want to start (doesn't apply to MATLAB which uses it's own parallel pool).




# Known inssues

When you're installing snakemake with pip, it is likely (as of Nov 2024) not going to work, throwing error
```
AttributeError: module 'pulp' has no attribute 'list_solvers'. Did you mean: 'listSolvers'?
```

The problem is the PuLP package, which got broken in version 2.8.0. You have to manually install version 2.7:

```
pip uninstall pulp
pip install pulp==2.7.0
```
