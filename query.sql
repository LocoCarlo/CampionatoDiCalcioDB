-- 1. Tutte le città in cui la squadra UDINESE 
--    ha giocato almeno 2 ed al massimo 3 volte (esattamente 2 o 3 volte)
SELECT DISTINCT S.citta
FROM Squadra SCasa, Squadra STrasferta, Partita P, Giocata G, Stadio S
WHERE SCasa.nome = P.squadra_casa AND
      STrasferta.nome = P.squadra_trasferta AND
      P.id_giocata = G.id_giocata AND
      S.indirizzo = P.indirizzo AND
      (SCasa.nome = 'Udinese' OR STrasferta.nome = 'Udinese') AND
      EXISTS(SELECT * --Almeno 2
                 FROM Squadra SCasa2, Squadra STrasferta2, Partita P2, Giocata G2, Stadio S2
                 WHERE SCasa2.nome = P.squadra_casa AND
                       STrasferta2.nome = P2.squadra_trasferta AND
                       P2.id_giocata = G2.id_giocata AND
                       S2.indirizzo = P2.indirizzo AND
                       (SCasa2.nome = 'Udinese' OR STrasferta2.nome = 'Udinese')  AND
                       P2.data <> P.data AND
                       S2.citta = S.citta
                       )
     AND NOT EXISTS(SELECT * -- Al max 3 (esattamente 3)
                     FROM Squadra SCasa2, Squadra STrasferta2, Partita P2, Giocata G2, Stadio S2,
                          Squadra SCasa3, Squadra STrasferta3, Partita P3, Giocata G3, Stadio S3,
                          Squadra SCasa4, Squadra STrasferta4, Partita P4, Giocata G4, Stadio S4
                     WHERE SCasa2.nome = P2.squadra_casa AND 
                           STrasferta2.nome = P2.squadra_trasferta AND
                           P2.id_giocata = G2.id_giocata AND
                           S2.indirizzo = P2.indirizzo AND
                           (SCasa2.nome = 'Udinese' OR STrasferta2.nome = 'Udinese')  AND

                           SCasa3.nome = P3.squadra_casa AND 
                           STrasferta3.nome = P3.squadra_trasferta AND
                           P3.id_giocata = G3.id_giocata AND
                           S3.indirizzo = P3.indirizzo AND
                           (SCasa3.nome = 'Udinese' OR STrasferta3.nome = 'Udinese')  AND

                           SCasa4.nome = P4.squadra_casa AND 
                           STrasferta4.nome = P4.squadra_trasferta AND
                           P4.id_giocata = G4.id_giocata AND
                           S4.indirizzo = P4.indirizzo AND
                           (SCasa4.nome = 'Udinese' OR STrasferta4.nome = 'Udinese')  AND

                           P2.data <> P.data AND P2.data <> P3.data AND P2.data <> P4.data AND P3.data <> P4.data
                           AND P3.data <> P.data AND P.data <> P4.data AND

                           S2.citta = S.citta AND S3.citta = S.citta AND S4.citta <> S.citta
                       )



-- 2  Il numero di giocatori che hanno giocato almeno 3 partite
--   
SELECT COUNT(DISTINCT cf) AS NumGiocatori
FROM ha_giocato g1
WHERE EXISTS (
    SELECT *
    FROM ha_giocato g2
    WHERE g2.cf = g1.cf 
      AND g1.id_giocata <> g2.id_giocata 
      AND EXISTS (
            SELECT *
            FROM ha_giocato g3
            WHERE g3.cf = g1.cf 
              AND g3.id_giocata <> g2.id_giocata 
              AND g1.id_giocata <> g3.id_giocata
      )
)



-- 3 Il numero di giocatori che appartengono alla squadra UDINESE e che hanno
--   giocato solo partite contro o la squadra INTER o la squadra MILAN 
SELECT COUNT(DISTINCT cf) AS NumGiocatori
FROM giocatore g1
WHERE g1.squadra = 'Udinese' AND
      NOT EXISTS(SELECT *
                  FROM ha_giocato h1, partita p1, giocatore g2
                  WHERE p1.id_giocata= h1.id_giocata AND
                        g2.cf = g1.cf AND
                        h1.cf = g2.cf AND
                        (p1.squadra_casa <> 'Milan' OR p1.squadra_trasferta <> 'Milan') AND
                        (p1.squadra_casa <> 'Inter' OR p1.squadra_trasferta <> 'Inter') 
                  )


-- 4 Il nome delle squadre che hanno giocato almeno 
--   una partita in casa in uno stadio diverso dal proprio
SELECT DISTINCT squadra_casa
FROM giocata g1, partita p1
WHERE g1.id_giocata = p1.id_giocata AND
      g1.stadio_proprieta = 'N'



-- 5 il CF degli arbitri di Udine che hanno diretto 
--   esattamente 1 o 3 partite 
SELECT cf
FROM arbitro a1, giocata g1
WHERE a1.citta = 'Illinois' AND
      a1.cf = g1.arbitro AND
      NOT EXISTS(SELECT *
                  FROM arbitro a2, giocata g2
                  WHERE a1.cf = a2.cf AND
                       a2.cf = g2.arbitro AND
                       g1.id_giocata <> g2.id_giocata)
UNION 
SELECT a1.cf
FROM arbitro a1, arbitro a2, arbitro a3, giocata g1, giocata g2, giocata g3
WHERE a1.citta = 'Illinois' AND
      a1.cf = g1.arbitro AND
      a2.cf = g2.arbitro AND
      a3.cf = g3.arbitro AND
      a1.cf = a2.cf AND
      a2.cf = a3.cf AND
      g1.id_giocata <> g2.id_giocata AND
      g2.id_giocata <> g3.id_giocata AND
      g1.id_giocata <> g3.id_giocata AND
      NOT EXISTS (SELECT *
                  FROM arbitro a4, giocata g4
                  WHERE a4.cf = g4.arbitro AND
                        a4.cf = a1.cf AND
                        g1.id_giocata <> g4.id_giocata AND
                        g2.id_giocata <> g4.id_giocata AND
                        g3.id_giocata <> g4.id_giocata )



-- 6 le partite rinviate che sono state giocate successivamente 
--   nello stadio della squadra in trasferta
SELECT g1.id_giocata
FROM giocata g1, partita p1, squadra qc, squadra qt, stadio sc, stadio st
WHERE g1.id_giocata = p1.id_giocata AND
      p1.squadra_casa = qc.nome AND
      p1.squadra_trasferta = qt.nome AND
      qc.indirizzo = sc.indirizzo AND
      qt.indirizzo = st.indirizzo AND
      p1.tipo = 'nonGiocata' AND
      g1.stadio_proprieta = 'N' AND
      g1.nome_stadio = qt.indirizzo


-- 7 Le squadre che hanno in comune la città con un altra squadra
SELECT nome
FROM squadra s1
WHERE EXISTS (SELECT citta
			  FROM squadra s2
			  WHERE s1.nome <> s2.nome AND
			        s1.citta = s2.citta)



-- 8 Tutte le squadre che hanno vinto almeno 10 partite 
--   alla fine del campionato
CREATE VIEW ContaVittorie AS 
SELECT squadra, COUNT(*) AS conteggio
FROM esito e1
WHERE e1.punti = 3
GROUP BY squadra

SELECT cv1.squadra
FROM ContaVittorie cv1
WHERE cv1.conteggio >= 15


