# ============================================================
# constraints.k
# ------------------------------------------------------------
# Higher-level behavioral / semantic validation rules for
# quantum circuit models.
#
# This file is separate from the metamodel on purpose.
# It captures domain correctness properties that go beyond
# abstract syntax and structural integrity.
# ============================================================

import .metamodel


# ------------------------------------------------------------
# Validation configuration
# ------------------------------------------------------------

schema ValidationConfig:
    # If true, measured qubits may only be used again after reset.
    enforceResetBeforeReuse?: bool = True

    # If true, ancilla/auxiliary qubits must not be reused after
    # measurement unless reset.
    enforceAncillaCleanup?: bool = True

    # If true, lightweight parallel conflict checks are enabled.
    enforceNoParallelConflicts?: bool = True


# ------------------------------------------------------------
# Validation wrapper
# ------------------------------------------------------------

schema CircuitValidation:
    circuit: metamodel.QuantumCircuit
    config?: ValidationConfig = ValidationConfig {}

    check:
        # ====================================================
        # Behavioral Constraint B1:
        # No reuse after measurement without reset
        # ----------------------------------------------------
        # Conservative approximation:
        # if a qubit is measured, then either
        #   (a) it is reset somewhere in the circuit, or
        #   (b) it is not used again by any gate.
        #
        # This is intentionally lightweight and suitable for
        # small case studies.
        # ====================================================
        (not config.enforceResetBeforeReuse) or all(
            (
                (m.qubit in {r.qubit for r in circuit.resets}) or
                not any(m.qubit in (g.targets + g.controls) for g in circuit.gates)
            )
            for m in circuit.measures
        ), "A measured qubit must not be reused unless a reset is declared"

        # ====================================================
        # Behavioral Constraint B2:
        # Ancilla / auxiliary cleanup
        # ----------------------------------------------------
        # If an ancilla or auxiliary qubit is measured, then
        # either it is reset, or it must not be reused in gates.
        # ====================================================
        (not config.enforceAncillaCleanup) or all(
            (
                (m.qubit in {r.qubit for r in circuit.resets}) or
                not any(
                    m.qubit in (g.targets + g.controls)
                    for g in circuit.gates
                )
            )
            for m in circuit.measures
            if m.qubit in {
                q.id for q in circuit.qubits
                if q.kind in ["ancilla", "auxiliary"]
            }
        ), "Ancilla or auxiliary qubits must be reset before reuse"

        # ====================================================
        # Behavioral Constraint B3:
        # Classical dependency must be produced by a measurement
        # ----------------------------------------------------
        # The metamodel already checks that the referenced
        # classical store exists. This rule strengthens that by
        # requiring the store to be produced by a measurement in
        # the same circuit.
        # ====================================================
        all(
            d in {m.output for m in circuit.measures}
            for g in circuit.gates
            for d in g.classicalDependsOn
        ), "Every classical dependency must be produced by a measurement in the circuit"

        # ====================================================
        # Behavioral Constraint B4:
        # Lightweight parallel conflict rule
        # ----------------------------------------------------
        # For gates directly reachable from the same fork node:
        #
        # - It is invalid if two parallel gates use the same qubit
        #   and at least one of them is NOT classically controlled.
        #
        # - It is allowed if all overlapping uses on that qubit are
        #   among classically controlled correction gates.
        #
        # This makes the rule compatible with teleportation, where
        # X and Z corrections both act on q2 after a fork and are
        # each controlled by classical measurement outcomes.
        # ====================================================
        (not config.enforceNoParallelConflicts) or all(
            not any(
                (
                    g1.id != g2.id and
                    len({q for q in (g1.targets + g1.controls) if q in (g2.targets + g2.controls)}) > 0 and
                    (
                        len(g1.classicalDependsOn) == 0 or
                        len(g2.classicalDependsOn) == 0
                    )
                )
                for g1 in [g for f in circuit.flows if f.source == fk.id for g in circuit.gates if g.id == f.target]
                for g2 in [g for f in circuit.flows if f.source == fk.id for g in circuit.gates if g.id == f.target]
            )
            for fk in circuit.forkNodes
        ), "Parallel branches from the same fork must not operate on the same qubit unless all overlapping gates are classically controlled"

        # ====================================================
        # Behavioral Constraint B5:
        # Classically controlled correction shape
        # ----------------------------------------------------
        # If a gate has classical dependencies, then it should
        # target exactly one qubit. This is a lightweight rule
        # suitable for teleportation-style correction gates.
        # ====================================================
        all(
            (len(g.classicalDependsOn) == 0) or (len(g.targets) == 1)
            for g in circuit.gates
        ), "A classically controlled correction gate must target exactly one qubit"
