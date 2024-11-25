import os
import re
import shutil
from util import group_files, fixpath, run_matlab, get_criteria_file, find_traces, find_traces4combine

### -------------------------------------
### START OF USER-CONFIGURABLE PARAMETERS
### -------------------------------------
# Use this prefix to filter out specific files. Set to "" to disable
PREFIX = "V2Rpp"

# Set names of your samples. A folder will be created for each of them. You can have either one or four
SAMPLES = ['A', 'B', 'C', 'D']

SAVE_INDIVIDUAL_TRACES = False
### -------------------------------------
### END OF USER-CONFIGURABLE PARAMETERS
### -------------------------------------


### Initialization
### --------------
# Sanity checks
assert isinstance(PREFIX, str), "Prefix should be a string"
SAMPLES = [SAMPLES] if isinstance(SAMPLES, str) else SAMPLES
assert len(SAMPLES) in [1, 4], f"You can have either one or four samples; you provided {len(SAMPLES)}: {SAMPLES}"

# Discover all input data files that match the given pattern
PTRN = rf"({PREFIX}.*_\d{{3}}).rawtraces"
raw_data_files = []
for f in os.listdir("data/rawtraces/"):
    m = re.match(PTRN, f)
    if m:
        raw_data_files.append(m.group(1))

# Group input files
GROUPED_FILES = group_files(raw_data_files)

extract_folder = [] if len(SAMPLES) == 1 else ["plt-extract_samples"]

rule all:
    input:
        expand("data/{sample}/combined_traces/{group}.traces", sample=SAMPLES, group=GROUPED_FILES.keys())

rule gettraces:
    input:
        tif="data/tif/{file}.tif"
    output:
        rt="data/rawtraces/{file}.rawtraces"
    run:
        shutil.copy(input.tif, output.rt)

rule extract_samples:
    input:
        rt="data/rawtraces/{file}.rawtraces"
    output:
        rt=expand("data/{sample}/rawtraces/{{file}}.rawtraces", sample=SAMPLES),
        plt=expand("data/{folder}/{{file}}.png", folder=extract_folder)
    run:
        run_matlab("scripts/extract_samples.m", input.rt, output.rt, PLT=fixpath(output.plt))

rule autotrace_each:
    input:
        traces = lambda wildcards: find_traces(wildcards, len(SAMPLES), SAVE_INDIVIDUAL_TRACES),
        criteria = lambda wildcards: get_criteria_file(wildcards,"data/conf/{sample}.mat")
    output:
        "data/{sample}/traces/{file}.traces"
    run:
        run_matlab(
            script="scripts/combine_traces.m",
            input=input.traces,
            output=output,
            CRITERIA=fixpath(input.criteria)
        )

rule combine_traces:
    input:
        traces   = lambda wildcards: find_traces4combine(wildcards, len(SAMPLES), GROUPED_FILES, SAVE_INDIVIDUAL_TRACES),
        criteria = lambda wildcards: get_criteria_file(wildcards, "data/conf/{sample}.mat")
    output:
        "data/{sample}/combined_traces/{group}.traces"
    run:
        run_matlab(
            script="scripts/combine_traces.m",
            input=input.traces,
            output=output[0],
            CRITERIA=fixpath(input.criteria)
        )


