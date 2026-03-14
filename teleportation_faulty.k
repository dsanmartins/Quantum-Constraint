import .metamodel
import .constraints

# ============================================================
# Faulty Case 1: Reuse after measurement without reset
# Violates B1
# q0 is measured and later reused by gate g5, but no reset exists.
# ============================================================

faulty_reuse_after_measurement = metamodel.QuantumCircuit {
    name = "FaultyReuseAfterMeasurement"
    numQubits = 3
    ordering = "little_endian"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "auxiliary"},
        metamodel.Qubit {id = "q2", index = 2, kind = "target"},
    ]

    initialNode = metamodel.InitialNode {id = "init"}
    finalNode   = metamodel.FinalNode   {id = "final"}

    classicalStores = [
        metamodel.ClassicalStore {name = "c0"},
    ]

    gates = [
        metamodel.GateNode {id = "g1", gateType = "H", targets = ["q0"]},
        metamodel.GateNode {id = "g5", gateType = "X", targets = ["q0"]},
    ]

    measures = [
        metamodel.MeasureNode {id = "m1", qubit = "q0", basis = "Z", output = "c0"},
    ]

    flows = [
        metamodel.Flow {source = "init", target = "g1"},
        metamodel.Flow {source = "g1", target = "m1"},
        metamodel.Flow {source = "m1", target = "g5"},
        metamodel.Flow {source = "g5", target = "final"},
    ]
}

validate_faulty_reuse_after_measurement = constraints.CircuitValidation {
    circuit = faulty_reuse_after_measurement
}


# ============================================================
# Faulty Case 2: Ancilla reuse without reset
# Violates B2
# q1 is auxiliary, measured, and later reused in a gate, but not reset.
# ============================================================

faulty_ancilla_cleanup = metamodel.QuantumCircuit {
    name = "FaultyAncillaCleanup"
    numQubits = 3
    ordering = "little_endian"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "auxiliary"},
        metamodel.Qubit {id = "q2", index = 2, kind = "target"},
    ]

    initialNode = metamodel.InitialNode {id = "init"}
    finalNode   = metamodel.FinalNode   {id = "final"}

    classicalStores = [
        metamodel.ClassicalStore {name = "c1"},
    ]

    gates = [
        metamodel.GateNode {id = "g1", gateType = "H", targets = ["q1"]},
        metamodel.GateNode {id = "g2", gateType = "X", targets = ["q1"]},
    ]

    measures = [
        metamodel.MeasureNode {id = "m1", qubit = "q1", basis = "Z", output = "c1"},
    ]

    flows = [
        metamodel.Flow {source = "init", target = "g1"},
        metamodel.Flow {source = "g1", target = "m1"},
        metamodel.Flow {source = "m1", target = "g2"},
        metamodel.Flow {source = "g2", target = "final"},
    ]
}

validate_faulty_ancilla_cleanup = constraints.CircuitValidation {
    circuit = faulty_ancilla_cleanup
}


# ============================================================
# Faulty Case 3: Classical dependency not produced by measurement
# Violates B3
# g5 depends on cX, but no measurement produces cX.
# ============================================================

faulty_classical_dependency = metamodel.QuantumCircuit {
    name = "FaultyClassicalDependency"
    numQubits = 3
    ordering = "little_endian"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "auxiliary"},
        metamodel.Qubit {id = "q2", index = 2, kind = "target"},
    ]

    initialNode = metamodel.InitialNode {id = "init"}
    finalNode   = metamodel.FinalNode   {id = "final"}

    classicalStores = [
        metamodel.ClassicalStore {name = "c0"},
        metamodel.ClassicalStore {name = "c1"},
        metamodel.ClassicalStore {name = "cX"},
    ]

    gates = [
        metamodel.GateNode {id = "g1", gateType = "H", targets = ["q1"]},
        metamodel.GateNode {id = "g5", gateType = "X", targets = ["q2"], classicalDependsOn = ["cX"]},
    ]

    measures = [
        metamodel.MeasureNode {id = "m1", qubit = "q0", basis = "Z", output = "c0"},
        metamodel.MeasureNode {id = "m2", qubit = "q1", basis = "Z", output = "c1"},
    ]

    flows = [
        metamodel.Flow {source = "init", target = "g1"},
        metamodel.Flow {source = "g1", target = "m1"},
        metamodel.Flow {source = "m1", target = "m2"},
        metamodel.Flow {source = "m2", target = "g5"},
        metamodel.Flow {source = "g5", target = "final"},
    ]
}

validate_faulty_classical_dependency = constraints.CircuitValidation {
    circuit = faulty_classical_dependency
}


# ============================================================
# Faulty Case 4: Parallel conflict after fork
# Violates B4
# Two gates directly reachable from the same fork both use q2.
# ============================================================

faulty_parallel_conflict = metamodel.QuantumCircuit {
    name = "FaultyParallelConflict"
    numQubits = 3
    ordering = "little_endian"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "auxiliary"},
        metamodel.Qubit {id = "q2", index = 2, kind = "target"},
    ]

    initialNode = metamodel.InitialNode {id = "init"}
    finalNode   = metamodel.FinalNode   {id = "final"}

    forkNodes = [
        metamodel.ForkNode {id = "fork1"},
    ]

    classicalStores = [
        metamodel.ClassicalStore {name = "c0"},
    ]

    gates = [
        metamodel.GateNode {id = "g1", gateType = "X", targets = ["q2"]},
        metamodel.GateNode {id = "g2", gateType = "Z", targets = ["q2"]},
    ]

    measures = [
        metamodel.MeasureNode {id = "m1", qubit = "q0", output = "c0"},
    ]

    flows = [
        metamodel.Flow {source = "init", target = "fork1"},
        metamodel.Flow {source = "fork1", target = "g1"},
        metamodel.Flow {source = "fork1", target = "g2"},
        metamodel.Flow {source = "g1", target = "final"},
        metamodel.Flow {source = "g2", target = "final"},
    ]
}

validate_faulty_parallel_conflict = constraints.CircuitValidation {
    circuit = faulty_parallel_conflict
}


# ============================================================
# Faulty Case 5: Classically controlled gate with multiple targets
# Violates B5
# A classically dependent SWAP targets two qubits.
# ============================================================

faulty_classical_correction_shape = metamodel.QuantumCircuit {
    name = "FaultyClassicalCorrectionShape"
    numQubits = 3
    ordering = "little_endian"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "auxiliary"},
        metamodel.Qubit {id = "q2", index = 2, kind = "target"},
    ]

    initialNode = metamodel.InitialNode {id = "init"}
    finalNode   = metamodel.FinalNode   {id = "final"}

    classicalStores = [
        metamodel.ClassicalStore {name = "c0"},
    ]

    gates = [
        metamodel.GateNode {
            id = "g1",
            gateType = "SWAP",
            targets = ["q1", "q2"],
            classicalDependsOn = ["c0"]
        },
    ]

    measures = [
        metamodel.MeasureNode {id = "m1", qubit = "q0", output = "c0"},
    ]

    flows = [
        metamodel.Flow {source = "init", target = "m1"},
        metamodel.Flow {source = "m1", target = "g1"},
        metamodel.Flow {source = "g1", target = "final"},
    ]
}

validate_faulty_classical_correction_shape = constraints.CircuitValidation {
    circuit = faulty_classical_correction_shape
}
