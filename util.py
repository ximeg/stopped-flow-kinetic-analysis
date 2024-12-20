from pathlib import Path
import os
import re
import matlab.engine as me

def group_files(files):
    """
    Split intput files into groups. The group names are created by removing the trailing
    repeat number _### (from FlashGordon), then input files are grouped according to these names.
    """
    groups = {}
    for file in files:
        # Extract base name by removing the last _###
        base_name = re.sub(r"_\d{3}(\.\w+)?$", "", file)
        groups.setdefault(base_name, []).append(file)
    return groups


def input4autotrace_each(wildcards, config):
    """Generate the input file paths for autotrace_each"""
    # Collect all rawtraces if we need to run autotrace for each input file...
    if config["AUTOTRACE_EACH"]:
        return f"data/{wildcards.sample}/rawtraces/{wildcards.file}.rawtraces"
    else:
        # otherwise, there is nothing to do
        return ""


def input4combine_traces(wildcards, config):
    """Generate the input file paths for combine_traces"""
    grp = config["GROUPED_FILES"]
    # We have traces files, and just need to combine them
    filetype = "traces" if config["AUTOTRACE_EACH"] else "rawtraces"
    return [f"data/{wildcards.sample}/{filetype}/{g}.{filetype}" for g in grp[wildcards.group]]


def fixpath(files):
    """ Fix file path(s) - convert to absolute & POSIX """

    def to_posix(f):
        return Path(os.path.abspath(f)).as_posix()

    if isinstance(files, list):
        if len(files) == 1:
            return to_posix(files[0])
        return [to_posix(f) for f in files]
    else:
        return to_posix(files)


def get_criteria_file(wildcards, criteria_file):
    """
    Find autotrace criteria file using provided template and wildcards.
    If not found, return the default criteria file.
    :param wildcards: snakemake wildcards
    :param criteria_file: template filename, with wildcards in it
    :return: path to autotrace criteria file
    """
    criteria_file = criteria_file.format(**wildcards)
    if os.path.exists(criteria_file):
        # Use the override file if it exists
        return criteria_file
    else:
        # Fallback to default if the override does not exist
        return "resources/default_criteria.mat"


def run_matlab(script, input, output, **kwargs):
    eng_sessions = me.find_matlab()  # Check for existing MATLAB sessions
    if not eng_sessions:
        eng = me.start_matlab()
    else:
        eng = me.connect_matlab(eng_sessions[0])

    eng.workspace['INPUT'] = fixpath(input)
    eng.workspace['OUTPUT'] = fixpath(output)
    for key, value in kwargs.items():
        eng.workspace[key] = value

    eng.eval(f"run('{fixpath(script)}')", nargout=0)
