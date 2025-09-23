# Auditing

I contratti di **Auditing** permettono di registrare dei documenti on-chain e peformare degli audit su di essi.

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

### Funzionalità

- Definizione di un **amministratore** che gestisce le autorizzazioni.
- Possibilità di aggiungere/rimuovere **Auditor** che può effettuare degli audit.
- Registrazione degli **Audit** on-chain.
- Visualizzazione degli audit registrati.
- Eventi per **trasparenza**.

### Struttura del Contratto

#### Variabili Principali

- `owner`: indirizzo dell'amministratore.
- `audits`: mapping degli audits registrati.
- `authorizedAuditor`: mapping degli Auditor autorizzati.
- `REGISTER_DOCUMENT_CONTRACT `: address del contratto RegisterDocument.

#### Strutture Principali
- `Audit`: struttura che rappresenta un "Audit"
  - `docHash`: hash del documento registrato.
  - `auditHash`: hash dell'audit.
  - `auditor`: address dell'Auditor.
  - `timestamp`: timestamp del momento della creazione dell'audit.
  - `isDocValid`: risultato dell'audit.

#### Eventi

- `AuditCreated`
- `AuditorAuthorized`
- `AuditorRevoked`

### Funzioni Principali
- `createAudit(bytes32 _docHash) external onlyAuditor`: crea un audit.
- `authorizeAuditor(address _auditor) external onlyOwner`: autorizza un auditor.
- `revokeAuditor(address _auditor) external onlyOwner`: rimuove l'autorizzazione ad un auditor.
- `IRegisterDocument`: interfaccia per il contratto RegisterDocument.

### Funzioni di Recupero
- `getAuditsByDoc(bytes32 _docHash) external view returns (Audit[] memory)`: restituisce tutti gli audit effettuati su un determinato documento.
- `getAudit(bytes32 _auditHash) external view returns (Audit memory)`: restituisce tutti i dati di un audit registrato.

### Modificatori di Sicurezza

- `onlyOwner`: limita alcune funzioni all’amministratore.
- `onlyAuditor`: limita alcune funzioni agli Auditor.

## Deploy e Testing

I contratti sono stati scritti, deployati e testati tramite **Remix IDE**.
