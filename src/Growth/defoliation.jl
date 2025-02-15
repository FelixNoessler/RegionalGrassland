@doc raw"""
    mowing!(;
        calc,
        mowing_height,
        days_since_last_mowing,
        height,
        biomass,
        mowing_mid_days)

```math
\begin{align}
    \lambda &= \frac{\text{mown_height}}{\text{height}}\\
    \text{mow_factor} &= \frac{1}{1+exp(-0.1*(\text{days_since_last_mowing}
        - \text{mowing_mid_days})}\\
    \text{mow} &= \lambda \cdot \text{biomass}
\end{align}
```

The mow_factor has been included to account for the fact that less biomass is mown
when the last mowing event was not long ago.
Influence of mowing for plant species with different heights ($height$):
![Image of mowing effect](../../img/mowing.svg)

Visualisation of the `mow_factor`:
![](../../img/mow_factor.svg)
"""
function mowing!(;
    calc,
    mowing_height,
    days_since_last_mowing,
    height,
    biomass,
    mowing_mid_days)

    # --------- mowing parameter λ
    calc.mown_height .= height .- mowing_height
    calc.mown_height .= max.(calc.mown_height, 0.01u"m")
    calc.mowing_λ .= calc.mown_height ./ height

    # --------- if meadow is too often mown, less biomass is removed
    ## the 'mowing_mid_days' is the day where the plants are grown
    ## back to their normal size/2
    mow_factor = 1 / (1 + exp(-0.05 * (days_since_last_mowing - mowing_mid_days)))

    # --------- add the removed biomass to the defoliation vector
    calc.defoliation .+= mow_factor .* calc.mowing_λ .* biomass .* u"d^-1"

    return nothing
end


@doc raw"""
    grazing_parameter(; LNCM, leafnitrogen_graz_exp)

Initialize the grazing parameter ρ.

```math
\rho =  \left(\frac{LNCM}{\overline{LNCM}}\right) ^ {\text{leafnitrogen_graz_exp}}
```

- `LNCM` leaf nitrogen per leaf mass
- `leafnitrogen_graz_exp` exponent of the leaf nitrogen per leaf mass
  in the grazing parameter
- `ρ` appetence of the plant species for livestock,
  dependent on nitrogen per leaf mass (LNCM) [dimensionless]

The function is excetued once at the start of the simulation.
The grazing parameter ρ is used in the function [`Growth.grazing!`](@ref).
"""
function grazing_parameter(; LNCM, leafnitrogen_graz_exp)
    return (LNCM ./ mean(LNCM)) .^ leafnitrogen_graz_exp
end

@doc raw"""
    grazing!(; calc, LD, biomass, relbiomass, ρ, grazing_half_factor)

```math
\begin{align}
μₘₐₓ &= κ \cdot \text{LD} \\
h &= \frac{1}{μₘₐₓ} \\
a &= \frac{1}{\text{grazing_half_factor}^2 \cdot h} \\
\text{totgraz} &= \frac{a \cdot (\sum \text{relbiomass}⋅\text{biomass})^2}
                    {1 + a\cdot h\cdot (\sum \text{relbiomass}⋅\text{biomass})^2} \\
\text{share} &= \frac{
    \rho \cdot \text{biomass}}
    {\sum \left[ \rho \cdot \text{biomass} \right]} \\
\text{graz} &= \text{share} \cdot \text{totgraz}
\end{align}
```

It is thought that animals consume more in areas with greater biomass,
resulting in greater trampling damage (see parameter `relbiomass`).

- `LD` daily livestock density [livestock units ha⁻¹]
- `κ` daily consumption of one livestock unit [kg d⁻¹], follows [Gillet2008](@cite)
- `ρ` appetence of the plant species for livestock,
  dependent on nitrogen per leaf mass (LNCM) [dimensionless],
  initiliazed by the function [`Growth.grazing_parameter`](@ref)
- `relbiomass`: relative biomass of the patch in relation to the mean
  biomass of the whole grassland,
  is calculated by [`Growth.calculate_relbiomass!`](@ref) [-]
- `grazing_half_factor` is the half-saturation constant [kg ha⁻¹]
- equation partly based on [Moulin2021](@cite)

Influence of grazing (livestock density = 2), all plant species have
an equal amount of biomass (total biomass / 3)
and a leaf nitrogen content of 15, 30 and 40 mg/g:

- `leafnitrogen_graz_exp` = 1.5
![](../../img/grazing_1_5.svg)

- `leafnitrogen_graz_exp` = 5
![](../../img/grazing_5.svg)

Influence of `grazing_half_factor`:
![](../../img/grazing_half_factor.svg)
"""
function grazing!(; calc, LD, biomass, relbiomass, ρ, grazing_half_factor)
    κ = 22u"kg / d"
    k_exp = 2
    μₘₐₓ = κ * LD
    h = 1 / μₘₐₓ
    a = 1 / (grazing_half_factor^k_exp * h)

    ## Exponentiation of Quantity with a variable is type unstable
    ## therefore this is a workaround, k_exp = 2
    # https://painterqubits.github.io/Unitful.jl/stable/trouble/#Exponentiation
    biomass_exp = relbiomass * sum(biomass)^2

    total_grazed_biomass = a * biomass_exp / (1u"kg / ha"^k_exp + a * h * biomass_exp)
    @. calc.biomass_ρ = ρ * biomass
    calc.grazed_share .= calc.biomass_ρ ./ sum(calc.biomass_ρ)

    #### add grazed biomass to defoliation
    @. calc.defoliation += calc.grazed_share * total_grazed_biomass

    return nothing
end



"""
    trampling_parameter(; trampling_factor)

Intialize the trampling factor.

To avoid a very small trampling factor for paramter inference,
the trampling factor is divided by 10000 and
the unit [ha m⁻¹] is added.

The `trampling_factor` is used in the function [`Growth.trampling!`](@ref).
"""
function trampling_parameter(; trampling_factor)
    return trampling_factor * u"ha / m" / 10000
end

@doc raw"""
    trampling!(; calc, LD, biomass, relbiomass, height, trampling_factor)

```math
\begin{align}
\text{trampled_proportion} &=
    \text{height} \cdot \text{LD} \cdot \text{trampling_factor}  \\
\text{trampled_biomass} &=
    \min(\text{relbiomass} ⋅ \text{biomass} ⋅ \text{trampled_proportion},
        \text{biomass}) \\
\end{align}
```

It is assumed that tall plants (trait: `height`) are stronger affected by trampling.
A linear function is used to model the influence of trampling.

It is thought that animals consume more in areas with greater biomass,
resulting in greater trampling damage (see parameter `relbiomass`).

Maximal the whole biomass of a plant species is removed by trampling.

- `biomass` [$\frac{kg}{ha}$]
- `relbiomass`: relative biomass of the patch in relation to the mean
  biomass of the whole grassland,
  is calculated by [`Growth.calculate_relbiomass!`](@ref) [-]
- `LD` daily livestock density [$\frac{\text{livestock units}}{ha}$]
- `trampling_factor` [$ha$], this parameter is initiliazed with the function
  [`Growth.trampling_parameter`](@ref)
- height canopy height [$m$]

![Image of trampling effect](../../img/trampling.svg)
"""
function trampling!(; calc, LD, biomass, relbiomass, height, trampling_factor)
    @. calc.trampling_proportion = height * LD * trampling_factor

    @. calc.trampled_biomass = relbiomass * biomass * calc.trampling_proportion
    @. calc.trampled_biomass .= min.(calc.trampled_biomass, biomass)

    calc.defoliation .+= calc.trampled_biomass ./ u"d"
    return nothing
end


@doc raw"""
    calculate_relbiomass!(; calc, p)

Relative biomass of the patches in relation to the mean biomass of the overall grassland.

```math
\text{relbiomass} = \frac{\text{patch_biomass}}{\text{mpatch_biomass}}
```

- `relbiomass` relative biomass of each patch [-]
- `patch_biomass` sum of the biomass of all species in one patch [kg ha⁻¹]
- `mpatch_biomass` mean of the sum of the biomass of all species in all patches [kg ha⁻¹]
"""
function calculate_relbiomass!(; calc, p)
    for pa in Base.OneTo(p.npatches)
        calc.biomass_per_patch[pa] = mean(@view calc.u_biomass[pa, :])
    end
    calc.relbiomass .= calc.biomass_per_patch ./ mean(calc.biomass_per_patch)

    return nothing
end
