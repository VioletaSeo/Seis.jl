# Synthetic traces
using Test
using Seis
using Seis.Synth
import DSP

@testset "Synth" begin
    @testset "Gaussian 1" begin
        for T in (Float32, Float64) # FIXME: Doesn't work for Float16 (problem with DSP.periodogram(x; fs=Float16(1/delta)))
            let b=-10, delta=0.01, n=2001, f=2, time=-1, t = gaussian1(b, delta, n, f, time, T=T)
                @test eltype(t) == T
                @test nsamples(t) == n
                @test starttime(t) == T(b)
                @test t.delta == T(delta)
                @test maximum(abs, trace(t)) == T(1)
                p = DSP.periodogram(trace(t), fs=1/t.delta)
                @test p.freq[argmax(p.power)] ≈ f rtol=0.01
            end
        end
    end

    @testset "Heaviside" begin
        @test_throws ArgumentError heaviside(0, 0.01, 100, -1)
        let t = heaviside(-10, 0.01, 1000)
            @test all(t.t[1:nsamples(t)÷2] .== 0.0)
            @test all(t.t[nsamples(t)÷2+1:end] .== 1.0)
            @test times(t)[nsamples(t)÷2+1] == -5.0
        end
        let t = heaviside(1, 1, 101, 99, reverse=true)
            @test all(t.t[100:end] .== 0.0)
            @test all(t.t[1:99] .== 1.0)
        end
        @test heaviside(0, 1, 100, T=Float16) isa Trace{Float16,Vector{Float16},Seis.Geographic{Float16}}
        @test heaviside(0, 1, 100, V=Vector{Float32}) isa
            Trace{Float64,Vector{Float32},Seis.Geographic{Float64}}
        @test eltype(heaviside(0, 1, 100, T=Float32) |> trace) == Float32
    end

    @testset "Ricker" begin
        for T in (Float32, Float64) # FIXME: Doesn't work for Float16 (problem with DSP.periodogram(x; fs=Float16(1/delta)))
            let b=-10, delta=0.01, n=2001, f=5, time=3, t=ricker(b, delta, n, f, time, T=T)
                @test eltype(t) == T
                @test nsamples(t) == n
                @test starttime(t) == T(b)
                @test t.delta == T(delta)
                @test maximum(abs, trace(t)) == T(1)
                p = DSP.periodogram(trace(t), fs=1/t.delta)
                @test p.freq[argmax(p.power)] ≈ f rtol=0.01
            end
        end
    end

    @testset "Sines"  begin
        @test_throws ArgumentError sines(0, 1, 100, [1, 2], [1, 2, 3])
        let b = 100*(rand() - 1), delta = rand(), n = rand(100:1000), ν = rand()/100, amp=rand()
            @test sines(b, delta, n, ν, amp) == sines(b, delta, n, [ν], [amp])
        end
        let t = sines(-10, 0.01, 1000, [0.1, 0.2], [1, 1])
        end
        @test sines(0, 1, 100, 0.1, T=Float16) isa Trace{Float16,Vector{Float16}}
    end

    @testset "Spikes" begin
        @test_throws ArgumentError spikes(0, 1, 100, [1,2], [3,4,5])
        @test_throws ErrorException spikes(0, 1, 100, -1)
        let t = spikes(-1, 1, 100, [0, 2], [3, 4])
            @test all(trace(t)[[1,3]] .== 0.0)
            @test all(trace(t)[5:end] .== 0)
            @test trace(t)[2] == 3.0
            @test trace(t)[4] == 4.0
            @test t isa Trace{Float64,Vector{Float64}}
        end
        let b = 10, delta = 0.01, n = rand(200:2000), time = 10.1, amp = rand()
            @test spikes(b, delta, n, time, amp) == spikes(b, delta, n, [time], [amp])
        end
    end
end
