rule combine_traces:
    input:
        "data/A/traces"  # Optional, if your script uses an input file
    output:
        "data/A/combined_traces"  # Optional, if your script generates an output file
    params:
        SAMPLE="A"  # Parameter to pass to MATLAB
    shell:
        """
        matlab -nodisplay -nosplash -r "SAMPLE='{params.SAMPLE}'; run('scripts/combine_traces.m'); exit;"
        """
