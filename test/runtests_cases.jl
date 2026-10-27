using FUSE
using Test

# Time-dependent cases are slow (ITER_time alone took ~3.5 of the ~8 minutes of this file) and not part of the
# design workflow: they only run with FUSE_TEST_TIME_DEPENDENT=true
const TIME_DEPENDENT_TEST_CASES = (:ITER_time,)
const RUN_TIME_DEPENDENT = get(ENV, "FUSE_TEST_TIME_DEPENDENT", "false") == "true"

@testset "test_cases" begin
    for testname in FUSE.available_test_cases()
        @testset "$(testname)" begin
            if testname in TIME_DEPENDENT_TEST_CASES && !RUN_TIME_DEPENDENT
                @test_skip "time-dependent case (set FUSE_TEST_TIME_DEPENDENT=true to run it)"
            else
                FUSE.TimerOutputs.reset_timer!(FUSE.timer, string(testname))
                FUSE.TimerOutputs.@timeit FUSE.timer string(testname) begin
                    println("== $(testname) ==")
                    dd = IMAS.dd()
                    FUSE.test_case(testname, dd)
                end
            end
        end
    end
end
