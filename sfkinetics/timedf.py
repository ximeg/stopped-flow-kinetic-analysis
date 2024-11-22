from pandas import DataFrame

class TimeDF(DataFrame):
    """Pandas DataFrame representing time series. It has to have a column named 'time'"""
    def __init__(self, *args, **kwargs):
        super(TimeDF, self).__init__(*args, **kwargs)
        assert('time' in self.columns)

    def set_time_zero(self, t0):
        """ Shift time axis, so that t0 becomes t=0"""
        return TimeDF(self.assign(time = lambda df: df.time - t0))

    def from_to(self, t1, t2, margin=0):
        """ Return subset of time series falling between given time points t1 and t2"""
        t1 = t1 - margin
        t2 = t2 + margin
        return TimeDF(self.query(f"{t1} <= time and time <= {t2}"))
