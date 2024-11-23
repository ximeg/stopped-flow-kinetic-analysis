import os
from pathlib import Path
import matlab.engine  # Import MATLAB engine

traces_dir = "data/A/traces/"
combined_traces_dir = "data/A/combined_traces/"
idealized_traces_dir = "data/A/idealized_traces/"

groups = sorted(set(Path(f).stem.split("_")[1] for f in os.listdir(traces_dir) if f.endswith(".traces")))

rule all:
    input:
        expand(f"{idealized_traces_dir}{{group}}.csv", group=groups)

rule combine_traces:
    input:
        lambda wildcards: sorted([f"{traces_dir}{f}" for f in os.listdir(traces_dir)
                                  if f.endswith(".traces") and f"_{wildcards.group}_" in f])
    output:
        f"{combined_traces_dir}{{group}}.traces"
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


rule idealize_traces:
    input:
        lambda wildcards: f"{combined_traces_dir}{wildcards.group}.traces"
    output:
        f"{idealized_traces_dir}{{group}}.csv"
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
        input_file = Path(os.path.abspath(input[0])).as_posix()

        output_file = Path(os.path.abspath(output[0])).as_posix()           # Output file path

        # Assign variables to MATLAB workspace
        eng.workspace['INPUT_FILE'] = input_file
        eng.workspace['OUTPUT_FILE'] = output_file
        eng.workspace['MODEL'] = os.path.abspath("data/A/config/batchkinetics.model")

        # Call MATLAB script
        eng.eval(f"cd('{os.getcwd()}');",nargout=0)
        eng.eval("run('scripts/idealize_traces.m');", nargout=0)

        # Optionally, close MATLAB session
        # eng.quit()
