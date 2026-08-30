# Purpose

This page should display parametrizable graphical information about the expenses with a focus on spending per category.

# Principles

- The user should be able to choose the visualization object (pie, diagram, etc)
- The data should be displayed per customizable periods
    - the period unit should be month
    - the period iterations should be "Last" (the one before the current), "Spefic" (e.g. April 2026) or "Range" (e.g. Jan to March 2026)
- The user should be able to see the amount spent either per Merchant, Category, Category group, Instrument or Total (parameterizable) - default `category`
- The user should be able to compare the current aggregated amount of the selected period with (configurable):
    - previous iteration of the selected time period (e.g. if last month -> 1 month before last month) -> not available for period iteration type: "Last"
    - average of all time spending for the selected aggregator (e.g. category) and period unit -> **default**
    - average for the selected aggregator and period based on any external historical data profiles stored in `reports.assistedHistoricalDataProfiles` (only for category and category group aggregators)  --> not visible only if the setting does not contains any value
    - the comparison difference should be displayed in percentages and graphical logic should be employed to emphasize:
        - if it is greater (negative aspect, eg red color) or less (positve aspect, e.g. green color) than the compared period
        - the difference depth.. for example a small difference should be displayed with "lighter" color compared to the big difference ("stroner/deeper" color)
- The user should be able to see period data of more than 1 iterations (if he chooses to) -> for example, all months of the current year
   - the period iteration number should be configurable (e.g `4` months) -> default should be 1 (current month)
- The `AggregatedData` api should be used to retrive the data and the GUI should resolve the period type to a date range filter for the backend
- On the top of the page a relative message indicating the report amounts currency used should be displayed (_derived from `settings.reports.dataCountryProfile`_)


