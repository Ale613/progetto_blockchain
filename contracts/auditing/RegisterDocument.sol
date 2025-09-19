// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


/** @title RegisterDocument
*   @notice A simplified contract aimed at the registration of a document for PA
*   @dev Implements a registration od a document
*/
contract RegisterDocument{

    struct Document {
        address submitter;      // who registered the contract
        bytes32 docHash;        // hash of the document
        uint256 timestamp;      // when registered
        bool exists;            // if the document exists
    }

    mapping(bytes32 => Document) public documents;

    // event when a document is registered
    event DocumentRegistered(bytes32 indexed docHash, address indexed registrant, uint256 indexed timestamp);

    /** @notice Function that register a new document */
    function registerDocument(bytes32 docHash) external {

        require(!isRegistered(docHash), "Document already registered!");

        documents[docHash] = Document({
            submitter: msg.sender,
            docHash: docHash,
            timestamp: block.timestamp,
            exists: true
        });

        emit DocumentRegistered(docHash, documents[docHash].submitter, documents[docHash].timestamp);
    }

    // Check if a document is already registered
    function isRegistered(bytes32 docHash) public view returns (bool) {
        return documents[docHash].exists;
    }

    // Retrieve all document's info
    function getDocument(bytes32 docHash) external view returns (address submitter, bytes32 dHash, uint256 timestamp,bool exists){
        
        require(documents[docHash].exists, "Document does not exists!");
        Document memory doc = documents[docHash];
        return (doc.submitter, doc.docHash, doc.timestamp, doc.exists);
    }
}
