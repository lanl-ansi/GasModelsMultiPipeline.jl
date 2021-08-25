# data
static_file_1 = "./data/case-6-1.m"
static_file_2 = "./data/case-6-2.m"

transient_file_1 = "./data/time-series-case-6b.csv"
transient_file_2 = "./data/time-series-case-6b.csv"

connection_file = "./data/connections.csv"

files = [(static_file_1, transient_file_1), (static_file_2, transient_file_2)]

# read data
data, p_ids, info = parse_files(files, connection_file)

# solve
result = run_transient_multi_ogf(data, GasModels.WPGasModel, nlp_solver)
make_si_units!(result["solution"])

# test
@testset "general transient tests" begin
    @test get_new_id(info, :junction, 1, 2) == 2
    @test get_new_id(info, :junction, 2, 1) == 7
    @test isapprox(result["solution"]["nw"]["1"]["junction"]["2"]["pressure"], result["solution"]["nw"]["7"]["junction"]["2"]["pressure"]; atol = 1e-3)
    @test result["termination_status"] == MOI.LOCALLY_SOLVED || result["termination_status"] == MOI.OPTIMAL
    transfer_id_1 = string(get_new_id(info, :transfer, 1, 1))
    transfer_id_2 = string(get_new_id(info, :transfer, 2, 6))
    @test isapprox(result["solution"]["nw"]["1"]["transfer"][transfer_id_1]["withdrawal"], result["solution"]["nw"]["1"]["transfer"][transfer_id_2]["injection"]; atol = 1e-3)
end

# steady state runs
files = [static_file_1, static_file_2]

# read data
data, p_ids, info = parse_files(files, connection_file)

result = run_multi_ogf(data, WPGasModel, nlp_solver)
make_si_units!(result["solution"])

@testset "general steady state tests" begin
    @test get_new_id(info, :junction, 1, 2) == 2
    @test get_new_id(info, :junction, 2, 1) == 7
    @test result["termination_status"] == MOI.LOCALLY_SOLVED || result["termination_status"] == MOI.OPTIMAL
    transfer_id_1 = string(get_new_id(info, :transfer, 1, 1))
    transfer_id_2 = string(get_new_id(info, :transfer, 2, 6))
    @test isapprox(result["solution"]["transfer"][transfer_id_1]["ft"], -1.0 * result["solution"]["transfer"][transfer_id_2]["ft"]; atol = 1e-3)
end
