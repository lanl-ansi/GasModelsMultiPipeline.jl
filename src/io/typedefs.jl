"UniqueId struct"
mutable struct UniqueId
    pipeline_id::Int
    component_id::Int
end


Base.hash(a::UniqueId, h::UInt) = hash(a.component_id, hash(a.pipeline_id, hash(:UniqueId, h)))
Base.isequal(a::UniqueId, b::UniqueId) = isequal(a.pipeline_id, b.pipeline_id) &&
    isequal(a.component_id, b.component_id) && true
Base.:(==)(a::UniqueId, b::UniqueId) = isequal(a.pipeline_id, b.pipeline_id) &&
    isequal(a.component_id, b.component_id) && true


"Renumbering Info struct"
mutable struct RenumberingInfo
    junction::Dict{UniqueId,Int}
    pipe::Dict{UniqueId,Int}
    compressor::Dict{UniqueId,Int}
    receipt::Dict{UniqueId,Int}
    delivery::Dict{UniqueId,Int}
    transfer::Dict{UniqueId,Int}
    short_pipe::Dict{UniqueId,Int}
    resistor::Dict{UniqueId,Int}
    regulator::Dict{UniqueId,Int}
    valve::Dict{UniqueId,Int}
    storage::Dict{UniqueId,Int}
    ne_pipe::Dict{UniqueId,Int}
    ne_compressor::Dict{UniqueId,Int}
    max_junction_id::Int
    max_pipe_id::Int
    max_compressor_id::Int
    max_receipt_id::Int
    max_delivery_id::Int
    max_transfer_id::Int
    max_short_pipe_id::Int
    max_resistor_id::Int
    max_regulator_id::Int
    max_valve_id::Int
    max_storage_id::Int
    max_ne_pipe_id::Int
    max_ne_compressor_id::Int
end


"map of component to max_id"
component_to_max_id_map = Dict(
    :junction => :max_junction_id,
    :pipe => :max_pipe_id,
    :compressor => :max_compressor_id,
    :receipt => :max_receipt_id,
    :delivery => :max_delivery_id,
    :transfer => :max_transfer_id,
    :short_pipe => :max_short_pipe_id,
    :resistor => :max_resistor_id,
    :regulator => :max_regulator_id,
    :valve => :max_valve_id,
    :storage => :max_storage_id,
    :ne_pipe => :max_ne_pipe_id,
    :ne_compressor => :max_ne_compressor_id
)


"component types that need to be renumbered"
components_to_renumber = ["junction", "pipe", "compressor",
    "receipt", "delivery", "transfer", "short_pipe", "resistor",
    "valve", "storage", "ne_pipe", "ne_compressor"]


"""
    RenumberingInfo()

Initialization of RenumberingInfo struct
"""
function RenumberingInfo()
    return RenumberingInfo(
        Dict{UniqueId,Int}(),
        Dict{UniqueId,Int}(),
        Dict{UniqueId,Int}(),
        Dict{UniqueId,Int}(),
        Dict{UniqueId,Int}(),
        Dict{UniqueId,Int}(),
        Dict{UniqueId,Int}(),
        Dict{UniqueId,Int}(),
        Dict{UniqueId,Int}(),
        Dict{UniqueId,Int}(),
        Dict{UniqueId,Int}(),
        Dict{UniqueId,Int}(),
        Dict{UniqueId,Int}(),
        0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0
    )
end


"""
get_new_id(info::RenumberingInfo, component_type::Symbol, pipeline_id::Int, component_id::Int)::Int

gets the new id
"""
function get_new_id(info::RenumberingInfo, component_type::Symbol, pipeline_id::Int, component_id::Int)::Int
    return getfield(info, component_type)[UniqueId(pipeline_id, component_id)]
end


"""
    update_counts!(info::RenumberingInfo)

updates the counts of the total number of assets
"""
function update_counts!(info::RenumberingInfo)
    info.max_junction_id = length(info.junction)
    info.max_pipe_id = length(info.pipe)
    info.max_compressor_id = length(info.compressor)
    info.max_receipt_id = length(info.receipt)
    info.max_delivery_id = length(info.delivery)
    info.max_transfer_id = length(info.transfer)
    info.max_short_pipe_id = length(info.short_pipe)
    info.max_resistor_id = length(info.resistor)
    info.max_regulator_id = length(info.regulator)
    info.max_valve_id = length(info.valve)
    info.max_storage_id = length(info.storage)
    info.max_ne_pipe_id = length(info.ne_pipe)
    info.max_ne_compressor_id = length(info.ne_compressor)
end


"""
    get_max_id(info, component_type::Symbol)::Int

Gets the maximum id of `component_type`
"""
function get_max_id(info, component_type::Symbol)::Int
    return getfield(info, component_to_max_id_map[component_type])
end
