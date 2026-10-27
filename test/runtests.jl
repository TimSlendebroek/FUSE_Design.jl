using FUSE

# Check if specific test files are requested via ARGS
if !isempty(ARGS)
    for testfile in ARGS
        @info "Running test file: $testfile"
        include(testfile)
    end
else
    # Default behavior: run all tests

    # one BLAS thread, as on study workers: FUSE's matrices are small, and extra BLAS threads only spin
    # (measured on a whole-facility run: same wall time, ~2.5x the CPU)
    FUSE.LinearAlgebra.BLAS.set_num_threads(1)

    # Conditionally run extension tests if environment variable is set.
    if get(ENV, "FUSE_WITH_EXTENSIONS", "false") == "true"
        using Pkg
        Pkg.add(["ThermalSystemModels", "PAM"])
        using ThermalSystemModels
        using PAM
    end

    include("runtests_warmup.jl")

    include("runtests_basics.jl")

    include("runtests_cases.jl")

    include("runtests_actors.jl")

    include("runtests_optional_deps.jl")

    include("runtests_init_expressions.jl")

    # Conditionally run extension tests if environment variable is set.
    if get(ENV, "FUSE_WITH_EXTENSIONS", "false") == "true"
        include("runtests_study.jl")
        include("runtests_pam.jl")
    end

    include("runtests_study_database.jl")
    
    println(FUSE.timer)
end
