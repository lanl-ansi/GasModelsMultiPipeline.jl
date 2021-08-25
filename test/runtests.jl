using GasModelsMultiPipeline

using JuMP
using Ipopt

import GasModels
import GasModels: make_si_units!, WPGasModel

import MathOptInterface: TerminationStatusCode
export TerminationStatusCode

import MathOptInterface: ResultStatusCode
export ResultStatusCode

const MathOptInterface = MOI

GasModels.Memento.setlevel!(GasModels.Memento.getlogger(GasModels), "error")
GasModels.Memento.setlevel!(GasModels.Memento.getlogger(GasModels._IM), "error")

ipopt_solver = JuMP.optimizer_with_attributes(
    Ipopt.Optimizer,
    "print_level" => 0,
    "sb" => "yes",
    "max_iter" => 50000,
    "acceptable_tol" => 1.0e-8,
)

using Test

nlp_solver = ipopt_solver

@testset "GasModelsMultiPipeline Tests" begin
    include("basic.jl")
end
