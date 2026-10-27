using FUSE
using PAM
using Test

@testset "ActorPAM (PAMExt)" begin
    @test Base.get_extension(FUSE, :PAMExt) !== nothing
    ini, act = FUSE.case_parameters(:ITER; init_from=:scalars) # ITER has a pellet launcher
    dd = IMAS.dd()
    FUSE.init(dd, ini, act)
    act.ActorSources.pellet_model = :PAM
    actor = FUSE.ActorSources(dd, act)
    @test actor.pellet_actor isa FUSE.AbstractActorPellet
    pellet = [s for s in dd.core_sources.source if s.identifier.name == "pellet" || occursin("pellet", lowercase(s.identifier.name))]
    @test length(pellet) == 1
    particles = pellet[1].profiles_1d[].electrons.particles
    @test all(isfinite, particles)
    @test maximum(particles) > 0.0
end
