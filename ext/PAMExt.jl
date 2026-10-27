module PAMExt

# import FUSE namespace (ActorPAM is defined here as the actor type; FUSE.ActorPAM is the entry point that forwards to it)
import FUSE
for n in names(FUSE; all=true)
    if Base.isidentifier(n) && n ∉ (Symbol(FUSE), :eval, :include, :ActorPAM)
        @eval import FUSE: $n
    end
end

include(joinpath("..", "src", "actors", "hcd", "pam_actor_ext.jl"))

end
