RR = RealField()
CC = ComplexField()

@testset "ComplexPoly.constructors" begin
   S1 = PolyRing(CC)
   S2 = PolyRing(CC)

   @test isa(S1, ComplexPolyRing)
   @test S1 !== S2

   R, x = polynomial_ring(CC, "x")

   @test elem_type(R) == ComplexPoly
   @test elem_type(ComplexPolyRing) == ComplexPoly
   @test parent_type(ComplexPoly) == ComplexPolyRing
   @test dense_poly_type(ComplexFieldElem) == ComplexPoly

   @test typeof(R) <: ComplexPolyRing

   @test isa(x, PolyRingElem)

   f = x^3 + 2x^2 + x + 1

   @test isa(f, PolyRingElem)

   g = R(2)

   @test isa(g, PolyRingElem)

   h = R(x^2 + 2x + 1)

   @test isa(h, PolyRingElem)

   k = R([CC(1), CC(0), CC(3)])

   @test isa(k, PolyRingElem)

   l = R([1, 2, 3])

   @test isa(l, PolyRingElem)

   for T in [RR, ZZRingElem, QQFieldElem, Int, BigInt, Rational{Int}, Rational{BigInt}]
     m = R(map(T, [1, 2, 3]))

     @test isa(m, PolyRingElem)
   end
end

@testset "ComplexPoly.printing" begin
   R, x = polynomial_ring(CC, "x")
   f = x^3 + 2x^2 + x + 1

   @test occursin(r"x", string(f))
   @test occursin(r"2.[0]+", string(f))
end

@testset "ComplexPoly.manipulation" begin
   R, x = polynomial_ring(CC, "x")

   @test iszero(zero(R))

   @test isone(one(R))

   @test is_gen(gen(R))

   # @test is_unit(one(R))

   f = x^2 + 2x + 1

   @test leading_coefficient(f) == 1

   @test degree(f) == 2

   @test length(f) == 3

   @test coeff(f, 1) == 2

   @test_throws DomainError coeff(f, -1)

   # @test canonical_unit(-x + 1) == -1

   @test deepcopy(f) == f

   @test characteristic(R) == 0
end

@testset "ComplexPoly.binary_ops" begin
   R, x = polynomial_ring(CC, "x")

   f = x^2 + 2x + 1
   g = x^3 + 3x + 2

   @test f + g == x^3+x^2+5*x+3

   @test f*g == x^5+2*x^4+4*x^3+8*x^2+7*x+2

   @test f - g == -x^3+x^2-x-1
end

@testset "ComplexPoly.adhoc_binary" begin
   R, x = polynomial_ring(CC, "x")

   f = x^2 + 2x + 1
   g = x^3 + 3x + 2

   for T in [Int, BigInt, RR, CC, ZZRingElem, QQFieldElem, Rational{Int}, Rational{BigInt}]
      @test f * T(12) == 12*x^2+24*x+12

      @test T(7) * g == 7*x^3+21*x+14

      @test T(3) * g == 3*x^3+9*x+6

      @test f * T(2) == 2*x^2+4*x+2

      @test T(2) * f == 2*x^2+4*x+2

      @test f + T(12) == x^2+2*x+13

      @test f - T(12) == x^2+2*x-11

      @test T(12) + g == x^3+3*x+14

      @test T(12) - g == -x^3-3*x+10
   end
end

@testset "ComplexPoly.comparison" begin
   R, x = polynomial_ring(CC, "x")
   Zx, zx = polynomial_ring(ZZ, "x")
   Qx, qx = polynomial_ring(QQ, "x")

   f = x^2 + 2x + 1
   g = x^3 + 3x + 2
   h = f + CC("0 +/- 0.0001")
   i = f + CC("0 +/- 0.0001") * x^4

   @test f != g
   @test f == deepcopy(f)

   @test !(f == h)
   @test !(f != h)

   @test !(f == i)
   @test !(f != i)

   @test isequal(f, deepcopy(f))
   @test !isequal(f, h)

   @test contains(f, f)
   @test contains(h, f)
   @test contains(i, f)

   @test !contains(f, h)
   @test !contains(f, g)

   @test contains(h, zx^2 + 2zx + 1)
   @test !contains(h, zx^2 + 2zx + 2)
   @test contains(h, qx^2 + 2qx + 1)
   @test !contains(h, qx^2 + 2qx + 2)

   @test overlaps(f, h)
   @test overlaps(f, i)
   @test !overlaps(f, g)

   uniq, p = unique_integer(h)
   @test uniq
   @test p == zx^2 + 2zx + 1

   uniq, p = unique_integer(f + CC("3 +/- 1.01") * x^4)
   @test !uniq
end

@testset "ComplexPoly.adhoc_comparison" begin
   R, x = polynomial_ring(CC, "x")

   f = x^2 + 2x + 1

   @test f != 1

   @test 1 != f

   @test R(7) == ZZRingElem(7)

   @test ZZRingElem(7) != f

   @test R(7) == CC(7)

   @test CC(7) != f

   @test R(7) == QQ(7)

   @test QQ(7) != f

   @test R(7) == RR(7.0)
end

@testset "ComplexPoly.unary_ops" begin
   R, x = polynomial_ring(CC, "x")

   f = x^2 + 2x + 1

   @test -f == -x^2 - 2x - 1
end

@testset "ComplexPoly.truncation" begin
   R, x = polynomial_ring(CC, "x")

   f = x^2 + 2x + 1
   g = x^3 + 3x + 1

   @test truncate(f, 2) == 2*x+1

   @test_throws DomainError truncate(f, -1)

   @test mullow(f, g, 3) == 7*x^2+5*x+1

   @test_throws DomainError mullow(f, g, -1)
end

@testset "ComplexPoly.reverse" begin
   R, x = polynomial_ring(CC, "x")

   f = x^2 + 2x + 3

   #@test reverse(f) == 3x^2 + 2x + 1
end

@testset "ComplexPoly.shift" begin
   R, x = polynomial_ring(CC, "x")

   f = x^2 + 2x + 1

   @test shift_left(f, 3) == x^5 + 2x^4 + x^3

   @test_throws DomainError shift_left(f, -1)

   @test shift_right(f, 1) == x + 2

   @test_throws DomainError shift_right(f, -1)
end

@testset "ComplexPoly.powering" begin
   R, x = polynomial_ring(CC, "x")

   f = x^2 + 2x + 1

   @test f^12 == x^24+24*x^23+276*x^22+2024*x^21+10626*x^20+42504*x^19+134596*x^18+346104*x^17+735471*x^16+1307504*x^15+1961256*x^14+2496144*x^13+2704156*x^12+2496144*x^11+1961256*x^10+1307504*x^9+735471*x^8+346104*x^7+134596*x^6+42504*x^5+10626*x^4+2024*x^3+276*x^2+24*x+1

   @test_throws DomainError f^-1
end

@testset "ComplexPoly.exact_division" begin
   R, x = polynomial_ring(CC, "x")

   f = x^2 + 2x + 1
   g = x^3 + 3x + 1

   @test divexact(f*g, f) == g
end

@testset "ComplexPoly.scalar_division" begin
   R, x = polynomial_ring(CC, "x")

   f = x^2 + 2x + 1

   @test divexact(2*f, ZZ(2)) == f

   @test divexact(2*f, 2) == f

   @test divexact(2*f, QQ(2)) == f

   @test divexact(2*f, CC(2)) == f

   @test divexact(2*f, 2.0) == f
end

@testset "ComplexPoly.evaluation" begin
   R, x = polynomial_ring(CC, "x")

   f = x^2 + 2x + 1

   @test evaluate(f, 3) == 16

   @test evaluate(f, 10.0) == 121

   @test evaluate(f, ZZ(10)) == 121

   @test evaluate(f, QQ(10)) == 121

   @test evaluate(f, CC(10)) == 121

   @test evaluate2(f, 10) == (121, 22)

   @test evaluate2(f, 10.0) == (121, 22)

   @test evaluate2(f, ZZ(10)) == (121, 22)

   @test evaluate2(f, QQ(10)) == (121, 22)

   @test evaluate2(f, CC(10)) == (121, 22)
end

@testset "ComplexPoly.roots" begin
   R, x = polynomial_ring(CC, "x")

   f = (x - 1)*(x - 2)*(x - CC("5 +/- 0.001"))

   r = roots(f, isolate_real = true)

   @test contains(r[1], 1)
   @test contains(r[2], 2)
   @test contains(r[3], 5)
end

@testset "ComplexPoly.composition" begin
   R, x = polynomial_ring(CC, "x")

   f = x^2 + 2x + 1
   g = x^3 + 3x + 1

   @test compose(f, g) == x^6+6*x^4+4*x^3+9*x^2+12*x+4
end

@testset "ComplexPoly.derivative_integral" begin
   R, x = polynomial_ring(CC, "x")

   f = x^2 + 2x + 1

   @test derivative(f) == 2x + 2

   @test contains(derivative(integral(f)), f)
end

@testset "ComplexPoly.evaluation_interpolation" begin
   R, x = polynomial_ring(CC, "x")

   n = 5
   xs = ComplexFieldElem[inv(CC(i)) for i=1:n]
   ys = ComplexFieldElem[CC(i) for i=1:n]

   f = interpolate(R, xs, ys)
   vs = evaluate(f, xs)
   for i=1:n
      @test contains(vs[i], ys[i])
   end

   f = interpolate(R, xs, ys)
   vs = evaluate(f, xs)
   for i=1:n
      @test contains(vs[i], ys[i])
   end

   f = interpolate_fast(R, xs, ys)
   vs = evaluate_fast(f, xs)
   for i=1:n
      @test contains(vs[i], ys[i])
   end

   f = interpolate_newton(R, xs, ys)
   vs = evaluate(f, xs)
   for i=1:n
      @test contains(vs[i], ys[i])
   end

   f = interpolate_barycentric(R, xs, ys)
   vs = evaluate(f, xs)
   for i=1:n
      @test contains(vs[i], ys[i])
   end

   f = from_roots(R, xs)
   @test degree(f) == n
   for i=1:n
      @test contains_zero(evaluate(f, xs[i]))
   end
end

@testset "ComplexPoly.root_bound" begin
   Rx, x = polynomial_ring(CC, "x")

   for i in 1:2
      r = rand(1:10)
      z = map(CC, rand(-BigInt(2)^60:BigInt(2)^60, r))
      f = prod([ x - (z[i]  + onei(CC)) for i in 1:r])
      b = roots_upper_bound(f)
      @test all([ abs(z[i] + onei(CC)) <= b for i in 1:r])
   end
end

@testset "Issue #1587" begin
   CC = ComplexField()
   R, t = polynomial_ring(CC, "t")
   D, Dt = polynomial_ring(R, "Dt")
   A_scalarform = t^3 * (32 * t^2 - 1) * (32 * t^2 + 1) * Dt^4 + 2 * t^2 * (7168 * t^4 - 3) * Dt^3 + t * (55296 * t^4 - 7) * Dt^2 + (61440 * t^4 - 1) * Dt + 12288 * t^3
   @test A_scalarform isa PolyRingElem{ComplexPoly}
end
