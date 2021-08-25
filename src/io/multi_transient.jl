"""
    parse_files(files::Vector{Tuple{String,String}}, connection_file::String; kwargs...)::Tuple{Dict{String,Any},Dict{String,Int},RenumberingInfo}

Parses tuples of steady-state and transient data with a connections file
"""
function parse_files(files::Vector{Tuple{String,String}}, connection_file::String; kwargs...)::Tuple{Dict{String,Any},Dict{String,Int},RenumberingInfo}
    files_io = [(open(static_file, "r"), open(transient_file, "r")) for (static_file, transient_file) in files]
    connection_file_io = open(connection_file, "r")

    mn_data, pipeline_ids, new_id_info = parse_files(files_io, connection_file_io; kwargs...)

    for (static_io, transient_io) in files_io
        close(static_io)
        close(transient_io)
    end
    close(connection_file_io)

    return mn_data, pipeline_ids, new_id_info
end


"""
    parse_files(
        ios::Vector{<:Tuple{<:IO,<:IO}},
        connections_io::IO;
        total_time::Real = 86400.0,
        time_step::Real = 3600.0,
        spatial_discretization::Real = 10000.0,
        additional_time::Real = 21600.0
    )::Tuple{Dict{String,Any},Dict{String,Int},RenumberingInfo}

Parses tuples of steady-state and transient data with a connections file
"""
function parse_files(ios::Vector{<:Tuple{<:IO,<:IO}}, connections_io::IO;
    total_time::Real = 86400.0,
    time_step::Real = 3600.0,
    spatial_discretization::Real = 10000.0,
    additional_time::Real = 21600.0)::Tuple{Dict{String,Any},Dict{String,Int},RenumberingInfo}

    new_id_info = RenumberingInfo()
    pipeline_ids = Dict{String,Int}()
    static_data = Dict{String,Any}(i => Dict{String,Any}() for i in components_to_renumber)
    transient_data = Array{Dict{String,Any},1}()

    for (static_io, transient_io) in ios
        static_pipeline_data = _GM.parse_matgas(static_io)

        if !haskey(static_pipeline_data, "name")
            @error "pipeline name needs to be provided for every pipeline"
        end

        pipeline_ids[static_pipeline_data["name"]] = length(pipeline_ids) + 1
        current_pipeline_id = length(pipeline_ids)

        for (key, val) in static_pipeline_data
            if !(key in components_to_renumber)
                static_data[key] = val
            end
        end

        for (component_id, component) in sort(collect(get(static_pipeline_data, "junction", [])); by=x->x[1])
            uniqueId = UniqueId(current_pipeline_id, parse(Int, component_id))
            new_id = get_max_id(new_id_info, :junction) + 1
            new_id_info.junction[uniqueId] = new_id
            update_counts!(new_id_info)
            static_data["junction"][string(new_id)] = Dict{String,Any}()
            for (key, value) in component
                static_data["junction"][string(new_id)][key] = (key == "id") ? new_id : value
            end
        end

        edge_components = [("pipe", new_id_info.pipe),
            ("compressor", new_id_info.compressor),
            ("ne_pipe", new_id_info.ne_pipe),
            ("ne_compressor", new_id_info.ne_compressor),
            ("short_pipe", new_id_info.short_pipe),
            ("resistor", new_id_info.resistor),
            ("regulator", new_id_info.regulator),
            ("valve", new_id_info.valve)
        ]
        for (component_name, dict_name) in edge_components
            for (component_id, component) in sort(collect(get(static_pipeline_data, component_name, [])); by=x->x[1])
                sym_component_name = Symbol(component_name)
                uniqueId = UniqueId(current_pipeline_id, parse(Int, component_id))
                new_id = get_max_id(new_id_info, sym_component_name) + 1
                dict_name[uniqueId] = new_id
                update_counts!(new_id_info)
                static_data[component_name][string(new_id)] = Dict{String,Any}()
                for (key, value) in component
                    fr_junction = get_new_id(new_id_info, :junction, current_pipeline_id, component["fr_junction"])
                    to_junction = get_new_id(new_id_info, :junction, current_pipeline_id, component["to_junction"])
                    (key == "fr_junction") && (static_data[component_name][string(new_id)][key] = fr_junction; continue)
                    (key == "to_junction") && (static_data[component_name][string(new_id)][key] = to_junction; continue)
                    static_data[component_name][string(new_id)][key] = (key == "id") ? new_id : value
                end
            end
        end

        nodal_components = [("receipt", new_id_info.receipt),
            ("delivery", new_id_info.delivery),
            ("transfer", new_id_info.transfer),
            ("storage", new_id_info.storage)
        ]
        for (component_name, dict_name) in nodal_components
            for (component_id, component) in sort(collect(get(static_pipeline_data, component_name, [])); by=x->x[1])
                sym_component_name = Symbol(component_name)
                uniqueId = UniqueId(current_pipeline_id, parse(Int, component_id))
                new_id = get_max_id(new_id_info, sym_component_name) + 1
                dict_name[uniqueId] = new_id
                update_counts!(new_id_info)
                static_data[component_name][string(new_id)] = Dict{String,Any}()
                for (key, value) in component
                    junction_id = get_new_id(new_id_info, :junction, current_pipeline_id, component["junction_id"])
                    (key == "junction_id") && (static_data[component_name][string(new_id)][key] = junction_id; continue)
                    static_data[component_name][string(new_id)][key] = (key == "id") ? new_id : value
                end
            end
        end

        transient_pipeline_data = _GM.parse_transient(transient_io)
        for data in transient_pipeline_data
            component_id = parse(Int, data["component_id"])
            component_type = Symbol(data["component_type"])
            new_component_id = get_new_id(new_id_info, component_type, current_pipeline_id, component_id)
            data["component_id"] = string(new_component_id)
            push!(transient_data, data)
        end
    end
    static_data["name"] = "combined_pipeline_case"

    static_data["interconnections"] = Array{Tuple{Int,Int},1}()

    raw = readlines(connections_io)
    for line in raw[2:end]
        case_1, transfer_id_1, case_2, transfer_id_2 = split(line, ",")
        pipeline_id_1 = pipeline_ids[case_1]
        pipeline_id_2 = pipeline_ids[case_2]
        new_id_1 = get_new_id(new_id_info, :transfer, pipeline_id_1, parse(Int, transfer_id_1))
        new_id_2 = get_new_id(new_id_info, :transfer, pipeline_id_2, parse(Int, transfer_id_2))
        push!(static_data["interconnections"], (new_id_1, new_id_2))
    end


    _GM.check_non_negativity(static_data)
    _GM.correct_p_mins!(static_data)

    _GM.per_unit_data_field_check!(static_data)
    _GM.add_compressor_fields!(static_data)

    _GM.make_si_units!(static_data)
    _GM.add_base_values!(static_data)
    _GM.check_connectivity(static_data)
    _GM.check_status(static_data)
    _GM.check_edge_loops(static_data)

    _GM.check_global_parameters(static_data)

    _GM._prep_transient_data!(static_data, spatial_discretization = spatial_discretization)

    _GM.make_si_units!(transient_data, static_data)
    time_series_block = _GM._create_time_series_block(
        transient_data,
        total_time = total_time,
        time_step = time_step,
        additional_time = additional_time
    )

    static_data["time_series"] = deepcopy(time_series_block)
    mn_data = _IM.make_multinetwork(static_data, _GM.gm_it_name, _GM._gm_global_keys)
    _GM.make_per_unit!(mn_data)
    return mn_data, pipeline_ids, new_id_info
end
