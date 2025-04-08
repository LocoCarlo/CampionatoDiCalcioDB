# Installazione e caricamento dei pacchetti
if (!require(RPostgres)) install.packages("RPostgres")
if (!require(DBI)) install.packages("DBI")
library(DBI)
library(RPostgres)

# Connessione a PostgreSQL
con <- dbConnect(RPostgres::Postgres(), 
                 dbname = 'CAMPIONATO',
                 host = '127.0.0.1', 
                 port = 5432,
                 user = 'postgres', 
                 password = '')

# Lettura di nomi e cognomi
v_nomi <- readLines("/Users/user/Desktop/Rprova/nomi.txt")
v_cognomi <- readLines("/Users/user/Desktop/Rprova/cognomi.txt")

# Funzione per generare un codice fiscale casuale
generate_cf <- function() {
  paste0(
    paste(sample(LETTERS, 6, replace = TRUE), collapse = ""),
    paste(sample(0:9, 2, replace = TRUE), collapse = ""),
    sample(LETTERS, 1),
    paste(sample(0:9, 2, replace = TRUE), collapse = ""),
    sample(LETTERS, 1),
    paste(sample(0:9, 3, replace = TRUE), collapse = ""),
    sample(LETTERS, 1)
  )
}

# Generazione di codici fiscali unici
cf_list <- character(0)
while (length(cf_list) < 500) {
  new_cf <- generate_cf()
  if (!(new_cf %in% cf_list)) {
    cf_list <- c(cf_list, new_cf)
  }
}

# Creazione dataframe per citta
df_citta <- data.frame(
  nome_citta = unique(c("Bergamo", "Bologna", "Cagliari", "Como", "Empoli", 
                        "Firenze", "Genova", "Milano", "Torino", "Roma", 
                        "Lecce", "Monza", "Napoli", "Parma", "Udine", 
                        "Venezia", "Verona"))
)

# Creazione dataframe per stadio
set.seed(123)  # Per risultati riproducibili
df_stadio <- data.frame(
  indirizzo = paste("Via", sample(LETTERS, 17, replace = TRUE), sample(1:100, 17, replace = TRUE)),
  citta = df_citta$nome_citta,  # Usa solo città presenti in df_citta
  capacita = sample(12000:75817, 17, replace = TRUE),
  num_partite = integer(17)
)

# Creazione dataframe per giornata
df_giornata <- data.frame(
  num_giornata = 1:38
)



# Creazione dataframe per esito
set.seed(Sys.time())
df_esito <- data.frame(
  squadra = rep(df_squadra$nome, each = 38),
  giornata = rep(1:38, times = 20),
  punti = sample(c(0, 1, 3), 760, replace = TRUE, prob = c(0.33, 0.34, 0.33))
)



# Creazione dataframe per squadra
df_squadra <- data.frame(
  nome = c("Atalanta", "Bologna", "Cagliari", "Como", "Empoli", 
           "Fiorentina", "Genoa", "Inter", "Juventus", "Lazio", 
           "Lecce", "Milan", "Monza", "Napoli", "Parma", 
           "Roma", "Torino", "Udinese", "Venezia", "Verona"),
  citta = c("Bergamo", "Bologna", "Cagliari", "Como", "Empoli", 
            "Firenze", "Genova", "Milano", "Torino", "Roma", 
            "Lecce", "Milano", "Monza", "Napoli", "Parma", 
            "Roma", "Torino", "Udine", "Venezia", "Verona")
)

df_squadra <- merge(df_squadra, df_stadio[, c("citta", "indirizzo")], by = "citta", all.x = TRUE)


# Calcolo dei punti totali per ogni squadra da df_esito
#punti_per_squadra <- aggregate(punti ~ squadra, data = df_esito, sum)
punti_per_squadra <- df_esito %>%
  group_by(squadra) %>%
  mutate(punti_cumulativi = cumsum(punti)) %>%
  summarise(punti = max(punti_cumulativi, na.rm = TRUE)) %>%
  ungroup()

# Unisci i punti calcolati con df_squadra
df_squadra <- left_join(df_squadra, punti_per_squadra, by = c("nome" = "squadra"))

# Sostituisci i NA con 0 per squadre che non hanno esiti
df_squadra$punti[is.na(df_squadra$punti)] <- 0

# Controllo finale
df_squadra[order(-df_squadra$punti), c("nome", "punti")]

# Creazione dataframe per persona
df_persona <- data.frame(
  nome = sample(v_nomi, 500, replace = TRUE),
  cognome = sample(v_cognomi, 500, replace = TRUE),
  cf = cf_list
)

# Suddivisione casuale in tipo persona
giocatori_index <- sample(1:500, 460)  # 460 giocatori
restanti_index <- setdiff(1:500, giocatori_index)
allenatori_index <- sample(restanti_index, 20)  # 20 allenatori
arbitri_index <- setdiff(restanti_index, allenatori_index)  # 20 arbitri

# Creazione dataframe per giocatore con ruoli fissi
set.seed(123)  # Per risultati riproducibili
fixed_roles <- data.frame()
for (squadra in df_squadra$nome) {
  giocatori_squadra <- df_persona[sample(1:nrow(df_persona), 23), ]
  giocatori_squadra$squadra <- squadra
  ruoli_fissi <- c(rep("Portiere", 3), rep("Difensore", 7), rep("Centrocampista", 7), rep("Attaccante", 6))
  giocatori_squadra$ruolo_principale <- ruoli_fissi
  giocatori_squadra$data_nascita <- sample(seq.Date(from = as.Date("1984-01-01"),
                                                    to = as.Date("2008-12-31"),
                                                    by = "day"), size = nrow(giocatori_squadra), replace = TRUE)
  fixed_roles <- rbind(fixed_roles, giocatori_squadra)
}
df_giocatore <- fixed_roles

# Creazione dataframe per allenatore
df_allenatore <- df_persona[allenatori_index, ]
df_allenatore$squadra <- sample(df_squadra$nome, nrow(df_allenatore), replace = FALSE)

# Creazione dataframe per arbitro
df_arbitro <- df_persona[arbitri_index, ]
df_arbitro$regione <- sample(state.name, nrow(df_arbitro), replace = TRUE)
df_arbitro$citta <- sample(state.name, nrow(df_arbitro), replace = TRUE)

# Generazione dataframe giocata
ordered_dates <- seq.Date(as.Date("2024-08-01"), as.Date("2025-05-31"), by = "day")
ordered_dates <- ordered_dates[1:380]
ordered_dates <- sort(ordered_dates)

df_giocata <- data.frame(
  id_giocata = 1:380,
  data = rep(ordered_dates, length.out = 380),
  regolare = sample(c("S", "N"), 380, replace = TRUE, prob = c(0.95, 0.05)),
  motivo = sample(c("Maltempo", "Problemi tecnici", "Sicurezza"), 380, replace = TRUE, prob = c(0.34, 0.33, 0.33)),
  stadio_proprieta = sample(c("S", "N"), 380, replace = TRUE, prob = c(0.95, 0.05)),
  nome_stadio = sample(df_stadio$indirizzo, 380, replace = TRUE),
  arbitro = sample(df_arbitro$cf, 380, replace = TRUE)
)
df_giocata$motivo <- ifelse(df_giocata$regolare == "S", NA, df_giocata$motivo)

for (i in which(df_giocata$stadio_proprieta == "N")) {
  altri_stadi <- setdiff(df_stadio$indirizzo, df_giocata$nome_stadio[i])
  df_giocata$nome_stadio[i] <- sample(altri_stadi, 1)
}

df_giocata$num_giornata <- rep(1:38, each = 10)

# Controllo finale
head(df_giocata)


# Aggiungi num_giornata seguendo l'ordine delle date
df_giocata$num_giornata <- rep(1:38, each = 10)


set.seed(123)  # Per risultati riproducibili

# Squadre e giornate
squadre <- df_squadra$nome
num_giornate <- 38
num_partite_per_giornata <- length(squadre) / 2

# Lista per raccogliere le partite
partite <- list()

# Generazione calendario round-robin rispettando le date ordinate in df_giocata
for (i in 1:num_giornate) {
  # Accoppiamenti diversi tra le squadre
  shuffled_squadre <- sample(squadre)
  
  # Seleziona le giocate relative alla giornata corrente
  giocate_giornata <- df_giocata[df_giocata$num_giornata == i, ]
  
  # Crea le partite rispettando le date ordinate
  giornata_partite <- data.frame(
    num_giornata = i,
    squadra_casa = shuffled_squadre[1:num_partite_per_giornata],
    squadra_trasferta = shuffled_squadre[(num_partite_per_giornata + 1):length(squadre)],
    tipo = sample(c("giocata", "nonGiocata"), num_partite_per_giornata, replace = TRUE, prob = c(0.95, 0.05)),
    girone = ifelse(i <= num_giornate / 2, "andata", "ritorno"),
    id_giocata = giocate_giornata$id_giocata,
    data = giocate_giornata$data
  )
  
  # Aggiungi alla lista
  partite[[i]] <- giornata_partite
}

# Unisci tutte le giornate
partite_df <- do.call(rbind, partite)

# Aggiungi indirizzo e città dello stadio in base alla squadra di casa
partite_df <- merge(partite_df, df_squadra[, c("nome", "indirizzo", "citta")], by.x = "squadra_casa", by.y = "nome", all.x = TRUE)
names(partite_df)[names(partite_df) == "citta"] <- "citta_stadio"
names(partite_df)[names(partite_df) == "indirizzo"] <- "indirizzo"

# Ordina le partite per num_giornata e data
partite_df <- partite_df[order(partite_df$num_giornata, partite_df$data), ]

# Assegna a df_partita
df_partita <- partite_df

# Controllo per verificare una sola partita per squadra per giornata
table(df_partita$num_giornata, df_partita$squadra_casa)
table(df_partita$num_giornata, df_partita$squadra_trasferta)






# Creazione dataframe per "ha_giocato" con ruoli fissi per ogni partita
num_giocatori_per_partita <- 22
ruoli_fissi <- c(rep("Portiere", 2), rep("Difensore", 8), rep("Centrocampista", 8), rep("Attaccante", 4))

# Lista per raccogliere le righe
lista_hagiocato <- list()

# Genera le righe per ogni partita
for (id in df_giocata$id_giocata) {
  # Seleziona casualmente 22 giocatori diversi per ogni partita
  giocatori_partita <- sample(df_giocatore$cf, num_giocatori_per_partita, replace = FALSE)
  
  # Assegna i ruoli fissi
  df_hagiocato_temp <- data.frame(
    id_giocata = rep(id, num_giocatori_per_partita),
    cf = giocatori_partita,
    ruolo_partita = ruoli_fissi
  )
  
  # Aggiungi alla lista
  lista_hagiocato[[length(lista_hagiocato) + 1]] <- df_hagiocato_temp
}

# Unisci tutto in un unico dataframe
df_hagiocato <- do.call(rbind, lista_hagiocato)

# Verifica il risultato
head(df_hagiocato)
table(df_hagiocato$ruolo_partita)



# SCRITTURA SU POSTGRES ----------------------------------------------------------

# Elimina le tabelle con CASCADE
# Truncate delle tabelle per evitare duplicati
dbExecute(con, "TRUNCATE TABLE ha_giocato RESTART IDENTITY CASCADE;")
dbExecute(con, "TRUNCATE TABLE esito RESTART IDENTITY CASCADE;")
dbExecute(con, "TRUNCATE TABLE partita RESTART IDENTITY CASCADE;")
dbExecute(con, "TRUNCATE TABLE giocata RESTART IDENTITY CASCADE;")
dbExecute(con, "TRUNCATE TABLE arbitro RESTART IDENTITY CASCADE;")
dbExecute(con, "TRUNCATE TABLE allenatore RESTART IDENTITY CASCADE;")
dbExecute(con, "TRUNCATE TABLE giocatore RESTART IDENTITY CASCADE;")
dbExecute(con, "TRUNCATE TABLE persona RESTART IDENTITY CASCADE;")
dbExecute(con, "TRUNCATE TABLE squadra RESTART IDENTITY CASCADE;")
dbExecute(con, "TRUNCATE TABLE giornata RESTART IDENTITY CASCADE;")
dbExecute(con, "TRUNCATE TABLE stadio RESTART IDENTITY CASCADE;")
dbExecute(con, "TRUNCATE TABLE citta RESTART IDENTITY CASCADE;")

# Scrittura delle tabelle sul database
dbWriteTable(con, "citta", df_citta, append = TRUE, row.names = FALSE)
dbWriteTable(con, "stadio", df_stadio, append = TRUE, row.names = FALSE)
dbWriteTable(con, "giornata", df_giornata, append = TRUE, row.names = FALSE)
dbWriteTable(con, "squadra", df_squadra, append = TRUE, row.names = FALSE)
dbWriteTable(con, "persona", df_persona, append = TRUE, row.names = FALSE)
dbWriteTable(con, "giocatore", df_giocatore, append = TRUE, row.names = FALSE)
dbWriteTable(con, "allenatore", df_allenatore, append = TRUE, row.names = FALSE)
dbWriteTable(con, "arbitro", df_arbitro, append = TRUE, row.names = FALSE)
dbWriteTable(con, "giocata", df_giocata, append = TRUE, row.names = FALSE)
dbWriteTable(con, "partita", df_partita, append = TRUE, row.names = FALSE)
dbWriteTable(con, "esito", df_esito, append = TRUE, row.names = FALSE)
dbWriteTable(con, "ha_giocato", df_hagiocato, append = TRUE, row.names = FALSE)


# Chiudi la connessione al database
#dbDisconnect(con)
#cat("Tabelle scritte con successo su PostgreSQL e connessione chiusa.\n")