using FUSE
using Test

# Plots and PAM are weak dependencies (ext/FUSEPlotsExt.jl, ext/PAMExt.jl), so worker processes never load them.
# This test process may already have Plots loaded, so "FUSE alone" is checked in a fresh Julia process.
@testset "optional dependencies" begin
    code = """
        using FUSE
        loaded(name) = any(k.name == name for k in keys(Base.loaded_modules))
        println("loaded: Plots=", loaded("Plots"), " GR=", loaded("GR"), " PAM=", loaded("PAM"))
        println("extensions: FUSEPlotsExt=", Base.get_extension(FUSE, :FUSEPlotsExt) !== nothing,
            " IMASPlotsExt=", Base.get_extension(IMAS, :IMASPlotsExt) !== nothing, " PAMExt=", Base.get_extension(FUSE, :PAMExt) !== nothing)
        error_of(f) = try f(); "no error" catch e; sprint(showerror, e) end
        dd = IMAS.dd()
        act = FUSE.ParametersActors()
        println("ActorPAM => ", error_of(() -> FUSE.ActorPAM(dd, act)))
        act.ActorPowerNeeds.do_plot = true
        println("do_plot => ", error_of(() -> FUSE.step(FUSE.ActorPowerNeeds(dd, act.ActorPowerNeeds))))
        println("scatter! => ", error_of(() -> FUSE.scatter!([1.0], [1.0])))
        println("plot => ", error_of(() -> FUSE.plot(dd.equilibrium)))
        """
    out = read(`$(Base.julia_cmd()) --project=$(Base.active_project()) --startup-file=no -e $code`, String)
    @test occursin("loaded: Plots=false GR=false PAM=false", out)
    @test occursin("extensions: FUSEPlotsExt=false IMASPlotsExt=false PAMExt=false", out)
    @test occursin("ActorPAM => The FUSE actor ActorPAM cannot be run because the Julia package PAM.jl is not loaded", out)
    @test occursin("@everywhere using PAM", out)
    @test occursin("do_plot => FUSE plotting needs Plots.jl", out) # step() stops before running the actor
    @test occursin("scatter! => FUSE plotting needs Plots.jl", out)
    @test occursin("run `using Plots` first", out) # IMAS error hint on the RecipesBase plot stub
end

ENV["GKSwstype"] = "nul" # headless GR
using Plots

@testset "plotting with Plots loaded" begin
    @test Base.get_extension(FUSE, :FUSEPlotsExt) !== nothing
    @test Base.get_extension(IMAS, :IMASPlotsExt) !== nothing
    @test FUSE.plots_module() === Plots

    ini, act = FUSE.case_parameters(:KDEMO)
    dd = IMAS.dd()
    FUSE.init(dd, ini, act)
    @testset "$name" for (name, f) in (
        ("build", () -> plot(dd.build)),
        ("build cx", () -> plot(dd.build; cx=true)),
        ("equilibrium", () -> plot(dd.equilibrium)),
        ("core_profiles", () -> plot(dd.core_profiles)),
        ("core_sources", () -> plot(dd.core_sources)),
        ("pf_active", () -> plot(dd.pf_active)),
        ("ini (FUSE recipe)", () -> plot(ini)))
        @test f() isa Plots.Plot
    end

    # do_plot code calls Plots-only functions (scatter!) through FUSE's forwarders
    act.ActorHFSsizing.do_plot = true
    @test FUSE.ActorHFSsizing(dd, act) isa FUSE.ActorHFSsizing
end
