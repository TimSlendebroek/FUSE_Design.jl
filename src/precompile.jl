"""
    warmup(dd::IMAS.DD)

Function used to precompile the majority of FUSE
"""
function warmup(dd::IMAS.DD)
    empty!(dd)

    ini, act = case_parameters(:KDEMO)

    ini_act_tests_customizations!(ini, act)

    init(dd, ini, act)

    ActorWholeFacility(dd, act)

    TimerOutputs.@timeit timer "freeze" begin
        frozen_dd = IMAS.freeze(dd)
    end

    return frozen_dd
end

# Compile the KDEMO init + ActorWholeFacility chain (what studies run, and what most tests exercise) into FUSE's
# package image: processes start without JIT-compiling it, and processes on one node share the compiled code.
# Every FUSE source change re-runs this during precompilation. To skip it while editing FUSE:
#     using Preferences, UUIDs
#     set_preferences!(UUID("e64856f0-3bb8-4376-b4b7-c03396503992"), "precompile_workload" => false; force=true)
# (delete the LocalPreferences.toml entry, or set it to true, to turn it back on)
PrecompileTools.@compile_workload begin
    Logging.with_logger(Logging.NullLogger()) do
        redirect_stdout(devnull) do
            warmup(IMAS.dd())
        end
    end
    # keep the workload's timings, memory trace and loaded models out of the package image
    TimerOutputs.reset_timer!(timer)
    empty!(memtrace.data)
    empty!(_PEDESTAL_NN_CACHE)
end
