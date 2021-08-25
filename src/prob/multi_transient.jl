export run_transient_multi_ogf, build_transient_multi_ogf

"""
    run_transient_multi_ogf(data, model_type, optimizer; kwargs...)

entry point for multipipeline transient optimal gas flow
"""
function run_transient_multi_ogf(data, model_type, optimizer; kwargs...)
    @assert _IM.ismultinetwork(data) == true
    return _GM.run_model(
        data,
        model_type,
        optimizer,
        build_transient_multi_ogf,
        ref_extensions = [_GM.ref_add_transient!],
        kwargs...,
    )
end

"""
    build_transient_multi_ogf(gm::_GM.AbstractGasModel)

builds the transient optimal gas flow nonlinear problem for multipipeline setting
"""
function build_transient_multi_ogf(gm::_GM.AbstractGasModel)
    time_points = sort(collect(_GM.nw_ids(gm)))
    start_t = time_points[1]
    end_t = time_points[end]
    num_well_discretizations = 4

    # variables for first n-1 time points
    for n in time_points[1:end]
        if n != end_t
            # nodal density variables
            _GM.variable_density(gm, n)

            # compressor variables
            _GM.variable_compressor_flow(gm, n)
            _GM.variable_c_ratio(gm, n)
            _GM.variable_compressor_power(gm, n)

            # pipe variables
            _GM.variable_pipe_flux_avg(gm, n)
            _GM.variable_pipe_flux_neg(gm, n)
            _GM.variable_pipe_flux_fr(gm, n)
            _GM.variable_pipe_flux_to(gm, n)

            # injection withdrawal variables
            _GM.variable_injection(gm, n)
            _GM.variable_withdrawal(gm, n)
            _GM.variable_transfer_flow(gm, n)
        end

        # storage variables
        _GM.variable_storage_flow(gm, n)
        _GM.variable_storage_c_ratio(gm, n)
        _GM.variable_reservoir_density(gm, n)
        _GM.variable_well_density(gm, n, num_discretizations = num_well_discretizations)
        _GM.variable_well_flux_avg(gm, n, num_discretizations = num_well_discretizations)
        _GM.variable_well_flux_neg(gm, n, num_discretizations = num_well_discretizations)
        _GM.variable_well_flux_fr(gm, n, num_discretizations = num_well_discretizations)
        _GM.variable_well_flux_to(gm, n, num_discretizations = num_well_discretizations)

        if n != end_t
            _GM.expression_net_nodal_injection(gm, n)
            _GM.expression_net_nodal_edge_out_flow(gm, n)
        end
    end

    for n in time_points[1:end-1]
        prev = n - 1
        (n == start_t) && (prev = time_points[end-1])
        _GM.expression_density_derivative(gm, n, prev)
        _GM.expression_compressor_power(gm, n)
    end

    # enforcing time-periodicity without adding additional variables
    _GM.var(gm, end_t)[:density] = _GM.var(gm, start_t, :density)
    _GM.var(gm, end_t)[:compressor_flow] = _GM.var(gm, start_t, :compressor_flow)
    _GM.var(gm, end_t)[:pipe_flux_avg] = _GM.var(gm, start_t, :pipe_flux_avg)
    _GM.var(gm, end_t)[:pipe_flux_neg] = _GM.var(gm, start_t, :pipe_flux_neg)
    _GM.var(gm, end_t)[:pipe_flux_fr] = _GM.var(gm, start_t, :pipe_flux_fr)
    _GM.var(gm, end_t)[:pipe_flux_to] = _GM.var(gm, start_t, :pipe_flux_to)
    _GM.var(gm, end_t)[:pipe_flow_avg] = _GM.var(gm, start_t, :pipe_flow_avg)
    _GM.var(gm, end_t)[:pipe_flow_neg] = _GM.var(gm, start_t, :pipe_flow_neg)
    _GM.var(gm, end_t)[:pipe_flow_fr] = _GM.var(gm, start_t, :pipe_flow_fr)
    _GM.var(gm, end_t)[:pipe_flow_to] = _GM.var(gm, start_t, :pipe_flow_to)
    _GM.var(gm, end_t)[:compressor_ratio] = _GM.var(gm, start_t, :compressor_ratio)
    _GM.var(gm, end_t)[:compressor_power_var] = _GM.var(gm, start_t, :compressor_power_var)
    _GM.var(gm, end_t)[:injection] = _GM.var(gm, start_t, :injection)
    _GM.var(gm, end_t)[:withdrawal] = _GM.var(gm, start_t, :withdrawal)
    _GM.var(gm, end_t)[:transfer_effective] = _GM.var(gm, start_t, :transfer_effective)
    _GM.var(gm, end_t)[:transfer_injection] = _GM.var(gm, start_t, :transfer_injection)
    _GM.var(gm, end_t)[:transfer_withdrawal] = _GM.var(gm, start_t, :transfer_withdrawal)
    _GM.var(gm, end_t)[:net_nodal_injection] = _GM.var(gm, start_t, :net_nodal_injection)
    _GM.var(gm, end_t)[:net_nodal_edge_out_flow] = _GM.var(gm, start_t, :net_nodal_edge_out_flow)

    # derivative expressions for the storage
    for n in time_points[1:end]
        (n == end_t) && (continue)
        next = n + 1
        _GM.expression_well_density_derivative(
            gm,
            n,
            next,
            num_discretizations = num_well_discretizations,
        )
        _GM.expression_reservoir_density_derivative(gm, n, next)
    end


    for i in _GM.ids(gm, start_t, :storage)
        _GM.constraint_initial_condition_reservoir(gm, i, start_t)
    end

    for n in time_points[1:end]
        if n != end_t
            for i in _GM.ids(gm, n, :slack_junctions)
                _GM.constraint_slack_junction_density(gm, i, n)
            end

            for i in _GM.ids(gm, n, :junction)
                _GM.constraint_nodal_balance(gm, i, n)
            end

            for i in _GM.ids(gm, n, :compressor)
                _GM.constraint_compressor_physics(gm, i, n)
                _GM.constraint_compressor_power(gm, i, n)
            end

            for i in _GM.ids(gm, n, :pipe)
                _GM.constraint_pipe_mass_balance(gm, i, n)
                _GM.constraint_pipe_momentum_balance(gm, i, n)
            end

            for (i, j) in _GM.ref(gm, n, :interconnections)
                constraint_interconnection_transient(gm, i, j, n)
            end

        end

        for i in _GM.ids(gm, n, :storage)
            _GM.constraint_storage_compressor_regulator(gm, i, n)
            _GM.constraint_storage_well_momentum_balance(
                gm,
                i,
                n,
                num_discretizations = num_well_discretizations,
            )
            if n != end_t
                _GM.constraint_storage_well_mass_balance(
                    gm,
                    i,
                    n,
                    num_discretizations = num_well_discretizations,
                )
            end
            _GM.constraint_storage_well_nodal_balance(
                gm,
                i,
                n,
                num_discretizations = num_well_discretizations,
            )
            _GM.constraint_storage_bottom_hole_reservoir_density(
                gm,
                i,
                n,
                num_discretizations = num_well_discretizations,
            )
            if n != end_t
                _GM.constraint_storage_reservoir_physics(gm, i, n)
            end
        end
    end

    econ_weight = gm.ref[:it][_GM.gm_it_sym][:economic_weighting]
    if econ_weight == 1.0
        _GM.objective_min_transient_load_shed(gm, time_points)
    elseif econ_weight == 0.0
        _GM.objective_min_transient_compressor_power(gm, time_points)
    else
        _GM.objective_min_transient_economic_costs(gm, time_points)
    end

end
