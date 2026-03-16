import .metamodel
import .constraints

teleportation = metamodel.QuantumCircuit {
    name = "Teleportation"
    numQubits = 3
    ordering = "little"

    qubits = [
        metamodel.Qubit {id = "q0", index = 0, kind = "data"},
        metamodel.Qubit {id = "q1", index = 1, kind = "ancilla"},
        metamodel.Qubit {id = "q2", index = 2, kind = "data"},
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
        # Bell-pair preparation on q1 and q2
        metamodel.GateNode {id = "g1", gateType = "H",    targets = ["q1"]},
        metamodel.GateNode {id = "g2", gateType = "CNOT", targets = ["q2"], controls = ["q1"]},

        # Bell-basis interaction between q0 and q1
        metamodel.GateNode {id = "g3", gateType = "CNOT", targets = ["q1"], controls = ["q0"]},
        metamodel.GateNode {id = "g4", gateType = "H",    targets = ["q0"]},

        # Conditional corrections on q2
        # X depends on the measurement of q1, stored in c1
        metamodel.GateNode {id = "g5", gateType = "X",    targets = ["q2"], classicalDependsOn = ["c1"]},

        # Z depends on the measurement of q0, stored in c0
        metamodel.GateNode {id = "g6", gateType = "Z",    targets = ["q2"], classicalDependsOn = ["c0"]},
    ]

    measures = [
        metamodel.MeasureNode {id = "m1", qubit = "q0", basis = "Z", output = "c0"},
        metamodel.MeasureNode {id = "m2", qubit = "q1", basis = "Z", output = "c1"},
    ]

    flows = [
        # Main quantum sequence
        metamodel.Flow {source = "init",      target = "g1"},
        metamodel.Flow {source = "g1",        target = "g2"},
        metamodel.Flow {source = "g2",        target = "g3"},
        metamodel.Flow {source = "g3",        target = "g4"},
        metamodel.Flow {source = "g4",        target = "m1"},
        metamodel.Flow {source = "m1",        target = "m2"},

        # Correction phase starts only after measurements are completed
        metamodel.Flow {source = "m2",        target = "fork_corr"},

        # Parallel classical corrections
        metamodel.Flow {source = "fork_corr", target = "g5"},
        metamodel.Flow {source = "fork_corr", target = "g6"},

        # Join and terminate
        metamodel.Flow {source = "g5",        target = "join_corr"},
        metamodel.Flow {source = "g6",        target = "join_corr"},
        metamodel.Flow {source = "join_corr", target = "final"},
    ]
}

validation = constraints.CircuitValidation {
    circuit = teleportation
}
