// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contratto per la gestione di una supply chain: il destinatario deposita fondi, 
// i fondi vengono rilasciati al fornitore solo se l'ispettore conferma la conformità; 
// in caso contrario vengono rimborsati al destinatario.
contract SupplyChain {
    
    // Ruoli disponibili
    enum Role { None, Admin, Fornitore, Trasportatore, Ispettore, Destinatario }

    // Stati possibili di un lotto
    enum LotStatus { Creato, Spedito, InTransito, Consegnato, Ispezionato, Completato }

    // Struttura che rappresenta un partecipante alla rete
    struct Partecipante {
        Role ruolo;       // ruolo (fornitore, destinatario, ecc.)
        bool autorizzato; // flag per autorizzazione
    }

    // Struttura per registrare gli eventi storici di un lotto (audit trail)
    struct EventoLotto {
        string descrizione; // descrizione evento (es. "spedito")
        address attore;     // chi ha eseguito l’azione
        uint256 timestamp;  // quando è stato registrato
    }

    // Struttura che descrive un lotto nella supply chain
    struct Lotto {
        uint256 id;             // identificativo univoco
        address fornitore;      // chi fornisce il bene
        address destinatario;   // chi paga (deposita i fondi)
        uint256 valore;         // fondi depositati in escrow (wei)
        LotStatus stato;        // stato attuale del lotto
        bool fondiRilasciati;   // true se i fondi sono già stati trasferiti
        EventoLotto[] eventi;   // storico eventi associati
    }

    address public admin;                 // indirizzo dell’admin (deploy del contratto)
    uint256 public counterLotti;          // contatore incrementale per i lotti
    mapping(address => Partecipante) public partecipanti; // mappa indirizzo → ruolo
    mapping(uint256 => Lotto) private lotti;              // mappa id → lotto

    // Anti-attacchi di reentrancy
    bool private locked;
    modifier noReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    // Modificatori di accesso
    modifier onlyAdmin() {
        require(msg.sender == admin, "Solo admin");
        _;
    }

    modifier onlyRole(Role ruolo) {
        require(partecipanti[msg.sender].ruolo == ruolo && partecipanti[msg.sender].autorizzato, "Ruolo non autorizzato");
        _;
    }

    modifier lottoExists(uint256 id) {
        require(lotti[id].id == id, "Lotto inesistente");
        _;
    }

    // Eventi
    event PartecipanteRegistrato(address account, Role ruolo);
    event LottoCreato(uint256 id, address fornitore, address destinatario, uint256 valore);
    event EventoRegistrato(uint256 id, string descrizione, address attore);
    event FondiRilasciati(uint256 id, address a, uint256 amount);

    // Costruttore
    constructor() {
        admin = msg.sender;
        partecipanti[msg.sender] = Partecipante(Role.Admin, true);
    }

    // Registra un nuovo partecipante con un ruolo definito
    function registraPartecipante(address _account, Role _ruolo) external onlyAdmin {
        partecipanti[_account] = Partecipante(_ruolo, true);
        emit PartecipanteRegistrato(_account, _ruolo);
    }

    // Il destinatario crea un lotto e deposita fondi in escrow.
    function creaLotto(address _fornitore) external payable onlyRole(Role.Destinatario) {
        require(msg.value > 0, "Devi depositare valore");
        counterLotti++;
        Lotto storage l = lotti[counterLotti];
        l.id = counterLotti;
        l.fornitore = _fornitore;
        l.destinatario = msg.sender;
        l.valore = msg.value;
        l.stato = LotStatus.Creato;
        l.fondiRilasciati = false;
        l.eventi.push(EventoLotto("Lotto creato e valore depositato in escrow", msg.sender, block.timestamp));
        emit LottoCreato(counterLotti, _fornitore, msg.sender, msg.value);
    }

    // -------------------------
    // Fasi Supply Chain
    // -------------------------

    // Il fornitore registra la spedizione del lotto
    function registraSpedizione(uint256 id) external lottoExists(id) onlyRole(Role.Fornitore) {
        Lotto storage l = lotti[id];
        require(l.stato == LotStatus.Creato, "Non nello stato giusto");
        require(msg.sender == l.fornitore, "Solo il fornitore associato puo' spedire");
        l.stato = LotStatus.Spedito;
        pushEvento(l, "Lotto spedito");
    }

    // Il trasportatore aggiorna lo stato del lotto a InTransito
    function aggiornaTrasporto(uint256 id) external lottoExists(id) onlyRole(Role.Trasportatore) {
        Lotto storage l = lotti[id];
        require(l.stato == LotStatus.Spedito, "Non nello stato giusto");
        l.stato = LotStatus.InTransito;
        pushEvento(l, "Lotto in transito");
    }

    // Il destinatario conferma la ricezione della merce
    function confermaRicezione(uint256 id) external lottoExists(id) onlyRole(Role.Destinatario) {
        Lotto storage l = lotti[id];
        require(msg.sender == l.destinatario, "Non sei il destinatario");
        require(l.stato == LotStatus.InTransito, "Non nello stato giusto");
        l.stato = LotStatus.Consegnato;
        pushEvento(l, "Lotto consegnato (ricezione confermata dal destinatario)");
    }

    // L'ispettore valida il lotto: se conforme i fondi vanno al fornitore, altrimenti rimborso al destinatario.
    function validaIspezione(uint256 id, bool conforme) external lottoExists(id) onlyRole(Role.Ispettore) noReentrant {
        Lotto storage l = lotti[id];
        require(l.stato == LotStatus.Consegnato, "Ispezione solo dopo consegna");
        require(!l.fondiRilasciati, "Fondi gia' rilasciati");

        if (conforme) {
            l.stato = LotStatus.Completato;
            l.fondiRilasciati = true;
            pushEvento(l, "Lotto ispezionato e conforme: rilascio fondi al fornitore");
            safeTransfer(l.fornitore, l.valore);
            emit FondiRilasciati(id, l.fornitore, l.valore);
        } else {
            l.stato = LotStatus.Ispezionato;
            l.fondiRilasciati = true;
            pushEvento(l, "Lotto ispezionato e NON conforme: rimborso al destinatario");
            safeTransfer(l.destinatario, l.valore);
            emit FondiRilasciati(id, l.destinatario, l.valore);
        }
    }

    // Helpers interni
    function pushEvento(Lotto storage l, string memory descr) internal {
        l.eventi.push(EventoLotto(descr, msg.sender, block.timestamp));
        emit EventoRegistrato(l.id, descr, msg.sender);
    }

    // Trasferimento sicuro di fondi con call
    function safeTransfer(address destinatario, uint256 importo) internal {
        (bool ok, ) = payable(destinatario).call{value: importo}("");
        require(ok, "Trasferimento fallito");
    }

    // Restituisce le informazioni principali di un lotto
    function getLotto(uint256 id) external view lottoExists(id) returns (
        uint256, address, address, uint256, LotStatus, bool, uint256
    ) {
        Lotto storage l = lotti[id];
        return (l.id, l.fornitore, l.destinatario, l.valore, l.stato, l.fondiRilasciati, l.eventi.length);
    }

    // Restituisce tutti gli eventi registrati per un lotto
    function getEventiLotto(uint256 id) external view lottoExists(id) returns (EventoLotto[] memory) {
        return lotti[id].eventi;
    }

    // Fallback per evitare invii accidentali
    receive() external payable {
        revert("Invii diretti non permessi");
    }

    fallback() external payable {
        revert("Function non trovata");
    }
}