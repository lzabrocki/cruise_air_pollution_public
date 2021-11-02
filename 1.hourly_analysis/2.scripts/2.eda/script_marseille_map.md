---
title: "Map of Marseille Context"
description: |
  Script for reproducing the map.
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

In this document, we provide all steps and R codes required to reproduce the figures of Fisherian intervals displayed in the main article. **Should you have any questions, need help to reproduce the analysis or find coding errors, please do not hesitate to contact us at leo.zabrocki@psemail.eu and marion.leroutier@psemail.eu.**

# Required Packages

To reproduce exactly the `script_figures_paper.html` document, we first need to have installed:

* the [R](https://www.r-project.org/) programming language 
* [RStudio](https://rstudio.com/), an integrated development environment for R, which will allow you to knit the `5_script_checking_balance_figures.Rmd` file and interact with the R code chunks
* the [R Markdown](https://rmarkdown.rstudio.com/) package
* and the [Distill](https://rstudio.github.io/distill/) package which provides the template for this document. 

Once everything is set up, we have to load the following packages:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># load required packages</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://yihui.org/knitr/'>knitr</a></span><span class='op'>)</span> <span class='co'># for creating the R Markdown document</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://here.r-lib.org/'>here</a></span><span class='op'>)</span> <span class='co'># for files paths organization</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://tidyverse.tidyverse.org'>tidyverse</a></span><span class='op'>)</span> <span class='co'># for data manipulation and visualization</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://docs.ropensci.org/osmdata/'>osmdata</a></span><span class='op'>)</span> <span class='co'># for retrieving open street map data</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='https://r-spatial.github.io/sf/'>sf</a></span><span class='op'>)</span> <span class='co'># for simple features access</span>
<span class='kw'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='op'>(</span><span class='va'><a href='http://www.rforge.net/Cairo/'>Cairo</a></span><span class='op'>)</span> <span class='co'># for printing customed police of graphs</span>
</code></pre></div>

</div>


We finally load our customed `ggplot2` theme for graphs:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># load ggplot customed theme</span>
<span class='kw'><a href='https://rdrr.io/r/base/source.html'>source</a></span><span class='op'>(</span><span class='fu'>here</span><span class='fu'>::</span><span class='fu'><a href='https://here.r-lib.org//reference/here.html'>here</a></span><span class='op'>(</span><span class='st'>"2.scripts"</span>, <span class='st'>"4.custom_ggplot2_theme"</span>, <span class='st'>"script_custom_ggplot_theme_small_wrap.R"</span><span class='op'>)</span><span class='op'>)</span>
</code></pre></div>

</div>


The theme is based on the fantastic [hrbrthemes](https://hrbrmstr.github.io/hrbrthemes/index.html) package. If you do not want to use this theme or are unable to install it because of fonts issues, you can use the `theme_bw()` already included in the `ggplot2` package.

# Gathering the data

### City's boundaries

We downloaded from [data.gouv.fr](https://www.data.gouv.fr/fr/datasets/quartiers-de-marseille-1/#) a shape file of Marseille's districts. We load these data and compute the union of the districts to have the boundaries of the city:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># load the city's boundaries</span>
<span class='va'>marseille_borders</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://r-spatial.github.io/sf/reference/st_read.html'>st_read</a></span><span class='op'>(</span><span class='fu'>here</span><span class='fu'>::</span><span class='fu'><a href='https://here.r-lib.org//reference/here.html'>here</a></span><span class='op'>(</span><span class='st'>"1.data"</span>, <span class='st'>"1.raw_data"</span>, <span class='st'>"6.marseille_map_data"</span>, <span class='st'>"districts_marseille.shp"</span><span class='op'>)</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://r-spatial.github.io/sf/reference/geos_combine.html'>st_union</a></span><span class='op'>(</span><span class='op'>)</span>
</code></pre></div>

```
Reading layer `districts_marseille' from data source 
  `D:\Dropbox\phd_thesis\project_cruise_air_pollution_osf\1.hourly_analysis\1.data\1.raw_data\6.marseille_map_data\districts_marseille.shp' 
  using driver `ESRI Shapefile'
Simple feature collection with 111 features and 3 fields
Geometry type: MULTIPOLYGON
Dimension:     XY
Bounding box:  xmin: 881250.9 ymin: 6232998 xmax: 905587.3 ymax: 6257715
Projected CRS: Lambert_Conformal_Conic
```

</div>


### Port's boundaries

Using the `osmdata` package, we retrieve the boundaries of Marseille's port:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># building the query to get boundaries of the port</span>
<span class='va'>harbour_query</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://docs.ropensci.org/osmdata/reference/getbb.html'>getbb</a></span><span class='op'>(</span><span class='st'>"Marseille"</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://docs.ropensci.org/osmdata/reference/opq.html'>opq</a></span><span class='op'>(</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://docs.ropensci.org/osmdata/reference/add_osm_feature.html'>add_osm_feature</a></span><span class='op'>(</span><span class='st'>"harbour"</span><span class='op'>)</span>

<span class='co'># retrieve the data</span>
<span class='va'>harbour_data</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://docs.ropensci.org/osmdata/reference/osmdata_sf.html'>osmdata_sf</a></span><span class='op'>(</span><span class='va'>harbour_query</span><span class='op'>)</span>
</code></pre></div>

</div>


### Roads data

Using the `osmdata` package, we retrieve Marseille's network of roads. This query takes a bit of time to run:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># building the query to get roads data</span>
<span class='va'>roads_query</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://docs.ropensci.org/osmdata/reference/getbb.html'>getbb</a></span><span class='op'>(</span><span class='st'>"Marseille"</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://docs.ropensci.org/osmdata/reference/opq.html'>opq</a></span><span class='op'>(</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
  <span class='fu'><a href='https://docs.ropensci.org/osmdata/reference/add_osm_feature.html'>add_osm_feature</a></span><span class='op'>(</span><span class='st'>"highway"</span><span class='op'>)</span>

<span class='co'># retrieve the data</span>
<span class='va'>roads_data</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://docs.ropensci.org/osmdata/reference/osmdata_sf.html'>osmdata_sf</a></span><span class='op'>(</span><span class='va'>roads_query</span><span class='op'>)</span>
</code></pre></div>

</div>


### Air pollution measuring stations data

We retrieve the coordinates of Longchamp and Saint Louis stations from [AtmoSud](https://www.atmosud.org/) website:

<div class="layout-chunk" data-layout="l-body">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># create air pollution measuring stations data</span>
<span class='va'>data_stations</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://r-spatial.github.io/sf/reference/tibble.html'>tibble</a></span><span class='op'>(</span>latitude <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fl'>43.34811</span>,  <span class='fl'>43.30610</span><span class='op'>)</span>, longitude <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fl'>5.36012</span>, <span class='fl'>5.39526</span><span class='op'>)</span>, name <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='st'>"Saint Louis"</span>, <span class='st'>"Longchamp"</span><span class='op'>)</span><span class='op'>)</span>

<span class='co'># set the crs</span>
<span class='va'>data_stations</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://r-spatial.github.io/sf/reference/st_as_sf.html'>st_as_sf</a></span><span class='op'>(</span>
  <span class='va'>data_stations</span>, 
  coords <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='st'>'longitude'</span>, <span class='st'>'latitude'</span><span class='op'>)</span>,
  crs <span class='op'>=</span> <span class='st'>"+init=epsg:4326"</span>
<span class='op'>)</span>

<span class='co'># retrieve station coordinates for labelling their names on the map</span>
<span class='va'>stations_coordinates</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/as.data.frame.html'>as.data.frame</a></span><span class='op'>(</span><span class='fu'><a href='https://r-spatial.github.io/sf/reference/st_transform.html'>st_transform</a></span><span class='op'>(</span><span class='va'>data_stations</span>, <span class='fl'>2154</span><span class='op'>)</span> <span class='op'>%&gt;%</span>
                                 <span class='fu'><a href='https://r-spatial.github.io/sf/reference/st_coordinates.html'>st_coordinates</a></span><span class='op'>(</span><span class='va'>.</span><span class='op'>)</span><span class='op'>)</span>
<span class='va'>stations_coordinates</span><span class='op'>$</span><span class='va'>name</span> <span class='op'>&lt;-</span> <span class='va'>data_stations</span><span class='op'>$</span><span class='va'>name</span>
</code></pre></div>

</div>


# Making the map

<div class="layout-chunk" data-layout="l-body-outset">
<div class="sourceCode"><pre class="sourceCode r"><code class="sourceCode r"><span class='co'># we first store a vector of colors to create the legend</span>
<span class='va'>colors</span> <span class='op'>&lt;-</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='st'>"Harbour"</span> <span class='op'>=</span> <span class='st'>"coral"</span>, <span class='st'>"Stations"</span> <span class='op'>=</span> <span class='st'>"deepskyblue3"</span><span class='op'>)</span>

<span class='co'># make the map</span>
<span class='va'>map_marseille</span> <span class='op'>&lt;-</span> <span class='fu'>ggplot</span><span class='op'>(</span><span class='op'>)</span> <span class='op'>+</span>
  <span class='co'># city's boundaries</span>
  <span class='fu'>geom_sf</span><span class='op'>(</span>
    data <span class='op'>=</span> <span class='va'>marseille_borders</span>,
    colour <span class='op'>=</span> <span class='st'>"black"</span>,
    fill <span class='op'>=</span> <span class='st'>"white"</span>,
    size <span class='op'>=</span> <span class='fl'>0.8</span>
  <span class='op'>)</span> <span class='op'>+</span>
  <span class='co'># roads</span>
  <span class='fu'>geom_sf</span><span class='op'>(</span>data <span class='op'>=</span> <span class='va'>roads_data</span><span class='op'>$</span><span class='va'>osm_lines</span>,
          colour <span class='op'>=</span> <span class='st'>"gray80"</span>,
          size <span class='op'>=</span> <span class='fl'>0.2</span><span class='op'>)</span> <span class='op'>+</span>
  <span class='co'># station coordinates</span>
  <span class='fu'>geom_sf</span><span class='op'>(</span>
    data <span class='op'>=</span> <span class='va'>data_stations</span>,
    <span class='fu'>aes</span><span class='op'>(</span>colour <span class='op'>=</span> <span class='st'>"Stations"</span><span class='op'>)</span>,
    shape <span class='op'>=</span> <span class='fl'>3</span>,
    stroke <span class='op'>=</span> <span class='fl'>2.5</span>,
    size <span class='op'>=</span> <span class='fl'>8</span>
  <span class='op'>)</span> <span class='op'>+</span>
  <span class='co'># port's boundaries</span>
  <span class='fu'>geom_sf</span><span class='op'>(</span>data <span class='op'>=</span> <span class='va'>harbour_data</span><span class='op'>$</span><span class='va'>osm_lines</span>,
          <span class='fu'>aes</span><span class='op'>(</span>colour <span class='op'>=</span> <span class='st'>"Harbour"</span><span class='op'>)</span>,
          size <span class='op'>=</span> <span class='fl'>1</span><span class='op'>)</span> <span class='op'>+</span>
  <span class='fu'>geom_sf</span><span class='op'>(</span>
    data <span class='op'>=</span> <span class='va'>harbour_data</span><span class='op'>$</span><span class='va'>osm_polygons</span>,
    <span class='fu'>aes</span><span class='op'>(</span>colour <span class='op'>=</span> <span class='st'>"Harbour"</span><span class='op'>)</span>,
    fill <span class='op'>=</span> <span class='cn'>NA</span>,
    size <span class='op'>=</span> <span class='fl'>0.8</span>
  <span class='op'>)</span> <span class='op'>+</span>
  <span class='co'># station labels</span>
  <span class='fu'>ggrepel</span><span class='fu'>::</span><span class='fu'><a href='https://rdrr.io/pkg/ggrepel/man/geom_text_repel.html'>geom_text_repel</a></span><span class='op'>(</span>
    data <span class='op'>=</span> <span class='va'>stations_coordinates</span>,
    <span class='fu'>aes</span><span class='op'>(</span><span class='va'>X</span>, <span class='va'>Y</span>, label <span class='op'>=</span> <span class='va'>name</span><span class='op'>)</span>,
    point.padding <span class='op'>=</span> <span class='fl'>1.8</span>,
    segment.color <span class='op'>=</span> <span class='cn'>NA</span>,
    size <span class='op'>=</span> <span class='fl'>12</span>,
    fontface <span class='op'>=</span> <span class='st'>'bold'</span>
  <span class='op'>)</span> <span class='op'>+</span>
  <span class='co'># axes labels</span>
  <span class='fu'>xlab</span><span class='op'>(</span><span class='st'>'Longitude'</span><span class='op'>)</span> <span class='op'>+</span> <span class='fu'>ylab</span><span class='op'>(</span><span class='st'>'Latitude'</span><span class='op'>)</span> <span class='op'>+</span>
  <span class='co'># add scale</span>
  <span class='fu'>ggspatial</span><span class='fu'>::</span><span class='fu'><a href='https://paleolimbot.github.io/ggspatial/reference/annotation_scale.html'>annotation_scale</a></span><span class='op'>(</span>
    location <span class='op'>=</span> <span class='st'>"br"</span>,
    line_width <span class='op'>=</span> <span class='fl'>0.5</span>,
    height <span class='op'>=</span> <span class='fu'>unit</span><span class='op'>(</span><span class='fl'>0.2</span>, <span class='st'>"cm"</span><span class='op'>)</span>
  <span class='op'>)</span> <span class='op'>+</span>
  <span class='co'># add north arrow</span>
  <span class='fu'>ggspatial</span><span class='fu'>::</span><span class='fu'><a href='https://paleolimbot.github.io/ggspatial/reference/annotation_north_arrow.html'>annotation_north_arrow</a></span><span class='op'>(</span>
    location <span class='op'>=</span> <span class='st'>"tr"</span>,
    which_north <span class='op'>=</span> <span class='st'>"true"</span>,
    height <span class='op'>=</span> <span class='fu'>unit</span><span class='op'>(</span><span class='fl'>1</span>, <span class='st'>"cm"</span><span class='op'>)</span>,
    width <span class='op'>=</span> <span class='fu'>unit</span><span class='op'>(</span><span class='fl'>1</span>, <span class='st'>"cm"</span><span class='op'>)</span>
  <span class='op'>)</span> <span class='op'>+</span>
  <span class='co'># zoom on the map</span>
  <span class='fu'>coord_sf</span><span class='op'>(</span>
    crs <span class='op'>=</span> <span class='fu'><a href='https://r-spatial.github.io/sf/reference/st_crs.html'>st_crs</a></span><span class='op'>(</span><span class='fl'>2154</span><span class='op'>)</span>,
    xlim <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fl'>885000</span>, <span class='fl'>898500</span><span class='op'>)</span>,
    ylim <span class='op'>=</span> <span class='fu'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='op'>(</span><span class='fl'>6245000</span>, <span class='fl'>6254000</span><span class='op'>)</span>,
    expand <span class='op'>=</span> <span class='cn'>FALSE</span>
  <span class='op'>)</span> <span class='op'>+</span>
  <span class='fu'>scale_color_manual</span><span class='op'>(</span>name <span class='op'>=</span> <span class='st'>"Legend:"</span>, values <span class='op'>=</span> <span class='va'>colors</span><span class='op'>)</span> <span class='op'>+</span>
  <span class='va'>custom_theme</span> <span class='op'>+</span>
  <span class='co'># theme options</span>
  <span class='fu'>theme</span><span class='op'>(</span>
    panel.border <span class='op'>=</span> <span class='fu'>element_rect</span><span class='op'>(</span>color <span class='op'>=</span> <span class='st'>"black"</span>, fill <span class='op'>=</span> <span class='cn'>NA</span>, size <span class='op'>=</span> <span class='fl'>0.8</span><span class='op'>)</span>,
    panel.background <span class='op'>=</span> <span class='fu'>element_rect</span><span class='op'>(</span>fill <span class='op'>=</span> <span class='st'>"aliceblue"</span><span class='op'>)</span>,
    panel.grid.major <span class='op'>=</span> <span class='fu'>element_blank</span><span class='op'>(</span><span class='op'>)</span>,
    <span class='co'># axis titles parameters</span>
    axis.title.x <span class='op'>=</span> <span class='fu'>element_text</span><span class='op'>(</span>
      size <span class='op'>=</span> <span class='fl'>36</span>,
      face <span class='op'>=</span> <span class='st'>"bold"</span>,
      margin <span class='op'>=</span> <span class='fu'>margin</span><span class='op'>(</span>
        t <span class='op'>=</span> <span class='fl'>20</span>,
        r <span class='op'>=</span> <span class='fl'>0</span>,
        b <span class='op'>=</span> <span class='fl'>0</span>,
        l <span class='op'>=</span> <span class='fl'>0</span>
      <span class='op'>)</span>
    <span class='op'>)</span>,
    axis.title.y <span class='op'>=</span> <span class='fu'>element_text</span><span class='op'>(</span>
      size <span class='op'>=</span> <span class='fl'>36</span>,
      face <span class='op'>=</span> <span class='st'>"bold"</span>,
      margin <span class='op'>=</span> <span class='fu'>margin</span><span class='op'>(</span>
        t <span class='op'>=</span> <span class='fl'>0</span>,
        r <span class='op'>=</span> <span class='fl'>20</span>,
        b <span class='op'>=</span> <span class='fl'>0</span>,
        l <span class='op'>=</span> <span class='fl'>0</span>
      <span class='op'>)</span>
    <span class='op'>)</span>,
    <span class='co'># axis texts</span>
    axis.text.x <span class='op'>=</span> <span class='fu'>element_text</span><span class='op'>(</span>size <span class='op'>=</span> <span class='fl'>20</span><span class='op'>)</span>,
    axis.text.y <span class='op'>=</span> <span class='fu'>element_text</span><span class='op'>(</span>size <span class='op'>=</span> <span class='fl'>20</span><span class='op'>)</span>,
    <span class='co'># facet texts</span>
    strip.text.x <span class='op'>=</span> <span class='fu'>element_text</span><span class='op'>(</span>size <span class='op'>=</span> <span class='fl'>36</span>, face <span class='op'>=</span> <span class='st'>"bold"</span><span class='op'>)</span>,
    strip.text.y <span class='op'>=</span> <span class='fu'>element_text</span><span class='op'>(</span>size <span class='op'>=</span> <span class='fl'>36</span>, face <span class='op'>=</span> <span class='st'>"bold"</span><span class='op'>)</span>,
    <span class='co'># legend parameters</span>
    legend.position <span class='op'>=</span> <span class='st'>"top"</span>,
    legend.justification <span class='op'>=</span> <span class='st'>"left"</span>,
    legend.direction <span class='op'>=</span> <span class='st'>"horizontal"</span>,
    legend.title <span class='op'>=</span> <span class='fu'>element_text</span><span class='op'>(</span>size <span class='op'>=</span> <span class='fl'>36</span>, face <span class='op'>=</span> <span class='st'>"bold"</span><span class='op'>)</span>,
    legend.text <span class='op'>=</span> <span class='fu'>element_text</span><span class='op'>(</span>size <span class='op'>=</span> <span class='fl'>28</span><span class='op'>)</span>
  <span class='op'>)</span>

<span class='co'># save the map</span>
<span class='fu'>ggsave</span><span class='op'>(</span>
  <span class='va'>map_marseille</span>,
  filename <span class='op'>=</span> <span class='fu'>here</span><span class='fu'>::</span><span class='fu'><a href='https://here.r-lib.org//reference/here.html'>here</a></span><span class='op'>(</span><span class='st'>"3.outputs"</span>, <span class='st'>"1.figures"</span>, <span class='st'>"1.eda"</span>, <span class='st'>"map_marseille.pdf"</span><span class='op'>)</span>,
  width <span class='op'>=</span> <span class='fl'>40</span>,
  height <span class='op'>=</span> <span class='fl'>28</span>,
  units <span class='op'>=</span> <span class='st'>"cm"</span>,
  device <span class='op'>=</span> <span class='va'>cairo_pdf</span>
<span class='op'>)</span>
</code></pre></div>

</div>

```{.r .distill-force-highlighting-css}
```
