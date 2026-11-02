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
        println("plots_loaded: FUSE=", FUSE.plots_loaded(), " IMAS=", IMAS.plots_loaded())
        """
    out = read(`$(Base.julia_cmd()) --project=$(Base.active_project()) --startup-file=no -e $code`, String)
    @test occursin("loaded: Plots=false GR=false PAM=false", out)
    @test occursin("extensions: FUSEPlotsExt=false IMASPlotsExt=false PAMExt=false", out)
    @test occursin("ActorPAM => The FUSE actor ActorPAM cannot be run because the Julia package PAM.jl is not loaded", out)
    @test occursin("@everywhere using PAM", out)
    @test occursin("do_plot => FUSE plotting needs Plots.jl", out) # step() stops before running the actor
    @test occursin("scatter! => FUSE plotting needs Plots.jl", out)
    @test occursin("run `using Plots` first", out) # IMAS error hint on the RecipesBase plot stub
    @test occursin("plots_loaded: FUSE=false IMAS=false", out)
end

# Actors draw diagnostic plots in some catch blocks before rethrowing. Without Plots (workers) such a plot would
# replace the real error with "needs Plots.jl" in the study's failures, so each one must be guarded by plots_loaded()
# (or do_plot/verbose, which the user asks for). Static check: no catch block in src/actors calls a plotting function
# unless an `if` on such a guard encloses the call or the catch itself; `guard && ...` covers only its own line.
const PLOTCALL = r"(^|[^.\w])(plot!?|contour!?|scatter!?|heatmap|current)\("
const GUARD_IF = r"^\s*(if|elseif)\b.*(plots_loaded\(\)|do_plot|verbose)"
const GUARD_AND = r"(plots_loaded\(\)|do_plot|verbose)\s*&&"
indentation(l) = length(l) - length(lstrip(l))
function inside_guard(lines, i)
    ind = indentation(lines[i])
    for k in i-1:-1:1
        l = lines[k]
        isempty(strip(l)) && continue
        indentation(l) < ind || continue
        occursin(GUARD_IF, l) && return true
        occursin(r"^\s*function\b", l) && return false
        ind = indentation(l)
    end
    return false
end
@testset "actor error paths do not need Plots" begin
    offenders = String[]
    for (root, _, files) in walkdir(joinpath(pkgdir(FUSE), "src", "actors")), f in files
        endswith(f, ".jl") || continue
        lines = readlines(joinpath(root, f))
        for (i, l) in enumerate(lines)
            occursin(r"^\s*catch\b", l) || continue
            inside_guard(lines, i) && continue
            for j in i+1:min(i + 40, length(lines))
                lj = lines[j]
                isempty(strip(lj)) && continue
                indentation(lj) <= indentation(l) && break # end of the catch block
                occursin(GUARD_IF, lj) && break
                occursin(GUARD_AND, lj) && continue
                occursin(PLOTCALL, lj) && (push!(offenders, "$f:$j"); break)
            end
        end
    end
    @test isempty(offenders)
end

ENV["GKSwstype"] = "nul" # headless GR
using Plots

@testset "plotting with Plots loaded" begin
    @test Base.get_extension(FUSE, :FUSEPlotsExt) !== nothing
    @test Base.get_extension(IMAS, :IMASPlotsExt) !== nothing
    @test FUSE.plots_module() === Plots
    @test FUSE.plots_loaded() && IMAS.plots_loaded()

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
