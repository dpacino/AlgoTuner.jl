# Simple SA for TSP

#
# To compile: time julia SA_Julia.jl ../Data/berlin52.tsp.dmat 30
#
# Static: juliac_opt SA_Julia.jl
# Static-run: time ./SA_Julia ../../Data/berlin52.tsp.dmat

using Random

function readInstance(filename)
    file = open(filename)
    name = split(readline(file))[2]
    readline(file);readline(file)
    dim = parse(Int64,split(readline(file))[2])
    readline(file);readline(file)
    coord = zeros(dim,2)
    for i in 1:dim
        data = parse.(Float32,split(readline(file)))
        coord[i,:]=data[2:3]
    end
    close(file)
    return name,coord,dim
end

function getDistanceMatrix(coord,dim)
    dist = zeros(dim,dim)
    for i in 1:dim
       for j in 1:dim
            if i!=j
                dist[i,j]=round(sqrt((coord[i,1]-coord[j,1])^2+(coord[i,2]-coord[j,2])^2),digits=0)
            end
        end
    end
    return dist
end


function randTour(N)
    tour2::Array{Int64}=zeros(Int64,N)
    @fastmath @inbounds for i=1:N
        tour2[i]=i
    end
    top=N
    tour::Array{Int64}=zeros(Int64,N)
    @fastmath @inbounds for i=1:N
        cur=trunc(Int32,1+rand()*top)
        tour[i]=tour2[cur]
        tour2[cur]=tour2[top]
        top=top-1
    end
    return tour
end


function cost(dist,tour::Array{Int64})
    N=length(tour)
    co=0
    @fastmath @inbounds for i=1:N-1
        co=co+dist[tour[i],tour[i+1]]
    end
    @fastmath @inbounds co=co+dist[tour[N],tour[1]]
    return co
end

function NeighbourMove(N::Int64)
    #    f::Int64=mod1(rand(Int),N)
    #    l::Int64=mod1(rand(Int),N)
    f::Int64=rand(1:N)
    l::Int64=rand(1:N)

    while f==l
        l=rand(1:N)
    end
    if f>l
        f, l=l, f
    end
    return (f,l)
end


function calc_delta(cur_sol::Array{Int64},s1::Int64,s2::Int64,dist,N::Int64)
    # case 1: if s1 is just before or after s2
    if  (s1+1==s2)
        @fastmath @inbounds p_s1=(s1>1 ? s1-1 : N)
        @fastmath @inbounds s_s2=(s2<N ? s2+1 : 1)
        @fastmath @inbounds return ( (dist[cur_sol[s1],cur_sol[s_s2]] - dist[cur_sol[p_s1],cur_sol[s1]]) +
                 (dist[cur_sol[p_s1],cur_sol[s2]] - dist[cur_sol[s2],cur_sol[s_s2]]) )
    end

    if s1==1 && s2==N
        @fastmath @inbounds return ( (dist[cur_sol[N-1],cur_sol[s1]] - dist[cur_sol[s1],cur_sol[2]]) +
                 (dist[cur_sol[s2],cur_sol[2]] - dist[cur_sol[N-1],cur_sol[s2]]) )
    end

    @fastmath @inbounds p_s1=(s1>1 ? s1-1 : N)
    @fastmath @inbounds p_s2=(s2>1 ? s2-1 : N)
    @fastmath @inbounds s_s1=(s1<N ? s1+1 : 1)
    @fastmath @inbounds s_s2=(s2<N ? s2+1 : 1)
    @fastmath @inbounds return ( (dist[cur_sol[p_s2],cur_sol[s1]] + dist[cur_sol[s1],cur_sol[s_s2]]) -
             (dist[cur_sol[p_s1],cur_sol[s1]] + dist[cur_sol[s1],cur_sol[s_s1]]) +
             (dist[cur_sol[p_s1],cur_sol[s2]] + dist[cur_sol[s2],cur_sol[s_s1]]) -
             (dist[cur_sol[p_s2],cur_sol[s2]] + dist[cur_sol[s2],cur_sol[s_s2]]) )
end

function SA(instance::String, time_limit::Int64, seed::Int64,
            T::Float64, alpha::Float64, test::Int64)

    test1 = zeros(test)
    t1::Float64=time_ns()
    Random.seed!(seed)

    name,coord,N = readInstance(instance)
    dist = getDistanceMatrix(coord,N)

    # Simple SA
    cur_sol::Array{Int64}=randTour(N)

    cur_cost::Int64=cost(dist,cur_sol)

    it::Int64=1
    it2::Int64=100000
    elapsed_time::Float64=0.0
    t2::Float64=-1.0
    It1::Float64=time_ns()
    prob::Float64=-1.0
    ex::Float64=-1.0
    delta::Int64=-1
    s1::Int64=-1
    s2::Int64=-1
    GC.enable(false)
    set_zero_subnormals(true)
    while true
        if it>=it2
            it2+=100000
            t2=time_ns()
            @fastmath @inbounds elapsed_time=(t2-t1)/1.0e9
            if elapsed_time>=time_limit
                break
            end
        end
        (s1,s2)=NeighbourMove(N)

        delta=calc_delta(cur_sol,s1,s2,dist,N)

        if delta <= 1
            @fastmath @inbounds cur_cost=cur_cost+delta
            @fastmath @inbounds cur_sol[s1], cur_sol[s2] = cur_sol[s2], cur_sol[s1]
        else
            prob=rand()
            @fastmath @inbounds ex=exp(-delta/T)
            @fastmath if prob < ex
                @fastmath @inbounds cur_cost=cur_cost+delta
                @fastmath @inbounds cur_sol[s1], cur_sol[s2] = cur_sol[s2], cur_sol[s1]
            end
        end
        @fastmath T=T*alpha
        it=it+1
    end
    t2=time_ns()
    elapsed_time=(t2-t1)/1.0e9
    Ielapsed_time=(It1-t1)/1.0e9
    #println("Mill it: $(it2 / 1.0e6)    T: $(T)  Running time: $(elapsed_time)  init time: $(Ielapsed_time)   found: $(cur_cost)   check: $(cost(dist,cur_sol))")
    return cur_cost

    #f = open("dario_sa_julia.log", "a")
    #@printf "%d , %.0f , %d, %d, %.0f\n" N elapsed_time cur_cost it2 (it2/(elapsed_time*1000))
#    @printf f "%d , %.1f , %d , %d, %d\n", N, elapsed_time, opt, cur_cost, it
    #close(f)
end

#=
Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    SA(ARGS)  # call your program's logic.
    return 0
end
=#

#SA("TSP/tsp_fun.tsp",2,1234,1000.0,0.9999999)







#elapsed time: 30.000000 it: 41.618.808

# It: 295.593.657 Running time: 30.000000124  init time: 0.036929127
