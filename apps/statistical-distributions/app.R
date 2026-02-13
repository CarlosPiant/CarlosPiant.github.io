
#'This app will provide a user-friendly interface to explore various 
#'statistical distributions interactively!

# Load necessary libraries
library(shiny)
library(ggplot2)
library(halfmoon)

# Define UI
ui <- fluidPage(
  titlePanel("Statistical Distributions Simulator"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("distribution", "Select Distribution:",
                  choices = c("Normal", "Uniform", "Exponential", "Binomial", 
                              "Poisson", "Geometric", "Negative Binomial", 
                              "Beta", "Gamma", "Log-Normal", "Weibull","Gompertz")),
      
      uiOutput("paramInputs"),
      
      numericInput("n_samples", "Number of Samples:", value = 1000, min = 1),
      
      selectInput("plot_type", "Select Plot Type:",
                  choices = c("Density Plot", "Histogram")),
      
      actionButton("update", "Update Plots")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("PDF/PMF", plotOutput("pdfPlot")),
        tabPanel("CDF", plotOutput("cdfPlot"))
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # Dynamic UI for parameter inputs based on selected distribution
  output$paramInputs <- renderUI({
    dist <- input$distribution
    if (dist == "Normal") {
      tagList(
        numericInput("mean", "Mean:", value = 0),
        numericInput("sd", "Standard Deviation:", value = 1)
      )
    } else if (dist == "Uniform") {
      tagList(
        numericInput("min", "Minimum:", value = 0),
        numericInput("max", "Maximum:", value = 1)
      )
    } else if (dist == "Exponential") {
      tagList(
        numericInput("rate", "Rate (lambda):", value = 1)
      )
    } else if (dist == "Binomial") {
      tagList(
        numericInput("size", "Number of Trials (size):", value = 10),
        numericInput("prob", "Probability of Success (p):", value = 0.5)
      )
    } else if (dist == "Poisson") {
      tagList(
        numericInput("lambda", "Rate (lambda):", value = 1)
      )
    } else if (dist == "Geometric") {
      tagList(
        numericInput("p_geom", "Probability of Success (p):", value = 0.5)
      )
    } else if (dist == "Negative Binomial") {
      tagList(
        numericInput("size_nb", "Number of Successes (size):", value = 10),
        numericInput("mean_nb", "Mean (mu):", value = 1)
      )
    } else if (dist == "Beta") {
      tagList(
        numericInput("shape1", "Shape 1:", value = 2),
        numericInput("shape2", "Shape 2:", value = 5)
      )
    } else if (dist == "Gamma") {
      tagList(
        numericInput("shape_g", "Shape:", value = 2),
        numericInput("scale_g", "Scale:", value = 1)
      )
    } else if (dist == "Log-Normal") {
      tagList(
        numericInput("meanlog", "Meanlog:", value = 0),
        numericInput("sdlog", "Sdlog:", value = 1)
      )
    } else if (dist == "Weibull") {
      tagList(
        numericInput("shape_w", "Shape:", value = 1),
        numericInput("scale_w", "Scale:", value = 1)
      )
    } else if (dist == "Gompertz") {
      tagList(
        numericInput("shape_gom", "Shape:", value = 1),
        numericInput("scale_gom", "Scale:", value = 1)
      )
    }
  })
  
  # Generate plots based on selected distribution
  observeEvent(input$update, {
    dist <- input$distribution
    n_samples <- input$n_samples
    samples <- NULL
    
    if (dist == "Normal") {
      samples <- rnorm(n_samples, mean = input$mean, sd = input$sd)
    } else if (dist == "Uniform") {
      samples <- runif(n_samples, min = input$min, max = input$max)
    } else if (dist == "Exponential") {
      samples <- rexp(n_samples, rate = input$rate)
    } else if (dist == "Binomial") {
      samples <- rbinom(n_samples, size = input$size, prob = input$prob)
    } else if (dist == "Poisson") {
      samples <- rpois(n_samples, lambda = input$lambda)
    } else if (dist == "Geometric") {
      samples <- rgeom(n_samples, prob = input$p_geom)
    } else if (dist == "Negative Binomial") {
      samples <- rnbinom(n_samples, size = input$size_nb, mu = input$mean_nb)
    } else if (dist == "Beta") {
      samples <- rbeta(n_samples, shape1 = input$shape1, shape2 = input$shape2)
    } else if (dist == "Gamma") {
      samples <- rgamma(n_samples, shape = input$shape_g, scale = input$scale_g)
    } else if (dist == "Log-Normal") {
      samples <- rlnorm(n_samples, meanlog = input$meanlog, sdlog = input$sdlog)
    } else if (dist == "Weibull") {
      samples <- rweibull(n_samples, shape = input$shape_w, scale = input$scale_w)
    } else if (dist == "Gompertz") {
      samples <- rgompertz(n_samples, shape = input$shape_gom, scale = input$scale_gom)
    }
    
    # Plot PDF/PMF or Density Plot
    output$pdfPlot <- renderPlot({
      if (input$plot_type == "Density Plot") {
        ggplot(data.frame(samples), aes(x = samples)) +
          #geom_histogram(aes(y = ..count..), bins = 30, fill = "blue", alpha = 0.5) +
          geom_density(fill = "blue", alpha = 0.5) +
          labs(title = paste(dist, "Density Plot"), x = "Value", y = "Density") +
          theme_minimal()
      } else {
        ggplot(data.frame(samples), aes(x = samples)) +
          geom_histogram(aes(y = ..count..), bins = 30, fill = "blue", alpha = 0.5) +
          labs(title = paste(dist, "Histogram"), x = "Value", y = "Density") +
          theme_minimal()
      }
    })
    
    # Plot CDF
    output$cdfPlot <- renderPlot({
      ggplot(data.frame(samples), aes(x = samples)) +
        geom_ecdf(color = "red") +
        labs(title = paste(dist, "CDF"), x = "Value", y = "Cumulative Probability") +
        theme_minimal()
    })
  })
}

# Run the application 
shinyApp(ui = ui, server = server)