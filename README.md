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

Put your smFRET data into folder `data/tifs`. Use this naming pattern: `<something>_<C>_<rep>.tif`, where `<C>` is in format `00uM` - two digits, and two symbols for units.

Adjust names of the samples in Snakefile, look for line

```
SAMPLES = ["A", "B", "C", "D"]
```
You can define either one or four (multiplexed experiment) names. If there are four samples, Snakemake will run `selectPrintedSpots` to extract them. If there is only one sample, this step is skipped.

Put config files (selection criteria, idealization models, etc.) into `data/<SAMPLE>/config` folder. They should be named:

```
criteria.mat  # autotrace selection criteria
bk.model      # batchKinetics model
```

## Data analysis steps

MATLAB:

* Run `gettraces` from SPARTAN. Use it in batch mode to create `rawtraces`.
* Run `selectPrintedSpots`. Feed it all the `rawtraces`.
* Gather resulting files ending with `_[ABCD].rawtraces` in separate `A`, `B`, `C`, `D` folders.
* Run `autotrace`. Load selection criteria, then run it in the batch mode to filter traces and create `_auto.traces`.
* Run `autotrace` again. Group your data by sample and concentration point; then combine all traces from one repeat together into one `[ABCD]/combined_auto.traces` file.
* Run automatic gamma correction. Makes `[ABCD]/combined_auto_gcorr.traces` file.
* Next, do idealization. There is a script for that:
```matlab
% Combine all traces matching the pattern together into one file
fileList = dir('*_auto_gcorr.traces');
load('criteria.mat');
options.outFilename = 'combined.traces';
loadPickSaveTraces({fileList.name}, criteria, options);

% Open traces file and do idealization
traces = loadTraces('combined.traces')
exp_time = traces.time(2) - traces.time(1)
model = QubModel('../D-arrestin_C tail 2.model');
[idl, model, LL] = skm(traces.fret, exp_time, model, struct());

% Save result to file
csvwrite("combined_idl.csv", idl);
```
The output is `[ABCD]/combined_idl.csv` file.

Python: use Snakemake. WIP.


# Snakemake and MATLAB

To reduce overhead, we connect to a running MATLAB session. Start MATLAB, then share it's session
by running this in MATLAB terminal:

```
matlab.engine.shareEngine
```

After that, Python can find matlab with

```python
import matlab.engine

matlab.engine.find_matlab()
```

Looks like Snakemake runs into problems interacting with matlab when number of jobs > 1.

Matlab parallel pool can be disabled in cascadeConstants.m, line 244.

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
