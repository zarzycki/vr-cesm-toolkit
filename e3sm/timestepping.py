### USER DEFINABLE
atm_ncpl = 480
dt_tracer_factor = 6
dt_remap_factor = 2
se_tstep = 7.5
rad_frequency = 5

### Calcs
DIVISIBLE_TOL = 1e-8  # Relative tolerance for "almost integer"
SECONDS_IN_DAY = 24 * 60 * 60
dtime = SECONDS_IN_DAY / atm_ncpl
dt_tracer = dt_tracer_factor * se_tstep
dt_remap = dt_remap_factor * se_tstep
dt_rad = dtime * rad_frequency
dt_max_factor = max(dt_remap_factor, dt_tracer_factor)

print(f"dt_max_factor: {dt_max_factor}")
print(f"se_tstep: {se_tstep} s")
print(f"dt_tracer: {dt_tracer} s")
print(f"dt_remap: {dt_remap} s")
print(f"dtime: {dtime} s -- {dtime/60:.2f} min")
print(f"dt_radiation: {dt_rad} s -- {dt_rad/60:.2f} min")

### ENFORCE CONSTRAINTS

# -----------------------------------------
# 1. dtime must divide evenly by se_tstep
# -----------------------------------------

nsplit_direct = dtime / se_tstep
if not nsplit_direct.is_integer():
    raise ValueError(f"Invalid config: dtime/se_tstep = {nsplit_direct:.4f} is not an integer. "
                     f"Ensure dtime ({dtime}) divides evenly by se_tstep ({se_tstep}).")

# -----------------------------------------
# 2. Compute nsplit from se_tstep and dt_max_factor
# This enforces that dtime is divisible by (dt_max_factor * se_tstep),
# i.e., that the time step hierarchy nests properly.
# -----------------------------------------

# Step size of the largest subcycle (e.g., tracer or remap step)
dt_max_step = dt_max_factor * se_tstep  # seconds
# Compute how many of those steps fit into the physics timestep (dtime)
nsplit_real = dtime / dt_max_step
# Round to nearest integer to get candidate nsplit
nsplit = round(nsplit_real)
# Total number of SE steps per dtime = dt_max_factor * nsplit
nstep_factor = dt_max_factor * nsplit

# Check if the real value of nsplit is close enough to an integer (within tolerance)
if abs(nsplit_real - nsplit) > DIVISIBLE_TOL * nsplit_real:
    raise ValueError(
        f"nsplit was computed as {nsplit_real:.6f} based on dtime = {dtime}, "
        f"se_tstep = {se_tstep}, and dt_max_factor = {dt_max_factor}, "
        f"which is outside the divisibility tolerance (tol = {DIVISIBLE_TOL}).\n"
        f"Set se_tstep, dt_remap_factor, and dt_tracer_factor so that both:\n"
        f"  - se_tstep divides dtime, and\n"
        f"  - dt_max_factor * se_tstep divides dtime."
    )

# -----------------------------------------
# 3. Either dt_remap_factor divides dt_tracer_factor or vice versa
# -----------------------------------------

if dt_remap_factor > 0:
    if dt_tracer_factor % dt_remap_factor != 0 and dt_remap_factor % dt_tracer_factor != 0:
        raise ValueError("Invalid config: neither dt_remap_factor nor dt_tracer_factor divides the other. "
                         f"Got dt_remap_factor = {dt_remap_factor}, dt_tracer_factor = {dt_tracer_factor}.")
