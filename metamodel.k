# ============================================================
# metamodel.k
# ------------------------------------------------------------
# Core metamodel for quantum circuit modeling.
#
# This file is aligned with the paper's Table II and Section
# III-B. It implements the structural constraints:
#   - C1 Flow Consistency
#   - C2 Node Existence
#   - C3 Qubit Binding
#   - C4 Control-Target Disjointness
#   - C5 Resource Locality
#   - C8 Control-Flow Anchoring
#
# Behavioral constraints are intentionally externalized to
# constraints.k:
#   - C6 Measurement Integrity
#   - C7 Classical Dependency Safety
# ============================================================

# ============================================================
# Enumerations reflected in the paper
# ------------------------------------------------------------
# QubitKind: data | ancilla
# BasisKind: X | Y | Z
# OrderingKind: little | big
# ============================================================

schema Qubit:
    id: str
    index: int
    kind?: "data" | "ancilla" = "data"

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
    classicalDependsOn?: [str] = []
    phaseExact?: bool = True
    decompositionName?: str

    check:
        # C3: every operation must be bound to at least one qubit
        len(targets) + len(controls) >= 1, \
            "C3 Violation: Every quantum operation must reference at least one qubit resource"

        len({t for t in targets}) == len(targets), \
            "Gate targets must be unique"
        len({c for c in controls}) == len(controls), \
            "Gate controls must be unique"
        len({d for d in classicalDependsOn}) == len(classicalDependsOn), \
            "Classical dependencies must be unique"

        # Lightweight gate-shape checks used by the case study.
        (gateType not in ["H", "X", "Y", "Z"]) or (len(targets) == 1 and len(controls) == 0), \
            "Single-qubit gates must have exactly one target and no controls"

        (gateType not in ["CNOT", "CZ"]) or (len(targets) == 1 and len(controls) == 1), \
            "CNOT and CZ must have exactly one target and one control"

        (gateType != "SWAP") or (len(targets) == 2 and len(controls) == 0), \
            "SWAP must have exactly two targets and no controls"

        # C4: control and target roles must be disjoint
        all(t not in controls for t in targets), \
            "C4 Violation: Control qubits and target qubits of a controlled gate must be disjoint"


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
    ordering: "little" | "big"

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
        numQubits >= 1, "A circuit must declare at least one qubit"
        len(qubits) == numQubits, \
            "numQubits must match the number of declared qubits"

        # Resource uniqueness
        len({q.id for q in qubits}) == len(qubits), \
            "Qubit ids must be unique"
        len({q.index for q in qubits}) == len(qubits), \
            "Qubit indices must be unique"
        len({c.name for c in classicalStores}) == len(classicalStores), \
            "Classical store names must be unique"

        # Global uniqueness of executable node identifiers
        len(
            {initialNode.id, finalNode.id} |
            {g.id for g in gates} |
            {m.id for m in measures} |
            {r.id for r in resets} |
            {fk.id for fk in forkNodes} |
            {jn.id for jn in joinNodes}
        ) == (2 + len(gates) + len(measures) + len(resets) + len(forkNodes) + len(joinNodes)), \
            "All node ids in the circuit must be globally unique"

        # ----------------------------------------------------
        # C5: Resource Locality
        # ----------------------------------------------------
        all(t in {q.id for q in qubits} for g in gates for t in g.targets), \
            "C5 Violation: Gate targets must belong to the circuit"

        all(c in {q.id for q in qubits} for g in gates for c in g.controls), \
            "C5 Violation: Gate controls must belong to the circuit"

        all(m.qubit in {q.id for q in qubits} for m in measures), \
            "C5 Violation: Measurements must reference qubits belonging to the circuit"

        all(r.qubit in {q.id for q in qubits} for r in resets), \
            "C5 Violation: Resets must reference qubits belonging to the circuit"

        all(m.output in {c.name for c in classicalStores} for m in measures), \
            "C5 Violation: Measurement outputs must belong to the circuit"

        all(d in {c.name for c in classicalStores} for g in gates for d in g.classicalDependsOn), \
            "C5 Violation: Classical dependencies must reference classical stores belonging to the circuit"

        # ----------------------------------------------------
        # C1 + C2: Flow Consistency and Node Existence
        # ----------------------------------------------------
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
        ), "C2 Violation: Every flow source must reference an existing node"

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
        ), "C2 Violation: Every flow target must reference an existing node"

        all(
            f.source != finalNode.id and f.target != initialNode.id
            for f in flows
        ), "C1 Violation: Every flow edge must define a valid directed execution relation inside the circuit"

        # ----------------------------------------------------
        # C8: Control-Flow Anchoring
        # ----------------------------------------------------
        any(f.source == initialNode.id for f in flows), \
            "C8 Violation: The circuit must contain an outgoing flow from the InitialNode"

        any(f.target == finalNode.id for f in flows), \
            "C8 Violation: The circuit must contain an incoming flow to the FinalNode"
