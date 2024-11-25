from pathlib import Path
import matlab.engine 
import os
import re
import shutil

# Use this prefix to filter out specific files. Set to "" to disable
PREFIX = "V2Rpp"

# Set names of your samples. A folder will be created for each of them. You can have either one or four
SAMPLES = ['A', 'B', 'C', 'D']
PTRN = rf"({PREFIX}.*_\d{{3}}).tif"

tifs = []
for f in os.listdir("data/tif/"):
    m = re.match(PTRN, f)
    if m:
        tifs.append(m.group(1))


#if True:
#    for s in SAMPLES:
#       with open(f"data/conf/criteria.mat", "w") as f:
#           f.write(s)

# Function to group files by unique base names
def group_files(files):
    groups = {}
    for file in files:
        # Extract base name by removing the last _###
        base_name = re.sub(r"_\d{3}$", "", file)
        groups.setdefault(base_name, []).append(file)
    return groups

# Create the groups
GROUPED_FILES = group_files(tifs)



def fixpath(files):
    """ fix file path(s) - convert to absolute & POSIX """
    fun = lambda f: Path(os.path.abspath(f)).as_posix()
    if isinstance(files, list):
        return [fun(f) for f in files]
    else:
        return fun(files)

def mkdir(files):
    files = files if isinstance(files, list) else [files]
    for f in files:
        os.makedirs(os.path.dirname(f), exist_ok=True)




rule all:
    input:
        # these are very final files we are trying to create
        #expand(f"data/{{sample}}/autotrace/{PREFIX}_auto.traces", sample=SAMPLES)
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
