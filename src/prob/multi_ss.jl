export run_multi_ogf, build_multi_ogf

# Definitions for running an optimal gas flow (ogf)

"""
    run_multi_ogf(file, model_type, optimizer; kwargs...)

entry point into running the ogf problem
"""
function run_multi_ogf(file, model_type, optimizer; kwargs...)
    return _GM.run_model(
        file,
        model_type,
        optimizer,
        build_multi_ogf;
        solution_processors = [
            _GM.sol_psqr_to_p!,
            _GM.sol_compressor_p_to_r!,
            _GM.sol_regulator_p_to_r!,
        ],
        kwargs...,
    )
end


"""
    run_soc_multi_ogf(file, optimizer; kwargs...)

run Second-Order Cone steady state multipipeline ogf
"""
function run_soc_multi_ogf(file, optimizer; kwargs...)
    return run_multi_ogf(file, CRDWPGasModel, optimizer; kwargs...)
end


"""
    run_dwp_multi_ogf(file, optimizer; kwargs...)

Run DWP steady state multipipeline ogf
"""
function run_dwp_multi_ogf(file, optimizer; kwargs...)
    return run_multi_ogf(file, DWPGasModel, optimizer; kwargs...)
end


"""
    build_multi_ogf(gm::AbstractGasModel)

construct the steady state ogf problem
"""
function build_multi_ogf(gm::AbstractGasModel)
    bounded_compressors = Dict(
        x for x in _GM.ref(gm, :compressor) if
        _GM._calc_is_compressor_energy_bounded(
            _GM.get_specific_heat_capacity_ratio(gm.data),
            _GM.get_gas_specific_gravity(gm.data),
            _GM.get_temperature(gm.data),
            x.second
        )
    )

    _GM.variable_pressure(gm)
    _GM.variable_pressure_sqr(gm)
    _GM.variable_flow(gm)
    _GM.variable_on_off_operation(gm)
    _GM.variable_load_mass_flow(gm)
    _GM.variable_production_mass_flow(gm)
    _GM.variable_transfer_mass_flow(gm)
    _GM.variable_compressor_ratio_sqr(gm)

    _GM.objective_min_economic_costs(gm)

    for (i, junction) in _GM.ref(gm, :junction)
        _GM.constraint_mass_flow_balance(gm, i)

        if (junction["junction_type"] == 1)
            _GM.constraint_pressure(gm, i)
        end
    end

    for i in _GM.ids(gm, :pipe)
        _GM.constraint_pipe_pressure(gm, i)
        _GM.constraint_pipe_mass_flow(gm, i)
        _GM.constraint_pipe_weymouth(gm, i)
    end

    for i in _GM.ids(gm, :resistor)
        _GM.constraint_resistor_pressure(gm, i)
        _GM.constraint_resistor_mass_flow(gm,i)
        _GM.constraint_resistor_darcy_weisbach(gm,i)
    end

    for i in _GM.ids(gm, :loss_resistor)
        _GM.constraint_loss_resistor_pressure(gm, i)
        _GM.constraint_loss_resistor_mass_flow(gm, i)
    end

    for i in _GM.ids(gm, :short_pipe)
        _GM.constraint_short_pipe_pressure(gm, i)
        _GM.constraint_short_pipe_mass_flow(gm, i)
    end

    for i in _GM.ids(gm, :compressor)
        _GM.constraint_compressor_ratios(gm, i)
        _GM.constraint_compressor_mass_flow(gm, i)
        _GM.constraint_compressor_ratio_value(gm, i)
    end

    for i in keys(bounded_compressors)
        _GM.constraint_compressor_energy(gm, i)
    end

    for i in _GM.ids(gm, :valve)
        _GM.constraint_on_off_valve_mass_flow(gm, i)
        _GM.constraint_on_off_valve_pressure(gm, i)
    end

    for i in _GM.ids(gm, :regulator)
        _GM.constraint_on_off_regulator_mass_flow(gm, i)
        _GM.constraint_on_off_regulator_pressure(gm, i)
    end

    for (i, j) in _GM.ref(gm, :interconnections)
        constraint_interconnection_ss(gm, i, j)
    end

end
