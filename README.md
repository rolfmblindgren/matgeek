# Matgeek – kjøkkenfysikk i praksis

Matgeek er en liten Shiny-app som gjør enkle, men nyttige
fysikkberegninger for kjøkkenbruk:

- hvor lang tid det tar å varme vann
- hvilken temperatur vannet må ha for å gi riktig blanding med melk
- hvordan temperaturen utvikler seg over tid
- hvor mye energi (og penger) som faktisk går med

Appen er ment som et pedagogisk verktøy, ikke som laboratorieinstrument.



## 1. Oppvarming av vann

Tiden det tar å varme vann beregnes ved klassisk varmebalanse:

$$
E = m \cdot c \cdot \Delta T
$$

der

- $m$ = masse vann (kg)  
- $c$ = spesifikk varmekapasitet for vann  
  ($c \approx 4180 \,\text{J/kg·°C}$)  
- $\Delta T$ = temperaturendring (°C)

Effekten fra vannkokeren gir:

$$
t = \frac{E}{P}
$$

hvor

- $P$ = elektrisk effekt (W), justert for antatt effektivitet

I appen brukes:

$$
P_\text{effektiv} = P \cdot \eta
$$

der $\eta$ er effektiviteten (typisk 0,85–0,95).

### Antagelser
- Temperaturen stiger tilnærmet lineært
- Varmetap til omgivelsene er inkludert via effektiviteten
- Kokepunktet antas ikke nødvendigvis å være 100 °C
  (termostaten i vannkokere slår ofte av tidligere)



## 2. Blanding av vann og melk

Når vann og melk blandes, brukes enkel varmebalanse:

$$
T_\text{slutt} =
\frac{m_v T_v + m_m T_m}{m_v + m_m}
$$

der

- $m_v$, $m_m$ = mengde vann og melk
- $T_v$, $T_m$ = temperatur på vann og melk

Melk behandles som vann, siden varmekapasiteten er svært lik.

### Omvendt problem
Hvis ønsket slutt-temperatur er kjent, løses ligningen for $T_v$:

$$
T_v =
\frac{T_\text{slutt}(m_v + m_m) - m_m T_m}{m_v}
$$



## 3. Temperaturkurver

Temperatur som funksjon av tid modelleres som lineær:

$$
T(t) = T_0 + \Delta T \cdot \frac{t}{t_\text{tot}}
$$

Dette er en forenkling, men gir god overensstemmelse
med målinger for vanlige vannkokere.

Ikke-linearitet nær kokepunktet er liten sammenlignet
med måleusikkerhet og termostatforsinkelse.



## 4. Energiforbruk og kostnad

Energibruk beregnes som:

$$
E_\text{kWh} = \frac{m \cdot c \cdot \Delta T}{3.6 \cdot 10^6}
$$

Kostnad:

$$
\text{Kostnad} = E_\text{kWh} \cdot \text{pris}
$$



## 5. Springtemperatur

Typiske antagelser brukt i appen:

- Vinter: 3–10 °C
- Vår/høst: 7–12 °C
- Sommer: 10–15 °C

For beregninger anbefales:
- **8 °C vinter**
- **12 °C ellers**



## Presisjonsnivå

Resultatene er ment å være:

- fysisk rimelige
- pedagogisk nyttige
- innenfor noen få sekunders og graders nøyaktighet

Dette er mer enn godt nok for kjøkkenbruk,
og ofte bedre enn det brukeren selv kan måle.



## Lisens

Fri bruk. Ingen garantier. Hvis noe koker over, er det ikke appens skyld.
