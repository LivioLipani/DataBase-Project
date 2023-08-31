
CREATE TABLE Utente (
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    indirizzo VARCHAR(255) NOT NULL,
    nome VARCHAR(255) NOT NULL,
    cognome VARCHAR(255) NOT NULL,
    eta INTEGER NOT NULL CHECK (eta >=16 AND eta <=120)
    PRIMARY KEY (Email)
);

CREATE TABLE Spedizione (
    Id_spedizione INT NOT NULL AUTO_INCREMENT,
    id_profilospedizione INT,
    email_utente VARCHAR(255) NOT NULL,
    id_dest INT NOT NULL,
    id_mitt INT NOT NULL,
    tipo_spedizione VARCHAR(255) NOT NULL CHECK (tipo_spedizione ='Express' OR tipo_spedizione='Stardad'),
    importo_totale FLOAT DEFAULT 0,
    data_spedizione DATE NOT NULL,
    stato_spedizione VARCHAR(255) NOT NULL DEFAULT 'IN CORSO' CHECK (stato_spedizione ='IN CORSO' OR stato_spedizione = 'IN ATTESA' OR stato_spedizione = 'IN PREPARAZIONE' OR stato_spedizione ='CONSEGNATA'),
    PRIMARY KEY(id_spedizione),
    FOREIGN KEY (email_utente) REFERENCES Utente(email)
    FOREIGN KEY (id_dest) REFERENCES MittenteDestinatario(id_mittdest)
    FOREIGN KEY (id_mitt) REFERENCES MittenteDestinatario(id_mittdest)
);

CREATE TABLE Pacco (
    id_pacco INT NOT NULL AUTO_INCREMENT,
    altezza FLOAT DEFAULT 0,
    larghezza FLOAT DEFAULT 0,
    peso FLOAT DEFAULT 0,
    tipo_pacco VARCHAR(255) NOT NULL,
    id_spedizione INT NOT NULL,
    PRIMARY KEY(id_pacco),
    FOREIGN KEY (id_spedizione) REFERENCES Spedizione(Id_spedizione)
);

CREATE TABLE ProfiloSpedizione (
    partita_IVA VARCHAR(11) NOT NULL,
    email_utente VARCHAR(255) NOT NULL,
    nome_azienda VARCHAR(255) NOT NULL,
    frequenza VARCHAR(255) CHECK (frequenza ='Giornaliera' OR frequenza='Settimanale' OR frequenza='Mensile') NOT NULL,
    n_pacchi INT NOT NULL,
    tipo_spedizione VARCHAR(255) CHECK (tipo_spedizione ='Express' OR tipo_spedizione='Standard') NOT NULL,
    importo_profilo FLOAT DEFAULT 0,
    PRIMARY KEY(partita_IVA),
    FOREIGN KEY (email_utente) REFERENCES Utente(email)
);

CREATE TABLE Corriere (
    id_corriere INT NOT NULL AUTO_INCREMENT,
    id_spedizione INT NOT NULL,
    consegne_effettuate INT NOT NULL DEFAULT 0,
    capacita_di_trasporto DECIMAL(10, 2) NOT NULL,
    emmissione_co2 DECIMAL(10, 2) NOT NULL,
    disponibilita BOOLEAN NOT NULL DEFAULT true,
    targa VARCHAR(255) NOT NULL,
    veicolo VARCHAR(255) NOT NULL CHECK (veicolo ='Furgone' OR veicolo='Nave' OR veicolo='Aereo'),
    PRIMARY KEY(id_corriere),
    FOREIGN KEY (id_spedizione) REFERENCES Spedizione(Id_spedizione)
);

CREATE TABLE CentroSmistamento (
    id_centrosmistamento INT NOT NULL,
    indirizzo VARCHAR(255) NOT NULL,
    dimensione VARCHAR(255) NOT NULL,
    capacita_smistamento INT NOT NULL,
    id_dipendente INT NOT NULL,
    PRIMARY KEY(id_centrosmistamento),
    FOREIGN KEY (id_dipendente) REFERENCES Dipendente(id_dipendente)
);

CREATE TABLE Dipendente (
    id_dipendente INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(255) NOT NULL,
    cognome VARCHAR(255) NOT NULL,
    stipendio FLOAT DEFAULT 0,
    data_di_nascita DATE NOT NULL,
    posizione VARCHAR(255) CHECK (posizione='Magazziniere' OR posizione='Addetto alle spedizioni' OR posizione='Impiegato' OR posizione='Dirigente'), 
    PRIMARY KEY(id_dipendente)
);

CREATE TABLE MittenteDestinatario (
    id_mittdest INT NOT NULL AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    indirizzo VARCHAR(255) NOT NULL,
    citta VARCHAR(255) NOT NULL,
    CAP VARCHAR(10) NOT NULL,
    nome VARCHAR(255) NOT NULL,
    cognome VARCHAR(255) NOT NULL,
    tipo VARCHAR(255) NOT NULL CHECK (tipo='Mittente' OR tipo='Destinatario'),
    note TEXT,
    PRIMARY KEY(id_mittdest)
    FOREIGN KEY (email) REFERENCES Utente(email_utente),
);

CREATE TABLE Gestisce (
    id_dipendente INT NOT NULL,
    id_pacco INT NOT NULL,
    data DATE NOT NULL,
    PRIMARY KEY (id_dipendente, id_pacco),
    FOREIGN KEY (id_dipendente) REFERENCES Dipendente(id_dipendente),
    FOREIGN KEY (id_pacco) REFERENCES Pacco(id_pacco)
);

--ESEMPIO OPERAZIONI

--O1
UPDATE Utente
SET indirizzo= "qualunque nuovo indirizzo"
WHERE Email= "utente@X.dominio"

--02
INSERT INTO Spedizione (Email_utente, tipo_spedizione)
    VALUES("utente@X.dominio", "Express");

--03
SELECT S.importo_totale
FROM Spedizione S
WHERE S.importo_totale = @attributo_input

--04
INSERT INTO ProfiloSpedizione(partita_IVA, email_utente, nome_azienda, frequenza, n_pacchi, tipo_spedizione)
    VALUES("12345678901", "Ferrero", "Settimanale", 100, "Standard");


--05
SELECT S.importo_totale
FROM Spedizione S
WHERE NOT EXIST(SELECT *
                FROM Spedizione S2
                WHERE S.importo_totale > S2.importo_totale AND 
                S.id_spedizione = @attributo_input)

--06
SELECT C.id_corriere
FROM Corriere C 
WHERE C.id_spedizione = @attributo_input

--07
UPDATE Spedizione
SET stato_spedizione= "IN ATTESA"
WHERE id_spedizione = @attributo_input

--08
SELECT G.id_dipendente
FROM Gestisce G, Dipendente D
WHERE P.id_pacco = @attributo_input AND G.id_dipendente = D.id_dipendente

--09
SELECT C.consegne_effettuate 
FROM Corriere C 
WHERE C.id_corriere = @attributo_input

--10
SELECT P.email_utente
FROM ProfiloSpedizione P
WHERE P.email_utente = @attributo_input

--TRIGGER

CREATE TRIGGER Cambio_Stato_Spedizione
BEFORE UPDATE OF stato_spedizione ON Spedizione
FOR EACH ROW 
IF  new.stato_spedizione = 'IN ATTESA' AND
    EXISTS(Select* FROM Corriere F where F.disponibile=true) AND new.importo_totale >=10  THEN
    SET new.Id_corriere= (Select Id_corriere
                        FROM Corriere
                        WHERE disponibile=true
                        ORDER BY Id_corriere ASC
                     	LIMIT 1);
    SET new.stato_spedizione='IN PREPARAZIONE';
    UPDATE Corriere
    SET disponibile=false
    where Id_orriere= (Select Id_corriere
                        FROM Corriere
                        WHERE disponibile = true
                        ORDER BY Id_corriere ASC
                     	LIMIT 1);
    ELSE IF new.stato_spedizione = 'CONSEGNATA' THEN 
        UPDATE Corriere
        SET disponibile = true, consegne_effettuate = consegne_effettuate+1
        WHERE Id_corriere = new.Id_corriere;
    END iF

CREATE DEFINER=`root`@`localhost` EVENT `Assegna_Corriere` ON SCHEDULE EVERY 1 SECOND STARTS CURRENT_TIME ON COMPLETION PRESERVE ENABLE DO 
IF EXiSTS(SELECT * FROM Corriere WHERE disponibile=true) AND EXISTS(SELECT * FROM Spedizione S WHERE S.stato_spedizione='IN ATTESA') THEN
    UPDATE Spedizione
    SET id_corriere =(Select id_corriere
                        FROM Corriere
                        WHERE disponibile = true
                        ORDER BY id_corriere ASC
                     	LIMIT 1), stato_spedizione = 'IN PREPARAZIONE'
                        WHERE Id_spedizione=( SELECT Id_spedizione 
                                FROM Spedizione S 
                                WHERE S.Stato='IN ATTESA' 
                                ORDER BY data_spedizione ASC LIMIT 1 );
    UPDATE Corriere
    SET disponibile=false;
    where id_corriere=(Select id_corriere
                        FROM Corriere
                        WHERE disponibile=true
                        ORDER BY id_corriere ASC
                     	LIMIT 1);
END IF;


--INSERT

INSERT INTO Utente (email, password, indirizzo, nome, cognome, eta)
VALUES ('utente@email.com', 'password123', 'Via Example 123', 'Mario', 'Rossi', 30);

INSERT INTO Spedizione (email_utente tipo_spedizione, importo_totale, data_spedizione, stato_spedizione)
VALUES ('utente@email.com','Express', 50.00, '2023-08-20', 'IN CORSO');

INSERT INTO Pacco (altezza, larghezza, peso, tipo_pacco, posizione, importo_pacco)
VALUES (20.0, 15.0, 2.5, 'Standard', 'Magazzino A', 10.00);

INSERT INTO ProfiloSpedizione (partita_IVA, email_utente, nome_azienda, frequenza, n_pacchi, tipo_spedizione, importo_profilo)
VALUES ('12345678901', 'utente@email.com', 'Azienda SRL', 'Settimanale', 100, 'Standard', 500.00);

INSERT INTO Corriere ( consegne_effettuate, capacita_di_trasporto, emmissione_co2, disponibilita, targa, veicolo)
VALUES (5, 5000.00, 50.00, true, 'AB123CD', 'Furgone');

INSERT INTO CentroSmistamento ( indirizzo, dimensione, capacita_smistamento)
VALUES ('Via Centrale 1', 'Grande', 1000);

INSERT INTO Dipendente (nome, cognome, stipendio, data_di_nascita, posizione)
VALUES ('Luca', 'Bianchi', 2000.00, '1990-05-15', 'Magazziniere');

INSERT INTO MittenteDestinatario (email, indirizzo, citta, CAP, nome, cognome, tipo, note)
VALUES ('mittente@email.com', 'Via Sender 2', 'Roma', '00123', 'Paolo', 'Verdi', 'Mittente', 'Note di spedizione');

INSERT INTO Gestisce (data)
VALUES ('2023-08-20');

