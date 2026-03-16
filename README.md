# Quantum Circuit Metamodel and Validation (KCL)

This repository provides a **model-driven representation of quantum
circuits** using **KCL (K Configuration Language)**.\
It implements a domain-specific metamodel, a constraint-based validation
layer, and example circuit models to demonstrate **structural and
behavioral verification of quantum circuit designs**.

The implementation follows the approach presented in the paper:

**"Towards a Constraint-Based Approach for Quantum Circuit Modeling."**

------------------------------------------------------------------------

# Repository Structure

-   `metamodel.k`\
    Defines the **abstract syntax** of the quantum circuit modeling
    language and implements **structural well-formedness constraints
    (C1--C5, C8)**.

-   `constraints.k`\
    Implements **behavioral validation rules (C6--C7)** that regulate
    the interaction between quantum operations and classical
    information.

-   `teleportation.k`\
    A **valid model** of the quantum teleportation protocol used as a
    reference circuit.

-   `teleportation_faulty.k`\
    A set of **fault-injected circuit models** used to test the
    validation mechanism.

------------------------------------------------------------------------

# Overview

The repository follows **Model-Driven Engineering (MDE)** principles.

Quantum circuits are represented as **models** that are validated before
being translated into executable quantum programs.

The approach separates three concerns:

### 1. Metamodel

Defines the **structural elements** of a quantum circuit.

These include:

-   Qubit resources
-   Classical registers
-   Quantum gates
-   Measurement operations
-   Reset operations
-   Control-flow nodes
-   Execution flow relations

The metamodel specifies the **abstract syntax** of the modeling
language.

------------------------------------------------------------------------

### 2. Constraint-Based Validation

Additional **well-formedness constraints** ensure that circuit models
satisfy both structural and behavioral rules.

The validation rules are divided into two groups:

#### Structural Constraints (implemented in `metamodel.k`)

-   **C1 -- Flow Consistency**\
    Each flow edge must connect nodes belonging to the same circuit.

-   **C2 -- Node Existence**\
    All node identifiers referenced in flows must exist.

-   **C3 -- Qubit Binding**\
    Every quantum operation must reference at least one qubit.

-   **C4 -- Control--Target Disjointness**\
    A gate cannot use the same qubit as both control and target.

-   **C5 -- Resource Locality**\
    Qubits and classical stores referenced by operations must belong to
    the circuit.

-   **C8 -- Control-Flow Anchoring**\
    Each circuit must contain exactly one `InitialNode` and one
    `FinalNode`.

------------------------------------------------------------------------

#### Behavioral Constraints (implemented in `constraints.k`)

-   **C6 -- Measurement Integrity**\
    A measurement must reference a valid qubit and produce a valid
    classical output.

-   **C7 -- Classical Dependency Safety**\
    Classically controlled gates must reference measurement results that
    are **produced earlier in the circuit execution flow**.

These constraints enforce **correct hybrid quantum--classical
interactions**.

------------------------------------------------------------------------

# Metamodel (`metamodel.k`)

The metamodel defines the structural components of quantum circuits.

Core modeling elements include:

-   `Qubit`
-   `ClassicalStore`
-   `GateNode`
-   `MeasureNode`
-   `ResetNode`
-   `InitialNode`
-   `FinalNode`
-   `ForkNode`
-   `JoinNode`
-   `Flow`
-   `QuantumCircuit`

Together, these elements represent both:

-   **quantum operations**
-   **classical control flow**

within a unified circuit model.

------------------------------------------------------------------------

# Constraints (`constraints.k`)

The constraint layer provides **behavioral validation rules** evaluated
by the KCL engine.

These rules detect inconsistencies such as:

-   invalid measurement definitions
-   classical dependencies that are not produced by measurements
-   classical dependencies that appear **after** the gate that uses them

The validation process analyzes the circuit model and produces
**diagnostic messages identifying violated constraints**.

------------------------------------------------------------------------

# Example Circuit (`teleportation.k`)

The repository includes a model of the **quantum teleportation
protocol**.

The circuit contains:

1.  Bell-pair generation between qubits
2.  Interaction with the source qubit
3.  Measurement of intermediate qubits
4.  Classical communication
5.  Conditional correction gates

This model satisfies all constraints and therefore **passes validation
successfully**.

------------------------------------------------------------------------

# Fault Injection (`teleportation_faulty.k`)

To evaluate the validation mechanism, several **fault scenarios** are
implemented.

Each faulty circuit introduces a specific modeling error corresponding
to one of the well-formedness constraints.

Examples include:

-   invalid flow connections
-   references to undefined nodes
-   gates without qubit bindings
-   control--target conflicts
-   invalid measurement outputs
-   incorrect classical dependencies
-   structural anchoring violations

These faulty models are expected to **fail validation** and generate
error reports.

------------------------------------------------------------------------

# Purpose

This repository demonstrates how **model-driven engineering techniques**
can improve the reliability of quantum software by:

-   representing quantum circuits as structured models
-   separating syntax from validation logic
-   enabling automated constraint checking
-   detecting design errors early in the development lifecycle

------------------------------------------------------------------------

# Possible Extensions

Future extensions may include:

-   hardware-aware validation rules
-   qubit resource analysis
-   connectivity constraints for specific devices
-   circuit equivalence checking
-   model-to-code transformations (e.g., OpenQASM or Qiskit generation)
