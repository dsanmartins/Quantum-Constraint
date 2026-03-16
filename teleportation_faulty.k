import .metamodel
import .constraints

# ============================================================
# teleportation_faulty.k
# ------------------------------------------------------------
# Fault-injected variants of the teleportation circuit aligned
# with the paper's constraint taxonomy (C1-C8).
#
# Each faulty scenario is defined as an independent mutated
# model derived from the same base structure. The companion
# validation object makes the intended failure explicit.
# ============================================================

# ------------------------------------------------------------
# F1 — C1 Flow Consistency
# Invalid execution relation: a flow starts at the FinalNode.
# ------------------------------------------------------------
teleportation_faulty_f1 = metamodel.QuantumCircuit {
    name = "Teleportation_F1_C1"
    numQubits = 3
    ordering = "little"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "ancilla"},
        metamodel.Qubit {id = "q2", index = 2, kind = "data"},
    ]

    initialNode = metamodel.InitialNode {id = "init"}
    finalNode   = metamodel.FinalNode   {id = "final"}

    classicalStores = [
        metamodel.ClassicalStore {name = "c0"},
        metamodel.ClassicalStore {name = "c1"},
    ]

    gates = [
        metamodel.GateNode {id = "g1", gateType = "H",    targets = ["q1"]},
        metamodel.GateNode {id = "g2", gateType = "CNOT", targets = ["q2"], controls = ["q1"]},
    ]

    measures = [
        metamodel.MeasureNode {id = "m1", qubit = "q0", basis = "Z", output = "c0"},
    ]

    flows = [
        metamodel.Flow {source = "final", target = "g1"},
        metamodel.Flow {source = "g1",    target = "g2"},
        metamodel.Flow {source = "g2",    target = "m1"},
        metamodel.Flow {source = "m1",    target = "final"},
    ]
}

validation_f1 = constraints.CircuitValidation {
    circuit = teleportation_faulty_f1
}


# ------------------------------------------------------------
# F2 — C2 Node Existence
# Undefined target node referenced by a flow.
# ------------------------------------------------------------
teleportation_faulty_f2 = metamodel.QuantumCircuit {
    name = "Teleportation_F2_C2"
    numQubits = 3
    ordering = "little"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "ancilla"},
        metamodel.Qubit {id = "q2", index = 2, kind = "data"},
    ]

    initialNode = metamodel.InitialNode {id = "init"}
    finalNode   = metamodel.FinalNode   {id = "final"}

    gates = [
        metamodel.GateNode {id = "g1", gateType = "H", targets = ["q1"]},
    ]

    flows = [
        metamodel.Flow {source = "init", target = "g1"},
        metamodel.Flow {source = "g1",   target = "ghost_node"},
        metamodel.Flow {source = "g1",   target = "final"},
    ]
}

validation_f2 = constraints.CircuitValidation {
    circuit = teleportation_faulty_f2
}


# ------------------------------------------------------------
# F3 — C3 Qubit Binding
# Gate declared without targets or controls.
# ------------------------------------------------------------
teleportation_faulty_f3 = metamodel.QuantumCircuit {
    name = "Teleportation_F3_C3"
    numQubits = 3
    ordering = "little"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "ancilla"},
        metamodel.Qubit {id = "q2", index = 2, kind = "data"},
    ]

    initialNode = metamodel.InitialNode {id = "init"}
    finalNode   = metamodel.FinalNode   {id = "final"}

    gates = [
        metamodel.GateNode {id = "g1", gateType = "Custom", targets = [], controls = []},
    ]

    flows = [
        metamodel.Flow {source = "init", target = "g1"},
        metamodel.Flow {source = "g1",   target = "final"},
    ]
}

validation_f3 = constraints.CircuitValidation {
    circuit = teleportation_faulty_f3
}


# ------------------------------------------------------------
# F4 — C4 Control-Target Disjointness
# Same qubit used as control and target in a controlled gate.
# ------------------------------------------------------------
teleportation_faulty_f4 = metamodel.QuantumCircuit {
    name = "Teleportation_F4_C4"
    numQubits = 3
    ordering = "little"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "ancilla"},
        metamodel.Qubit {id = "q2", index = 2, kind = "data"},
    ]

    initialNode = metamodel.InitialNode {id = "init"}
    finalNode   = metamodel.FinalNode   {id = "final"}

    gates = [
        metamodel.GateNode {id = "g1", gateType = "CNOT", targets = ["q1"], controls = ["q1"]},
    ]

    flows = [
        metamodel.Flow {source = "init", target = "g1"},
        metamodel.Flow {source = "g1",   target = "final"},
    ]
}

validation_f4 = constraints.CircuitValidation {
    circuit = teleportation_faulty_f4
}


# ------------------------------------------------------------
# F5 — C5 Resource Locality
# Gate references a qubit that does not belong to the circuit.
# ------------------------------------------------------------
teleportation_faulty_f5 = metamodel.QuantumCircuit {
    name = "Teleportation_F5_C5"
    numQubits = 3
    ordering = "little"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "ancilla"},
        metamodel.Qubit {id = "q2", index = 2, kind = "data"},
    ]

    initialNode = metamodel.InitialNode {id = "init"}
    finalNode   = metamodel.FinalNode   {id = "final"}

    gates = [
        metamodel.GateNode {id = "g1", gateType = "X", targets = ["q9"]},
    ]

    flows = [
        metamodel.Flow {source = "init", target = "g1"},
        metamodel.Flow {source = "g1",   target = "final"},
    ]
}

validation_f5 = constraints.CircuitValidation {
    circuit = teleportation_faulty_f5
}


# ------------------------------------------------------------
# F6 — C6 Measurement Integrity
# Measurement output does not correspond to a valid classical
# store in the circuit. Under the current metamodel, this also
# triggers C5 because output locality is structural.
# ------------------------------------------------------------
teleportation_faulty_f6 = metamodel.QuantumCircuit {
    name = "Teleportation_F6_C6"
    numQubits = 3
    ordering = "little"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "ancilla"},
        metamodel.Qubit {id = "q2", index = 2, kind = "data"},
    ]

    initialNode = metamodel.InitialNode {id = "init"}
    finalNode   = metamodel.FinalNode   {id = "final"}

    classicalStores = [
        metamodel.ClassicalStore {name = "c0"},
    ]

    measures = [
        metamodel.MeasureNode {id = "m1", qubit = "q0", basis = "Z", output = "cX"},
    ]

    flows = [
        metamodel.Flow {source = "init", target = "m1"},
        metamodel.Flow {source = "m1",   target = "final"},
    ]
}

validation_f6 = constraints.CircuitValidation {
    circuit = teleportation_faulty_f6
}


# ------------------------------------------------------------
# F7 — C7 Classical Dependency Safety
# Classically controlled gate depends on an existing classical
# store that is never produced by any preceding measurement.
# ------------------------------------------------------------
teleportation_faulty_f7 = metamodel.QuantumCircuit {
    name = "Teleportation_F7_C7"
    numQubits = 3
    ordering = "little"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "ancilla"},
        metamodel.Qubit {id = "q2", index = 2, kind = "data"},
    ]

    initialNode = metamodel.InitialNode {id = "init"}
    finalNode   = metamodel.FinalNode   {id = "final"}

    classicalStores = [
        metamodel.ClassicalStore {name = "c0"},
        metamodel.ClassicalStore {name = "c1"},
    ]

    gates = [
        metamodel.GateNode {id = "g1", gateType = "H", targets = ["q1"]},
        metamodel.GateNode {id = "g2", gateType = "X", targets = ["q2"], classicalDependsOn = ["c1"]},
    ]

    measures = [
        metamodel.MeasureNode {id = "m1", qubit = "q0", basis = "Z", output = "c0"},
    ]

    flows = [
        metamodel.Flow {source = "init", target = "g1"},
        metamodel.Flow {source = "g1",   target = "m1"},
        metamodel.Flow {source = "m1",   target = "g2"},
        metamodel.Flow {source = "g2",   target = "final"},
    ]
}

validation_f7 = constraints.CircuitValidation {
    circuit = teleportation_faulty_f7
}


# ------------------------------------------------------------
# F8 — C8 Control-Flow Anchoring
# No incoming flow reaches the FinalNode.
# ------------------------------------------------------------
teleportation_faulty_f8 = metamodel.QuantumCircuit {
    name = "Teleportation_F8_C8"
    numQubits = 3
    ordering = "little"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "ancilla"},
        metamodel.Qubit {id = "q2", index = 2, kind = "data"},
    ]

    initialNode = metamodel.InitialNode {id = "init"}
    finalNode   = metamodel.FinalNode   {id = "final"}

    gates = [
        metamodel.GateNode {id = "g1", gateType = "H", targets = ["q1"]},
        metamodel.GateNode {id = "g2", gateType = "X", targets = ["q2"]},
    ]

    flows = [
        metamodel.Flow {source = "init", target = "g1"},
        metamodel.Flow {source = "g1",   target = "g2"},
    ]
}

validation_f8 = constraints.CircuitValidation {
    circuit = teleportation_faulty_f8
}
