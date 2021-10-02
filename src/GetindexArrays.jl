module GetindexArrays

export GetindexArray

struct GetindexArray{T,N,F,Axs<:NTuple{N,AbstractUnitRange{Int}},Ex} <: AbstractArray{T,N}
    getindex::F
    axes::Axs
    extras::Ex     # captured data needed to implement `getindex`
end
GetindexArray{T}(getindex::F, axes, extras=nothing) where {T,F} =
    GetindexArray{T, length(axes), F, typeof(axes), typeof(extras)}(getindex, axes, extras)
GetindexArray(getindex::F, axes, extras=nothing) where F =
    GetindexArray{Base._return_type(getindex, Tuple{typeof(extras), NTuple{length(axes), Int}})}(getindex, axes, extras)

Base.@propagate_inbounds function Base.getindex(A::GetindexArray{T,N}, i::Vararg{Int,N}) where {T,N}
    @boundscheck checkbounds(A, i...)
    convert(T, A.getindex(A.extras, i))::T
end
Base.size(A::GetindexArray) = map(length, A.axes)
Base.axes(A::GetindexArray) = A.axes

end
