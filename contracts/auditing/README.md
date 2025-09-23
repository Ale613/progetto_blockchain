# Auditing

I contratt di **Auditing** permettono di registrare un documento on-chain e peformare degli audit su di esso.

## Contratto RegisterDocument

### Funzionalità

- Definizione di un **amministratore** che gestisce le autorizzazioni.
- Possibilità di aggiungere/rimuovere **utenti autorizzati** alla registrazione di un documento.
- Registrazione dei **documenti** on-chain.
- Visualizzazione dei documenti registrati.
- Eventi per **trasparenza** e auditing.

### Struttura del Contratto

#### Variabili Principali

- `owner`: indirizzo dell'amministratore.
- `documents`: mapping dei documenti registrati.
- `authorized`: mapping degli indirizzi autorizzati.

#### Strutture Principali
- `Document`: struttura che rappresenta un "Documento"
  - `submitter`: address di chi registra il documento
  - `docHash`: hash del documento registrato
  - `timestamp`: timestamp del momento della registrazione
  - `exists`: flag di sicurezza

#### Eventi

- `DocumentRegistered`
- `AuthorizedAdded`
- `AuthorizedRemoved`

### Funzioni Principali
- `registerDocument(bytes32 docHash) external onlyAuthorized`: registra un documento.
- `addAuthorized(address _address) external onlyOwner`: autorizza un address.
- `removeAuthorized(address _address) external onlyOwner`: rimuove l'autorizzazione ad un address.

### Funzioni di Auditing
- `isRegistered(bytes32 docHash) public view returns (bool)`: restituisce true se un documento è già registrato.
- `getDocument(bytes32 docHash) external view returns (address submitter, bytes32 dHash, uint256 timestamp,bool exists)`: restituisce tutti i dati di un documento registrato.

### Modificatori di Sicurezza

- `onlyOwner`: limita alcune funzioni all’amministratore.
- `onlyAuthorized`: limita alcune funzioni agli address autorizzati.

## Contratto AuditDocument

## Deploy e Testing

I contratti sono stati scritti, deployati e testati tramite **Remix IDE**.
