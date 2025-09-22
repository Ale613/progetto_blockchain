// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contratto per un appalto pubblico con meccanismo commit-reveal
contract Procurement {

    // Fasi del processo di appalto
    enum Fase { Inizializzazione, Commit, Reveal, Valutazione, Consegna, Completato, Arbitrato }
    Fase public faseCorrente;

    address public enteAppaltante; // Indirizzo dell'ente che gestisce l'appalto
    uint256 public importoEscrow; // Importo bloccato nel contratto da rilasciare al vincitore
    address public vincitore; // Indirizzo del vincitore dell'appalto

    // Struttura per memorizzare l'offerta di un partecipante
    struct Offerta {
        bytes32 impegno;        // Hash dell'offerta + nonce (fase commit)
        uint256 valoreRivelato; // Valore rivelato; 0 = non rivelata
    }

    mapping(address => Offerta) public offerte; // Mappa indirizzo -> offerta
    mapping(address => bool) private haPartecipato; // Per evitare commit multipli

    // Gestione revisori e voti
    mapping(address => bool) public revisori; // Indirizzi autorizzati a validare la consegna
    mapping(address => bool) public voti;     // Voti dei revisori
    uint8 public votiPositivi;                // Conteggio dei voti positivi
    uint8 public quorumRichiesto = 2;         // Numero minimo di voti positivi per rilasciare il pagamento

    // Tracking del miglior offerente durante la fase di reveal
    address private migliorOfferente;
    uint256 private migliorValore = type(uint256).max;

    // Eventi
    event OffertaCommit(address indexed offerente);
    event OffertaReveal(address indexed offerente, uint256 valore);
    event VincitorePreliminare(address indexed vincitore, uint256 valore);
    event VincitoreFinale(address indexed vincitore);
    event PagamentoRilasciato(address indexed vincitore, uint256 importo);

    // Modificatori
    modifier soloEnte() {
        require(msg.sender == enteAppaltante, "Solo ente appaltante");
        _;
    }

    modifier inFase(Fase f) {
        require(faseCorrente == f, "Fase non corretta");
        _;
    }

    // Costruttore: imposta ente appaltante, importo escrow e fase iniziale
    constructor() payable {
        enteAppaltante = msg.sender;
        importoEscrow = msg.value;
        faseCorrente = Fase.Inizializzazione;
    }

    // -------------------------
    // Fasi del procurement
    // -------------------------

    // L'ente appaltante avvia la fase di commit
    function avviaFaseCommit() external soloEnte inFase(Fase.Inizializzazione) {
        faseCorrente = Fase.Commit;
    }

    // Un partecipante può inviare la provare offerta sotto forma di hash
    function inviaCommit(bytes32 _impegno) external inFase(Fase.Commit) {
        require(!haPartecipato[msg.sender], "Gia' inviato");
        offerte[msg.sender] = Offerta(_impegno, 0);
        haPartecipato[msg.sender] = true;
        emit OffertaCommit(msg.sender);
    }

    // L'ente appaltante avvia la fase di reveal
    function avviaFaseReveal() external soloEnte inFase(Fase.Commit) {
        faseCorrente = Fase.Reveal;
    }

    // Durante la fase di reveal nn partecipante può rivelare la propria offerta indicato valore e nonce
    function rivelaOfferta(uint256 _valore, string memory _nonce) external inFase(Fase.Reveal) {
        Offerta storage o = offerte[msg.sender];
        require(o.impegno != 0, "Nessun commit");
        require(o.valoreRivelato == 0, "Gia' rivelata");
        require(keccak256(abi.encodePacked(_valore, _nonce)) == o.impegno, "Rivelazione errata");

        o.valoreRivelato = _valore;

        // Aggiorna miglior offerente subito
        if (_valore < migliorValore) {
            migliorValore = _valore;
            migliorOfferente = msg.sender;
        }

        emit OffertaReveal(msg.sender, _valore);
    }

    // L'ente appaltante valuta tutte le offerte è seleziona la più conveniente impostando il vincitore preliminare
    function valutaOfferte() external soloEnte inFase(Fase.Reveal) {
        vincitore = migliorOfferente;
        faseCorrente = Fase.Valutazione;
        emit VincitorePreliminare(vincitore, migliorValore);
    }

    // L'ente appaltante conferma il vincitore
    function abilitaVincitore(bool abilitato) external soloEnte inFase(Fase.Valutazione) {
        if (abilitato) {
            faseCorrente = Fase.Consegna;
            emit VincitoreFinale(vincitore);
        } else {
            faseCorrente = Fase.Arbitrato;
        }
    }

    // L'ente apparltante può registrare dei revisori
    function registraRevisore(address _revisore) external soloEnte {
        revisori[_revisore] = true;
    }

    // La consegna viene validata dei revisori
    // se i voti dei revisori raggiungono il quorum viene rilasciato il pagamento
    function validaConsegna(bool approvato) external inFase(Fase.Consegna) {
        require(revisori[msg.sender], "Non sei revisore");
        require(!voti[msg.sender], "Gia' votato");

        voti[msg.sender] = true;
        if (approvato) votiPositivi++;

        if (votiPositivi >= quorumRichiesto) {
            (bool ok, ) = payable(vincitore).call{value: importoEscrow}("");
            require(ok, "Trasferimento fallito");
            faseCorrente = Fase.Completato;
            emit PagamentoRilasciato(vincitore, importoEscrow);
        }
    }
}
