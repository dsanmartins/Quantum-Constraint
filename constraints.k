# ============================================================
# constraints.k
# ------------------------------------------------------------
# Behavioral validation rules for quantum circuit models.
# Aligned with Section IV-B and Table II.
# ============================================================
import .metamodel

schema ValidationConfig:
    strictMeasurementChecks: bool = True
    strictClassicalDependencyChecks: bool = True

schema CircuitValidation:
    circuit: metamodel.QuantumCircuit
    config: ValidationConfig = ValidationConfig {}

    # --- 1. Resource ID Lookups (for performance and clarity) ---
    _qIds = [q.id for q in circuit.qubits]
    _csNames = [cs.name for cs in circuit.classicalStores]
    _mOutputs = [m.output for m in circuit.measures]

    # Map classical store names to the IDs of measurement nodes that produce them
    _producingMIds = {
        cs.name: [m.id for m in circuit.measures if m.output == cs.name]
        for cs in circuit.classicalStores
    }

    # --- 2. Execution Graph views (C7) ---
    _allNodes = [
        circuit.initialNode.id,
        circuit.finalNode.id
    ] + [g.id for g in circuit.gates] + [m.id for m in circuit.measures] + [r.id for r in circuit.resets] + [fk.id for fk in circuit.forkNodes] + [jn.id for jn in circuit.joinNodes]

    # Direct predecessor map
    _directPreds = {
        n: [f.source for f in circuit.flows if f.target == n]
        for n in _allNodes
    }

    # Unfold reachability (4 steps)
    # This identifies nodes "earlier" in the flow
    _p1 = {n: _directPreds[n] for n in _allNodes}
    _p2 = {n: _p1[n] + [p_flat for p in _p1[n] for p_flat in _p1[p] if p_flat not in _p1[n]] for n in _allNodes}
    _p3 = {n: _p2[n] + [p_flat for p in _p2[n] for p_flat in _p1[p] if p_flat not in _p2[n]] for n in _allNodes}
    _p4 = {n: _p3[n] + [p_flat for p in _p3[n] for p_flat in _p1[p] if p_flat not in _p3[n]] for n in _allNodes}

    _reachablePreds = _p4

    # --- 3. Pre-calculated Validations (Bypasses check block parser limits) ---

    # C6: Measurement Integrity
    _c6_valid = all m in circuit.measures {
        m.qubit in _qIds and m.output in _csNames
    }

    # C7: Classical Dependency Safety
    # Checks if (i) dependency exists and (ii) is a predecessor
    _c7_valid = all g in circuit.gates {
        all d in g.classicalDependsOn {
            d in _mOutputs and any mid in _producingMIds[d] {
                mid in _reachablePreds[g.id]
            }
        }
    }

    check:
        # C6: A measurement must target a valid qubit and store output in a valid classical store.
        _c6_valid if config.strictMeasurementChecks, "C6 Violation: Measurement references invalid qubit or classical store"

        # C7: Classically controlled gates must reference results from earlier measurements.
        _c7_valid if config.strictClassicalDependencyChecks, "C7 Violation: Classical dependency refers to a measurement not yet performed"