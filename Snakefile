import os
import re
import shutil
from util import group_files, fixpath, run_matlab, get_criteria_file, input4autotrace_each, input4combine_traces

configfile: "config.yaml"

# Sanity checks
SAMPLES = config["SAMPLES"]
SAMPLES = [SAMPLES] if isinstance(SAMPLES, str) else SAMPLES
config["SAMPLES"] = SAMPLES

assert len(SAMPLES) in [1, 4], f"You can have either one or four samples; you provided {len(SAMPLES)}: {SAMPLES}"

# Discover all input data files that match the given pattern
PTRN = rf"({config['PREFIX']}.*_\d{{3}}).rawtraces"
raw_data_files = []
for f in os.listdir("data/rawtraces/"):
    m = re.match(PTRN, f)
    if m:
        raw_data_files.append(m.group(1))

# Group input files
config["GROUPED_FILES"] = group_files(raw_data_files)


# Generate names of the target files
combined_traces_ptrn = "data/{sample}/combined_traces/{group}.traces"
combined_traces_target = expand(
            combined_traces_ptrn,
            sample=SAMPLES,
            group=config["GROUPED_FILES"].keys())

contour_plots_indiv_ptrn = "data/{sample}/plt_traces/{group}.{fmt}"
contour_plots_indiv_target = expand(contour_plots_indiv_ptrn,
            sample=SAMPLES,
            fmt=config["PLOTS"]['contour_formats'],
            group=config["GROUPED_FILES"].keys()) if config["PLOTS"]["contour_individual"] else []

contour_plots_combined_ptrn = "data/{sample}/plt_combined_traces/{group}.{fmt}"
contour_plots_combined_target = expand(contour_plots_combined_ptrn,
    sample = SAMPLES,
    fmt=config["PLOTS"]['contour_formats'],
    group =config["GROUPED_FILES"].keys()) if config["PLOTS"]["contour_combined"] else []

# Main rule that defines what we want to get in the end
rule all:
    input:
        combined_traces_target,
        "workflow_graph.png",
        contour_plots_indiv_target,
        contour_plots_combined_target



# Extraction of microarrayed spots
# This rule checks number of samples. If only one, it temporarily copies rawtraces to data/<sample>/rawtraces/.
# If there are multiple samples, the corresponding traces are extracted and saved under data/<sample_N>/rawtraces/
extract_samples_path = expand("data/{sample}/rawtraces/{{file}}.rawtraces", sample=SAMPLES)

if len(SAMPLES) == 1:
    # mark duplicates of rawtraces as temporary
    extract_samples_path = [temp(s) for s in extract_samples_path]

plots_folder = []
if config["PLOTS"]["extract_samples"] and len(SAMPLES) > 1:
    plots_folder = ["plt_extract_samples"]

rule extract_samples:
    input:
        "data/rawtraces/{file}.rawtraces"
    output:
        rawtraces = extract_samples_path,
        plt       = expand("data/{dir}/{{file}}.png", dir = plots_folder)
    run:
        if len(SAMPLES) == 1:
            shutil.copy(input[0], output.rt[0])
        else:
            run_matlab("scripts/extract_samples.m", input[0], output.rawtraces, PLT=fixpath(output.plt))


# Process each rawtraces file individually (1:1)
# Optional rule: see AUTOTRACE_EACH flag in config.yaml
rule autotrace_each:
    input:
        traces   = lambda wildcards: input4autotrace_each(wildcards, config),
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


# Combine all rawtraces or traces files within a group together (N:1)
rule combine_traces:
    input:
        traces   = lambda wildcards: input4combine_traces(wildcards, config),
        criteria = lambda wildcards: get_criteria_file(wildcards, "data/conf/{sample}.mat")
    output:
        combined_traces_ptrn
    run:
        run_matlab(
            script="scripts/combine_traces.m",
            input=input.traces,
            output=output[0],
            CRITERIA=fixpath(input.criteria)
        )


# Contour plots

rule contour_plots_individual:
    input:
        lambda wildcards: input4combine_traces(wildcards,config)
    output:
        contour_plots_indiv_ptrn
    run:
        print(output)
        run_matlab(
            script="scripts/make_contour_plots.m",
            input=input,
            output=output,
            N_FRAMES=int(config["PLOTS"]["contour_N_frames"])
        )

rule contour_plots_combined:
    input:
        lambda wildcards: f"data/{wildcards.sample}/combined_traces/{wildcards.group}.traces"
    output:
        contour_plots_combined_ptrn
    run:
        print(output)
        run_matlab(
            script="scripts/make_contour_plots.m",
            input=input,
            output=output,
            N_FRAMES=int(config["PLOTS"]["contour_N_frames"])
        )

# Create a graph of the workflow
rule workflow_graph:
    output:
        "workflow_graph.png"
    shell:
        """
        snakemake --dag | dot -Tpng > {output}
        """