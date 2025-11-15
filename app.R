library(shiny)

###############################
# Felles fysikkfunksjoner
###############################

# spesifikk varmekapasitet for vann (og melk ~ vann)
c_water <- 4180   # J/kg°C

# Oppvarmingstid (sekunder)
heat_time <- function(mass_kg, dT, watt, eff) {
  E <- mass_kg * c_water * dT
  P <- watt * eff
  t <- E / P
  return(t)
}

# Temperatur etter blanding
mix_temp <- function(mv, mm, Tv, Tm) {
  # mv, mm i kg (eller dl – spiller ingen rolle siden cp er likt)
  (mv*Tv + mm*Tm) / (mv + mm)
}

###############################
# UI
###############################

ui <- navbarPage(
  "Kjøkkenfysikk",

  #######################################
  # FANE 1: OPPVARMING AV VANN
  #######################################
  tabPanel("Oppvarming av vann",
    sidebarLayout(
      sidebarPanel(
        numericInput("watt", "Effekt (W):", 2000, min = 200),
        numericInput("mengde", "Mengde vann (dl):", 7.5, min = 0.1),
        numericInput("starttemp", "Starttemperatur (°C):", 10),
        numericInput("sluttemp", "Måltemperatur (°C):", 75),
        sliderInput("eff", "Effektivitet (%):", 50, 100, 90),
        actionButton("calc_heat", "Beregn")
      ),
      mainPanel(
        h3("Tid til ønsket temperatur:"),
        verbatimTextOutput("tid_heat")
      )
    )
  ),

  #######################################
  # FANE 2: BLANDING VANN OG MELK
  #######################################
  tabPanel("Blanding vann og melk",
    sidebarLayout(
      sidebarPanel(
        numericInput("mv", "Mengde vann (dl):", 7.5, min = 0.1),
        numericInput("mm", "Mengde melk (dl):", 2.0, min = 0.1),
        numericInput("Tm", "Temperatur på melk (°C):", 4),
        numericInput("Ts", "Ønsket slutt-temperatur (°C):", 37),
        actionButton("calc_mix", "Beregn nødvendig vanntemp"),
        hr(),
        h4("Hva blir temperaturen hvis jeg bare blander disse to?"),
        numericInput("Tv2", "Vanntemperatur (°C):", 60),
        actionButton("calc_mix2", "Beregn blandet temperatur")
      ),
      mainPanel(
        h3("Nødvendig temperatur på vannet:"),
        verbatimTextOutput("Tv_needed"),
        hr(),
        h3("Temperaturen på blandingen:"),
        verbatimTextOutput("T_mix_raw")
      )
    )
  ),

  #######################################
  # FANE 3: KURVER OG ENERGI
  #######################################
  tabPanel("Kurver og energi",
    sidebarLayout(
      sidebarPanel(
        h4("Oppvarmingskurve"),
        numericInput("watt3", "Effekt (W):", 2000),
        numericInput("mengde3", "Mengde vann (dl):", 7.5),
        numericInput("start3", "Starttemperatur (°C):", 10),
        numericInput("slutt3", "Sluttemperatur (°C):", 75),
        sliderInput("eff3", "Effektivitet (%):", 50, 100, 90),
        actionButton("plot_heat", "Tegn kurve"),
        hr(),
        h4("Energi og kostnad"),
        numericInput("kost_kwh", "Strømpris (kr/kWh):", 0.4)
      ),
      mainPanel(
        h3("Temperatur som funksjon av tid:"),
        plotOutput("heat_curve"),
        hr(),
        h3("Anslag for energibruk:"),
        verbatimTextOutput("energi_kostnad")
      )
    )
  )
)

###############################
# SERVER
###############################

server <- function(input, output) {

  #################################
  # FANE 1 – oppvarmingstid
  #################################
  observeEvent(input$calc_heat, {

    mass <- input$mengde / 10
    dT   <- input$sluttemp - input$starttemp
    watt <- input$watt
    eff  <- input$eff / 100

    if (dT <= 0) {
      output$tid_heat <- renderText("Sluttemperaturen må være høyere enn starttemperaturen.")
      return()
    }

    t <- heat_time(mass, dT, watt, eff)
    minutter <- floor(t / 60)
    sekunder <- round(t %% 60)

    output$tid_heat <- renderText(
      sprintf("≈ %d min %02d sek", minutter, sekunder)
    )
  })

  #################################
  # FANE 2 – blanding
  #################################

  # hvor varmt må vannet være
  observeEvent(input$calc_mix, {
    mv <- input$mv
    mm <- input$mm
    Tm <- input$Tm
    Ts <- input$Ts

    Tv <- (Ts*(mv + mm) - mm*Tm) / mv

    output$Tv_needed <- renderText(
      sprintf("Vannet må holde ca. %.1f °C.", Tv)
    )
  })

  # temperatur direkte ved blanding
  observeEvent(input$calc_mix2, {
    mv <- input$mv
    mm <- input$mm
    Tv <- input$Tv2
    Tm <- input$Tm

    T_mix <- mix_temp(mv, mm, Tv, Tm)

    output$T_mix_raw <- renderText(
      sprintf("Blandingen blir ca. %.1f °C.", T_mix)
    )
  })

  #################################
  # FANE 3 – kurver og energi
  #################################

  # oppvarmingskurve
  observeEvent(input$plot_heat, {

    mass <- input$mengde3 / 10
    Ti <- input$start3
    Tf <- input$slutt3
    watt <- input$watt3
    eff  <- input$eff3 / 100
    dT <- Tf - Ti

    tot_t <- heat_time(mass, dT, watt, eff)

    t <- seq(0, tot_t, length.out = 200)
    T <- Ti + (dT) * (t / tot_t)

    output$heat_curve <- renderPlot({
      plot(t, T, type = "l",
           xlab = "Tid (sekunder)",
           ylab = "Temperatur (°C)",
           main = "Temperatur som funksjon av tid")
      grid()
    })

    # energi og kostnad:
    E_J <- mass * c_water * dT
    E_kWh <- E_J / (3.6e6)
    kost <- E_kWh * input$kost_kwh

    output$energi_kostnad <- renderText({
      sprintf("Energibruk: %.3f kWh\nKostnad: %.2f kr (ved %.2f kr/kWh)",
              E_kWh, kost, input$kost_kwh)
    })
  })
}

shinyApp(ui, server)
