"""
    constraint_interconnection_transient(gm::AbstractGasModel, i::Int, j::Int, nw::Int = _GM.nw_id_default)

Transient constraint for the interconnection point
"""
function constraint_interconnection_transient(gm::AbstractGasModel, i::Int, j::Int, nw::Int = _GM.nw_id_default)
    junction_id_i = _IM.ref(gm, :gm, nw, :transfer, i)["junction_id"]
    junction_id_j = _IM.ref(gm, :gm, nw, :transfer, j)["junction_id"]
    constraint_interconnection_transient(gm, nw, i, j, junction_id_i, junction_id_j)
end


"""
    constraint_interconnection_ss(gm::AbstractGasModel, i::Int, j::Int, nw::Int = _GM.nw_id_default)

Steady-state constraint for the interconnection point
"""
function constraint_interconnection_ss(gm::AbstractGasModel, i::Int, j::Int, nw::Int = _GM.nw_id_default)
    junction_id_i = _IM.ref(gm, :gm, nw, :transfer, i)["junction_id"]
    junction_id_j = _IM.ref(gm, :gm, nw, :transfer, j)["junction_id"]
    constraint_interconnection_ss(gm, nw, i, j, junction_id_i, junction_id_j)
end
