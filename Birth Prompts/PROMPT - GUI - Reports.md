# Purpose

This page should display parametrizable graphical information about the expenses with a focus on spending per category.

# Principles

- The user should be able to choose the visualization object (pie, diagram, etc)
- The data should be displayed per customizable periods (current month, current quarter, current year or custom) - default `current month`
- The user should be able to see the amount spent either per merchant, category, category group or instrument (parameterizable) - default `category`
- The user should be able to compare the current aggregated amount of the selected period with (configurable):
    - previous iteration of the selected time period (e.g. if current month -> previous month)
    - average of all time spending for the selected aggregator (e.g. category) exluding the current period -> **default**
    - average for the selected aggregator and period based on `External` type of *HistoricalData* (only for category and category group aggregators) -> visible only if the setting `reports.assistedHistoricalData.enabled` is true
    - the comparison difference should be displayed in percentages and graphical logic should be employed to emphasize:
        - if it is greater (negative aspect, eg red color) or less (positve aspect, e.g. green color) than the compared period
        - the difference depth.. for example a small difference should be displayed with "lighter" color compared to the big difference ("stroner/deeper" color)
- The user should be able to see period data of more than 1 iterations (if he chooses to) -> for example, all months of the current year
   - the period iteration number should be configurable (e.g `4` months) -> default should be 1 (current month)
- The `HistoricalData` api should be used to retrive the data


