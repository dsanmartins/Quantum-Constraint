# ============================================================
# metamodel.k
# ============================================================

schema Qubit:
    id: str
    index: int
    kind?: "data" | "ancilla" = "data"
    check:
        index >= 0, "Qubit index must be non-negative"

schema ClassicalStore:
    name: str

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
        len(targets) + len(controls) >= 1, "C3 Violation: operation must reference a qubit"

        # Uniqueness using length of filtered list
        all t in targets { len([x for x in targets if x == t]) == 1 }, "Gate targets must be unique"
        all c in controls { len([x for x in controls if x == c]) == 1 }, "Gate controls must be unique"

        # Gate-shape constraints
        (gateType not in ["H", "X", "Y", "Z"]) or (len(targets) == 1 and len(controls) == 0), "Single-qubit gate shape mismatch"
        (gateType not in ["CNOT", "CZ"]) or (len(targets) == 1 and len(controls) == 1), "Two-qubit gate shape mismatch"
        (gateType != "SWAP") or (len(targets) == 2 and len(controls) == 0), "SWAP gate shape mismatch"

        # C4: disjoint roles
        all t in targets { t not in controls }, "C4 Violation: Control and target qubits must be disjoint"

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

schema QuantumCircuit:
    name: str
    numQubits: int
    ordering: "little" | "big"
    qubits: [Qubit]
    initialNode: InitialNode
    finalNode: FinalNode
    forkNodes: [ForkNode] = []
    joinNodes: [JoinNode] = []
    gates: [GateNode] = []
    measures: [MeasureNode] = []
    resets: [ResetNode] = []
    classicalStores: [ClassicalStore] = []
    flows: [Flow] = []

    check:
        numQubits >= 1
        len(qubits) == numQubits

        # Unique Qubits using nested comprehension
        all q in qubits { len([qu for qu in qubits if qu.id == q.id]) == 1 }, "Qubit ids must be unique"
        all q in qubits { len([qu for qu in qubits if qu.index == q.index]) == 1 }, "Qubit indices must be unique"

        # C5: Resource Locality
        all g in gates { all t in g.targets { t in [q.id for q in qubits] } }
        all g in gates { all c in g.controls { c in [q.id for q in qubits] } }
        all m in measures { m.qubit in [q.id for q in qubits] }
        all m in measures { m.output in [cs.name for cs in classicalStores] }

        # C1, C2, C8: Flow Constraints
        all f in flows {
            f.source in [initialNode.id, finalNode.id] + [g.id for g in gates] + [m.id for m in measures] + [r.id for r in resets] + [fk.id for fk in forkNodes] + [jn.id for jn in joinNodes]
        }, "C2 Violation: Flow source does not exist"

        all f in flows { f.source != finalNode.id }, "C1 Violation: FinalNode cannot be a source"
        all f in flows { f.target != initialNode.id }, "C1 Violation: InitialNode cannot be a target"

        any f in flows { f.source == initialNode.id }, "C8 Violation: No outgoing flow from InitialNode"
        any f in flows { f.target == finalNode.id }, "C8 Violation: No incoming flow to FinalNode"