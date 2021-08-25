module GasModelsMultiPipeline
    import Base
    import InfrastructureModels
    using GasModels
    using JuMP

    const _IM = InfrastructureModels
    const _GM = GasModels

    include("io/typedefs.jl")

    include("core/data.jl")

    include("io/multi_transient.jl")
    include("io/multi_ss.jl")

    include("core/multi_constraint.jl")
    include("core/multi_constraint_template.jl")

    include("prob/multi_transient.jl")
    include("prob/multi_ss.jl")

    include("core/export.jl")
end
