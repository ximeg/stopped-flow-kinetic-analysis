This folder contains everything related to one specific microarray sample A. You might have more folders (B, C, D, etc)
for other microarray samples. Each of them follows this structure:

A/
    config/
        criteria.mat    # autotrace selection criteria
        A.model         # batchkinetics model

    rawtraces/          # .rawtraces created with `selectprintedspots` script, then moved here
        V2Rpp_06uM_004_A.rawtraces
        V2Rpp_06uM_004_A.rawtraces
        V2Rpp_10uM_002_A.rawtraces

    traces/             # files created with `autotrace`
        V2Rpp_06uM_003_A_auto.traces        # traces filtered by `autotrace`
        V2Rpp_06uM_003_A_auto_gcorr.traces
        V2Rpp_06uM_004_A_auto.traces
        V2Rpp_06uM_004_A_auto_gcorr.traces
        V2Rpp_10uM_002_A_auto.traces
        V2Rpp_10uM_002_A_auto_gcorr.traces
        ...
    combined_traces/
        V2Rpp_06uM.traces       # all traces combined together
        V2Rpp_06uM.dwt          # dwell times of combined traces
        V2Rpp_06uM_idl.csv      # idealization data for kinetic analysis in Python
        V2Rpp_10uM.traces
        V2Rpp_10uM_idl.csv

    kinetics/           # output of kinetic analysis in Python
