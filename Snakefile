from snakemake.io import directory

rule combine_traces:
    input:
        "data/A/traces/"
    output:
        directory("data/A/combined_traces/")
    params:
        SAMPLE="A"  # Parameter to pass to MATLAB
    run:
        import os
        print(output[0])
        os.makedirs(output[0], exist_ok=True)
        shell(f"matlab -nosplash -r \"SAMPLE='{params.SAMPLE}'; run('scripts/combine_traces.m'); exit;\"")