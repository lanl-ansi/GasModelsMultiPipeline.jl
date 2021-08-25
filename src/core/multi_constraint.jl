"""
    constraint_interconnection_transient(gm::_GM.AbstractGasModel, nw::Int, i::Int, j::Int, junction_id_i::Int, junction_id_j::Int)

Transient constraint for the interconnection point
"""
function constraint_interconnection_transient(gm::_GM.AbstractGasModel, nw::Int, i::Int, j::Int, junction_id_i::Int, junction_id_j::Int)

    if (_GM.ref(gm, nw, :transfer, i)["is_dispatchable"] == 0 &&
        _GM.ref(gm, nw, :transfer, j)["is_dispatchable"] == 0)
        density = _GM.var(gm, nw, :density)
        rho_i = density[junction_id_i]
        rho_j = density[junction_id_j]
        _GM._add_constraint!(gm, nw, :interconnect_pressure_eq, i, JuMP.@constraint(gm.model, rho_i - rho_j == 0))
        return
    end

    transfer_dict = _GM.var(gm, nw, :transfer_effective)

    t_i = transfer_dict[i]
    t_j = transfer_dict[j]

    density_or_pressure = _GM.var(gm, nw, :density)
    rho_i = density_or_pressure[junction_id_i]
    rho_j = density_or_pressure[junction_id_j]

    _GM._add_constraint!(gm, nw, :interconnect_eq_1, i, JuMP.@constraint(gm.model, t_i + t_j == 0))
    _GM._add_constraint!(gm, nw, :interconnect_pressure_eq, i, JuMP.@constraint(gm.model, rho_i - rho_j == 0))
end


"""
    constraint_interconnection_ss(gm::_GM.AbstractGasModel, nw::Int, i::Int, j::Int, junction_id_i::Int, junction_id_j::Int)

Steady-state constraint for the interconnection point
"""
function constraint_interconnection_ss(gm::_GM.AbstractGasModel, nw::Int, i::Int, j::Int, junction_id_i::Int, junction_id_j::Int)

    if (_GM.ref(gm, nw, :transfer, i)["is_dispatchable"] == 0 &&
        _GM.ref(gm, nw, :transfer, j)["is_dispatchable"] == 0)
        density = _GM.var(gm, nw, :psqr)
        rho_i = density[junction_id_i]
        rho_j = density[junction_id_j]
        _GM._add_constraint!(gm, nw, :interconnect_pressure_eq, i, JuMP.@constraint(gm.model, rho_i - rho_j == 0))
        return
    end

    transfer_dict = _GM.var(gm, nw, :ft)

    t_i = transfer_dict[i]
    t_j = transfer_dict[j]

    density_or_pressure = _GM.var(gm, nw, :psqr)
    rho_i = density_or_pressure[junction_id_i]
    rho_j = density_or_pressure[junction_id_j]

    _GM._add_constraint!(gm, nw, :interconnect_eq_1, i, JuMP.@constraint(gm.model, t_i + t_j == 0))
    _GM._add_constraint!(gm, nw, :interconnect_pressure_eq, i, JuMP.@constraint(gm.model, rho_i - rho_j == 0))
end
