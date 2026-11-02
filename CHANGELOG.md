# FUSE_Design changelog

FUSE_Design is the design-study line of [FUSE](https://github.com/ProjectTorreyPines/FUSE.jl): steady-state
power-plant design and constrained multi-objective optimization (CMOOP), not time-dependent scenarios.

Versions are `<upstream FUSE version at the split>+design.<n>`: `1.1.5+design.2` is the second design release on top
of upstream v1.1.5. They satisfy the same compat bounds as the upstream version (`"1"`, `"1.1"`, `"~1.1.5"`) and never
clash with upstream release numbers. When upstream is merged in again, the base moves (e.g. `1.3.0+design.1`).
Releases are git tags `v<version>`. The rest of the stack (IMAS_Design, FRESCO, TJLFEP, TroyonBetaNN) follows the same
scheme; the FuseRegistry fork at github.com/TimSlendebroek/FuseRegistry.jl points every stack package at these forks.

## 1.1.5+design.2 (2026-11-02, branch `lean-deps`)

Worker processes no longer load plotting or the pellet solver: `using FUSE` takes ~10 s and ~1.5 GB instead of ~20 s
and ~2.2 GB, and pulls in ~200 fewer packages.

- Plots.jl is a weak dependency (`ext/FUSEPlotsExt.jl`). Recipes and `do_plot` code use the RecipesBase `plot`/`plot!`
  stubs; the few Plots-only functions FUSE calls are forwarded once Plots is loaded. `using Plots` brings everything
  back, e.g. `plot(dd.core_sources)`. An actor with `do_plot=true` stops with a message saying so if Plots is missing.
- PAM.jl is a weak dependency (`ext/PAMExt.jl`): `ActorPAM` needs `using PAM` (`@everywhere using PAM` on workers); the
  error says how to add it.
- Diagnostic plots drawn in actor error paths (TEQUILA, equilibrium flux surfaces, cross-section build, HFS sizing,
  CHEASE) and Mars' boundary plots only run when Plots is loaded, so without Plots the real error is rethrown instead
  of "needs Plots.jl". `FUSE.plots_loaded()` tells whether Plots is loaded.
- SnoopPrecompile dependency dropped (unused).
- Tests: fresh-process check that FUSE loads without Plots/PAM, plotting checks after `using Plots`, a static check
  that actor catch blocks never plot unguarded, PAM tests under `FUSE_WITH_EXTENSIONS`; one warmup round instead of
  two; the time-dependent ITER case is opt-in (`FUSE_TEST_TIME_DEPENDENT=true`); BLAS single-threaded in tests.
- CI: FuseRegistry from the TimSlendebroek fork with ProjectTorreyPines made unreachable, so no dependency on it can
  creep back; companion forks are dev'd at the branch matching the FUSE branch; the stack is precompiled once.

## 1.1.5+design.1 (2026-10-19, tag on `cmoop-fixes` 2705b832)

The stack of the October 2026 NERSC CMOOP studies. Everything the design line carries on top of upstream v1.1.5
(merged 2026-07-21):

- Pedestal: EPED-NN deep ensemble with uncertainty in `ActorEPED` (default `:variable_nesep_ratio`), `rot_ped`
  parameter, EPED extrapolation detection, `density_match = :fixed`, fixed density for the WPED option, updated
  `pedestal_poloidal_βn_scaling_from_βn`.
- Rotation: sonic rotation as primary input, ion toroidal rotation derived explicitly; better `tglf_folder` saving and
  rotation for the ITER init.
- Studies: `DatabaseGenerator` with lazy generators (memory), pmap on the main process, error logging,
  `extract_ini`/`extract_act` and failed-run handling; HDB5 validation as a study; CMOOP templates (PT, NT, QCE,
  L-mode) with the `alpha_t` constraint; per-process study files tagged with host and pid (multi-node runs);
  `mkpath` against directory races.
- CMOOP fixes from the fusebox workshop: quadratic interpolation of the SPEA2 settings (cubic needs 4 points),
  `ini.general.dd` not serialized into `ini.h5`, `ini.ec_launcher[].rho_0` so the EC deposition location can be a gene.
- `tungsten_density` in `ini.core_profiles` for trace W impurity.
- Repository: knowledge base, fusebot, docs and make-based workflows removed (canonical docs live upstream); CI on
  public dependencies only.

## Earlier

- `0.5.11+design.1` (tag on e3eb02f0, 2025-04-08): upstream v0.5.11 with a committed Manifest and GACODE added to the
  TGLF actor — the version frozen to finish the MOOP paper (Slendebroek et al., Nucl. Fusion 66 026032, 2026). Identified
  from the git history in 2026-11; the exact commit of the paper runs was not recorded.
- 2026-02: upstream v0.10.0 merged into the design line (`master` until 2026-11).
