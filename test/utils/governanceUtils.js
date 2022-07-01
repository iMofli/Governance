const QUORUM_PERCENTAGE = 4; // need 4% of voters to pass --50
const VOTING_PERIOD = 5; // #of blocks. 1 week - vote process duration --50
const VOTING_DELAY = 1; // How many blocks till a proposal vote becomes active --3
const PROPOSAL_DESCRIPTION = "Proposal #1: First proposal";

module.exports = {
    QUORUM_PERCENTAGE,
    VOTING_DELAY,
    VOTING_PERIOD,
    PROPOSAL_DESCRIPTION,
};