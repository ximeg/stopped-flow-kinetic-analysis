import os
import re
import shutil
from util import group_files, fixpath, mkdir, run_matlab

# Use this prefix to filter out specific files. Set to "" to disable
PREFIX = "V2Rpp"

# Set names of your samples. A folder will be created for each of them. You can have either one or four
SAMPLES = ['A', 'B', 'C', 'D']


# Discover all input data files that match the given pattern
PTRN = rf"({PREFIX}.*_\d{{3}}).rawtraces"
raw_data_files = []
for f in os.listdir("data/rawtraces/"):
    m = re.match(PTRN, f)
    if m:
        raw_data_files.append(m.group(1))

# Group input files
GROUPED_FILES = group_files(raw_data_files)

rule test_matlab:
    input:
        "test.txt",
        "test2.txt"
    output:
        "data/abc/test_from_matlab.txt"
    run:
        mkdir(output)
        run_matlab("scripts/test.m", input, output, TXT="bye, world!")


rule all:
    input:
        expand("data/{sample}/autotrace/{group}_auto.traces", sample=SAMPLES, group=GROUPED_FILES.keys())

rule gettraces:
    input:
        tif="data/tif/{file}.tif"
    output:
        rt="data/rawtraces/{file}.rawtraces"
    run:
        mkdir(output)
        shutil.copy(input.tif, output.rt)

rule spots:
    input:
        rt="data/rawtraces/{file}.rawtraces"
    output:
        rt=expand("data/{sample}/rawtraces/{{file}}.rawtraces", sample=SAMPLES)
    run:
        mkdir(output.rt)

        if len(SAMPLES) == 1:  # don't run selectPrintedSpots
            print("One sample - skipping `selectPrintedSpots`")
            for f in output.rt:
                shutil.copy(input.rt, f)
        elif len(SAMPLES) == 4:
            print("Running `selectPrintedSpots`")
            for f in output.rt:
                shutil.copy(input.rt, f)
        else:
            raise ValueError(f"Check SAMPLES variable - it has {len(SAMPLES)} samples, but should be either one or four")

rule autotrace:
    input:
        rt=lambda wildcards: [f"data/{{sample}}/rawtraces/{g}.rawtraces" for g in GROUPED_FILES[wildcards.group]],
        criteria="data/conf/{sample}.mat"
    output:
        at="data/{sample}/autotrace/{group}_auto.traces"
    run:
        mkdir(output.at)

        txt = ""
        for f in input.rt:
            with open(f, 'r') as fh:
                txt += fh.read()
        with open(output.at, 'w') as fh:
            fh.write(txt)
