using FUSE
using Test

# KDEMO init + ActorWholeFacility: every actor coupled together, in one round (it also compiles that chain for
# the tests that follow; a second "after compile" round only re-measured the runtime)
@testset "warmup" begin
    FUSE.TimerOutputs.@timeit FUSE.timer "warmup" begin
        dd = IMAS.dd()
        @test FUSE.warmup(dd) isa IMAS.DD
    end
end
