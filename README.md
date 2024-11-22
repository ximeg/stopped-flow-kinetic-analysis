# Stopped-flow smFRET - kinetic analysis of data

Intro

## Requirements

[SPARTAN](https://github.com/stjude-smc/SPARTAN) for MATLAB, and following packages for Python:

```
pip install pandas plotnine scipy snakemake
```

## Data location and naming patterns

Put your smFRET data into folder `data/spartan`. Use this naming pattern: `<something>_<C>_<rep>.tif`.

Put config files (selection criteria, idealization models, etc.) into `data/config` folder.

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
