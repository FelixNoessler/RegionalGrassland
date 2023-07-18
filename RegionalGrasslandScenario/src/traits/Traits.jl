module Traits

using Unitful
using Distributions
using DataFrames
using JLD2
using LinearAlgebra

function inverse_logit(x)
    return exp(x)/(1+exp(x))
end

function random_traits(n; datapath, back_transform=true)
    μ, Σ, ϕ = load("$datapath/input/traits_gaussian_mixture.jld2", "μ", "Σ", "ϕ")

    m = MixtureModel([
        MvNormal(μ[1, :], Hermitian(Σ[1, :, :])),
        MvNormal(μ[2, :], Hermitian(Σ[2, :, :]))],
        ϕ
    )

    log_logit_traits = rand(m, n)

    if back_transform
        transformations = [
            exp, exp, exp, exp, exp,
            inverse_logit,
            exp, exp, exp,
        ]

        units = [
            u"mm^2", u"mg", u"mg",          # leaf traits
            NoUnits, u"m^2/g", NoUnits,     # root traits,
            u"m",              # LEDA
            u"g/g", u"mg/g" # TRY
        ]

        traits = Array{Quantity{Float64}}(
            undef,
            n,
            length(transformations)
        )
        traitdf_names = [
            "LA_log", "LFM_log", "LDM_log",
            "BA_log", "SRSA_log", "AMC_logit",
            "CH_log",
            "LDMPM_log", "LNCM_log"
        ]
        trait_names = first.(split.(traitdf_names, "_"))

        for (i,t) in enumerate(transformations)
            trait = t.(log_logit_traits[i, :])
            unit_vector = repeat([units[i]], n)
            traits[:, i] .= trait .* unit_vector
        end

        trait_df = DataFrame(traits, trait_names)
        trait_df.SLA = trait_df.LA ./ trait_df.LDM
        trait_df.SLA = uconvert.(u"m^2/g", trait_df.SLA)

        trait_df.SRSA_above = trait_df.SRSA .* trait_df.BA

        return trait_df
    else
        return log_logit_traits
    end
end

function relative_traits(; trait_data, datapath)
    trait_data = ustrip.(trait_data)
    nspecies, ntraits = size(trait_data)

    #### calculate extrema from more data
    many_traits = random_traits(100; datapath)
    many_traits = Matrix(ustrip.(many_traits))

    for i in 1:ntraits
        mint, maxt = quantile(many_traits[:, i], [0.05, 0.95])
        trait_data[:, i] .= (trait_data[:, i] .- mint) ./ (maxt - mint)
    end

    [trait_data[trait_data[:, i] .< 0, i] .= 0.0  for i in 1:ntraits]
    [trait_data[trait_data[:, i] .> 1, i] .= 1.0  for i in 1:ntraits]

    return trait_data
end


end
