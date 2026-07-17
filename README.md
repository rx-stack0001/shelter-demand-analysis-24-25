# Toronto Shelter Occupancy and Capacity Analysis

**An independent data analytics project comparing Toronto's shelter system in 2024 and 2025 using SQL, Google BigQuery, and Power BI.**

## Project Overview

This project analyzes daily shelter occupancy and capacity data published by the City of Toronto.

The purpose of the project is to compare shelter use between 2024 and 2025 and identify changes in occupancy, capacity, service demand, population sectors, program types, and shelter providers.

The two annual datasets were loaded into Google BigQuery, combined and cleaned with SQL, and used to create a year-over-year analysis. The final results were presented in a Power BI dashboard.

## Research Questions

1. How did overall shelter occupancy change from 2024 to 2025?
2. Did the number of shelter programs and program days increase?
3. Which population sectors had the highest occupancy rates?
4. Were emergency programs more occupied than transitional programs?
5. How did shelter occupancy change by month?
6. Which overnight service types had the highest occupancy?
7. Which organizations handled the most service demand?
8. How often were shelter programs at or near full capacity?

## Findings

- Q1: The system got less crowded in 2025, because the City added space faster than demand grew. More programs were open in 2025 than in 2024, rising from 157 to 188, and the total number of program-days went up about 6%, from 48,794 to 51,543. But demand did not rise to match. The total number of service-user-days fell by about 6%, from 3.57 million to 3.36 million. As a result, average occupancy slipped from 98.4% to 96.1%. The share of program-days that were completely full (100% or more) fell from 83.6% to 73.7%, and the share that were full or nearly full (90% or more) fell from 95.4% to 89.0%. The system was still very tight, with most nights at or near capacity, but it was not as constantly full as it had been the year before.
  
- Q2: Every group saw a bit more breathing room, but the order stayed the same. Women's programs were the fullest in both years, easing from 99.6% to 97.8%. Youth programs were the least full, easing from 95.3% to 93.5%. Youth was also the only group where demand went up, rising about 10% in service-user-days, while demand fell for every other group.

- Q3: Emergency shelters stayed busier than transitional ones in both years. In 2025 they ran at 97.0% occupancy on average, compared with 92.7% for transitional programs.
- Q4: The same seasonal pattern showed up in both years. Occupancy rose through the late summer, reaching about 99% in August 2024, and dipped every December. Only 72.8% of program-days were full in December 2024, and 64.4% in December 2025. The dip happens because the City opens extra winter sites, which adds space. Across the two years, the 2025 line sat a little below the 2024 line.
- Q5: Motel and hotel shelters were the fullest and the steadiest, staying at about 99% in both years (99.5%, then 99.2%). Round-the-clock respite sites, women's drop-ins, and isolation or recovery sites were also very full, roughly 95% to 99%. Warming centres had the most space available, and they were the one type that got busier, rising from 88.7% to 91.6%. Newer overflow spaces (called Alternative Space Protocol) emptied out a lot, from 98.2% down to 73.1%, which fits the picture of the City adding backup space faster than it was needed.
- Q6: The same big providers carried most of the demand. The City of Toronto, Homes First Society, and COSTI Immigrant Services led in both years. Homes First's numbers dropped a fair amount, from 638,000 down to 485,000 service-user-days, while COSTI, the Salvation Army, and Fred Victor stayed about the same.
- Q7: Youth programs had the lowest occupancy overall, but they were also the most uneven. Youth had the lowest average occupancy of any group, yet its busiest programs were essentially full, around 99% to 100%. These included YMCA House, Horizons for Youth, Covenant House, and Kennedy House, all running about 10 points above the roughly 90% youth average. So the spare room in youth programs is spread unevenly. Some sites are packed while others have space.
- Q8: The mix of demand barely changed. Refugee programs stayed at about 29% of the total, moving only slightly from 29.5% in 2024 to 28.6% in 2025. The base shelter system edged up to 47.1%, and winter programs grew a little, from 2.1% to 2.8%.

Overall, Toronto's shelter system remained highly occupied in 2025, but capacity pressure was lower than in 2024.

## Data Source

### Daily Shelter and Overnight Service Occupancy and Capacity

- **Source:** City of Toronto Open Data
- **Years used:** 2024 and 2025
- **Coverage:** January 1, 2024 to December 31, 2025
- **2024 rows:** 48,794
- **2025 rows:** 51,543
- **Combined rows:** 100,337
- **Dataset page:** https://open.toronto.ca/dataset/daily-shelter-overnight-service-occupancy-capacity/

Each row represents one shelter program on one day.


## Methodology

1. **Data loading:** The 2024 and 2025 CSV files were uploaded into separate raw tables in Google BigQuery.
2. **Data review:** Column names, data types, missing values, and record counts were checked.
3. **Data combining:** The two yearly files were combined using UNION ALL.
4. **Data cleaning:** Extra spaces were removed, missing categories were labelled, and bed-based and room-based fields were combined.
5. **Feature creation:** New fields were created for year, month, year-month, capacity type, and capacity status.
6. **Data validation:** Duplicate records, missing dates, row counts, and occupancy values were reviewed.
7. **SQL analysis:** Queries were used to compare occupancy, demand, sectors, program models, service types, and organizations.
8. **Dashboard creation:** The cleaned data was exported and used to build a Power BI dashboard.

## Data Cleaning

The raw data reports capacity differently depending on the shelter program.

Some programs use beds, while others use rooms. To make the data easier to compare, the matching bed and room fields were combined into common columns for:

- Actual capacity
- Occupied spaces
- Occupancy rate

Further cleaning steps:

- Removing extra spaces from text fields
- Replacing missing location names with `Unknown`
- Replacing missing program model values with `Unknown`

## Capacity Status

A capacity status field was created to group each program day into one of three categories:

- **At Capacity:** Occupancy rate of 100 percent or higher
- **Near Capacity:** Occupancy rate from 90 percent to less than 100 percent
- **Available:** Occupancy rate below 90 percent

This field was used to measure how often shelter programs were full or close to full.

## Power BI Dashboard

[View the full Power BI dashboard PDF](shelter_dashboard.pdf)

The Power BI dashboard includes:

- Average occupancy rate
- Percentage of days at capacity
- Total service user days
- Total program days
- Monthly occupancy trend
- Occupancy by population sector
- Emergency and transitional program comparison
- Occupancy by overnight service type
- Demand by organization
- Demand by program area

The dashboard also includes filters for:

- Year
- Population sector
- Program model
- Month
- Location
- Capacity status

## How to Run

- Google Cloud account
- Google BigQuery
- Power BI Desktop
- The 2024 and 2025 shelter CSV files

## Notes and Limitations

- Service user totals represent service user days, not unique people.
- Occupancy rates can be above 100 percent when a program operates over its listed capacity.
- Hidden locations were labelled as `Unknown` and were not removed.
- The analysis describes patterns in the data but does not explain the cause of every change.

## License

This project is released for academic and educational purposes. Data sources keep their original licenses.

The source data is published by the City of Toronto under the Open Government Licence Toronto.

## Author

Ryan Xian

Honours Bachelor of Science in Statistics and Economics

University of Toronto
