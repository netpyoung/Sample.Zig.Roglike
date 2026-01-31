const std = @import("std");

const SeedRandom = @This();

_seed: u64,
_prng: std.Random.Xoshiro256,

pub fn InitWitoutSeed() SeedRandom {
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));
    return Init(seed);
}

pub fn Init(seed: u64) SeedRandom {
    const prng = std.Random.DefaultPrng.init(seed);
    return SeedRandom{
        ._seed = seed,
        ._prng = prng,
    };
}

pub fn NextUsize(self: *SeedRandom, min: usize, max: usize) usize {
    const rand = self._prng.random();
    return rand.intRangeLessThan(usize, min, max);
}

pub fn NextPerc(self: *SeedRandom) f64 {
    const rand = self._prng.random();
    return rand.floatNorm(f64);
}