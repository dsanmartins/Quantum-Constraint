
# Quantum Circuit Metamodel and Validation (KCL)

This repository contains a model-driven representation of quantum circuits using KCL (K Configuration Language).
It defines a metamodel, validation constraints, and example circuits for demonstrating structural and behavioral
verification of quantum circuit models.

## Repository Structure

- `metamodel.k` — Defines the abstract syntax of the quantum circuit modeling language.
- `constraints.k` — Contains validation rules ensuring semantic correctness of circuits.
- `teleportation.k` — Example of a valid quantum teleportation circuit.
- `teleportation_faulty.k` — Fault-injected circuits used to test validation rules.

## Overview

The repository follows Model-Driven Engineering (MDE) principles:

1. **Metamodel**
   Defines the elements of a quantum circuit such as qubits, gates, measurements, and control-flow nodes.

2. **Constraints**
   Specify semantic rules that valid circuits must satisfy (e.g., qubit reuse restrictions, classical control validity).

3. **Example Models**
   Demonstrate how circuits are represented and validated.

## Metamodel (`metamodel.k`)

The metamodel defines the structural components of quantum circuits:

- Qubit
- ClassicalStore
- GateNode
- MeasureNode
- ResetNode
- InitialNode
- FinalNode
- ForkNode
- JoinNode
- Flow
- QuantumCircuit

These elements represent both quantum operations and classical control structures.

## Constraints (`constraints.k`)

Validation rules ensure that circuits obey semantic restrictions.

Example rules include:

- No reuse of a qubit after measurement without reset.
- Ancilla qubits must be cleaned before reuse.
- Parallel operations cannot act on the same qubit simultaneously.
- Classical dependencies must reference valid measurement results.

## Example Circuit (`teleportation.k`)

Implements the quantum teleportation protocol:

- Preparation of an entangled Bell pair
- Interaction with the source qubit
- Measurement of control qubits
- Conditional correction on the target qubit

The circuit passes all validation rules.

## Fault Injection (`teleportation_faulty.k`)

Contains intentionally incorrect circuits used to validate constraint detection.

Examples:

- Using a measured qubit without reset
- Reusing ancilla qubits improperly
- Invalid classical control dependencies

These models should fail validation.

## Purpose

This project demonstrates how model-driven engineering techniques can be used to:

- represent quantum circuits at a modeling level
- separate syntax from semantic validation
- detect modeling errors early
- support experimentation with quantum software verification

## Possible Extensions

Future improvements may include:

- resource analysis for qubits
- concurrency verification
- hardware-aware constraints
- circuit optimization checks
