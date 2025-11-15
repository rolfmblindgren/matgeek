library(shiny)

##############################################
# KONSTANTER OG HJELPEFUNKSJONER
##############################################

c_water <- 4180  # J/kg°C

# Tid i sekunder for å varme vann
heat_time <- function(mass_kg, dT, watt, eff) {
  E <- mass_kg * c_water * dT
  P <- watt * eff
  E / P
}

# Slutt-temp ved blanding
mix_temp <- function(mv, mm, Tv, Tm) {
  (mv*Tv + mm*Tm) / (mv + mm)
}

##############################################
# UI
##############################################

ui <- navbarPage(
  "Kjøkkenfysikk",

  ##################################################
  # FANE 1: Oppvarming
  ##################################################
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
        h3("Tid:"),
        verbatimTextOutput("tid_heat")
      )
    )
  ),

  ##################################################
  # FANE 2: Blanding
  ##################################################
  tabPanel("Blanding vann og melk",
    sidebarLayout(
      sidebarPanel(
        numericInput("mv", "Mengde vann (dl):", 7.5),
        numericInput("mm", "Mengde melk (dl):", 2.0),
        numericInput("Tm", "Temperatur på melk (°C):", 4),
        numericInput("Ts", "Ønsket slutt-temperatur (°C):", 37),
        actionButton("calc_mix", "Beregn nødvendig vanntemperatur"),
        hr(),
        h4("Hva blir temperaturen hvis jeg bare blander?"),
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

  ##################################################
  # FANE 3: Kurver og energi
  ##################################################
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
        numericInput("kost_kwh", "Strømpris (kr/kWh):", 1.50)
      ),
      mainPanel(
        h3("Temperatur som funksjon av tid:"),
        plotOutput("heat_curve"),
        hr(),
        h3("Anslag for energibruk:"),
        verbatimTextOutput("energi_kostnad")
      )
    )
  ),

  ##################################################
  # FANE 4: Springtemperatur
  ##################################################
  tabPanel("Springtemperatur",
    sidebarLayout(
      sidebarPanel(
        h4("Typiske temperaturer i springvann"),
        helpText("Dette er omtrentlige tall basert på norske forhold."),
        hr(),
        actionButton("calc_spring", "Vis anbefalinger")
      ),
      mainPanel(
        h3("Vanlige intervaller i Norge:"),
        verbatimTextOutput("spring_ranges"),
        hr(),
        h3("Hva bør man anta i beregninger?"),
        verbatimTextOutput("spring_suggestion"),
        br(),
        p("Vintervann kan være overraskende kaldt. På en del steder i landet er
           3–7 °C vanlig når det er kaldest ute.
           Sommeren gir ofte 10–15 °C, litt høyere der stigerørene ligger varmt.")
      )
    )
  )
)

##############################################
# SERVER
##############################################

server <- function(input, output) {

  ############################
  # FANE 1 – oppvarming
  ############################
  observeEvent(input$calc_heat, {
    mass <- input$mengde / 10
    dT   <- input$sluttemp - input$starttemp
    t    <- heat_time(mass, dT, input$watt, input$eff / 100)

    minutter <- floor(t / 60)
    sekunder <- round(t %% 60)

    output$tid_heat <- renderText(
      sprintf("≈ %d min %02d sek", minutter, sekunder)
    )
  })

  ############################
  # FANE 2 – blanding
  ############################
  observeEvent(input$calc_mix, {
    mv <- input$mv
    mm <- input$mm
    Tm <- input$Tm
    Ts <- input$Ts

    Tv <- (Ts*(mv + mm) - mm*Tm) / mv
    output$Tv_needed <- renderText(sprintf("≈ %.1f °C", Tv))
  })

  observeEvent(input$calc_mix2, {
    Tmix <- mix_temp(input$mv, input$mm, input$Tv2, input$Tm)
    output$T_mix_raw <- renderText(sprintf("≈ %.1f °C", Tmix))
  })

  ############################
  # FANE 3 – kurver og energi
  ############################
  observeEvent(input$plot_heat, {

    mass <- input$mengde3 / 10
    Ti <- input$start3
    Tf <- input$slutt3
    dT <- Tf - Ti

    tot_t <- heat_time(mass, dT, input$watt3, input$eff3 / 100)

    t <- seq(0, tot_t, length.out = 200)
    T <- Ti + (dT) * (t / tot_t)

    output$heat_curve <- renderPlot({
      plot(t, T, type = "l", lwd = 2,
           xlab = "Tid (sekunder)",
           ylab = "Temperatur (°C)",
           main = "Temperatur som funksjon av tid")
      grid()
    })

    E_J   <- mass * c_water * dT
    E_kWh <- E_J / 3.6e6
    kost  <- E_kWh * input$kost_kwh

    output$energi_kostnad <- renderText(
      sprintf("Energibruk: %.3f kWh\nKostnad: %.2f kr", E_kWh, kost)
    )
  })

  ############################
  # FANE 4 – springtemperatur
  ############################
  observeEvent(input$calc_spring, {
    output$spring_ranges <- renderText(
      paste(
        "• Vinter: 3–10 °C",
        "• Vår/høst: 7–12 °C",
        "• Sommer: 10–15 °C (kan være høyere i blokk)",
        sep = "\n"
      )
    )

    output$spring_suggestion <- renderText(
      "For beregninger anbefales:
– 8 °C om vinteren
– 12 °C ellers i året

Begge er gode overslag."
    )
  })
}

shinyApp(ui, server)
