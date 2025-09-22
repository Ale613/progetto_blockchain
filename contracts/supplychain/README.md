# SupplyChain

Il contratto **SupplyChain** gestisce una catena di fornitura con escrow.

## Funzionalità

- Gestione di diversi **ruoli**: Admin, Fornitore, Trasportatore, Ispettore, Destinatario.  
- Creazione e gestione di **lotti** con deposito di fondi in **escrow**.  
- Tracciamento dello **stato del lotto**: Creato → Spedito → InTransito → Consegnato → Ispezionato → Completato.  
- Registro degli **eventi** per ogni lotto (audit trail).  
- **Rilascio sicuro dei fondi** al fornitore o rimborso al destinatario tramite validazione dell’ispettore.  
- Protezione contro attacchi di tipo **reentrancy**.  
- Eventi per **trasparenza e auditing**.

## Stati del Lotto

Ogni lotto può trovarsi in uno dei seguenti stati:

1. **Creato**: il destinatario ha depositato i fondi.  
2. **Spedito**: il fornitore ha spedito la merce.  
3. **InTransito**: il trasportatore aggiorna lo stato durante la consegna.  
4. **Consegnato**: il destinatario conferma la ricezione.  
5. **Ispezionato**: l’ispettore ha verificato il lotto come non conforme.  
6. **Completato**: l’ispettore ha verificato il lotto come conforme e i fondi sono stati rilasciati al fornitore.

## Flusso operativo

1. L’**Admin** deploya il contratto e registra i partecipanti con i rispettivi ruoli.  
2. Il **Destinatario** crea un lotto e deposita i fondi in escrow.  
3. Il **Fornitore** registra la spedizione del lotto.  
4. Il **Trasportatore** aggiorna lo stato a **InTransito** durante la consegna.  
5. Il **Destinatario** conferma la ricezione del lotto.  
6. L’**Ispettore** valuta il lotto:  
   - Se conforme → rilascio dei fondi al fornitore (stato **Completato**).  
   - Se non conforme → rimborso al destinatario (stato **Ispezionato**).

## Struttura del Contratto

### Variabili Principali

- `admin`: indirizzo dell’amministratore del contratto.  
- `counterLotti`: contatore incrementale per identificare i lotti.  
- `partecipanti`: mapping indirizzo → ruolo e autorizzazione.  
- `lotti`: mapping id lotto → dettagli del lotto.  
- `locked`: variabile per prevenire reentrancy.

### Tipi e Strutture

- `Role`: enum dei ruoli disponibili.  
- `LotStatus`: enum degli stati possibili del lotto.  
- `Partecipante`: struttura che rappresenta un partecipante e il suo ruolo.  
- `EventoLotto`: struttura per registrare eventi storici di un lotto.  
- `Lotto`: struttura che rappresenta un lotto della supply chain.

### Eventi

- `PartecipanteRegistrato`  
- `LottoCreato`  
- `EventoRegistrato`  
- `FondiRilasciati`

## Funzioni Principali

### Funzioni Admin

- `registraPartecipante(address _account, Role _ruolo)`: registra un nuovo partecipante con un ruolo specifico.  

### Funzioni Destinatario

- `creaLotto(address _fornitore)`: crea un lotto e deposita fondi in escrow.  
- `confermaRicezione(uint256 id)`: conferma la ricezione del lotto.  

### Funzioni Fornitore

- `registraSpedizione(uint256 id)`: registra la spedizione del lotto.  

### Funzioni Trasportatore

- `aggiornaTrasporto(uint256 id)`: aggiorna lo stato del lotto a "InTransito".  

### Funzioni Ispettore

- `validaIspezione(uint256 id, bool conforme)`: valida il lotto; rilascia fondi al fornitore se conforme, altrimenti rimborso al destinatario.  

### Funzioni di Consultazione

- `getLotto(uint256 id)`: restituisce informazioni principali sul lotto.  
- `getEventiLotto(uint256 id)`: restituisce tutti gli eventi registrati di un lotto.  

### Funzioni di Sicurezza

- `noReentrant`: previene attacchi di tipo reentrancy.  
- `safeTransfer(address destinatario, uint256 importo)`: trasferimento sicuro dei fondi.

## Modificatori di Sicurezza

- `onlyAdmin`: limita alcune funzioni all’amministratore.  
- `onlyRole(Role ruolo)`: limita alcune funzioni a specifici ruoli autorizzati.  
- `lottoExists(uint256 id)`: assicura che il lotto esista.  

## Deploy e Testing

Il contratto è stato scritto, deployato e testato tramite **Remix IDE**.
