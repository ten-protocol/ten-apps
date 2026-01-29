# UAT Node Selectors

## SGX Nodes Allocation

| Node | Pods |
|------|------|
| vmss00000b | Sequencer enclave + host |
| vmss00000c | Validator-01 + Gateway |
| vmss00000d | Validator-02 + Sequencer enclave02 |
| vmss00000a | Validator-03 |
| vmss000009 | (available/spare) |

## Rules

- **Sequencer**: Main enclave and host must be together on vmss00000b
- **Sequencer enclave02**: Shares node with Validator-02 on vmss00000d
- **Validator-01**: On vmss00000c, shares with Gateway
- **Validator-02**: On vmss00000d, shares with Sequencer enclave02
- **Validator-03**: On vmss00000a
- **Gateway**: Must be on SGX node (vmss00000c with Validator-01)
