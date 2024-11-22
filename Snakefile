import os
from pathlib import Path
import matlab.engine  # Import MATLAB engine

input_dir = "data/A/traces/"
output_dir = "data/A/combined_traces/"

groups = sorted(set(Path(f).stem.split("_")[1] for f in os.listdir(input_dir) if f.endswith(".traces")))

rule all:
    input:
        expand(f"{output_dir}{{group}}.traces", group=groups)

rule combine_traces:
    input:
        lambda wildcards: sorted([f"{input_dir}{f}" for f in os.listdir(input_dir)
                                  if f.endswith(".traces") and f"_{wildcards.group}_" in f])
    output:
        f"{output_dir}{{group}}.traces"
    run:
        # Ensure the output directory exists
        os.makedirs(os.path.dirname(output[0]), exist_ok=True)

        # Start MATLAB engine (reuse or start if not already running)
        eng_sessions = matlab.engine.find_matlab()  # Check for existing MATLAB sessions
        if not eng_sessions:
            eng = matlab.engine.start_matlab()
        else:
            eng = matlab.engine.connect_matlab(eng_sessions[0])

        # Convert inputs and outputs
        input_files = [Path(os.path.abspath(f)).as_posix() for f in input]  # List of input file paths
        output_file = Path(os.path.abspath(output[0])).as_posix()           # Output file path

        # Assign variables to MATLAB workspace
        eng.workspace['INPUT_FILES'] = input_files
        eng.workspace['OUTPUT_FILE'] = output_file
        eng.workspace['CRITERIA'] = os.path.abspath("data/A/config/criteria.mat")

        # Call MATLAB script
        eng.eval(f"cd('{os.getcwd()}');",nargout=0)
        eng.eval("run('scripts/combine_traces.m');", nargout=0)

        # Optionally, close MATLAB session
        # eng.quit()
