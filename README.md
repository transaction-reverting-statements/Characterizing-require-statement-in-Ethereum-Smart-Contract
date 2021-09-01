# Characterizing-require-statement-in-Ethereum-Smart-Contract
Dataset for the manuscript "Characterizing Transaction-Reverting Statements in Ethereum Smart Contracts", 
including the contract dataset of tmeplate contract and dapp contracts, 
as well as the results of use purpose classification and customization patterns classification on transaction-Reverting statements.

## Repository Structure
- **Dataset** folder includes the template contract dataset and dapp contract dataset we constructed.
- **User_purpose_taxonomy** folder includes the use purpose taxonomy classification results for both dapp contracts and template contracts.
- **Customization_pattern_use_purpose_taxonomy** folder includes the use purpose taxonomy  classification results for 100 random selected customization patterns.
- **Running_cases** folder includes the running result of the increased case and decreased case shown in RQ4, which is detected by the Oyente tool.
- [Static analyzer](https://github.com/echohermion/customization_pattern_checker) used in RQ3 for identifying customization
 patterns of transaction-reverting statements.

## Publication
ASE 2021 submission #223 [arxiv version](https://arxiv.org/abs/2108.10799).
