using GetindexArrays
using CoordinateTransformations, Rotations, StaticArrays
using OffsetArrays
using AxisArrays: AxisArrays, AxisArray
using ImageCore, ImageAxes
using Test

if Base.VERSION < v"1.1"
    using Compat   # oneunit(::CartesianIndex)
end

@testset "GetindexArrays.jl" begin
    # A purely computational array
    A = GetindexArray((Base.OneTo(5), Base.OneTo(7))) do _, (y, x)
        asin((x-1)^2/72 + (y-1)^2/32)
    end
    @test @inferred(A[1, 1]) == 0
    @test @inferred(A[5, 7]) ≈ π/2
    @test_throws BoundsError A[0, 1]
    @test_throws BoundsError A[6, 1]

    P = [1 2; 3 4]
    @test P[1, 1] == 1
    @test P[1, 2] == 2
    @test P[2, 1] == 3
    @test P[2, 2] == 4
    A = GetindexArray(axes(P), P) do AA, idx
        # reverse both indexes
        AA[(size(AA) .+ 1 .- idx)...]
    end
    @test @inferred(A[1, 1]) == 4
    @test A[1, 2] == 3
    @test A[2, 1] == 2
    @test A[2, 2] == 1
    @test_throws BoundsError A[3, 2]
    @test_throws BoundsError A[2, 3]
    @test @inferred(axes(A)) == axes(P)

    # Test that construction is inferred (@inferred can't handle `do` syntax)
    # on an example that mimics PermutedDimsArray
    P = rand(3, 2)
    A = @inferred(GetindexArray{eltype(P)}((AA, (i1, i2))->AA[i2, i1], reverse(axes(P)), P))
    @test @inferred(size(A)) == (2, 3)
    @test @inferred(axes(A)) == (1:2, 1:3)
    @test @inferred(A[1, 1]) == P[1, 1]
    @test A[2, 1] == P[1, 2]
    @test_throws BoundsError A[3, 1]
    @test A[1, 2] == P[2, 1]
    @test A[2, 2] == P[2, 2]
    @test A[1, 3] == P[3, 1]
    @test A[2, 3] == P[3, 2]
    @test_throws BoundsError A[1, 4]

    P = rand(3, 5, 4)
    A = GetindexArray((axes(P, 1), axes(P, 3)), P) do AA, (i1, i2)
        sum(view(AA, i1, :, i2))
    end
    @test size(A) == (3, 4)
    for i in eachindex(A)
        @test A[i] == sum(P[i[1], :, i[2]])
    end

    # A much more complex example using traits, applying a coordinate transformation,
    # mapping values, and local averaging.
    function fancy_getindex((A, tforms), i)
        # Get the spatial slice and transformation for this time point
        tax, ti = timeaxis(A), i[timedim(A)]
        Aspatial = view(A, tax(ti))
        tform = tforms[ti]
        # Compute the transformed center position
        si = ImageAxes.filter_space_axes(AxisArrays.axes(A), i)
        tformi = tform(SVector(si))
        ci = CartesianIndex(Tuple(round.(Int, tformi)))
        # Average over a spatial 3x3x... region, considering just those points that are in-bounds
        sinds = CartesianIndices(axes(Aspatial))
        s, n = float(zero(eltype(A))), 0
        @inbounds for j in max(first(sinds), ci-oneunit(ci)):min(last(sinds), ci+oneunit(ci))
            s += Aspatial[j]      # cumulative sum
            n += 1                # number of in-bounds voxels
        end
        # square-root transform and return the result
        # Both `s` and `n` will be zero if there were no in-bounds points, in which case we return NaN (which is good)
        return sqrt(s/n)
    end

    tforms = [LinearMap(RotMatrix(θ)) for θ = 0:π/16:2π]
    P = zeros(8, 13, length(tforms))
    P[3:6, 4:9, :] .= 1
    P = AxisArray(OffsetArray(P, -3:4, -6:6, 1:length(tforms)), :y, :x, :time)
    A = @inferred(GetindexArray(fancy_getindex, axes(P), (P, tforms)))
    @test @inferred(A[0, 0, lastindex(tforms)]) === 1.0
end
