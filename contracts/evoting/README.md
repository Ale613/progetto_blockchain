# EVoting

Il contratto **EVtoting** permette a un amministratore di creare elezioni, registrare candidati ed elettori, e contare i voti in modo trasparente e sicuro.

## Funzionalità

- Definizione di un **amministratore** che gestisce l'elezione.
- Possibilità di aggiungere **candidati** all'elezione.
- Registrazione degli **elettori** che possono votare una sola volta.
- **Votazione sicura** e tracciata on-chain.
- Visualizzazione dei risultati **in tempo reale**.
- Eventi per **trasparenza** e auditing.

## Stato dell'Elezione

Il contratto gestisce tre stati principali:

1. **Non iniziata**: l'elezione può essere configurata (aggiunta candidati e registrazione elettori).
2. **In corso**: gli elettori registrati possono votare.
3. **Terminata**: l'elezione è conclusa, i voti non possono più essere modificati.

## Struttura del Contratto

### Variabili Principali

- `admin`: indirizzo dell'amministratore.
- `nomeElezione`: nome dell'elezione.
- `iniziata`: stato booleano che indica se l'elezione è in corso.
- `terminata`: stato booleano che indica se l'elezione è terminata.
- `candidati`: array contenente i candidati con nome e numero di voti.
- `registrato`: mapping degli elettori registrati.
- `haVotato`: mapping per controllare se un elettore ha già votato.

### Eventi

- `CandidatoAggiunto`
- `ElettoreRegistrato`
- `VotoEspresso`
- `ElezioneIniziata`
- `ElezioneTerminata`

## Funzioni Principali

### Funzioni Admin

- `aggiungiCandidato(string calldata _nome)`: aggiunge un nuovo candidato.
- `registraElettore(address _elettore)`: registra un elettore.
- `iniziaElezione()`: avvia l'elezione.
- `terminaElezione()`: termina l'elezione.

### Funzioni Elettore

- `vota(uint256 candidatoIndex)`: permette a un elettore registrato di votare per un candidato specifico.

### Funzioni di Consultazione

- `numeroCandidati()`: restituisce il numero totale dei candidati.
- `getCandidato(uint256 idx)`: restituisce nome e numero di voti di un candidato.
- `getTuttiCandidati()`: restituisce l’elenco completo dei candidati con i rispettivi voti.

## Modificatori di Sicurezza

- `soloAdmin`: limita alcune funzioni all’amministratore.
- `soloQuandoIniziata`: permette l’esecuzione di funzioni solo quando l’elezione è attiva.


## Deploy e Testing

Il contratto è stato scritto, deployato e testato tramite **Remix IDE**.
