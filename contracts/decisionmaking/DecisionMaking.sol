// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DecisionMakingPA {

    enum Role { NONE, PROPOSER, TECHNICAL_REVIEWER, DECISION_MAKER, ADMIN }
    enum Stage { Draft, TechnicalReview, Approval, Approved, Rejected }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        bytes32 documentHash;
        Stage stage;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 approvals;
        uint256 rejections;
    }

    struct ReviewDecision {
        bool decided;
        bool approved;
        string comment;
    }

    uint256 public nextProposalId = 1;

    // Should be decided by the administration or set to immutable
    // For example, in a voting with a fixed threshold set by the law, it should be immutable
    uint256 public approvalThreshold = 1;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(Role => bool)) public hasRole;
    mapping(uint256 => mapping(address => ReviewDecision)) public technicalReviews;
    mapping(uint256 => mapping(address => int8)) public approvalVotes;
    mapping(uint256 => address[]) public reviewersForProposal;

    event ProposalCreated(uint256 proposalId, address proposer, string title, bytes32 documentHash);
    event ProposalDocumentUpdated(uint256 proposalId, bytes32 newHash);
    event TechnicalReviewCast(uint256 proposalId, address reviewer, bool approved, string comment);
    event ProposalAdvanced(uint256 proposalId, Stage newStage);
    event ApprovalCast(uint256 proposalId, address decisionMaker, bool support);
    event ProposalFinalized(uint256 proposalId, bool result);
    event RoleAssigned(address indexed user, Role role);
    event RoleRevoked(address indexed user, Role role);

    modifier onlyRole(Role role) {
        require(hasRole[msg.sender][role], "Access denied: wrong role");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposals[proposalId].id != 0, "Proposal does not exist");
        _;
    }

    // Deployer is Admin by default
    constructor() {
        hasRole[msg.sender][Role.ADMIN] = true;
        hasRole[msg.sender][Role.PROPOSER] = true;
        hasRole[msg.sender][Role.TECHNICAL_REVIEWER] = true;
        hasRole[msg.sender][Role.DECISION_MAKER] = true;
    }

    function assignRole(address user, Role role) external onlyRole(Role.ADMIN){
        require(role != Role.NONE, "Invalid role");
        require(!hasRole[user][role], "User already has this role");
        hasRole[user][role] = true;
        emit RoleAssigned(user, role);

    }

    function revokeRole(address user, Role role) external onlyRole(Role.ADMIN){
        require(role != Role.NONE, "Invalid role");
        require(hasRole[user][role], "User does not have this role");
        hasRole[user][role] = false;
        emit RoleRevoked(user, role);
    }

    function createProposal(string calldata title, bytes32 documentHash) external onlyRole(Role.PROPOSER) {
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            title: title,
            documentHash: documentHash,
            stage: Stage.Draft,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            approvals: 0,
            rejections: 0
        });

        emit ProposalCreated(proposalId, msg.sender, title, documentHash);
    }

    function updateProposalDocument(uint256 proposalId, bytes32 newHash)
        external
        onlyRole(Role.PROPOSER)
        proposalExists(proposalId)
    {
        Proposal storage p = proposals[proposalId];
        require(p.proposer == msg.sender, "Not the proposer");
        require(p.stage == Stage.Draft, "Proposal not in Draft stage");

        p.documentHash = newHash;
        p.updatedAt = block.timestamp;

        emit ProposalDocumentUpdated(proposalId, newHash);
    }

    function advanceToTechnicalReview(uint256 proposalId) external
        proposalExists(proposalId)
        onlyRole(Role.ADMIN)
    {
        Proposal storage p = proposals[proposalId];
        require(p.stage == Stage.Draft, "Not in Draft stage");

        p.stage = Stage.TechnicalReview;
        p.updatedAt = block.timestamp;

        emit ProposalAdvanced(proposalId, Stage.TechnicalReview);
    }

    function castTechnicalReview(uint256 proposalId, bool approved, string calldata comment)
        external
        proposalExists(proposalId)
        onlyRole(Role.TECHNICAL_REVIEWER)
    {
        Proposal storage p = proposals[proposalId];
        require(p.stage == Stage.TechnicalReview, "Not in TechnicalReview stage");

        ReviewDecision storage decision = technicalReviews[proposalId][msg.sender];
        require(!decision.decided, "Already reviewed");

        decision.decided = true;
        decision.approved = approved;
        decision.comment = comment;

        reviewersForProposal[proposalId].push(msg.sender);

        emit TechnicalReviewCast(proposalId, msg.sender, approved, comment);
    }

    function advanceToApproval(uint256 proposalId)
        external
        proposalExists(proposalId)
        onlyRole(Role.ADMIN)
    {
        Proposal storage p = proposals[proposalId];
        require(p.stage == Stage.TechnicalReview, "Not in TechnicalReview stage");

        for (uint256 i = 0; i < reviewersForProposal[proposalId].length; i++) {
            address reviewer = reviewersForProposal[proposalId][i];
            ReviewDecision storage decision = technicalReviews[proposalId][reviewer];

            if (!decision.decided || !decision.approved) {
                p.stage = Stage.Rejected;
                p.updatedAt = block.timestamp;
                emit ProposalFinalized(proposalId, false);
                return;
            }
        }

        p.stage = Stage.Approval;
        p.updatedAt = block.timestamp;
        emit ProposalAdvanced(proposalId, Stage.Approval);
    }

    function castApproval(uint256 proposalId, bool support)
        external
        onlyRole(Role.DECISION_MAKER)
        proposalExists(proposalId)
    {
        Proposal storage p = proposals[proposalId];
        require(p.stage == Stage.Approval, "Not in Approval stage");
        require(approvalVotes[proposalId][msg.sender] == 0, "Already voted");

        if (support) {
            p.approvals++;
            approvalVotes[proposalId][msg.sender] = 1;
        } else {
            p.rejections++;
            approvalVotes[proposalId][msg.sender] = -1;
        }

        emit ApprovalCast(proposalId, msg.sender, support);
    }

    function finalizeProposal(uint256 proposalId) external proposalExists(proposalId) onlyRole(Role.ADMIN) {
        Proposal storage p = proposals[proposalId];
        require(p.stage == Stage.Approval, "Not in Approval stage");

        bool result = p.approvals >= approvalThreshold && p.approvals > p.rejections;
        
        if (result) {
            p.stage = Stage.Approved;
        } else {
            p.stage = Stage.Rejected;
        }
        
        p.updatedAt = block.timestamp;

        emit ProposalFinalized(proposalId, result);
    }

    // Only if PA doesn't want the threshold to be immutable
    function setApprovalThreshold(uint256 _newThreshold) external onlyRole(Role.ADMIN) {
        approvalThreshold = _newThreshold;
    }
}
