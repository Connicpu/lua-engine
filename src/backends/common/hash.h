#pragma once

#include <string>
#include <vector>
#include <random>
#include <memory>
#include <stdint.h>

#if defined(__has_include) && __has_include(<gsl.h>)
#include <gsl.h>
#ifndef GSL_INCLUDED
#define GSL_INCLUDED
#endif
#endif

#if defined(__has_include) && __has_include(<string_view>) && \
    (!defined(_MSC_VER) || (defined(_HAS_CXX17) && _HAS_CXX17 != 0))
#include <string_view>
#ifndef STRING_VIEW_INCLUDED
#define STRING_VIEW_INCLUDED
#endif
#endif

////////////////////////////////////////////////////////////////////////////////////////////////
// Implementation helper

namespace HashDetails
{
    template <typename H, typename In, typename Out>
    struct TruncateHash
    {
        using result_type = Out;

        template <typename ...Args>
        TruncateHash(Args &&...args)
            : hasher(std::forward<Args>(args)...)
        {
        }

        inline void reset()
        {
            hasher.reset();
        }

        inline void write(const uint8_t *data, size_t len)
        {
            hasher.write(data, data + len);
        }

        inline void write(const void *data, size_t len)
        {
            hasher.write(data, len);
        }

        #ifdef GSL_INCLUDED
        void write(gsl::span<const uint8_t> data)
        {
            hasher.write(data);
        }
        #endif

        operator Out() const
        {
            return static_cast<Out>(static_cast<In>(hasher));
        }

        H hasher;
    };
}

////////////////////////////////////////////////////////////////////////////////////////////////
// FNV-1 Hash implementation

namespace Fnv1Details
{
    template <typename Integral, Integral offset_basis, Integral prime>
    struct Hasher
    {
        using result_type = Integral;

        Hasher()
            : state(offset_basis)
        {
        }

        inline void reset()
        {
            state = offset_basis;
        }

        inline void write(const uint8_t *data, size_t len)
        {
            for (size_t i = 0; i < len; ++i)
            {
                state = state * prime;
                state = state ^ static_cast<Integral>(data[i]);
            }
        }

        inline void write(const void *data, size_t len)
        {
            auto ptr = reinterpret_cast<const uint8_t *>(data);
            write(ptr, len);
        }

#ifdef GSL_INCLUDED
        void write(gsl::span<const uint8_t> data)
        {
            write(data.data(), data.size());
        }
#endif

        operator Integral() const
        {
            return state;
        }

        Integral state;
    };
}

using Fnv1_32 = Fnv1Details::Hasher<uint32_t, 2166136261U, 16777619U>;
using Fnv1_64 = Fnv1Details::Hasher<uint64_t, 14695981039346656037U, 1099511628211U>;
using Fnv1 = std::conditional<std::is_same<size_t, uint32_t>::value, Fnv1_32, Fnv1_64>::type;

////////////////////////////////////////////////////////////////////////////////////////////////
// FNV-1A Hash implementation

namespace Fnv1ADetails
{
    template <typename Integral, Integral offset_basis, Integral prime>
    struct Hasher
    {
        using result_type = Integral;

        Hasher()
            : state(offset_basis)
        {
        }

        inline void reset()
        {
            state = offset_basis;
        }

        inline void write(const uint8_t *data, size_t len)
        {
            for (size_t i = 0; i < len; ++i)
            {
                state = state ^ static_cast<Integral>(data[i]);
                state = state * prime;
            }
        }

        inline void write(const void *data, size_t len)
        {
            auto ptr = reinterpret_cast<const uint8_t *>(data);
            write(ptr, len);
        }

#ifdef GSL_INCLUDED
        void write(gsl::span<const uint8_t> data)
        {
            write(data.data(), data.size());
        }
#endif

        operator Integral() const
        {
            return state;
        }

        Integral state;
    };
}

using Fnv1A_32 = Fnv1ADetails::Hasher<uint32_t, 2166136261U, 16777619U>;
using Fnv1A_64 = Fnv1ADetails::Hasher<uint64_t, 14695981039346656037U, 1099511628211>;
using Fnv1A = std::conditional<std::is_same<size_t, uint32_t>::value, Fnv1A_32, Fnv1A_64>::type;

////////////////////////////////////////////////////////////////////////////////////////////////
// SipHash implementation

namespace SipDetails
{
#pragma region State + Rounds

    struct State
    {
        uint64_t v0, v2, v1, v3;
    };

    inline uint64_t rotl(uint64_t x, uint64_t b)
    {
        return (x << b) | (x >> (64 - b));
    }

    inline void compress(State &state)
    {
        uint64_t &v0 = state.v0, &v2 = state.v2, &v1 = state.v1, &v3 = state.v3;
        v0 += v1; v1 = rotl(v1, 13); v1 ^= v0;
        v0 = rotl(v0, 32);
        v2 += v3; v3 = rotl(v3, 16); v3 ^= v2;
        v0 += v3; v3 = rotl(v3, 21); v3 ^= v0;
        v2 += v1; v1 = rotl(v1, 17); v1 ^= v2;
        v2 = rotl(v2, 32);
    }

    struct Sip13Rounds
    {
        static inline void c_rounds(State &state)
        {
            compress(state);
        }
        static inline void d_rounds(State &state)
        {
            compress(state);
            compress(state);
            compress(state);
        }
    };

    struct Sip24Rounds
    {
        static inline void c_rounds(State &state)
        {
            compress(state);
            compress(state);
        }
        static inline void d_rounds(State &state)
        {
            compress(state);
            compress(state);
            compress(state);
            compress(state);
        }
    };

#pragma endregion

#pragma region Hasher

    inline uint64_t u8to64_le(const uint8_t *buf, size_t i)
    {
        return
            uint64_t(buf[0 + i]) << 0 |
            uint64_t(buf[1 + i]) << 8 |
            uint64_t(buf[2 + i]) << 16 |
            uint64_t(buf[3 + i]) << 24 |
            uint64_t(buf[4 + i]) << 32 |
            uint64_t(buf[5 + i]) << 40 |
            uint64_t(buf[6 + i]) << 48 |
            uint64_t(buf[7 + i]) << 56;
    }

    inline uint64_t u8to64_le(const uint8_t *buf, size_t i, size_t len)
    {
        size_t t = 0;
        uint64_t out = 0;
        while (t < len)
        {
            out |= ((uint64_t)buf[t + i]) << (t * 8);
            t += 1;
        }
        return out;
    }

    template <typename Rounds>
    struct Hasher64
    {
        using result_type = uint64_t;

        Hasher64()
            : Hasher64(0, 0)
        {
        }

        Hasher64(uint64_t k0, uint64_t k1)
            : k0(k0), k1(k1)
        {
            reset();
        }

        void reset()
        {
            length = 0;
            state.v0 = k0 ^ 0x736f6d6570736575;
            state.v1 = k1 ^ 0x646f72616e646f6d;
            state.v2 = k0 ^ 0x6c7967656e657261;
            state.v3 = k1 ^ 0x7465646279746573;
            ntail = 0;
        }

        inline void write(const uint8_t *data, size_t len)
        {
            length += len;

            size_t needed = 0;

            if (ntail != 0)
            {
                needed = 8 - ntail;
                if (len < needed)
                {
                    tail |= u8to64_le(data, 0, len) << 8 * ntail;
                    ntail += len;
                    return;
                }

                uint64_t m = tail | u8to64_le(data, 0, needed) << 8 * ntail;

                state.v3 ^= m;
                Rounds::c_rounds(state);
                state.v0 ^= m;

                ntail = 0;
            }

            len = len - needed;
            size_t left = len & 0b111;

            size_t i;
            for (i = needed; i < len - left; i += 8)
            {
                uint64_t mi = u8to64_le(data, i);

                state.v3 ^= mi;
                Rounds::c_rounds(state);
                state.v0 ^= mi;
            }

            tail = u8to64_le(data, i, left);
            ntail = left;
        }

        inline void write(const void *data, size_t len)
        {
            auto ptr = reinterpret_cast<const uint8_t *>(data);
            write(ptr, len);
        }

#ifdef GSL_INCLUDED
        void write(gsl::span<const uint8_t> data)
        {
            write(data.data(), data.size());
        }
#endif

        operator uint64_t() const
        {
            State end_state = state;

            uint64_t b = ((uint64_t(length) & 0xff) << 56) | tail;

            end_state.v3 ^= b;
            Rounds::c_rounds(end_state);
            end_state.v0 ^= b;

            end_state.v2 ^= 0xff;
            Rounds::d_rounds(end_state);

            return end_state.v0 ^ end_state.v1 ^ end_state.v2 ^ end_state.v3;
        }

        uint64_t k0, k1;
        size_t length;
        State state;
        uint64_t tail;
        size_t ntail;
    };

    template <typename Rounds>
    struct Hasher32 : public HashDetails::TruncateHash<Hasher64<Rounds>, uint64_t, uint32_t>
    {
        Hasher32() = default;
        Hasher32(uint64_t k0, uint64_t k1)
            : HashDetails::TruncateHash<Hasher64<Rounds>, uint64_t, uint32_t>(k0, k1)
        {
        }
    };

    template <typename Rng>
    inline uint64_t rand_key(Rng &rng)
    {
        return std::uniform_int_distribution<uint64_t>(
            std::numeric_limits<uint64_t>::min(),
            std::numeric_limits<uint64_t>::max())
            (rng);
    }

    inline uint64_t rand_key()
    {
        static std::random_device drng;
        static thread_local std::mt19937_64 rng(drng());
        return rand_key(rng);
    }

    template <typename H, typename Out>
    struct RandomKey
    {
        RandomKey()
            : hasher(rand_key(), rand_key())
        {
        }

        RandomKey(uint64_t k1, uint64_t k2)
            : hasher(k1, k2)
        {
        }

        inline void reset()
        {
            hasher.reset();
        }

        inline void write(const uint8_t *data, size_t len)
        {
            hasher.write(data, data + len);
        }

        inline void write(const void *data, size_t len)
        {
            hasher.write(data, len);
        }

#ifdef GSL_INCLUDED
        void write(gsl::span<const uint8_t> data)
        {
            hasher.write(data);
        }
#endif

        operator Out() const
        {
            return static_cast<Out>(hasher);
        }

        H hasher;
    };

#pragma endregion
}

using SipHash13_32 = SipDetails::Hasher32<SipDetails::Sip13Rounds>;
using SipHash13_64 = SipDetails::Hasher64<SipDetails::Sip13Rounds>;
using SipHash24_32 = SipDetails::Hasher32<SipDetails::Sip24Rounds>;
using SipHash24_64 = SipDetails::Hasher64<SipDetails::Sip24Rounds>;
using SipHash13 = std::conditional<std::is_same<size_t, uint32_t>::value, SipHash13_32, SipHash13_64>::type;
using SipHash24 = std::conditional<std::is_same<size_t, uint32_t>::value, SipHash24_32, SipHash24_64>::type;

using RandomSipHash13_32 = SipDetails::RandomKey<SipHash13_32, uint32_t>;
using RandomSipHash24_32 = SipDetails::RandomKey<SipHash24_32, uint32_t>;
using RandomSipHash13_64 = SipDetails::RandomKey<SipHash13_64, uint64_t>;
using RandomSipHash24_64 = SipDetails::RandomKey<SipHash24_64, uint64_t>;
using RandomSipHash13 = SipDetails::RandomKey<SipHash13, size_t>;
using RandomSipHash24 = SipDetails::RandomKey<SipHash24, size_t>;

////////////////////////////////////////////////////////////////////////////////////////////////
// Wrapper to allow use of custom hashers where one would normally expect std::hash

template <typename Algo, typename T>
inline size_t simple_hash(const T &value)
{
    Algo hasher;
    hash_apply(value, hasher);
    return static_cast<size_t>(hasher);
}

template <typename Algo, typename T>
inline uint32_t simple_hash_32(const T &value)
{
    Algo hasher;
    hash_apply(value, hasher);
    return static_cast<uint32_t>(hasher);
}

template <typename Algo, typename T>
inline uint64_t simple_hash_64(const T &value)
{
    Algo hasher;
    hash_apply(value, hasher);
    return static_cast<uint64_t>(hasher);
}

////////////////////////////////////////////////////////////////////////////////////////////////
// The following is a bunch of hash_apply implementations for standard types

template <typename H>
inline void hash_apply(int8_t i, H &h)
{
    h.write(&i, sizeof(i));
}
template <typename H>
inline void hash_apply(uint8_t i, H &h)
{
    h.write(&i, sizeof(i));
}
template <typename H>
inline void hash_apply(int16_t i, H &h)
{
    h.write(&i, sizeof(i));
}
template <typename H>
inline void hash_apply(uint16_t i, H &h)
{
    h.write(&i, sizeof(i));
}
template <typename H>
inline void hash_apply(int32_t i, H &h)
{
    h.write(&i, sizeof(i));
}
template <typename H>
inline void hash_apply(uint32_t i, H &h)
{
    h.write(&i, sizeof(i));
}
template <typename H>
inline void hash_apply(int64_t i, H &h)
{
    h.write(&i, sizeof(i));
}
template <typename H>
inline void hash_apply(uint64_t i, H &h)
{
    h.write(&i, sizeof(i));
}
template <typename H>
inline void hash_apply(float i, H &h)
{
    h.write(&i, sizeof(i));
}
template <typename H>
inline void hash_apply(double i, H &h)
{
    h.write(&i, sizeof(i));
}
template <typename H, typename Ptr>
inline void hash_apply(Ptr *p, H &h)
{
    h.write(&p, sizeof(Ptr *));
}

namespace std
{
    template <typename H, typename Elem, typename Traits, typename Alloc>
    inline void hash_apply(const std::basic_string<Elem, Traits, Alloc> &s, H &h)
    {
        h.write(s.data(), s.size() * sizeof(Elem));
    }

    template <typename H, typename T, typename Alloc>
    inline void hash_apply(const std::vector<T, Alloc> &vec, H &h)
    {
        for (const T &elem : vec)
        {
            hash_apply(elem, h);
        }
    }

    template <typename H, typename T, typename D>
    inline void hash_apply(const std::unique_ptr<T, D> &ptr, H &h)
    {
        hash_apply(ptr.get(), h);
    }

    #ifdef STRING_VIEW_INCLUDED
    template <typename H, typename Elem, typename Traits>
    inline void hash_apply(const std::basic_string_view<Elem, Traits> &str, H &h)
    {
        h.write(str.data(), str.size() * sizeof(Elem));
    }
    #endif
}

#if GSL_INCLUDED
namespace gsl
{
    template <typename H, typename Elem, ptrdiff_t Extent>
    inline void hash_apply(gsl::basic_string_span<Elem, Extent> span, H &h)
    {
        h.write(span.data(), span.size_bytes());
    }
}
#endif

template <typename Hasher = Fnv1A>
class StdHash
{
    const Hasher hasher;

public:
    template <typename T>
    size_t operator()(const T &value) const
    {
        auto h = hasher;
        hash_apply(value, h);
        return static_cast<size_t>(h);
    }
};
