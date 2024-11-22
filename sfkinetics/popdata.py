import numpy as np
import pandas as pd
from plotnine import ggplot, geom_line, aes, xlab, ylab


class PopData:
    def __init__(self, idealization_arr, exp_time=0.1, target_fret_state=3, photobleach_thresh=0.10):
        self.exp_time = exp_time
        self.idealization_arr = idealization_arr

        self.arr_target_state = np.where(self.idealization_arr == target_fret_state, 1, 0)
        self.N_target_state = self.arr_target_state.sum(axis=0)

        self.arr_any_state = np.where(self.idealization_arr >= 2, 1, 0)
        self.N_any_state = self.arr_any_state.sum(axis=0)

        self.N_traces = self.N_any_state.max()
        subset_ = np.where(self.N_any_state > photobleach_thresh * self.N_traces)

        # Shorten traces
        self.N_target_state = self.N_target_state[subset_]
        self.N_any_state = self.N_any_state[subset_]

        # Calculate state occupancy
        self.data = pd.DataFrame(columns=['i', 'C', 'time', 'state_occupancy'])
        self.data.state_occupancy = self.N_target_state / self.N_any_state
        self.data.time = np.arange(0, len(self.data)) * exp_time

    def gglayer(self):
        return [
            geom_line(aes(x='time', y='state_occupancy'), data=self.data),
            xlab("Time, s"),
            ylab("State occupancy"),
        ]

    def ggplot(self):
        plot = ggplot()
        for layer in self.gglayer():
            plot += layer
        return plot

    def __repr__(self):
        return  f"FRET state population based on {self.N_traces:,} traces\n" \
                f"{self.data.drop(columns=['i', 'C'])}"
