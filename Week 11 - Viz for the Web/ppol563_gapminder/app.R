## This is a shiny web application built for PPOL 563 using gapminder data
## Adapted from https://github.com/akshi8/Gapminder
## Akshi Chaudhary

library(tidyverse)
library(shiny)
library(shinydashboard)
library(shinythemes)
library(plotly)

d1 <- gapminder::gapminder

# Convert population into a more readable format (millions)
# Round life expectancy to make it more readable
d1 <- d1 %>% 
   mutate(lifeExp = round(lifeExp),
          pop = pop / 1000000)


# Define UI for application
# using the shinytheme package to get access to a bunch of high quality themes
ui <- fluidPage(theme = shinytheme("superhero"),
                
                # Application title
                titlePanel("PPOL 563 Gapminder Visualization using Shiny"),
                
                # Overall layout will have a sidebar
                sidebarLayout(position = "right",
                              # this is where we specify what goes in the sidebar
                              # open with explantory text
                              sidebarPanel("Compare population, life-expectancy and GDP per Capita between two countries over the years by selecting the quantity to be compared and the year.",
                                           
                                           # this is an html tag that defines a thematic break in an HTML page, typically a horizontal rule
                                           hr(), 
                                           # Now we build all the input containers
                                           # Use a radio button to dhoose the variable to visualize
                                           radioButtons("variable_from_gapminder",
                                                        label = h5("Compare"),
                                                        choices = c("Population" = "pop",
                                                                    "Life Expectancy" = "lifeExp",
                                                                    "GDP Per Capita" = "gdpPercap"),
                                                        selected = "gdpPercap"),
                                           hr(),
                                           # Use an input selector to choose the first country
                                           selectInput("country_from_gapminder", 
                                                       h5("First country:"),
                                                       levels(d1$country),
                                                       selected = "United States"),
                                           hr(),
                                           # Use an input selector to choose the second country
                                           # Note that technically a person could choose the same country as the first one
                                           # To avoid that you'd have to get a bit more tricky and move these selectInputs to the server
                                           # and create a reactive value that is country1 which could be used to filter the options for country2
                                           selectInput("country_2_from_gapminder", 
                                                       h5("Second country:"),
                                                       levels(d1$country),
                                                       selected = "Canada"),
                                           hr(),
                                           # Build a year range slider
                                           sliderInput("year_range",
                                                       label = h5("Range of years:"),
                                                       min = 1952,
                                                       max = 2007,
                                                       value = c(1952, 2007),
                                                       step = 5, 
                                                       sep = ""),
                              ),
                              
                              # this is where we specify what goes in the main panel
                              mainPanel(
                                 # Title of the plot (actually built on server side, but remember this makes the UI)
                                 h3(textOutput("output_countries_years")),
                                 # Placeholder for a Plotly plot
                                 plotlyOutput("ggplot_variable_vs_two_countries")
                              )
                )
)

# Define server logic
server <- function(input, output) {
   
   # Render the first Country Selector UI and map the output of that to a reactive variable
   country_from_gapminder <- renderUI({
      input$country_from_gapminder
   })
   
   # Render the second Country Selector UI and map the output of that to a reactive variable
   country_2_from_gapminder <- renderUI({
      input$country_2_from_gapminder
   })
   
   # Create the filtered data set of the two selected countries and the right years.
   # This is done in a reactive expression so it creates a reactive variable for the dataset
   # every time the inputs change, the dataset will update.  
   # We include some error handling here in case the country inputs are NULL
   two_country_data <- reactive({
      
      if(is.null(input$country_from_gapminder)){
         return(NULL)
      }
      
      if(is.null(input$country_2_from_gapminder)){
         return(NULL)
      }
      
      d1 %>% 
         select(country, year, continent, 
                matches(input$variable_from_gapminder)) %>% 
         filter(country %in% c(input$country_from_gapminder, 
                               input$country_2_from_gapminder),
                year >= min(input$year_range) & 
                   year <= max(input$year_range))
   })
   
   # Render country and range of years input from UI as text
   # This generates the title
   output$output_countries_years <- renderText({
      paste(input$country_from_gapminder, "and", 
            input$country_2_from_gapminder, 
            min(input$year_range), "-", max(input$year_range))
   })

   # Render ggplot plot based on variable input from radioButtons
   # Then, turn it into a Plotly plot using ggplotly
   # note that we had to use renderPlotly instead of renderPlot
   # we've included some error handling here again
   # and some If logic to determine what label we use for the Y axis
   output$ggplot_variable_vs_two_countries <- renderPlotly({
      
      if(is.null(two_country_data()$year)){
         return(NULL)
      }
      
      if(input$variable_from_gapminder == "pop") y_axis_label <- "Population (millions)"
      if(input$variable_from_gapminder == "lifeExp") y_axis_label <- "Life Expectancy (years)"
      if(input$variable_from_gapminder == "gdpPercap") y_axis_label <- "GDP Per Capita (in US dollars)"
      
      p1 <- ggplot(two_country_data(), aes_string(x = "year", 
                                                  y = input$variable_from_gapminder,
                                                  color = "country")) +
         geom_line(size = 1) +
         geom_point(size = 3) +
         labs(color = "Countries",
              x = "Year", y = y_axis_label) +
         scale_y_continuous(labels = scales::comma)
      
      ggplotly(p1)
      
   })
   
}

# Run the application 
shinyApp(ui = ui, server = server)
