#= ======== =#
#  PLOTTING  #
#= ======== =#
# Plots.jl is a weak dependency of FUSE (ext/FUSEPlotsExt.jl), so worker processes never load it.
# Recipes and do_plot code call the RecipesBase plot/plot! stubs, which Plots implements once it is loaded;
# the few Plots-only functions that FUSE uses are forwarded to Plots below.

"""
    plots_module()

Returns the Plots module, or throws an error saying that plotting needs `using Plots`
"""
function plots_module()
    ext = Base.get_extension(@__MODULE__, :FUSEPlotsExt)
    if ext === nothing
        error("FUSE plotting needs Plots.jl, which FUSE does not load by default (keeps worker processes small). Run `using Plots` first.")
    end
    return ext.Plots
end

for f in (:scatter, :scatter!, :vline!, :hline!, :vspan!, :contour, :contour!, :heatmap, :histogram, :pie, :twinx, :current, :savefig, :gif, :cgrad)
    @eval $f(args...; kw...) = Base.invokelatest(getfield(plots_module(), $(QuoteNode(f))), args...; kw...)
end

_has_do_plot(::OverrideParameters{P,T}) where {P,T} = hasfield(T, :do_plot)
_has_do_plot(par::ParametersActor) = hasfield(typeof(par), :do_plot)
_has_do_plot(::Any) = false
