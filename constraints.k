# ============================================================
# constraints.k
# ------------------------------------------------------------
# Behavioral validation rules for quantum circuit models.
#
# This file is aligned with Table II of the paper and with the
# structural/behavioral separation stated in Section IV-B:
#   - C6 Measurement Integrity
#   - C7 Classical Dependency Safety
#
# Structural constraints C1-C5 and C8 are defined in
# metamodel.k.
# ============================================================

import .metamodel

schema ValidationConfig:
    strictMeasurementChecks?: bool = True
    strictClassicalDependencyChecks?: bool = True


schema CircuitValidation:
    circuit: metamodel.QuantumCircuit
    config?: ValidationConfig = ValidationConfig {}

    # --------------------------------------------------------
    # Derived views over the execution graph
    # --------------------------------------------------------
    allNodeIds = (
        {circuit.initialNode.id, circuit.finalNode.id} |
        {g.id for g in circuit.gates} |
        {m.id for m in circuit.measures} |
        {r.id for r in circuit.resets} |
        {fk.id for fk in circuit.forkNodes} |
        {jn.id for jn in circuit.joinNodes}
    )

    # Direct predecessor relation of a node
    directPreds = {
        n: {f.source for f in circuit.flows if f.target == n}
        for n in allNodeIds
    }

    # Acyclic circuits let us unfold predecessor reachability up
    # to the number of nodes. This gives a graph-based notion of
    # "defined earlier in the circuit" for C7.
    predDepth1 = {n: directPreds[n] for n in allNodeIds}
    predDepth2 = {n: predDepth1[n] | {p2 for p1 in predDepth1[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth3 = {n: predDepth2[n] | {p2 for p1 in predDepth2[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth4 = {n: predDepth3[n] | {p2 for p1 in predDepth3[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth5 = {n: predDepth4[n] | {p2 for p1 in predDepth4[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth6 = {n: predDepth5[n] | {p2 for p1 in predDepth5[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth7 = {n: predDepth6[n] | {p2 for p1 in predDepth6[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth8 = {n: predDepth7[n] | {p2 for p1 in predDepth7[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth9 = {n: predDepth8[n] | {p2 for p1 in predDepth8[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth10 = {n: predDepth9[n] | {p2 for p1 in predDepth9[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth11 = {n: predDepth10[n] | {p2 for p1 in predDepth10[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth12 = {n: predDepth11[n] | {p2 for p1 in predDepth11[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth13 = {n: predDepth12[n] | {p2 for p1 in predDepth12[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth14 = {n: predDepth13[n] | {p2 for p1 in predDepth13[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth15 = {n: predDepth14[n] | {p2 for p1 in predDepth14[n] for p2 in predDepth1[p1]} for n in allNodeIds}
    predDepth16 = {n: predDepth15[n] | {p2 for p1 in predDepth15[n] for p2 in predDepth1[p1]} for n in allNodeIds}

    # For the case-study circuits in the paper, 16 steps is more
    # than enough to cover the full execution graph. If larger
    # models are used later, this unfolding depth can be increased.
    reachablePreds = predDepth16

    producingMeasurementIds = {
        c.name: {m.id for m in circuit.measures if m.output == c.name}
        for c in circuit.classicalStores
    }

    check:
        # ====================================================
        # C6: Measurement Integrity
        # A measurement must target exactly one qubit and
        # produce a classical output. Since MeasureNode has a
        # single qubit field, here we enforce semantic validity:
        #   (i) the measured qubit belongs to the circuit,
        #   (ii) the output classical store belongs to the circuit.
        # ====================================================
        (not config.strictMeasurementChecks) or all(
            (
                m.qubit in {q.id for q in circuit.qubits} and
                m.output in {c.name for c in circuit.classicalStores}
            )
            for m in circuit.measures
        ), "C6 Violation: A measurement must target exactly one valid circuit qubit and produce a valid classical output"

        # ====================================================
        # C7: Classical Dependency Safety
        # A classically controlled gate must reference a
        # measurement result that is:
        #   (i) produced by some measurement in the circuit, and
        #   (ii) produced earlier in the execution graph.
        #
        # Condition (ii) is approximated strongly through graph
        # reachability: the measurement node producing the
        # classical store must be a predecessor of the gate node.
        # This matches the causal reading in the paper.
        # ====================================================
        (not config.strictClassicalDependencyChecks) or all(
            (
                d in {m.output for m in circuit.measures}
            ) and (
                any(
                    mid in reachablePreds[g.id]
                    for mid in producingMeasurementIds[d]
                )
            )
            for g in circuit.gates
            for d in g.classicalDependsOn
        ), "C7 Violation: Classically controlled gates must reference measurement results defined earlier in the circuit execution flow"
