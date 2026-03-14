import .metamodel
import .constraints

teleportation = metamodel.QuantumCircuit {
    name = "Teleportation"
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
        metamodel.ForkNode {id = "fork_corr"},
    ]

    joinNodes = [
        metamodel.JoinNode {id = "join_corr"},
    ]

    classicalStores = [
        metamodel.ClassicalStore {name = "c0"},
        metamodel.ClassicalStore {name = "c1"},
    ]

    gates = [
        # Entanglement preparation
        metamodel.GateNode {id = "g1", gateType = "H",    targets = ["q1"]},
        metamodel.GateNode {id = "g2", gateType = "CNOT", targets = ["q2"], controls = ["q1"]},

        # Bell-basis interaction
        metamodel.GateNode {id = "g3", gateType = "CNOT", targets = ["q1"], controls = ["q0"]},
        metamodel.GateNode {id = "g4", gateType = "H",    targets = ["q0"]},

        # Classical corrections on q2
        # X depends on measurement of q1 -> c1
        metamodel.GateNode {id = "g5", gateType = "X",    targets = ["q2"], classicalDependsOn = ["c1"]},

        # Z depends on measurement of q0 -> c0
        metamodel.GateNode {id = "g6", gateType = "Z",    targets = ["q2"], classicalDependsOn = ["c0"]},
    ]

    measures = [
        metamodel.MeasureNode {id = "m1", qubit = "q0", basis = "Z", output = "c0"},
        metamodel.MeasureNode {id = "m2", qubit = "q1", basis = "Z", output = "c1"},
    ]

    flows = [
        # Main sequence before correction phase
        metamodel.Flow {source = "init",      target = "g1"},
        metamodel.Flow {source = "g1",        target = "g2"},
        metamodel.Flow {source = "g2",        target = "g3"},
        metamodel.Flow {source = "g3",        target = "g4"},
        metamodel.Flow {source = "g4",        target = "m1"},
        metamodel.Flow {source = "m1",        target = "m2"},

        # Correction phase starts after both measurements
        metamodel.Flow {source = "m2",        target = "fork_corr"},

        # Independent correction branches
        metamodel.Flow {source = "fork_corr", target = "g5"},
        metamodel.Flow {source = "fork_corr", target = "g6"},

        # Rejoin before final
        metamodel.Flow {source = "g5",        target = "join_corr"},
        metamodel.Flow {source = "g6",        target = "join_corr"},
        metamodel.Flow {source = "join_corr", target = "final"},
    ]
}

validation = constraints.CircuitValidation {
    circuit = teleportation
}
