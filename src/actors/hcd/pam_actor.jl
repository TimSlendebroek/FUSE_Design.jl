#= ======== =#
#  ActorPAM  #
#= ======== =#
Base.@kwdef mutable struct FUSEparameters__ActorPAM{T<:Real} <: ParametersActor{T}
    _parent::WeakRef = WeakRef(nothing)
    _name::Symbol = :not_set
    _time::Float64 = NaN
    drift_model::Switch{Symbol} = Switch{Symbol}([:HPI2, :Parks, :none], "-", "drift model"; default=:Parks)
    time_from::Switch{Symbol} = Switch{Symbol}([:pulse_schedule, :pellet_time, :none], "-", "initialize time for the pellet calculations"; default=:none)
    time_step::Entry{Float64} = Entry{Float64}("-", "Time step [s]"; default=0.00001)
    time_end::Entry{Float64} = Entry{Float64}("-", "Time end [s]"; default=0.0008)
    Bt_dependance::Entry{Bool} = Entry{Bool}("-", "Enable Bt dependance"; default=true)
    density_update::Entry{Bool} = Entry{Bool}("-", "Update plasma density"; default=false)
end

abstract type AbstractActorPellet{D,P} <: SingleAbstractActor{D,P} end

"""
    ActorPAM(dd::IMAS.DD, act::ParametersAllActors; kw...)

Estimates the Pellet particle direction, ablation rate, density source deposition

!!! note

    Reads data in `pellet`, `pulse_schedule`, `equilibrium`, and stores data in `pellet`

!!! note

    Needs `using PAM` (and `@everywhere using PAM` on Distributed workers). PAM is a weak dependency of FUSE
    because it pulls in ~400 MB of ODE/BVP solver code that every process would otherwise load.
    The actor itself lives in `ext/PAMExt.jl` (`src/actors/hcd/pam_actor_ext.jl`).
"""
function ActorPAM(args...; kw...)
    ext = Base.get_extension(@__MODULE__, :PAMExt)
    if ext === nothing
        throw(MissingExtensionError("ActorPAM", "PAM"))
    end
    return Base.invokelatest(ext.ActorPAM, args...; kw...)
end
