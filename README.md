# GasModelsMultiPipeline.jl

The latest stable release of GasModels is installed using the Julia package manager with

```julia
]add https://github.com/lanl-ansi/GasModelsMultiPipeline.jl
```

Once installed, the multi pipeline optimal gas flow can be run as follows:

```julia
using GasModelsMultiPipeline

using JuMP
using Ipopt
using GasModels

nlp_solver = optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-3, "print_level" => 3)

static_file_1 = "test/data/case-6-1.m"
static_file_2 = "test/data/case-6-2.m"

transient_file_1 = "test/data/time-series-case-6b.csv"
transient_file_2 = "test/data/time-series-case-6b.csv"

connection_file = "test/data/connections.csv"

files = [(static_file_1, transient_file_1), (static_file_2, transient_file_2)]

# read data
data, p_ids, info = parse_files(files, connection_file)

# solve
result = run_transient_multi_ogf(data, WPGasModel, knitro_solver)
make_si_units!(result["solution"])
```
