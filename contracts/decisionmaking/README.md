# DecisionMaking

Il contratto di **Decision Making** permette un processo di votazione di una proposta in maniera sicura e trasparente.

## Funzionalità

- Definizione di un **vari ruoli**, ognuno con un compito preciso nel processo di votazione.
- Possibilità di assegnare/revocare **ruoli** agli address.
- Possibilità di proporre un **atto/legge**.
- Possibilità di **votazione** tracciata e sicura nelle varie fasi.
- Visualizzazione dei risultati in tempo reale.
- Eventi per **trasparenza** e auditing.

## Fasi della Votazione

Il contratto gestisce quattro fasi principali:

1. **Drafting**: proposta di un atto/legge, possibilità di modifiche al documento.
2. **Technical Review**: revisione e approvazione da parte degli uffici tecnici.
3. **Approval**: votazione definitiva da parte dei Decision Maker.
4. **Finalization**: stato finale della proposta - apporvata/respinta.

## Ruoli

- `PROPOSER`: chi può avanzare una proposta di legge/atto.
- `TECHNICAL_REVIEWER`: revisori tecnici.
- `DECISION_MAKER`: stakeholders deputati alla votazione finale.
- `ADMIN`: ha funzioni amministrative e di gestione delle fasi del processo decisionale.

## Struttura del Contratto

### Variabili Principali

- `approvalThreshold`: soglia di successo per la fase Approval.
- `proposals`: mapping delle proposte registrate.
- `hasRole`: mapping degli indirizzi con i rispettivi ruoli.
- `techincalReviews`: mapping delle revisione dei Revisori per proposta.

### Strutture Principali
- `Proposal`: struttura che rappresenta una "Proposta".
  - `id`: id della proposta.
  - `proposer`: address del Proposer.
  - `title`: nome della proposta.
  - `documentHash`: hash del documento della proposta.
  - `Stage`: fase attuale del processo decisionale della proposta.
  - `createdAt`: quando la proposta è stata effettuata.
  - `updatedAt`: timestamp dell'ultimo update alla proposta.
  - `approvals`: voti favorevoli alla proposta.
  - `rejections`: voti contrari alla proposta.
- `ReviewDecision`: struttura che rappresenta una "Revision" dei Revisori.
  - `decided`: flag per la verifica del voto da parte del revisore.
  - `approved`: voto del revisore.
  - `comment`: commento opzionale al voto.

### Eventi

- `ProposalCreated`
- `ProposalDocumentUpdated`
- `TechnicalReviewCast`
- `ProposalAdvanced`
- `ApprovalCast`
- `ProposalFinalized`
- `RoleAssigned`
- `RoleRevoked`

## Funzioni Principali
- `createProposal(string calldata title, bytes32 documentHash) external onlyRole(Role.PROPOSER)`: crea una proposta di legge/atto.
- `updateProposalDocument(uint256 proposalId, bytes32 newHash) external onlyRole(Role.PROPOSER) proposalExists(proposalId)`: aggiorna documento della proposta.
- `advanceToTechnicalReview(uint256 proposalId) external proposalExists(proposalId) onlyRole(Role.ADMIN)`: avanza alla fase di Technical Review.
- `castTechnicalReview(uint256 proposalId, bool approved, string calldata comment) external proposalExists(proposalId) onlyRole(Role.TECHNICAL_REVIEWER)`: votazione da parte di un revisore tecnico.
- `advanceToApproval(uint256 proposalId) external proposalExists(proposalId) onlyRole(Role.ADMIN)`: avanza alla fase di approvazione.
- `castApproval(uint256 proposalId, bool support) external onlyRole(Role.DECISION_MAKER) proposalExists(proposalId)`: votazione finale da parte di un Decision Maker.
- `finalizeProposal(uint256 proposalId) external proposalExists(proposalId) onlyRole(Role.ADMIN)`: finalizzazione della proposta - approvata/respinta.
- `setApprovalThreshold(uint256 _newThreshold) external onlyRole(Role.ADMIN)`: modifica della soglia per la votazione finale.
- `assignRole(address user, Role role) external onlyRole(Role.ADMIN)`: asseggna un ruolo.
- `revokeRole(address user, Role role) external onlyRole(Role.ADMIN)`: revoca un ruolo.

## Modificatori di Sicurezza

- `onlyRole(Role role)`: limita alcune funzioni al rispettivo ruolo.
- `proposalExists(uint256 proposalId)`: controllo sulla effettiva esistenza di una proposta.

## Deploy e Testing

I contratti sono stati scritti, deployati e testati tramite **Remix IDE**.
