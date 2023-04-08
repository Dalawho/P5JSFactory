## P5Factory
A simple Factory contract setup to make deploying P5JS projects using scripty easy and cheap. 

2 Variables are available in the p5js script: 
- randomNr: A uint96 random number generated at mint
- tokenId: TokenNr of the NFT

Uses the solady (https://github.com/Vectorized/solady) ERC1967Factory to deploy clones and scripty (https://github.com/intartnft/scripty.sol) to generate the html. 
