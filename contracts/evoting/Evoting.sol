// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//Contratto minimale che implementa un'elezione on-chain:
// l'admin definisce i candidati e registra gli elettori.
// ogni elettore registrato può votare una sola volta.
// i voti vengono conteggiati automaticamente e i risultati sono visibili in tempo reale.
contract EVoting {
    
    // Indirizzo dell'amministratore che gestisce l'elezione
    address public admin;

    // Nome identificativo dell'elezione (es. "Elezioni 2025")
    string public nomeElezione;

    // Stati dell'elezione
    bool public iniziata;
    bool public terminata;

    // Struttura dati per i candidati
    struct Candidato {
        string nome;
        uint256 voti;
    }

    // Lista dei candidati
    Candidato[] private candidati;

    // Mapping degli elettori registrati e se hanno già votato
    mapping(address => bool) public registrato;
    mapping(address => bool) public haVotato;

    // Eventi per trasparenza e auditing
    event CandidatoAggiunto(uint256 indexed idx, string nome);
    event ElettoreRegistrato(address indexed elettore);
    event VotoEspresso(address indexed elettore, uint256 indexed candidatoIdx);
    event ElezioneIniziata();
    event ElezioneTerminata();

    // Modificatori
    modifier soloAdmin() {
        require(msg.sender == admin, "Solo admin");
        _;
    }

    modifier soloQuandoIniziata() {
        require(iniziata && !terminata, "Elezione non attiva");
        _;
    }

    // Costruttore
    constructor(string memory _nome) {
        admin = msg.sender;
        nomeElezione = _nome;
        iniziata = false;
        terminata = false;
    }

    // Funzioni admin
    
    // Aggiunge un nuovo candidato all'elezione
    function aggiungiCandidato(string calldata _nome) external soloAdmin {
        candidati.push(Candidato({nome: _nome, voti: 0}));
        emit CandidatoAggiunto(candidati.length - 1, _nome);
    }

    // Registra un elettore che potrà votare una sola volta
    function registraElettore(address _elettore) external soloAdmin {
        require(!registrato[_elettore], "Gia registrato");
        registrato[_elettore] = true;
        emit ElettoreRegistrato(_elettore);
    }

    // Avvia ufficialmente l'elezione
    function iniziaElezione() external soloAdmin {
        require(!iniziata, "Gia iniziata");
        require(!terminata, "Gia terminata");
        iniziata = true;
        emit ElezioneIniziata();
    }

    // Termina l'elezione
    function terminaElezione() external soloAdmin soloQuandoIniziata {
        terminata = true;
        iniziata = false;
        emit ElezioneTerminata();
    }
    
    // Permette a un elettore registrato di esprimere un voto indicando l'id del candidato
    function vota(uint256 candidatoIndex) external soloQuandoIniziata {
        require(registrato[msg.sender], "Non registrato");
        require(!haVotato[msg.sender], "Hai gia votato");
        require(candidatoIndex < candidati.length, "Candidato inesistente");

        candidati[candidatoIndex].voti += 1;
        haVotato[msg.sender] = true;

        emit VotoEspresso(msg.sender, candidatoIndex);
    }
    
    // Restituisce il numero di candidati registrati
    function numeroCandidati() external view returns (uint256) {
        return candidati.length;
    }

    // Restituisce nome e voti di un candidato dato il suo indice
    function getCandidato(uint256 idx) external view returns (string memory nome, uint256 voti) {
        require(idx < candidati.length, "Indice non valido");
        Candidato storage c = candidati[idx];
        return (c.nome, c.voti);
    }

    // Restituisce l'intera lista dei candidati con i relativi voti
    function getTuttiCandidati() external view returns (string[] memory nomi, uint256[] memory voti) {
        uint256 n = candidati.length;
        nomi = new string[](n);
        voti = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            nomi[i] = candidati[i].nome;
            voti[i] = candidati[i].voti;
        }
        return (nomi, voti);
    }

}
