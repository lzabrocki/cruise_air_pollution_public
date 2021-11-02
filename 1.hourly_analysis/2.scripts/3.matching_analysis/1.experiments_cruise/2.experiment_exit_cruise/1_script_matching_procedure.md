---
title: "Matching Procedure - Exiting Cruise Experiment"
description: |
  Comparing hours with exiting cruise traffic to hours without. Adjusting for calendar and weather indicators.
author:
  - name: Marie-Abèle Bind 
    url: https://scholar.harvard.edu/marie-abele
    affiliation: Biostatistics Center, Massachusetts General Hospital
    affiliation_url: https://biostatistics.massgeneral.org/faculty/marie-abele-bind-phd/
  - name: Marion Leroutier 
    url: https://www.parisschoolofeconomics.eu/en/leroutier-marion/work-in-progress/
    affiliation: Misum, Stockholm School of Economics
    affiliation_url: https://www.hhs.se/en/persons/l/leroutier-marion/
  - name: Léo Zabrocki 
    url: https://lzabrocki.github.io/
    affiliation: Paris School of Economics
    affiliation_url: https://www.parisschoolofeconomics.eu/fr/zabrocki-leo/
date: "2021-11-02"
output: 
    distill::distill_article:
      keep_md: true
      toc: true
      toc_depth: 2
---

<style>
body {
text-align: justify}
</style>

In this document, we provide all steps required to reproduce our matching procedure. We compare hours where:

* treated units are hours with positive exiting cruise traffic in t.
* control units are hours without exiting cruise traffic in t.

We adjust for calendar calendar indicator and weather confouding factors.

**Should you have any questions, need help to reproduce the analysis or find coding errors, please do not hesitate to contact us at leo.zabrocki@psemail.eu and marion.leroutier@psemail.eu.**

# Required Packages

To reproduce exactly the `1_script_matching_procedure.html` document, we first need to have installed:

* the [R](https://www.r-project.org/) programming language 
* [RStudio](https://rstudio.com/), an integrated development environment for R, which will allow you to knit the `1_script_matching_procedure.Rmd` file and interact with the R code chunks
* the [R Markdown](https://rmarkdown.rstudio.com/) package
* and the [Distill](https://rstudio.github.io/distill/) package which provides the template for this document. 

Once everything is set up, we have to load the following packages:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># load required packages</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://yihui.org/knitr/'>knitr</a></span><span class='op'>)</span> <span class='co'># for creating the R Markdown document</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://here.r-lib.org/'>here</a></span><span class='op'>)</span> <span class='co'># for files paths organization</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://tidyverse.tidyverse.org'>tidyverse</a></span><span class='op'>)</span> <span class='co'># for data manipulation and visualization</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='http://www.rcpp.org'>Rcpp</a></span><span class='op'>)</span> <span class='co'># for running the matching algorithm</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://github.com/markmfredrickson/optmatch'>optmatch</a></span><span class='op'>)</span> <span class='co'># for matching pairs</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://igraph.org'>igraph</a></span><span class='op'>)</span> <span class='co'># for pair matching via bipartite maximal weighted matching</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='http://www.rforge.net/Cairo/'>Cairo</a></span><span class='op'>)</span> <span class='co'># for printing customed police of graphs</span>
</code></pre></div>

</div>


We load the `script_time_series_matching_function.R` located in the *3.matching_analysis/0.script_matching_algorithm* folder and which provides the functions used for our matching procedure:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># command to overcome the Rcpp pakage error that forbids the compilation of the .Rmd file</span>
<span class='fu'><a href='https://rdrr.io/r/base/Sys.setenv.html'>Sys.setenv</a></span><span class='op'>(</span>PATH <span class='op'>=</span> <span class='st'>"%PATH%;C:/Rtools/gcc-4.6.3/bin;c:/Rtools/bin"</span><span class='op'>)</span>
<span class='co'># load matching functions</span>
<span class='kw'><a href='https://rdrr.io/r/base/source.html'>source</a></span><span class='op'>(</span>
  <span class='fu'>here</span><span class='fu'>::</span><span class='fu'><a href='https://here.r-lib.org//reference/here.html'>here</a></span><span class='op'>(</span>
    <span class='st'>"2.scripts"</span>,
    <span class='st'>"3.matching_analysis"</span>,
    <span class='st'>"0.script_matching_algorithm"</span>,
    <span class='st'>"script_time_series_matching_function.R"</span>
  <span class='op'>)</span>
<span class='op'>)</span>
</code></pre></div>

</div>


We use a custom `ggplot2` theme for graphs:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># load ggplot customed theme</span>
<span class='kw'><a href='https://rdrr.io/r/base/source.html'>source</a></span><span class='op'>(</span>
  <span class='fu'>here</span><span class='fu'>::</span><span class='fu'><a href='https://here.r-lib.org//reference/here.html'>here</a></span><span class='op'>(</span>
    <span class='st'>"2.scripts"</span>,
    <span class='st'>"4.custom_ggplot2_theme"</span>,
    <span class='st'>"script_custom_ggplot_theme.R"</span>
  <span class='op'>)</span>
<span class='op'>)</span>
</code></pre></div>

</div>


The theme is based on the fantastic [hrbrthemes](https://hrbrmstr.github.io/hrbrthemes/index.html) package. If you do not want to use this theme or are unable to install it because of fonts issues, you can use the `theme_bw()` already included in the `ggplot2` package.

Finally, the matching procedure at the **hourly** level is computationally demanding and we could not run it on our local computer. Instead, we set up an RStudio version on Amazon Web Service EC2 and use a t3.2xlarge computer.

# Preparing the Data for Matching

### Selecting and Creating Relevant Variables

First, we load the data: 

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># load data</span>
<span class='va'>data_all_years</span> <span class='op'>&lt;-</span>
  <span class='fu'><a href='https://rdrr.io/r/base/readRDS.html'>readRDS</a></span><span class='op'>(</span>
    <span class='fu'>here</span><span class='fu'>::</span><span class='fu'><a href='https://here.r-lib.org//reference/here.html'>here</a></span><span class='op'>(</span>
      <span class='st'>"1.data"</span>,
      <span class='st'>"2.data_for_analysis"</span>,
      <span class='st'>"0.main_data"</span>,
      <span class='st'>"data_for_analysis_hourly.RDS"</span>
    <span class='op'>)</span>
  <span class='op'>)</span>
</code></pre></div>

</div>


Then, we select relevant variables for matching and create the **processed_data**:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># select relevant variables</span>
<span class='va'>relevant_variables</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span>
  <span class='co'># date variable</span>
  <span class='st'>"date"</span>,
  <span class='co'># air pollutants variables</span>
  <span class='st'>"mean_no2_l"</span>,
  <span class='st'>"mean_no2_sl"</span>,
  <span class='st'>"mean_pm10_l"</span>,
  <span class='st'>"mean_pm10_sl"</span>,
  <span class='st'>"mean_pm25_l"</span>,
  <span class='st'>"mean_so2_l"</span>,
  <span class='st'>"mean_o3_l"</span>,
  <span class='co'># total gross tonnage</span>
  <span class='st'>"total_gross_tonnage"</span>,
  <span class='st'>"total_gross_tonnage_entry"</span>,
  <span class='st'>"total_gross_tonnage_exit"</span>,
  <span class='st'>"total_gross_tonnage_other_vessels"</span>,
  <span class='st'>"total_gross_tonnage_cruise"</span>,
  <span class='st'>"total_gross_tonnage_ferry"</span>,
  <span class='st'>"total_gross_tonnage_entry_cruise"</span>,
  <span class='st'>"total_gross_tonnage_entry_ferry"</span>,
  <span class='st'>"total_gross_tonnage_entry_other_vessels"</span>,
  <span class='st'>"total_gross_tonnage_exit_cruise"</span>,
  <span class='st'>"total_gross_tonnage_exit_ferry"</span>,
  <span class='st'>"total_gross_tonnage_exit_other_vessels"</span>,
  <span class='co'># weather factors</span>
  <span class='st'>"temperature_average"</span>,
  <span class='st'>"rainfall_height_dummy"</span>,
  <span class='st'>"humidity_average"</span>,
  <span class='st'>"wind_speed"</span>,
  <span class='st'>"wind_direction_categories"</span>,
  <span class='st'>"wind_direction_east_west"</span>,
  <span class='co'># road traffic variables</span>
  <span class='st'>"road_traffic_flow"</span>,
  <span class='co'># calendar data</span>
  <span class='st'>"hour"</span>,
  <span class='st'>"day_index"</span>,
  <span class='st'>"weekday"</span>,
  <span class='st'>"holidays_dummy"</span>,
  <span class='st'>"bank_day_dummy"</span>,
  <span class='st'>"month"</span>,
  <span class='st'>"year"</span>
<span class='op'>)</span>

<span class='co'># create processed_data with the relevant variables</span>
<span class='kw'>if</span> <span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/exists.html'>exists</a></span><span class='op'>(</span><span class='st'>"relevant_variables"</span><span class='op'>)</span> <span class='op'>&amp;&amp;</span> <span class='op'>!</span><span class='fu'><a href='https://rdrr.io/r/base/NULL.html'>is.null</a></span><span class='op'>(</span><span class='va'>relevant_variables</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>{</span>
  <span class='co'># extract relevant variables (if specified)</span>
  <span class='va'>processed_data</span> <span class='op'>=</span> <span class='va'>data_all_years</span><span class='op'>[</span><span class='va'>relevant_variables</span><span class='op'>]</span>
<span class='op'>}</span> <span class='kw'>else</span> <span class='op'>{</span>
  <span class='va'>processed_data</span> <span class='op'>=</span> <span class='va'>data_all_years</span>
<span class='op'>}</span>
</code></pre></div>

</div>


For each covariate, we create the 0-3 hourly lags and leads:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># we first define processed_data_leads and processed_data_lags</span>
<span class='co'># to store leads and lags</span>

<span class='va'>processed_data_leads</span> <span class='op'>&lt;-</span> <span class='va'>processed_data</span>
<span class='va'>processed_data_lags</span> <span class='op'>&lt;-</span> <span class='va'>processed_data</span>

<span class='co'>#</span>
<span class='co'># create leads</span>
<span class='co'># </span>

<span class='co'># create a list to store dataframe of leads</span>
<span class='va'>leads_list</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/vector.html'>vector</a></span><span class='op'>(</span>mode <span class='op'>=</span> <span class='st'>"list"</span>, length <span class='op'>=</span> <span class='fl'>3</span><span class='op'>)</span>
<span class='fu'><a href='https://rdrr.io/r/base/names.html'>names</a></span><span class='op'>(</span><span class='va'>leads_list</span><span class='op'>)</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fl'>1</span><span class='op'>:</span><span class='fl'>3</span><span class='op'>)</span> 

<span class='co'># create the leads</span>
<span class='kw'>for</span><span class='op'>(</span><span class='va'>i</span> <span class='kw'>in</span> <span class='fl'>1</span><span class='op'>:</span><span class='fl'>3</span><span class='op'>)</span><span class='op'>{</span>
  <span class='va'>leads_list</span><span class='op'>[[</span><span class='va'>i</span><span class='op'>]</span><span class='op'>]</span> <span class='op'>&lt;-</span> <span class='va'>processed_data_leads</span> <span class='op'>%&gt;%</span>
    <span class='fu'>mutate_at</span><span class='op'>(</span><span class='fu'>vars</span><span class='op'>(</span><span class='op'>-</span><span class='va'>date</span><span class='op'>)</span>, <span class='op'>~</span>  <span class='fu'>lead</span><span class='op'>(</span><span class='va'>.</span>, n <span class='op'>=</span> <span class='va'>i</span>, order_by <span class='op'>=</span> <span class='va'>date</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>rename_at</span><span class='op'>(</span><span class='fu'>vars</span><span class='op'>(</span><span class='op'>-</span><span class='va'>date</span><span class='op'>)</span>,<span class='kw'>function</span><span class='op'>(</span><span class='va'>x</span><span class='op'>)</span> <span class='fu'><a href='https://rdrr.io/r/base/paste.html'>paste0</a></span><span class='op'>(</span><span class='va'>x</span>,<span class='st'>"_lead_"</span>, <span class='va'>i</span><span class='op'>)</span><span class='op'>)</span>
<span class='op'>}</span>

<span class='co'># merge the dataframes of leads</span>
<span class='va'>data_leads</span> <span class='op'>&lt;-</span> <span class='va'>leads_list</span> <span class='op'>%&gt;%</span>
  <span class='fu'>reduce</span><span class='op'>(</span><span class='va'>left_join</span>, by <span class='op'>=</span> <span class='st'>"date"</span><span class='op'>)</span>

<span class='co'># merge the leads with the processed_data_leads</span>
<span class='va'>processed_data_leads</span> <span class='op'>&lt;-</span> <span class='fu'>left_join</span><span class='op'>(</span><span class='va'>processed_data_leads</span>, <span class='va'>data_leads</span>, by <span class='op'>=</span> <span class='st'>"date"</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>select</span><span class='op'>(</span><span class='op'>-</span><span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='va'>mean_no2_l</span><span class='op'>:</span><span class='va'>year</span><span class='op'>)</span><span class='op'>)</span>

<span class='co'>#</span>
<span class='co'># create lags</span>
<span class='co'># </span>

<span class='co'># create a list to store dataframe of lags</span>
<span class='va'>lags_list</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/vector.html'>vector</a></span><span class='op'>(</span>mode <span class='op'>=</span> <span class='st'>"list"</span>, length <span class='op'>=</span> <span class='fl'>3</span><span class='op'>)</span>
<span class='fu'><a href='https://rdrr.io/r/base/names.html'>names</a></span><span class='op'>(</span><span class='va'>lags_list</span><span class='op'>)</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fl'>1</span><span class='op'>:</span><span class='fl'>3</span><span class='op'>)</span> 

<span class='co'># create the lags</span>
<span class='kw'>for</span><span class='op'>(</span><span class='va'>i</span> <span class='kw'>in</span> <span class='fl'>1</span><span class='op'>:</span><span class='fl'>3</span><span class='op'>)</span><span class='op'>{</span>
  <span class='va'>lags_list</span><span class='op'>[[</span><span class='va'>i</span><span class='op'>]</span><span class='op'>]</span> <span class='op'>&lt;-</span> <span class='va'>processed_data_lags</span> <span class='op'>%&gt;%</span>
    <span class='fu'>mutate_at</span><span class='op'>(</span><span class='fu'>vars</span><span class='op'>(</span><span class='op'>-</span><span class='va'>date</span><span class='op'>)</span>, <span class='op'>~</span>  <span class='fu'><a href='https://rdrr.io/r/stats/lag.html'>lag</a></span><span class='op'>(</span><span class='va'>.</span>, n <span class='op'>=</span> <span class='va'>i</span>, order_by <span class='op'>=</span> <span class='va'>date</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>rename_at</span><span class='op'>(</span><span class='fu'>vars</span><span class='op'>(</span><span class='op'>-</span><span class='va'>date</span><span class='op'>)</span>,<span class='kw'>function</span><span class='op'>(</span><span class='va'>x</span><span class='op'>)</span> <span class='fu'><a href='https://rdrr.io/r/base/paste.html'>paste0</a></span><span class='op'>(</span><span class='va'>x</span>,<span class='st'>"_lag_"</span>, <span class='va'>i</span><span class='op'>)</span><span class='op'>)</span>
<span class='op'>}</span>

<span class='co'># merge the dataframes of lags</span>
<span class='va'>data_lags</span> <span class='op'>&lt;-</span> <span class='va'>lags_list</span> <span class='op'>%&gt;%</span>
  <span class='fu'>reduce</span><span class='op'>(</span><span class='va'>left_join</span>, by <span class='op'>=</span> <span class='st'>"date"</span><span class='op'>)</span>

<span class='co'># merge the lags with the initial processed_data_lags</span>
<span class='va'>processed_data_lags</span> <span class='op'>&lt;-</span> <span class='fu'>left_join</span><span class='op'>(</span><span class='va'>processed_data_lags</span>, <span class='va'>data_lags</span>, by <span class='op'>=</span> <span class='st'>"date"</span><span class='op'>)</span>

<span class='co'>#</span>
<span class='co'># merge processed_data_leads with processed_data_lags</span>
<span class='co'>#</span>

<span class='va'>processed_data</span> <span class='op'>&lt;-</span> <span class='fu'>left_join</span><span class='op'>(</span><span class='va'>processed_data_lags</span>, <span class='va'>processed_data_leads</span>, by <span class='op'>=</span> <span class='st'>"date"</span><span class='op'>)</span>
</code></pre></div>

</div>


We can now define the hypothetical experiment that we would like to investigate.

### Defining the Hypothetical Experiment

We defined our potential experiments such that:* treated units are hours with positive exiting cruise traffic in t.
* control units are hours without exiting cruise traffic in t.

Below are the required steps to select the corresponding treated and control units whose observations are stored in the **
matching_data ** :

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># construct treatment assigment variable</span>
<span class='va'>processed_data</span> <span class='op'>&lt;-</span> <span class='va'>processed_data</span> <span class='op'>%&gt;%</span> 
  <span class='fu'>mutate</span><span class='op'>(</span>is_treated <span class='op'>=</span> <span class='cn'>NA</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='co'># the hour is defined as treated if there was positive exiting cruise traffic in t</span>
  <span class='fu'>mutate</span><span class='op'>(</span>is_treated <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='op'>(</span><span class='va'>total_gross_tonnage_exit_cruise</span> <span class='op'>&gt;</span> <span class='fl'>0</span>, <span class='cn'>TRUE</span>, <span class='va'>is_treated</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span> 
  <span class='co'># the hour is defined as treated if there was no exiting cruise traffic in t</span>
  <span class='fu'>mutate</span><span class='op'>(</span>is_treated <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='op'>(</span><span class='va'>total_gross_tonnage_exit_cruise</span> <span class='op'>==</span> <span class='fl'>0</span>, <span class='cn'>FALSE</span>, <span class='va'>is_treated</span><span class='op'>)</span><span class='op'>)</span>

<span class='co'># remove the hours for which assignment is undefined</span>
<span class='va'>matching_data_all_years</span> <span class='op'>=</span> <span class='va'>processed_data</span><span class='op'>[</span><span class='op'>!</span><span class='fu'><a href='https://rdrr.io/r/base/NA.html'>is.na</a></span><span class='op'>(</span><span class='va'>processed_data</span><span class='op'>$</span><span class='va'>is_treated</span><span class='op'>)</span>, <span class='op'>]</span>

<span class='co'># susbet treated and control units</span>
<span class='va'>treated_units</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/subset.html'>subset</a></span><span class='op'>(</span><span class='va'>matching_data_all_years</span>, <span class='va'>is_treated</span><span class='op'>)</span>
<span class='va'>control_units</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/subset.html'>subset</a></span><span class='op'>(</span><span class='va'>matching_data_all_years</span>, <span class='op'>!</span><span class='va'>is_treated</span><span class='op'>)</span>
<span class='va'>N_treated</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='op'>(</span><span class='va'>treated_units</span><span class='op'>)</span> <span class='co'># gives the total number of treated units for all years</span>
<span class='va'>N_control</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='op'>(</span><span class='va'>control_units</span><span class='op'>)</span> <span class='co'># gives the total number of control units for all years</span>

<span class='co'># save matching_data_all_years</span>
<span class='fu'><a href='https://rdrr.io/r/base/readRDS.html'>saveRDS</a></span><span class='op'>(</span>
<span class='va'>matching_data_all_years</span>,
<span class='fu'>here</span><span class='fu'>::</span><span class='fu'><a href='https://here.r-lib.org//reference/here.html'>here</a></span><span class='op'>(</span>
<span class='st'>"1.data"</span>,
<span class='st'>"2.data_for_analysis"</span>,
<span class='st'>"1.matched_data"</span>,
<span class='st'>"1.experiments_cruise"</span>,
<span class='st'>"2.experiment_exit_cruise"</span>,
<span class='st'>"matching_data.rds"</span>
<span class='op'>)</span>
<span class='op'>)</span>
</code></pre></div>

</div>


There are 4037 treated units and  92393 control units. 

# Matching Procedure

### Define Thresholds for Matching Covariates

Now that treated and control units have been defined, we need to set the thresholds values for the matching algorithm. For the hour, day of the day, holidays and bank days indicators, we force treated and control units to have the same values at t, t-1 and t-2. To limit differences in a pollutant's concentration between treated and controls units that could be due to seasonality, the treated and controls units cannot be further apart than 30 days. We also adjust for weather counfounding variables : for our most flexible thresholds, we allow a discrepency between a treated and control unit up to half a standard deviation.

Below is the code to define the relevant thresholds:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># we create the scaling list as it is needed for running the algorithm</span>
<span class='co'># but we do not use it</span>

<span class='va'>scaling</span> <span class='op'>=</span>  <span class='fu'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='op'>(</span><span class='fl'>1</span><span class='op'>)</span>,<span class='fu'><a href='https://rdrr.io/r/base/nrow.html'>ncol</a></span><span class='op'>(</span><span class='va'>matching_data_all_years</span><span class='op'>)</span><span class='op'>)</span>
<span class='fu'><a href='https://rdrr.io/r/base/names.html'>names</a></span><span class='op'>(</span><span class='va'>scaling</span><span class='op'>)</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/colnames.html'>colnames</a></span><span class='op'>(</span><span class='va'>matching_data_all_years</span><span class='op'>)</span>

<span class='co'># instead, we manually defined the threshold for each covariate</span>
<span class='va'>thresholds</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='op'>(</span><span class='cn'>Inf</span><span class='op'>)</span>,<span class='fu'><a href='https://rdrr.io/r/base/nrow.html'>ncol</a></span><span class='op'>(</span><span class='va'>matching_data_all_years</span><span class='op'>)</span><span class='op'>)</span>
<span class='fu'><a href='https://rdrr.io/r/base/names.html'>names</a></span><span class='op'>(</span><span class='va'>thresholds</span><span class='op'>)</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/colnames.html'>colnames</a></span><span class='op'>(</span><span class='va'>matching_data_all_years</span><span class='op'>)</span>

<span class='co'># threshold for hour</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>hour</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>hour_lag_1</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>hour_lag_2</span> <span class='op'>=</span> <span class='fl'>0</span>

<span class='co'># threshold for weekday</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>weekday</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>weekday_lag_1</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>weekday_lag_2</span> <span class='op'>=</span> <span class='fl'>0</span>

<span class='co'># threshold for holidays</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>holidays_dummy</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>holidays_dummy_lag_1</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>holidays_dummy_lag_2</span> <span class='op'>=</span> <span class='fl'>0</span>

<span class='co'># threshold for bank days</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>bank_day_dummy</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>bank_day_dummy_lag_1</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>bank_day_dummy_lag_2</span> <span class='op'>=</span> <span class='fl'>0</span>

<span class='co'># threshold for distance in days (day_index variable)</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>day_index</span> <span class='op'>=</span> <span class='fl'>30</span>

<span class='co'># thresholds for rainfall dummy</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>rainfall_height_dummy</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholdsrainfall_height_dummy_lag_1</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>rainfall_height_dummy_lag_2</span> <span class='op'>=</span> <span class='fl'>0</span>

<span class='co'># thresholds for average humidity</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>humidity_average</span> <span class='op'>=</span> <span class='fl'>9</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>humidity_average_lag_1</span> <span class='op'>=</span> <span class='fl'>9</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>humidity_average_lag_2</span> <span class='op'>=</span> <span class='fl'>9</span>

<span class='co'># thresholds for temperature average</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>temperature_average</span> <span class='op'>=</span> <span class='fl'>4</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>temperature_average_lag_1</span> <span class='op'>=</span> <span class='fl'>4</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>temperature_average_lag_2</span> <span class='op'>=</span> <span class='fl'>4</span>

<span class='co'># thresholds for wind direction categories</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>wind_direction_east_west</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>wind_direction_east_west_lag_1</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>wind_direction_east_west_lag_2</span> <span class='op'>=</span> <span class='fl'>0</span>

<span class='co'># thresholds for wind speed</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>wind_speed</span> <span class='op'>=</span> <span class='fl'>1.8</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>wind_speed_lag_1</span> <span class='op'>=</span> <span class='fl'>1.8</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>wind_speed_lag_2</span> <span class='op'>=</span> <span class='fl'>1.8</span>
</code></pre></div>

</div>


### Running the Procedure

Once the thresholds values have been set, we can run the time series matching algorithm. Unfortunately, with 96430 observations, the matching procedure requires large computer power. We rented an Amazon Web Services virtual computer (EC2 t3.2xlarge) and even with this computation power, we had to run the matching on each year separetely. We proceeded as follows using a loop for each year:

* we loaded the data and prepare them for the matching procedure by defining treated and control units and setting up the thresholds values.
* we computed for each year the discrepancy matrix and ran the matching algorithm
* for somes cases, several controls units were matched to a treatment unit. We use the `igraph` package to force pair matching via bipartite maximal weighted matching.
* we saved each matched yearly file and merged them into a signle file with all years.

Below is the full code that we ran on the AWS EC2 t3.2xlarge computer:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'>#--------------------------------------------------------------------</span>

<span class='co'># SCRIPT: TIME SERIES MATCHING IN AWS FOR EXITING CRUISE EXPERIMENT</span>

<span class='co'>#--------------------------------------------------------------------</span>

<span class='co'># load required packages</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://tidyverse.tidyverse.org'>tidyverse</a></span><span class='op'>)</span> <span class='co'># for data manipulation and visualization</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='http://www.rcpp.org'>Rcpp</a></span><span class='op'>)</span> <span class='co'># for running the matching algorithm</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://github.com/markmfredrickson/optmatch'>optmatch</a></span><span class='op'>)</span> <span class='co'># for matching pairs</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://igraph.org'>igraph</a></span><span class='op'>)</span> <span class='co'># for pair matching via bipartite maximal weighted matching</span>

<span class='co'># load matching functions</span>
<span class='kw'><a href='https://rdrr.io/r/base/source.html'>source</a></span><span class='op'>(</span><span class='st'>"~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/2.scripts/3.matching_analysis/0.script_matching_algorithm/script_time_series_matching_function.R"</span><span class='op'>)</span>

<span class='co'># load data</span>
<span class='va'>data_all_years</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/readRDS.html'>readRDS</a></span><span class='op'>(</span><span class='st'>"~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/1.data/2.data_for_analysis/0.main_data/data_for_analysis_hourly.RDS"</span><span class='op'>)</span>

<span class='co'>#-------------------------------------------------------------</span>

<span class='co'># SETTING UP THE DATA FOR MATCHING</span>

<span class='co'>#-------------------------------------------------------------</span>

<span class='co'># select relevant variables</span>
<span class='va'>relevant_variables</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span>
  <span class='co'># date variable</span>
  <span class='st'>"date"</span>, 
  <span class='co'># air pollutants variables</span>
  <span class='st'>"mean_no2_l"</span>, <span class='st'>"mean_no2_sl"</span>, <span class='st'>"mean_pm10_l"</span>, <span class='st'>"mean_pm10_sl"</span>, <span class='st'>"mean_pm25_l"</span>, <span class='st'>"mean_so2_l"</span>, <span class='st'>"mean_o3_l"</span>,
  <span class='co'># total gross tonnage</span>
  <span class='st'>"total_gross_tonnage"</span>, <span class='st'>"total_gross_tonnage_entry"</span>, <span class='st'>"total_gross_tonnage_exit"</span>,
  <span class='st'>"total_gross_tonnage_other_vessels"</span>, <span class='st'>"total_gross_tonnage_cruise"</span>, <span class='st'>"total_gross_tonnage_ferry"</span>,
  <span class='st'>"total_gross_tonnage_entry_cruise"</span>, <span class='st'>"total_gross_tonnage_entry_ferry"</span>, <span class='st'>"total_gross_tonnage_entry_other_vessels"</span>,
  <span class='st'>"total_gross_tonnage_exit_cruise"</span>, <span class='st'>"total_gross_tonnage_exit_ferry"</span>, <span class='st'>"total_gross_tonnage_exit_other_vessels"</span>,
  <span class='co'># weather factors</span>
  <span class='st'>"temperature_average"</span>, <span class='st'>"rainfall_height_dummy"</span>, <span class='st'>"humidity_average"</span>, <span class='st'>"wind_speed"</span>, <span class='st'>"wind_direction_categories"</span>, <span class='st'>"wind_direction_east_west"</span>,
  <span class='co'># road traffic flow</span>
  <span class='st'>"road_traffic_flow"</span>,
  <span class='co'># calendar data</span>
  <span class='st'>"hour"</span>, <span class='st'>"day_index"</span>, <span class='st'>"weekday"</span>, <span class='st'>"holidays_dummy"</span>, <span class='st'>"bank_day_dummy"</span>, <span class='st'>"month"</span>, <span class='st'>"year"</span><span class='op'>)</span>

<span class='co'># create processed_data with the relevant variables</span>
<span class='kw'>if</span> <span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/exists.html'>exists</a></span><span class='op'>(</span><span class='st'>"relevant_variables"</span><span class='op'>)</span> <span class='op'>&amp;&amp;</span> <span class='op'>!</span><span class='fu'><a href='https://rdrr.io/r/base/NULL.html'>is.null</a></span><span class='op'>(</span><span class='va'>relevant_variables</span><span class='op'>)</span><span class='op'>)</span><span class='op'>{</span>
  <span class='co'># extract relevant variables (if specified)</span>
  <span class='va'>processed_data</span> <span class='op'>=</span> <span class='va'>data_all_years</span><span class='op'>[</span><span class='va'>relevant_variables</span><span class='op'>]</span>
<span class='op'>}</span> <span class='kw'>else</span> <span class='op'>{</span>
  <span class='va'>processed_data</span> <span class='op'>=</span> <span class='va'>data_all_years</span>
<span class='op'>}</span>


<span class='co'>#-----------------------------------------------------------------------------------------------------------</span>

<span class='co'># CREATING LAGS AND LEAGS </span>

<span class='co'>#-----------------------------------------------------------------------------------------------------------</span>

<span class='co'># we first define processed_data_leads and processed_data_lags</span>
<span class='co'># to store leads and lags</span>

<span class='va'>processed_data_leads</span> <span class='op'>&lt;-</span> <span class='va'>processed_data</span>
<span class='va'>processed_data_lags</span> <span class='op'>&lt;-</span> <span class='va'>processed_data</span>

<span class='co'>#</span>
<span class='co'># create leads</span>
<span class='co'># </span>

<span class='co'># create a list to store dataframe of leads</span>
<span class='va'>leads_list</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/vector.html'>vector</a></span><span class='op'>(</span>mode <span class='op'>=</span> <span class='st'>"list"</span>, length <span class='op'>=</span> <span class='fl'>3</span><span class='op'>)</span>
<span class='fu'><a href='https://rdrr.io/r/base/names.html'>names</a></span><span class='op'>(</span><span class='va'>leads_list</span><span class='op'>)</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fl'>1</span><span class='op'>:</span><span class='fl'>3</span><span class='op'>)</span> 

<span class='co'># create the leads</span>
<span class='kw'>for</span><span class='op'>(</span><span class='va'>i</span> <span class='kw'>in</span> <span class='fl'>1</span><span class='op'>:</span><span class='fl'>3</span><span class='op'>)</span><span class='op'>{</span>
  <span class='va'>leads_list</span><span class='op'>[[</span><span class='va'>i</span><span class='op'>]</span><span class='op'>]</span> <span class='op'>&lt;-</span> <span class='va'>processed_data_leads</span> <span class='op'>%&gt;%</span>
    <span class='fu'>mutate_at</span><span class='op'>(</span><span class='fu'>vars</span><span class='op'>(</span><span class='op'>-</span><span class='va'>date</span><span class='op'>)</span>, <span class='op'>~</span>  <span class='fu'>lead</span><span class='op'>(</span><span class='va'>.</span>, n <span class='op'>=</span> <span class='va'>i</span>, order_by <span class='op'>=</span> <span class='va'>date</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>rename_at</span><span class='op'>(</span><span class='fu'>vars</span><span class='op'>(</span><span class='op'>-</span><span class='va'>date</span><span class='op'>)</span>,<span class='kw'>function</span><span class='op'>(</span><span class='va'>x</span><span class='op'>)</span> <span class='fu'><a href='https://rdrr.io/r/base/paste.html'>paste0</a></span><span class='op'>(</span><span class='va'>x</span>,<span class='st'>"_lead_"</span>, <span class='va'>i</span><span class='op'>)</span><span class='op'>)</span>
<span class='op'>}</span>

<span class='co'># merge the dataframes of leads</span>
<span class='va'>data_leads</span> <span class='op'>&lt;-</span> <span class='va'>leads_list</span> <span class='op'>%&gt;%</span>
  <span class='fu'>reduce</span><span class='op'>(</span><span class='va'>left_join</span>, by <span class='op'>=</span> <span class='st'>"date"</span><span class='op'>)</span>

<span class='co'># merge the leads with the processed_data_leads</span>
<span class='va'>processed_data_leads</span> <span class='op'>&lt;-</span> <span class='fu'>left_join</span><span class='op'>(</span><span class='va'>processed_data_leads</span>, <span class='va'>data_leads</span>, by <span class='op'>=</span> <span class='st'>"date"</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>select</span><span class='op'>(</span><span class='op'>-</span><span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='va'>mean_no2_l</span><span class='op'>:</span><span class='va'>year</span><span class='op'>)</span><span class='op'>)</span>

<span class='co'>#</span>
<span class='co'># create lags</span>
<span class='co'># </span>

<span class='co'># create a list to store dataframe of lags</span>
<span class='va'>lags_list</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/vector.html'>vector</a></span><span class='op'>(</span>mode <span class='op'>=</span> <span class='st'>"list"</span>, length <span class='op'>=</span> <span class='fl'>3</span><span class='op'>)</span>
<span class='fu'><a href='https://rdrr.io/r/base/names.html'>names</a></span><span class='op'>(</span><span class='va'>lags_list</span><span class='op'>)</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fl'>1</span><span class='op'>:</span><span class='fl'>3</span><span class='op'>)</span> 

<span class='co'># create the lags</span>
<span class='kw'>for</span><span class='op'>(</span><span class='va'>i</span> <span class='kw'>in</span> <span class='fl'>1</span><span class='op'>:</span><span class='fl'>3</span><span class='op'>)</span><span class='op'>{</span>
  <span class='va'>lags_list</span><span class='op'>[[</span><span class='va'>i</span><span class='op'>]</span><span class='op'>]</span> <span class='op'>&lt;-</span> <span class='va'>processed_data_lags</span> <span class='op'>%&gt;%</span>
    <span class='fu'>mutate_at</span><span class='op'>(</span><span class='fu'>vars</span><span class='op'>(</span><span class='op'>-</span><span class='va'>date</span><span class='op'>)</span>, <span class='op'>~</span>  <span class='fu'><a href='https://rdrr.io/r/stats/lag.html'>lag</a></span><span class='op'>(</span><span class='va'>.</span>, n <span class='op'>=</span> <span class='va'>i</span>, order_by <span class='op'>=</span> <span class='va'>date</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>rename_at</span><span class='op'>(</span><span class='fu'>vars</span><span class='op'>(</span><span class='op'>-</span><span class='va'>date</span><span class='op'>)</span>,<span class='kw'>function</span><span class='op'>(</span><span class='va'>x</span><span class='op'>)</span> <span class='fu'><a href='https://rdrr.io/r/base/paste.html'>paste0</a></span><span class='op'>(</span><span class='va'>x</span>,<span class='st'>"_lag_"</span>, <span class='va'>i</span><span class='op'>)</span><span class='op'>)</span>
<span class='op'>}</span>

<span class='co'># merge the dataframes of lags</span>
<span class='va'>data_lags</span> <span class='op'>&lt;-</span> <span class='va'>lags_list</span> <span class='op'>%&gt;%</span>
  <span class='fu'>reduce</span><span class='op'>(</span><span class='va'>left_join</span>, by <span class='op'>=</span> <span class='st'>"date"</span><span class='op'>)</span>

<span class='co'># merge the lags with the initial processed_data_lags</span>
<span class='va'>processed_data_lags</span> <span class='op'>&lt;-</span> <span class='fu'>left_join</span><span class='op'>(</span><span class='va'>processed_data_lags</span>, <span class='va'>data_lags</span>, by <span class='op'>=</span> <span class='st'>"date"</span><span class='op'>)</span>

<span class='co'>#</span>
<span class='co'># merge processed_data_leads with processed_data_lags</span>
<span class='co'>#</span>

<span class='va'>processed_data</span> <span class='op'>&lt;-</span> <span class='fu'>left_join</span><span class='op'>(</span><span class='va'>processed_data_lags</span>, <span class='va'>processed_data_leads</span>, by <span class='op'>=</span> <span class='st'>"date"</span><span class='op'>)</span>

<span class='co'>#-----------------------------------------------------------------------------</span>

<span class='co'># DEFINING TREATMENT ASSIGNMENT</span>

<span class='co'>#-----------------------------------------------------------------------------</span>

<span class='co'># construct treatment assigment variable</span>
<span class='va'>processed_data</span> <span class='op'>&lt;-</span> <span class='va'>processed_data</span> <span class='op'>%&gt;%</span> 
  <span class='fu'>mutate</span><span class='op'>(</span>is_treated <span class='op'>=</span> <span class='cn'>NA</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='co'># the hour is defined as treated if there was positive cruise traffic in t</span>
  <span class='fu'>mutate</span><span class='op'>(</span>is_treated <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='op'>(</span><span class='va'>total_gross_tonnage_exit_cruise</span> <span class='op'>&gt;</span> <span class='fl'>0</span>, <span class='cn'>TRUE</span>, <span class='va'>is_treated</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span> 
  <span class='co'># the hour is defined as treated if there was no cruise traffic in t</span>
  <span class='fu'>mutate</span><span class='op'>(</span>is_treated <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='op'>(</span><span class='va'>total_gross_tonnage_exit_cruise</span> <span class='op'>==</span> <span class='fl'>0</span>, <span class='cn'>FALSE</span>, <span class='va'>is_treated</span><span class='op'>)</span><span class='op'>)</span>

<span class='co'># remove the hours for which assignment is undefined</span>
<span class='va'>matching_data_all_years</span> <span class='op'>=</span> <span class='va'>processed_data</span><span class='op'>[</span><span class='op'>!</span><span class='fu'><a href='https://rdrr.io/r/base/NA.html'>is.na</a></span><span class='op'>(</span><span class='va'>processed_data</span><span class='op'>$</span><span class='va'>is_treated</span><span class='op'>)</span>,<span class='op'>]</span>

<span class='co'># susbet treated and control units</span>
<span class='va'>treated_units</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/subset.html'>subset</a></span><span class='op'>(</span><span class='va'>matching_data_all_years</span>,<span class='va'>is_treated</span><span class='op'>)</span>
<span class='va'>control_units</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/subset.html'>subset</a></span><span class='op'>(</span><span class='va'>matching_data_all_years</span>,<span class='op'>!</span><span class='va'>is_treated</span><span class='op'>)</span>
<span class='va'>N_treated</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='op'>(</span><span class='va'>treated_units</span><span class='op'>)</span> <span class='co'># gives the total number of treated units for all years</span>
<span class='va'>N_control</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='op'>(</span><span class='va'>control_units</span><span class='op'>)</span> <span class='co'># gives the total number of control units for all years</span>

<span class='co'>#---------------------------------------------------------------------------</span>

<span class='co'># DEFINING THRESHOLDS</span>

<span class='co'>#---------------------------------------------------------------------------</span>

<span class='co'># we create the scaling list as it is needed for running the algorithm</span>
<span class='co'># but we do not use it</span>

<span class='va'>scaling</span> <span class='op'>=</span>  <span class='fu'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='op'>(</span><span class='fl'>1</span><span class='op'>)</span>,<span class='fu'><a href='https://rdrr.io/r/base/nrow.html'>ncol</a></span><span class='op'>(</span><span class='va'>matching_data_all_years</span><span class='op'>)</span><span class='op'>)</span>
<span class='fu'><a href='https://rdrr.io/r/base/names.html'>names</a></span><span class='op'>(</span><span class='va'>scaling</span><span class='op'>)</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/colnames.html'>colnames</a></span><span class='op'>(</span><span class='va'>matching_data_all_years</span><span class='op'>)</span>

<span class='co'># instead, we manually defined the threshold for each covariate</span>
<span class='va'>thresholds</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='op'>(</span><span class='cn'>Inf</span><span class='op'>)</span>,<span class='fu'><a href='https://rdrr.io/r/base/nrow.html'>ncol</a></span><span class='op'>(</span><span class='va'>matching_data_all_years</span><span class='op'>)</span><span class='op'>)</span>
<span class='fu'><a href='https://rdrr.io/r/base/names.html'>names</a></span><span class='op'>(</span><span class='va'>thresholds</span><span class='op'>)</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/colnames.html'>colnames</a></span><span class='op'>(</span><span class='va'>matching_data_all_years</span><span class='op'>)</span>

<span class='co'># threshold for hour</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>hour</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>hour_lag_1</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>hour_lag_2</span> <span class='op'>=</span> <span class='fl'>0</span>

<span class='co'># threshold for weekday</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>weekday</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>weekday_lag_1</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>weekday_lag_2</span> <span class='op'>=</span> <span class='fl'>0</span>

<span class='co'># threshold for holidays</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>holidays_dummy</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>holidays_dummy_lag_1</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>holidays_dummy_lag_2</span> <span class='op'>=</span> <span class='fl'>0</span>

<span class='co'># threshold for bank days</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>bank_day_dummy</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>bank_day_dummy_lag_1</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>bank_day_dummy_lag_2</span> <span class='op'>=</span> <span class='fl'>0</span>

<span class='co'># threshold for distance in days (day_index variable)</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>day_index</span> <span class='op'>=</span> <span class='fl'>30</span>

<span class='co'># thresholds for rainfall dummy</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>rainfall_height_dummy</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholdsrainfall_height_dummy_lag_1</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>rainfall_height_dummy_lag_2</span> <span class='op'>=</span> <span class='fl'>0</span>

<span class='co'># thresholds for average humidity</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>humidity_average</span> <span class='op'>=</span> <span class='fl'>9</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>humidity_average_lag_1</span> <span class='op'>=</span> <span class='fl'>9</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>humidity_average_lag_2</span> <span class='op'>=</span> <span class='fl'>9</span>

<span class='co'># thresholds for temperature average</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>temperature_average</span> <span class='op'>=</span> <span class='fl'>4</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>temperature_average_lag_1</span> <span class='op'>=</span> <span class='fl'>4</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>temperature_average_lag_2</span> <span class='op'>=</span> <span class='fl'>4</span>

<span class='co'># thresholds for wind direction categories</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>wind_direction_east_west</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>wind_direction_east_west_lag_1</span> <span class='op'>=</span> <span class='fl'>0</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>wind_direction_east_west_lag_2</span> <span class='op'>=</span> <span class='fl'>0</span>

<span class='co'># thresholds for wind speed</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>wind_speed</span> <span class='op'>=</span> <span class='fl'>1.8</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>wind_speed_lag_1</span> <span class='op'>=</span> <span class='fl'>1.8</span>
<span class='va'>thresholds</span><span class='op'>$</span><span class='va'>wind_speed_lag_2</span> <span class='op'>=</span> <span class='fl'>1.8</span>

<span class='co'>#--------------------------------------------------------------------------------</span>

<span class='co'># RUNNING THE MATCHING PROCEDURE</span>

<span class='co'>#--------------------------------------------------------------------------------</span>

<span class='co'># we run the matching procedure for each year on the amazon EC2 t3.2xlarge</span>
<span class='co'># we cannot run the matching on the full dataset at once</span>
<span class='co'># as the computation is too intensive</span>

<span class='co'># running the loop</span>

<span class='kw'>for</span> <span class='op'>(</span><span class='va'>i</span> <span class='kw'>in</span> <span class='fl'>2008</span><span class='op'>:</span><span class='fl'>2018</span><span class='op'>)</span><span class='op'>{</span>
  <span class='co'># select relevant year</span>
  <span class='va'>matching_data</span> <span class='op'>&lt;-</span> <span class='va'>matching_data_all_years</span> <span class='op'>%&gt;%</span>
    <span class='fu'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='op'>(</span><span class='va'>year</span> <span class='op'>==</span> <span class='va'>i</span><span class='op'>)</span>
  
  <span class='co'># susbet treated and control units</span>
  <span class='va'>treated_units</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/subset.html'>subset</a></span><span class='op'>(</span><span class='va'>matching_data</span>,<span class='va'>is_treated</span><span class='op'>)</span>
  <span class='va'>control_units</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/subset.html'>subset</a></span><span class='op'>(</span><span class='va'>matching_data</span>,<span class='op'>!</span><span class='va'>is_treated</span><span class='op'>)</span>
  <span class='va'>N_treated</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='op'>(</span><span class='va'>treated_units</span><span class='op'>)</span>
  <span class='va'>N_control</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='op'>(</span><span class='va'>control_units</span><span class='op'>)</span>
  
  <span class='co'>#-----------------------------------------------------------------------------------</span>
  
  <span class='co'># COMPUTE DISCREPANCY MATRIX</span>
  
  <span class='co'>#-----------------------------------------------------------------------------------</span>
  
  <span class='co'># first we compute the discrepancy matrix</span>
  <span class='va'>discrepancies</span> <span class='op'>=</span> <span class='fu'>discrepancyMatrix</span><span class='op'>(</span><span class='va'>treated_units</span>, <span class='va'>control_units</span>, <span class='va'>thresholds</span>, <span class='va'>scaling</span><span class='op'>)</span>
  
  <span class='fu'><a href='https://rdrr.io/r/base/colnames.html'>rownames</a></span><span class='op'>(</span><span class='va'>discrepancies</span><span class='op'>)</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/format.html'>format</a></span><span class='op'>(</span><span class='va'>matching_data</span><span class='op'>$</span><span class='va'>date</span><span class='op'>[</span><span class='fu'><a href='https://rdrr.io/r/base/which.html'>which</a></span><span class='op'>(</span><span class='va'>matching_data</span><span class='op'>$</span><span class='va'>is_treated</span><span class='op'>)</span><span class='op'>]</span><span class='op'>)</span>
  <span class='fu'><a href='https://rdrr.io/r/base/colnames.html'>colnames</a></span><span class='op'>(</span><span class='va'>discrepancies</span><span class='op'>)</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/format.html'>format</a></span><span class='op'>(</span><span class='va'>matching_data</span><span class='op'>$</span><span class='va'>date</span><span class='op'>[</span><span class='fu'><a href='https://rdrr.io/r/base/which.html'>which</a></span><span class='op'>(</span><span class='op'>!</span><span class='va'>matching_data</span><span class='op'>$</span><span class='va'>is_treated</span><span class='op'>)</span><span class='op'>]</span><span class='op'>)</span>
  <span class='fu'><a href='https://rdrr.io/r/base/colnames.html'>rownames</a></span><span class='op'>(</span><span class='va'>matching_data</span><span class='op'>)</span> <span class='op'>=</span> <span class='va'>matching_data</span><span class='op'>$</span><span class='va'>date</span>
  
  <span class='co'>#-----------------------------------------------------------------------------------</span>
  
  <span class='co'># RUN MATCHING</span>
  
  <span class='co'>#-----------------------------------------------------------------------------------</span>
  
  <span class='co'># run the fullmatch algorithm</span>
  <span class='va'>matched_groups</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/pkg/optmatch/man/fullmatch.html'>fullmatch</a></span><span class='op'>(</span><span class='va'>discrepancies</span>, data <span class='op'>=</span> <span class='va'>matching_data</span>, remove.unmatchables <span class='op'>=</span> <span class='cn'>TRUE</span>, max.controls <span class='op'>=</span> <span class='fl'>1</span><span class='op'>)</span>
  
  <span class='co'># get list of matched  treated-control groups</span>
  <span class='va'>groups_labels</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/unique.html'>unique</a></span><span class='op'>(</span><span class='va'>matched_groups</span><span class='op'>[</span><span class='op'>!</span><span class='fu'><a href='https://rdrr.io/r/base/NA.html'>is.na</a></span><span class='op'>(</span><span class='va'>matched_groups</span><span class='op'>)</span><span class='op'>]</span><span class='op'>)</span>
  <span class='va'>groups_list</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='op'>(</span><span class='op'>)</span>
  <span class='kw'>for</span> <span class='op'>(</span><span class='va'>j</span> <span class='kw'>in</span> <span class='fl'>1</span><span class='op'>:</span><span class='fu'><a href='https://rdrr.io/r/base/length.html'>length</a></span><span class='op'>(</span><span class='va'>groups_labels</span><span class='op'>)</span><span class='op'>)</span><span class='op'>{</span>
    <span class='va'>IDs</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/names.html'>names</a></span><span class='op'>(</span><span class='va'>matched_groups</span><span class='op'>)</span><span class='op'>[</span><span class='op'>(</span><span class='va'>matched_groups</span><span class='op'>==</span><span class='va'>groups_labels</span><span class='op'>[</span><span class='va'>j</span><span class='op'>]</span><span class='op'>)</span><span class='op'>]</span>
    <span class='va'>groups_list</span><span class='op'>[[</span><span class='va'>j</span><span class='op'>]</span><span class='op'>]</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/as.Date.html'>as.Date</a></span><span class='op'>(</span><span class='va'>IDs</span><span class='op'>[</span><span class='op'>!</span><span class='fu'><a href='https://rdrr.io/r/base/NA.html'>is.na</a></span><span class='op'>(</span><span class='va'>IDs</span><span class='op'>)</span><span class='op'>]</span><span class='op'>)</span>
  <span class='op'>}</span>
  
  <span class='co'>#-----------------------------------------------------------------------------------</span>
  
  <span class='co'># BIPARTITE GRAPH AND GET FINAL DATA</span>
  
  <span class='co'>#-----------------------------------------------------------------------------------</span>
  
  <span class='co'># we build a bipartite graph with one layer of treated nodes, and another layer of control nodes.</span>
  <span class='co'># the nodes are labeled by integers from 1 to (N_treated + N_control)</span>
  <span class='co'># by convention, the first N_treated nodes correspond to the treated units, and the remaining N_control</span>
  <span class='co'># nodes correspond to the control units.</span>
  
  <span class='co'># build pseudo-adjacency matrix: edge if and only if match is admissible</span>
  <span class='co'># NB: this matrix is rectangular so it is not per say the adjacendy matrix of the graph</span>
  <span class='co'># (for this bipartite graph, the adjacency matrix had four blocks: the upper-left block of size</span>
  <span class='co'># N_treated by N_treated filled with 0's, bottom-right block of size N_control by N_control filled with 0's,</span>
  <span class='co'># top-right block of size N_treated by N_control corresponding to adj defined below, and bottom-left block</span>
  <span class='co'># of size N_control by N_treated corresponding to the transpose of adj)</span>
  <span class='va'>adj</span> <span class='op'>=</span> <span class='op'>(</span><span class='va'>discrepancies</span><span class='op'>&lt;</span><span class='cn'>Inf</span><span class='op'>)</span>
  
  <span class='co'># extract endpoints of edges</span>
  <span class='va'>edges_mat</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/which.html'>which</a></span><span class='op'>(</span><span class='va'>adj</span>,arr.ind <span class='op'>=</span> <span class='cn'>TRUE</span><span class='op'>)</span>
  
  <span class='co'># build weights, listed in the same order as the edges (we use a decreasing function x --&gt; 1/(1+x) to</span>
  <span class='co'># have weights inversely proportional to the discrepancies, since maximum.bipartite.matching</span>
  <span class='co'># maximizes the total weight and we want to minimize the discrepancy)</span>
  <span class='va'>weights</span> <span class='op'>=</span> <span class='fl'>1</span><span class='op'>/</span><span class='op'>(</span><span class='fl'>1</span><span class='op'>+</span><span class='fu'><a href='https://rdrr.io/r/base/lapply.html'>sapply</a></span><span class='op'>(</span><span class='fl'>1</span><span class='op'>:</span><span class='fu'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='op'>(</span><span class='va'>edges_mat</span><span class='op'>)</span>,<span class='kw'>function</span><span class='op'>(</span><span class='va'>j</span><span class='op'>)</span><span class='va'>discrepancies</span><span class='op'>[</span><span class='va'>edges_mat</span><span class='op'>[</span><span class='va'>j</span>,<span class='fl'>1</span><span class='op'>]</span>,<span class='va'>edges_mat</span><span class='op'>[</span><span class='va'>j</span>,<span class='fl'>2</span><span class='op'>]</span><span class='op'>]</span><span class='op'>)</span><span class='op'>)</span>
  
  <span class='co'># format list of edges (encoded as a vector resulting from concatenating the end points of each edge)</span>
  <span class='co'># i.e c(edge1_endpoint1, edge1_endpoint2, edge2_endpoint1, edge2_endpoint1, edge3_endpoint1, etc...)</span>
  <span class='va'>edges_mat</span><span class='op'>[</span>,<span class='st'>"col"</span><span class='op'>]</span> <span class='op'>=</span> <span class='va'>edges_mat</span><span class='op'>[</span>,<span class='st'>"col"</span><span class='op'>]</span> <span class='op'>+</span> <span class='va'>N_treated</span>
  <span class='va'>edges_vector</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/t.html'>t</a></span><span class='op'>(</span><span class='va'>edges_mat</span><span class='op'>)</span><span class='op'>)</span>
  
  <span class='co'># NB: by convention, the first N_treated nodes correspond to the treated units, and the remaining N_control</span>
  <span class='co'># nodes correspond to the control units (hence the "+ N_treated" to shift the labels of the control nodes)</span>
  
  <span class='co'># build the graph from the list of edges</span>
  <span class='va'>BG</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/pkg/igraph/man/make_bipartite_graph.html'>make_bipartite_graph</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span><span class='op'>(</span><span class='cn'>TRUE</span>,<span class='va'>N_treated</span><span class='op'>)</span>,<span class='fu'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span><span class='op'>(</span><span class='cn'>FALSE</span>,<span class='va'>N_control</span><span class='op'>)</span><span class='op'>)</span>, edges <span class='op'>=</span> <span class='va'>edges_vector</span><span class='op'>)</span>
  
  <span class='co'># find the maximal weighted matching</span>
  <span class='va'>MBM</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/pkg/igraph/man/matching.html'>maximum.bipartite.matching</a></span><span class='op'>(</span><span class='va'>BG</span>,weights <span class='op'>=</span> <span class='va'>weights</span><span class='op'>)</span>
  
  <span class='co'># list the dates of the matched pairs</span>
  <span class='va'>pairs_list</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='op'>(</span><span class='op'>)</span>
  <span class='va'>N_matched</span> <span class='op'>=</span> <span class='fl'>0</span>
  <span class='kw'>for</span> <span class='op'>(</span><span class='va'>j</span> <span class='kw'>in</span> <span class='fl'>1</span><span class='op'>:</span><span class='va'>N_treated</span><span class='op'>)</span><span class='op'>{</span>
    <span class='kw'>if</span> <span class='op'>(</span><span class='op'>!</span><span class='fu'><a href='https://rdrr.io/r/base/NA.html'>is.na</a></span><span class='op'>(</span><span class='va'>MBM</span><span class='op'>$</span><span class='va'>matching</span><span class='op'>[</span><span class='va'>j</span><span class='op'>]</span><span class='op'>)</span><span class='op'>)</span><span class='op'>{</span>
      <span class='va'>N_matched</span> <span class='op'>=</span> <span class='va'>N_matched</span> <span class='op'>+</span> <span class='fl'>1</span>
      <span class='va'>pairs_list</span><span class='op'>[[</span><span class='va'>N_matched</span><span class='op'>]</span><span class='op'>]</span> <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='va'>treated_units</span><span class='op'>$</span><span class='va'>date</span><span class='op'>[</span><span class='va'>j</span><span class='op'>]</span>,<span class='va'>control_units</span><span class='op'>$</span><span class='va'>date</span><span class='op'>[</span><span class='va'>MBM</span><span class='op'>$</span><span class='va'>matching</span><span class='op'>[</span><span class='va'>j</span><span class='op'>]</span><span class='op'>-</span><span class='va'>N_treated</span><span class='op'>]</span><span class='op'>)</span>
    <span class='op'>}</span>
  <span class='op'>}</span>
  
  <span class='co'># transform the list of matched pairs to a dataframe</span>
  <span class='va'>matched_pairs</span> <span class='op'>&lt;-</span> <span class='fu'>enframe</span><span class='op'>(</span><span class='va'>pairs_list</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>unnest</span><span class='op'>(</span>cols <span class='op'>=</span> <span class='st'>"value"</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
    <span class='fu'>rename</span><span class='op'>(</span>pair_number <span class='op'>=</span> <span class='va'>name</span>,
           date <span class='op'>=</span> <span class='va'>value</span><span class='op'>)</span>
  
  <span class='co'># select the matched data for the analysis</span>
  <span class='va'>final_data</span> <span class='op'>&lt;-</span> <span class='fu'>left_join</span><span class='op'>(</span><span class='va'>matched_pairs</span>, <span class='va'>matching_data</span>, by <span class='op'>=</span> <span class='st'>"date"</span><span class='op'>)</span>
  
  <span class='co'># save the data</span>
  <span class='fu'><a href='https://rdrr.io/r/base/readRDS.html'>saveRDS</a></span><span class='op'>(</span><span class='va'>final_data</span>, <span class='fu'><a href='https://rdrr.io/r/base/paste.html'>paste0</a></span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/paste.html'>paste0</a></span><span class='op'>(</span><span class='st'>"~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/1.data/2.data_for_analysis/1.matched_data/1.experiments_cruise/2.experiment_exit_cruise/temporary_matched_data_"</span>, <span class='va'>i</span><span class='op'>)</span>, <span class='st'>".RDS"</span><span class='op'>)</span><span class='op'>)</span>
<span class='op'>}</span>

<span class='co'>#-----------------------------------------------------------------------------------------------------------</span>

<span class='co'># COMBINING YEARLY DATA INTO A SINGLE FILE</span>

<span class='co'>#-----------------------------------------------------------------------------------------------------------</span>

<span class='co'># list the names of the matched data for each year</span>
<span class='va'>matched_data_all_years</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/list.files.html'>list.files</a></span><span class='op'>(</span>path <span class='op'>=</span> <span class='st'>"~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/1.data/2.data_for_analysis/1.matched_data/1.experiments_cruise/2.experiment_exit_cruise/"</span>,
                                     pattern <span class='op'>=</span> <span class='st'>"temporary"</span>, 
                                     full.names <span class='op'>=</span> <span class='cn'>T</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'>map_df</span><span class='op'>(</span><span class='op'>~</span><span class='fu'><a href='https://rdrr.io/r/base/readRDS.html'>readRDS</a></span><span class='op'>(</span><span class='va'>.</span><span class='op'>)</span><span class='op'>)</span>

<span class='co'># recreate the pair ids</span>
<span class='va'>matched_data_all_years</span> <span class='op'>&lt;-</span> <span class='va'>matched_data_all_years</span> <span class='op'>%&gt;%</span>
  <span class='fu'>mutate</span><span class='op'>(</span>pair_number <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/rep.html'>rep</a></span><span class='op'>(</span><span class='fl'>1</span><span class='op'>:</span><span class='op'>(</span><span class='fu'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='op'>(</span><span class='va'>matched_data_all_years</span><span class='op'>)</span><span class='op'>/</span><span class='fl'>2</span><span class='op'>)</span>, each<span class='op'>=</span><span class='fl'>2</span><span class='op'>)</span><span class='op'>)</span>

<span class='co'># save the data</span>
<span class='fu'><a href='https://rdrr.io/r/base/readRDS.html'>saveRDS</a></span><span class='op'>(</span><span class='va'>matched_data_all_years</span>, <span class='st'>"~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/1.data/2.data_for_analysis/1.matched_data/1.experiments_cruise/2.experiment_exit_cruise/matched_data_exit_cruise.RDS"</span><span class='op'>)</span>
</code></pre></div>

</div>


# Matching Results

We open the matched data:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='va'>matched_data</span> <span class='op'>&lt;-</span>
  <span class='fu'><a href='https://rdrr.io/r/base/readRDS.html'>readRDS</a></span><span class='op'>(</span>
    <span class='fu'>here</span><span class='fu'>::</span><span class='fu'><a href='https://here.r-lib.org//reference/here.html'>here</a></span><span class='op'>(</span>
      <span class='st'>"1.data"</span>,
      <span class='st'>"2.data_for_analysis"</span>,
      <span class='st'>"1.matched_data"</span>,
      <span class='st'>"1.experiments_cruise"</span>,
      <span class='st'>"2.experiment_exit_cruise"</span>,
      <span class='st'>"matched_data_exit_cruise.RDS"</span>
    <span class='op'>)</span><span class='op'>)</span>
</code></pre></div>

</div>


The matching procedure resulted in 123 matched pairs.
```{.r .distill-force-highlighting-css}
```
