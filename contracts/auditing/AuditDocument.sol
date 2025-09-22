// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/** @title IRegisterDocument
*   @notice Interface for an external contract
*/
interface IRegisterDocument{

    function getDocument(bytes32 docHash) external view returns (address submitter, bytes32 dHash, uint256 timestamp,bool exists);
}


/** @title AuditDocument
*   @notice A simplified contract that implement a method to audit a document for the PA
*   @dev Implements the audit of a document
*/
contract AuditDocument{

    address public owner;

    // Deployer become owner
    constructor() {
        owner = msg.sender;
    }

    struct Audit{

        bytes32 docHash;
        bytes32 auditHash;
        address auditor;
        uint256 timestamp;
        bool isDocValid;
    }
    
    mapping(bytes32 => Audit) public audits;
    mapping(bytes32 => bytes32[]) private auditsByDoc;
    mapping(address => bool) public authorizedAuditors;

    // !!! THE ADDRESS IS ONLY AN EXAMPLE
    address public constant REGISTER_DOCUMENT_CONTRACT = 0x9d83e140330758a8fFD07F8Bd73e86ebcA8a5692;
    IRegisterDocument RegisterDocumentContract = IRegisterDocument(REGISTER_DOCUMENT_CONTRACT);

    event AuditCreated(
        bytes32 indexed docHash,
        bytes32 indexed auditHash,
        address indexed auditor,
        uint256 timestamp,
        bool  isDocValid
    );
    event AuditorAuthorized(address indexed auditor);
    event AuditorRevoked(address indexed auditor);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyAuditor() {
        require(authorizedAuditors[msg.sender], "Not an authorized auditor");
        _;
    }

    function authorizeAuditor(address _auditor) external onlyOwner {
        require(!authorizedAuditors[_auditor], "Auditor already authorized!");
        authorizedAuditors[_auditor] = true;
        emit AuditorAuthorized(_auditor);
    }

    function revokeAuditor(address _auditor) external onlyOwner {
        require(authorizedAuditors[_auditor], "Auditor is not authorized!");
        authorizedAuditors[_auditor] = false;
        emit AuditorRevoked(_auditor);
    }

    /** @notice Create an audit by an authorized auditor */
    function createAudit(bytes32 _docHash) external onlyAuditor{

        (, bytes32 tempDocHash, ,) = RegisterDocumentContract.getDocument(_docHash);

        bool _isDocValid = (tempDocHash == _docHash);

        bytes32 _auditHash = keccak256(
            abi.encodePacked(_docHash, msg.sender, block.timestamp, _isDocValid)
        );

        audits[_auditHash] = Audit({
            docHash: _docHash,
            auditor: msg.sender,
            timestamp: block.timestamp,
            isDocValid: _isDocValid,
            auditHash: _auditHash
        });

        auditsByDoc[_docHash].push(_auditHash);

        emit AuditCreated(
            _docHash,
            _auditHash,
            audits[_auditHash].auditor,
            audits[_auditHash].timestamp,
            audits[_auditHash].isDocValid
            ); 
    }

    /** @notice Return all audits for a given document */
    function getAuditsByDoc(bytes32 _docHash) external view returns (Audit[] memory) {
        
        require(auditsByDoc[_docHash].length > 0, "No audits found for this document!");

        bytes32[] storage hashes = auditsByDoc[_docHash];
        Audit[] memory result = new Audit[](hashes.length);

        for (uint256 i = 0; i < hashes.length; i++) {
            result[i] = audits[hashes[i]];
        }

        return result;    }

    /** @notice Return a single audit by auditHash */
    function getAudit(bytes32 _auditHash) external view returns (Audit memory){
            
        require(audits[_auditHash].timestamp > 0, "Audit does not exist!");
        return audits[_auditHash];
    }

}