```@meta
CurrentModule=RegionalGrasslandSim
```

# Functional response

The growth of the plants is limited by soil water and nutrients

## [Water stress](@id water_stress)

The species differ in the response to water stress by the different [specific leaf areas](@ref sla) and [root surface areas per above ground biomass](@ref srsa_water). The values of both response curves are multiplied to get the growth reduction factor.

It is implemented in [`Growth.water_reduction!`](@ref).

---
### [Specific leaf area](@id sla) 

- the core of the functional response is build in [`FunctionalResponse.sla_water_response`](@ref)
- the strength of the reduction is modified by the parameter `max_SLA_water_reduction` in [`Growth.sla_water_reduction!`](@ref)

`max_SLA_water_reduction` equals 1:
![Graphical overview of the functional response](../../img/sla_water_response.svg)

`max_SLA_water_reduction` equals 0.5:
![Graphical overview of the functional response](../../img/sla_water_response_0_5.svg)

```@docs
FunctionalResponse.sla_water_response
Growth.sla_water_reduction!
```

--- 
### [Root surface area / aboveground biomass](@id srsa_water)

- the core of the functional response is build in [`FunctionalResponse.srsa_response`](@ref)
- the strength of the reduction is modified by the parameter `max_SRSA_water_reduction` in [`Growth.srsa_water_reduction!`](@ref)

`max_SRSA_water_reduction` equals 1:
![Graphical overview of the functional response](../../img/srsa_water_response.svg)

`max_SRSA_water_reduction` equals 0.5:
![Graphical overview of the functional response](../../img/srsa_water_response_0_5.svg)

```@docs
FunctionalResponse.srsa_response
Growth.srsa_water_reduction!
```

## [Nutrient stress](@id nut_stress)

The species differ in the response to nutrient availability by different proportion of [mycorrhizal colonisations ](@ref amc) and [root surface per above ground biomass](@ref srsa_nut). The maximum of both response curves is used for the nutrient reduction function. It is assumed that the plants needs either many fine roots per above ground biomass or have a strong symbiosis with mycorrhizal fungi. 

It is implemented in [`Growth.nutrient_reduction!`](@ref).

---
### [Arbuscular mycorrhizal colonisation](@id amc)

- the core of the functional response is build in [`FunctionalResponse.amc_nut_response`](@ref)
- the strength of the reduction is modified by the parameter `max_AMC_nut_reduction` in [`Growth.amc_nut_reduction!`](@ref)

`max_AMC_nut_reduction` equals 1:
![Graphical overview of the AMC functional response](../../img/amc_nut_response.svg)

`max_AMC_nut_reduction` equals 0.5:
![Graphical overview of the AMC functional response](../../img/amc_nut_response_0_5.svg)

```@docs
FunctionalResponse.amc_nut_response
Growth.amc_nut_reduction!
```


---
### [Root surface area / aboveground biomass](@id srsa_nut)

- the core of the functional response is build in [`FunctionalResponse.srsa_response`](@ref)
- the strength of the reduction is modified by the parameter `max_SRSA_nut_reduction` in [`Growth.srsa_nut_reduction!`](@ref)

`max_SRSA_nut_reduction` equals 1:
![Graphical overview of the functional response](../../img/srsa_nut_response.svg)

`max_SRSA_nut_reduction` equals 0.5:
![Graphical overview of the functional response](../../img/srsa_nut_response_0_5.svg)


```@docs
Growth.srsa_nut_reduction!
```