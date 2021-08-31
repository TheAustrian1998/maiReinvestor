## **maiReinvestor**

**Warning**: this contract assumes that USDC or MAI are equal to 1USD, in the case of any of this coins fall below 1USD aka "loss it's peg" you can suffer impermanent loss or similar losses. Proceed with caution.

------

### **What is**

maiReinvestor is a contract to execute a yield strategy on polygon network. It accepts USDC and uses miMatic protocol (or maiProtocol) to generate QiDao token and dump it for more USDC. 

The purpose of the contract is to be a single-user contract, it means, only you (deployer) can interact with this contract once it's deployed. It is possible because uses OpenZeppelin [access control contracts](https://docs.openzeppelin.com/contracts/4.x/access-control).

The contract has 3 functions: 

- **deposit()**: introduces USDC in the contract.
- **reinvest()**: swap half of USDC for MAI, add liquidity in Quickswap for pair USDC-MAI, deposits this pair in MaiStakingRewards contract to receive QiDao as rewards. Harvest if can. It receives a "*deadline*" parameter, you can obtain a deadline calling view function **getDeadline()**.
- **closePosition()**: close all positions described above, and returns all yield in form of USDC.

------

### **How to use**

1. Clone repo using *git clone.*
2. Install dependencies using *sudo npm install.*
3. Get a free [alchemy](https://www.alchemy.com/) api key to test in polygon mainnet fork and deploy. Paste it in a *secrets.json* file in root folder (look for *secrets.example.json*).
4. Start your polygon mainnet fork with *npx hardhat node*. (If you don't complete all fields in secrets.json it will throw an error)
5. Check that all works fine with *npx hardhat test tests/testMaiReinvestor.js --network localhost*.
6. Deploy with *npx hardhat run scripts/deploy.js --network polygon*
7. Verify with *npx hardhat verify --constructor-args argumentsVerify.js DEPLOYED_CONTRACT_ADDRESS --network polygon*

To interact with the contract you'll need to do it with [PolygonScan](https://polygonscan.com/). 

Tip: remember to approve to spend your USDC before call **deposit()**, and add 6 more zeros to balances when depositing or approving (USDC ERC20 have 6 decimals).

