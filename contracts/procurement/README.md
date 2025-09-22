# Procurement

Il contratto **Procurement** gestisce appalti pubblici con un meccanismo **commit-reveal**. Permette a un ente appaltante di gestire offerte, selezionare un vincitore e rilasciare pagamenti solo dopo la validazione da parte di revisori.

## Funzionalità

- Definizione di un **ente appaltante** che gestisce l’intero processo.
- Meccanismo **commit-reveal** per invio e rivelazione delle offerte.
- Selezione automatica del **miglior offerente** (offerta minima).
- Registrazione di **revisori** per validare la consegna.
- Rilascio del pagamento solo se viene raggiunto il **quorum di approvazione**.
- Eventi per **trasparenza** e auditing on-chain.

## Stato dell’Appalto

Il contratto gestisce sei stati principali:

1. **Inizializzazione**: l’ente appaltante può depositare l’importo in escrow.
2. **Commit**: i partecipanti inviano l’hash delle proprie offerte.
3. **Reveal**: i partecipanti rivelano le proprie offerte.
4. **Valutazione**: l’ente seleziona il vincitore preliminare.
5. **Consegna**: i revisori validano la consegna.
6. **Completato**: pagamento rilasciato al vincitore.
7. **Arbitrato**: stato alternativo se l’ente decide di non confermare il vincitore.

## Flusso operativo

1. L’ente appaltante deploya il contratto con un importo in escrow.
2. L’ente avvia la fase di **Commit**.
3. I partecipanti inviano i loro commit (hash delle offerte + nonce).
4. L’ente avvia la fase di **Reveal**.
5. I partecipanti rivelano le loro offerte.
6. L’ente valuta le offerte e seleziona il vincitore preliminare.
7. L’ente conferma il vincitore.
8. I revisori validano la consegna; se il quorum è raggiunto, viene rilasciato il pagamento.

## Struttura del Contratto

### Variabili principali

- `enteAppaltante`: indirizzo dell’ente che gestisce l’appalto.
- `importoEscrow`: importo bloccato nel contratto da rilasciare al vincitore.
- `vincitore`: indirizzo del vincitore dell’appalto.
- `faseCorrente`: fase attuale dell’appalto.
- `offerte`: mapping degli offerenti con i relativi commit e valori rivelati.
- `revisori`: mapping degli indirizzi autorizzati a validare la consegna.
- `voti`: mapping dei voti dei revisori.
- `votiPositivi`: conteggio dei voti favorevoli per il rilascio del pagamento.
- `quorumRichiesto`: numero minimo di voti positivi per approvare la consegna.

### Eventi

- `OffertaCommit(address indexed offerente)`: quando un offerente invia il commit.
- `OffertaReveal(address indexed offerente, uint256 valore)`: quando un offerente rivela l’offerta.
- `VincitorePreliminare(address indexed vincitore, uint256 valore)`: selezione del miglior offerente.
- `VincitoreFinale(address indexed vincitore)`: conferma del vincitore da parte dell’ente.
- `PagamentoRilasciato(address indexed vincitore, uint256 importo)`: rilascio del pagamento.

## Funzioni principali

### Funzioni per l’ente appaltante

- `avviaFaseCommit()`: avvia la fase di commit.
- `avviaFaseReveal()`: avvia la fase di reveal.
- `valutaOfferte()`: valuta tutte le offerte e seleziona il miglior offerente.
- `abilitaVincitore(bool abilitato)`: conferma o meno il vincitore.
- `registraRevisore(address _revisore)`: registra un revisore autorizzato.

### Funzioni per i partecipanti

- `inviaCommit(bytes32 _impegno)`: invia l’hash dell’offerta durante la fase di commit.
- `rivelaOfferta(uint256 _valore, string memory _nonce)`: rivela il valore dell’offerta e il nonce.

### Funzioni per i revisori

- `validaConsegna(bool approvato)`: vota per approvare o meno la consegna; se viene raggiunto il quorum, il pagamento viene rilasciato.

## Modificatori di sicurezza

- `soloEnte`: limita alcune funzioni all’ente appaltante.
- `inFase(Fase f)`: permette l’esecuzione di funzioni solo nella fase corretta.

## Deploy e Testing

Il contratto è stato scritto, deployato e testato tramite **Remix IDE**.
