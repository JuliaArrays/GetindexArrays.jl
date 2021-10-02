using GetindexArrays
using Documenter

DocMeta.setdocmeta!(GetindexArrays, :DocTestSetup, :(using GetindexArrays); recursive=true)

makedocs(;
    modules=[GetindexArrays],
    authors="Tim Holy <tim.holy@gmail.com> and contributors",
    repo="https://github.com/JuliaArrays/GetindexArrays.jl/blob/{commit}{path}#{line}",
    sitename="GetindexArrays.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaArrays.github.io/GetindexArrays.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaArrays/GetindexArrays.jl",
    devbranch="main",
)
