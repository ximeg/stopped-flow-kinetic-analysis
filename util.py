from pathlib import Path
import matlab.engine 
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
        base_name = re.sub(r"_\d{3}$", "", file)
        groups.setdefault(base_name, []).append(file)
    return groups


def fixpath(files):
    """ Fix file path(s) - convert to absolute & POSIX """
    fun = lambda f: Path(os.path.abspath(f)).as_posix()
    if isinstance(files, list):
        if len(files) == 1:
            return fun(files[0])
        return [fun(f) for f in files]
    else:
        return fun(files)


def mkdir(files):
    """ Create the directory structure for given file(s) """
    files = files if isinstance(files, list) else [files]
    for f in files:
        os.makedirs(os.path.dirname(fixpath(f)), exist_ok=True)


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


def run_matlab(script, input_files, output_files, **kwargs):
    eng_sessions = me.find_matlab()  # Check for existing MATLAB sessions
    if not eng_sessions:
        eng = matlab.engine.start_matlab()
    else:
        eng = matlab.engine.connect_matlab(eng_sessions[0])

    eng.workspace['INPUT'] = fixpath(input_files)
    eng.workspace['OUTPUT'] = fixpath(output_files)
    for key, value in kwargs.items():
        eng.workspace[key] = value

    eng.eval(f"run('{fixpath(script)}')", nargout=0)
