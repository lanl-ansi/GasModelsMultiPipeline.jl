"""
    remap_result(result::Dict{String,<:Any}, data::Dict{String,<:Any}, pipeline_map::Dict{String,Int}, info::RenumberingInfo; units::String=get(data, "per_unit", false) ? "pu" : get(data, "units", "si"))::Dict{String,Any}

Maps result dictionary from multipipeline combined solution to solution by pipeline
"""
function remap_result(result::Dict{String,<:Any}, data::Dict{String,<:Any}, pipeline_map::Dict{String,Int}, info::RenumberingInfo; units::String=get(data, "per_unit", false) ? "pu" : get(data, "units", "si"))::Dict{String,Any}
    if units == "si"
        _GM.make_si_units!(result)
        _GM.make_si_units!(data)
    elseif units == "usc"
        _GM.make_english_units!(result)
        _GM.make_english_units!(data)
    elseif units == "pu"
        _GM.make_per_unit!(result)
        _GM.make_per_unit!(data)
    else
        throw(KeyError("return units '$units' not recognized"))
    end

    asset_types = ["junction", "pipe", "compressor", "short_pipe", "resistor", "regulator", "valve", "receipt", "delivery", "transfer", "storage"]

    pipeline_map = Dict(pipeline_id => pipeline_name for (pipeline_name,pipeline_id) in pipeline_map)

    key_map = Dict()
    for key in asset_types
        if hasproperty(info, Symbol(key)) && !isempty(getproperty(info, Symbol(key)))
            key_map[key] = Dict()
        end

        for (uid, rid) in getproperty(info, Symbol(key))
            if key == "pipe"
                original_pipe = (first(data["nw"]).second)["original_pipe"]["$rid"]

                for pipe_id in original_pipe["fr_pipe"]:original_pipe["to_pipe"]
                    key_map[key][pipe_id] = (uid.pipeline_id, pipe_id)
                    fr_junction = (first(data["nw"]).second)["pipe"]["$pipe_id"]["fr_junction"]
                    to_junction = (first(data["nw"]).second)["pipe"]["$pipe_id"]["to_junction"]
                    key_map["junction"][fr_junction] = (uid.pipeline_id, fr_junction)
                    key_map["junction"][to_junction] = (uid.pipeline_id, to_junction)
                end
            else
                key_map[key][rid] = (uid.pipeline_id, uid.component_id)
            end
        end
    end

    remapped_result = Dict(pipeline_name => Dict(parse(Int, timestep) => Dict() for (timestep,_) in result["nw"]) for (_,pipeline_name) in pipeline_map)
    for (n, nw) in result["nw"]
        if !isempty(nw)
            for asset_type in asset_types
                for (asset_id, asset_result) in get(nw, asset_type, Dict())
                    pipeline_id, component_id = key_map[asset_type][parse(Int, asset_id)]
                    if !haskey(remapped_result[pipeline_map[pipeline_id]][parse(Int, n)], asset_type)
                        remapped_result[pipeline_map[pipeline_id]][parse(Int, n)][asset_type] = Dict()
                    end

                    remapped_result[pipeline_map[pipeline_id]][parse(Int, n)][asset_type][component_id] = asset_result
                end
            end
        end
    end

    return remapped_result
end
