
library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)

# ----------------------------
# Survival / hazard functions
# ----------------------------
S_exp <- function(t, rate) exp(-rate * t)
h_exp <- function(t, rate) rep(rate, length(t))

# Weibull parameterization: S(t) = exp(-(t/scale)^shape)
S_weib <- function(t, shape, scale) exp(- (t / scale)^shape)
h_weib <- function(t, shape, scale) (shape / scale) * (t / scale)^(shape - 1)

# ----------------------------
# Shiny app
# ----------------------------
ui <- fluidPage(
  titlePanel("Survival curves + time-varying RR, HR, OR (Treatment vs Control)"),
  sidebarLayout(
    sidebarPanel(
      selectInput("dist", "Distribution",
                  choices = c("Exponential", "Weibull"),
                  selected = "Weibull"),
      tags$hr(),
      
      numericInput("tmax", "Max time", value = 10, min = 0.1, step = 0.5),
      numericInput("npts", "Time points", value = 400, min = 50, step = 50),
      tags$hr(),
      
      conditionalPanel(
        condition = "input.dist == 'Exponential'",
        h4("Exponential parameters"),
        numericInput("rate_c", "Control rate (λc)", value = 0.15, min = 1e-6, step = 0.01),
        numericInput("rate_t", "Treatment rate (λt)", value = 0.10, min = 1e-6, step = 0.01),
        helpText("Exponential: S(t)=exp(-λ t), hazard=λ (constant). HR(t)=λt/λc (constant).")
      ),
      
      conditionalPanel(
        condition = "input.dist == 'Weibull'",
        h4("Weibull parameters"),
        
        checkboxInput(
          "ph_weibull",
          "Proportional hazards (force equal Weibull shapes across groups)",
          value = FALSE
        ),
        helpText("When enabled, kt is forced to equal kc, so HR(t) becomes constant over time."),
        tags$hr(style = "margin-top: 8px;"),
        
        tags$div(style="margin-bottom:6px;", strong("Control")),
        numericInput("shape_c", "Control shape (kc)", value = 1.4, min = 0.05, step = 0.05),
        numericInput("scale_c", "Control scale (sc)", value = 6, min = 1e-6, step = 0.25),
        
        tags$div(style="margin-top:10px; margin-bottom:6px;", strong("Treatment")),
        numericInput("shape_t", "Treatment shape (kt)", value = 1.0, min = 0.05, step = 0.05),
        numericInput("scale_t", "Treatment scale (st)", value = 7, min = 1e-6, step = 0.25),
        
        # Little visual cue when PH is on (and kt is ignored)
        uiOutput("phNotice"),
        
        helpText("Weibull: S(t)=exp(-(t/scale)^shape), h(t)=(shape/scale)*(t/scale)^(shape-1).")
      ),
      
      tags$hr(),
      checkboxInput("clip_metrics", "Clip extreme metric values (for readability)", value = TRUE),
      numericInput("clip_at", "Clip at (max)", value = 10, min = 1, step = 1),
      helpText("RR/OR can explode when risk_control(t) ~ 0. Clipping helps visualization early in time.")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Survival curves", plotOutput("survPlot", height = 420)),
        tabPanel("RR / HR / OR vs time", plotOutput("metricPlot", height = 460)),
        tabPanel("Definitions",
                 tags$ul(
                   tags$li("Risk(t) = 1 - S(t)"),
                   tags$li("RR(t) = Risk_t(t) / Risk_c(t)"),
                   tags$li("OR(t) = [Risk_t(t)/(1-Risk_t(t))] / [Risk_c(t)/(1-Risk_c(t))]"),
                   tags$li("HR(t) = h_t(t) / h_c(t)"),
                   tags$li("For Exponential, HR(t) is constant. For Weibull, HR(t) can vary if shapes differ.")
                 )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  output$phNotice <- renderUI({
    req(input$dist == "Weibull")
    if (isTRUE(input$ph_weibull)) {
      tags$div(
        style = "margin-top:8px; padding:8px; background:#f5f5f5; border-radius:6px;",
        strong("PH on: "), "kt is set to kc (the kt input is ignored)."
      )
    }
  })
  
  dat <- reactive({
    t <- seq(0, input$tmax, length.out = input$npts)
    
    if (input$dist == "Exponential") {
      Sc <- S_exp(t, input$rate_c)
      St <- S_exp(t, input$rate_t)
      hc <- h_exp(t, input$rate_c)
      ht <- h_exp(t, input$rate_t)
    } else {
      # If PH toggle is ON, force equal shapes
      shape_c <- input$shape_c
      shape_t <- if (isTRUE(input$ph_weibull)) shape_c else input$shape_t
      
      Sc <- S_weib(t, shape_c, input$scale_c)
      St <- S_weib(t, shape_t, input$scale_t)
      hc <- h_weib(t, shape_c, input$scale_c)
      ht <- h_weib(t, shape_t, input$scale_t)
    }
    
    # Risk (cumulative incidence)
    Rc <- 1 - Sc
    Rt <- 1 - St
    
    # Avoid division issues at very early times (Rc ~ 0)
    eps <- 1e-12
    RR <- Rt / pmax(Rc, eps)
    
    odds_c <- Rc / pmax(1 - Rc, eps)
    odds_t <- Rt / pmax(1 - Rt, eps)
    OR <- odds_t / pmax(odds_c, eps)
    
    HR <- ht / pmax(hc, eps)
    
    out <- tibble(
      time = t,
      Sc = Sc, St = St,
      Rc = Rc, Rt = Rt,
      RR = RR, OR = OR, HR = HR
    )
    
    if (isTRUE(input$clip_metrics)) {
      cap <- input$clip_at
      out <- out %>%
        mutate(
          RR = pmin(RR, cap),
          OR = pmin(OR, cap),
          HR = pmin(HR, cap)
        )
    }
    
    out
  })
  
  output$survPlot <- renderPlot({
    df <- dat() %>%
      select(time, Control = Sc, Treatment = St) %>%
      pivot_longer(cols = c(Control, Treatment), names_to = "Group", values_to = "Survival")
    
    ggplot(df, aes(x = time, y = Survival, linetype = Group)) +
      geom_line(linewidth = 1) +
      scale_y_continuous(limits = c(0, 1)) +
      labs(x = "Time", y = "Survival S(t)", linetype = "Group") +
      theme_minimal(base_size = 13)
  })
  
  output$metricPlot <- renderPlot({
    df <- dat() %>%
      select(time, RR, HR, OR) %>%
      pivot_longer(cols = c(RR, HR, OR), names_to = "Metric", values_to = "Value")
    
    subtitle_txt <- if (isTRUE(input$clip_metrics)) {
      paste0("Values clipped at ", input$clip_at, " for readability")
    } else {
      "No clipping"
    }
    
    ggplot(df, aes(x = time, y = Value, linetype = Metric)) +
      geom_hline(yintercept = 1, linewidth = 0.6) +
      geom_line(linewidth = 1) +
      labs(
        x = "Time",
        y = "Effect measure (time-varying)",
        linetype = "Metric",
        subtitle = subtitle_txt
      ) +
      theme_minimal(base_size = 13)
  })
}

shinyApp(ui, server)
