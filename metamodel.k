# ============================================================
# metamodel.k
# ------------------------------------------------------------
# Core metamodel for UML-like quantum circuit modeling.
#
# This file contains only:
#   - abstract syntax
#   - typing
#   - arity checks
#   - uniqueness checks
#   - reference integrity
#   - basic control-flow anchoring
#
# It intentionally does NOT contain higher-level behavioral
# constraints such as:
#   - no reuse after measurement without reset
#   - ancilla cleanup
#   - no parallel conflicts
#   - semantic correctness of teleportation
# ============================================================


# ============================================================
# Basic domain elements
# ============================================================

schema Qubit:
    id: str
    index: int
    kind?: "data" | "ancilla" | "auxiliary" | "target" = "data"

    check:
        index >= 0, "Qubit index must be non-negative"


schema ClassicalStore:
    name: str


# ============================================================
# Node hierarchy
# ============================================================

schema InitialNode:
    id: str


schema FinalNode:
    id: str


schema ForkNode:
    id: str


schema JoinNode:
    id: str


schema GateNode:
    id: str
    gateType: "H" | "X" | "Y" | "Z" | "CNOT" | "CZ" | "SWAP" | "Custom"
    targets: [str]
    controls?: [str] = []

    # Optional classical dependencies for hybrid quantum-classical circuits
    classicalDependsOn?: [str] = []

    # Optional metadata
    phaseExact?: bool = True
    decompositionName?: str

    check:
        len(targets) >= 1, "A gate must have at least one target"
        len({t for t in targets}) == len(targets), "Gate targets must be unique"
        len({c for c in controls}) == len(controls), "Gate controls must be unique"
        len({d for d in classicalDependsOn}) == len(classicalDependsOn), \
            "Classical dependencies must be unique"

        # Single-qubit gates
        (gateType not in ["H", "X", "Y", "Z"]) or (len(targets) == 1 and len(controls) == 0), \
            "H, X, Y, Z must have exactly one target and no controls"

        # Standard controlled gates
        (gateType not in ["CNOT", "CZ"]) or (len(targets) == 1 and len(controls) == 1), \
            "CNOT and CZ must have exactly one control and one target"

        # SWAP
        (gateType != "SWAP") or (len(targets) == 2 and len(controls) == 0), \
            "SWAP must have exactly two targets and no controls"

        # Controlled gates cannot use same qubit as control and target
        (gateType not in ["CNOT", "CZ"]) or (controls[0] != targets[0]), \
            "A control qubit cannot be equal to its target qubit"


schema MeasureNode:
    id: str
    qubit: str
    basis?: "X" | "Y" | "Z" = "Z"
    output: str


schema ResetNode:
    id: str
    qubit: str


schema Flow:
    source: str
    target: str

    check:
        source != target, "A flow cannot be a self-loop"


# ============================================================
# Main circuit container
# ============================================================

schema QuantumCircuit:
    name: str
    numQubits: int
    ordering: "little_endian" | "big_endian"

    qubits: [Qubit]

    initialNode: InitialNode
    finalNode: FinalNode

    forkNodes?: [ForkNode] = []
    joinNodes?: [JoinNode] = []

    gates?: [GateNode] = []
    measures?: [MeasureNode] = []
    resets?: [ResetNode] = []

    classicalStores?: [ClassicalStore] = []
    flows?: [Flow] = []

    check:
        # Basic circuit sanity
        numQubits >= 1, "A circuit must have at least one qubit"
        len(qubits) == numQubits, "numQubits must match the number of declared qubits"

        # Uniqueness of qubits
        len({q.id for q in qubits}) == len(qubits), "Qubit ids must be unique"
        len({q.index for q in qubits}) == len(qubits), "Qubit indices must be unique"

        # Uniqueness of node ids by category
        len({g.id for g in gates}) == len(gates), "Gate ids must be unique"
        len({m.id for m in measures}) == len(measures), "Measure ids must be unique"
        len({r.id for r in resets}) == len(resets), "Reset ids must be unique"
        len({f.id for f in forkNodes}) == len(forkNodes), "Fork node ids must be unique"
        len({j.id for j in joinNodes}) == len(joinNodes), "Join node ids must be unique"

        # Uniqueness of classical stores
        len({c.name for c in classicalStores}) == len(classicalStores), \
            "Classical store names must be unique"

        # Initial/final node uniqueness
        initialNode.id != finalNode.id, "Initial and final node ids must be different"

        initialNode.id not in (
            {g.id for g in gates} |
            {m.id for m in measures} |
            {r.id for r in resets} |
            {f.id for f in forkNodes} |
            {j.id for j in joinNodes}
        ), "Initial node id must be unique within the circuit"

        finalNode.id not in (
            {g.id for g in gates} |
            {m.id for m in measures} |
            {r.id for r in resets} |
            {f.id for f in forkNodes} |
            {j.id for j in joinNodes}
        ), "Final node id must be unique within the circuit"

        # NEW: global uniqueness of all node ids across all categories
        len(
            {initialNode.id, finalNode.id} |
            {g.id for g in gates} |
            {m.id for m in measures} |
            {r.id for r in resets} |
            {f.id for f in forkNodes} |
            {j.id for j in joinNodes}
        ) == (
            2 + len(gates) + len(measures) + len(resets) + len(forkNodes) + len(joinNodes)
        ), "All node ids in the circuit must be globally unique"

        # Gate references to declared qubits
        all(t in {q.id for q in qubits} for g in gates for t in g.targets), \
            "Every gate target must reference an existing qubit"

        all(c in {q.id for q in qubits} for g in gates for c in g.controls), \
            "Every gate control must reference an existing qubit"

        # Measure/reset references to declared qubits
        all(m.qubit in {q.id for q in qubits} for m in measures), \
            "Every measurement must reference an existing qubit"

        all(r.qubit in {q.id for q in qubits} for r in resets), \
            "Every reset must reference an existing qubit"

        # Measurement outputs must reference declared classical stores
        all(m.output in {c.name for c in classicalStores} for m in measures), \
            "Every measurement output must reference an existing classical store"

        # Classical dependencies must reference declared classical stores
        all(d in {c.name for c in classicalStores} for g in gates for d in g.classicalDependsOn), \
            "Every classical dependency of a gate must reference an existing classical store"

        # Flow references must point to declared nodes
        all(
            f.source in (
                {initialNode.id, finalNode.id} |
                {g.id for g in gates} |
                {m.id for m in measures} |
                {r.id for r in resets} |
                {fk.id for fk in forkNodes} |
                {jn.id for jn in joinNodes}
            )
            for f in flows
        ), "Every flow source must reference an existing declared node"

        all(
            f.target in (
                {initialNode.id, finalNode.id} |
                {g.id for g in gates} |
                {m.id for m in measures} |
                {r.id for r in resets} |
                {fk.id for fk in forkNodes} |
                {jn.id for jn in joinNodes}
            )
            for f in flows
        ), "Every flow target must reference an existing declared node"

        # Basic control-flow anchoring
        any(f.source == initialNode.id for f in flows), \
            "The circuit must have at least one flow leaving the initial node"

        any(f.target == finalNode.id for f in flows), \
            "The circuit must have at least one flow entering the final node"
