#pragma once

#include "hash.h"
#include <stdlib.h>
#include <optional>
#include <cmath>

namespace hashmap_details
{
    template <typename Hasher, typename K, typename V>
    struct entry
    {
        entry(K &&key, V &&value, typename Hasher::result_type hash)
            : key(key), value(value), hash(hash)
        {
        }

        V move_value()
        {
            return std::move(value);
        }

        K key;
        V value;
        typename Hasher::result_type hash;
    };

    template <typename Hasher, typename K>
    struct entry<Hasher, K, void>
    {
        template <typename V>
        entry(K &&key, V &&, typename Hasher::result_type hash)
            : key(key), hash(hash)
        {
        }

        bool move_value()
        {
            return true;
        }

        K key;
        typename Hasher::result_type hash;
    };
}

template <typename K>
struct hashmap_key_traits;
template <typename V>
struct hashmap_value_traits;

template <typename K, typename V, typename Hasher = SipHash13_64>
class hashmap
{
    using entry = hashmap_details::entry<Hasher, K, V>;
    using key_traits = hashmap_key_traits<K>;
    using value_traits = hashmap_value_traits<V>;
    using hash_t = typename Hasher::result_type;
    static constexpr size_t hash_bits = sizeof(hash_t) * 8;

public:
    using value_type = typename value_traits::value_type;
    using optional_value_type = typename value_traits::optional_value_type;
    using optional_value_ref = typename value_traits::optional_value_ref;
    using optional_value_cref = typename value_traits::optional_value_cref;
    using lookup_type = typename key_traits::lookup_type;

    hashmap(const Hasher &hasher = Hasher{});
    ~hashmap();

    optional_value_type insert(K key, value_type value);
    optional_value_type remove(lookup_type key);
    void clear();
    void shrink();

    optional_value_cref get(lookup_type key) const;
    optional_value_ref get_mut(lookup_type key) const;

private:
    template <typename Q>
    hash_t hash_key(const Q &key) const;
    static bool is_deleted(hash_t hash);
    size_t desired_pos(hash_t hash) const;
    size_t probe_distance(hash_t hash, size_t slot_index) const;
    void alloc();
    void insert_helper(entry &&entry);
    std::optional<size_t> lookup_index(lookup_type key) const;
    void erase(size_t idx);
    void grow();

    Hasher hash_state;
    entry *data;
    size_t cap;
    size_t len;
    size_t max_probe;
};

template<typename K, typename V, typename Hasher>
inline hashmap<K, V, Hasher>::hashmap(const Hasher &hasher)
    : hash_state(std::move(hasher)), data(nullptr), cap(0), len(0), max_probe(0)
{
}

template<typename K, typename V, typename Hasher>
inline hashmap<K, V, Hasher>::~hashmap()
{
    clear();
    shrink();
}

template<typename K, typename V, typename Hasher>
inline auto hashmap<K, V, Hasher>::insert(K key, value_type value) -> optional_value_type
{
    auto old_value = remove(static_cast<lookup_type>(key));

    if (len >= cap * 0.95)
    {
        grow();
    }

    hash_t hash = hash_key(key);
    entry e{ std::move(key), std::move(value), std::move(hash) };
    insert_helper(std::move(e));

    len++;

    return old_value;
}

template<typename K, typename V, typename Hasher>
inline auto hashmap<K, V, Hasher>::remove(lookup_type key) -> optional_value_type
{
    optional_value_type old_value = {};
    if (auto old = lookup_index(key))
    {
        entry &e = data[*old];
        old_value = e.move_value();
        erase(*old);
    }
    return old_value;
}

template<typename K, typename V, typename Hasher>
inline void hashmap<K, V, Hasher>::clear()
{
    for (int i = 0; i < cap && len; ++i)
    {
        entry &e = data[i];
        if (e.hash != 0 && !is_deleted(e.hash))
        {
            erase(i);
        }
    }
}

template<typename K, typename V, typename Hasher>
inline void hashmap<K, V, Hasher>::shrink()
{
    entry *old_data = data;
    size_t old_cap = cap;

    if (len != 0)
    {
        // Find the next power of two of len
        cap = len;
        for (int x : { 1, 2, 4, 8, 16, 32 })
        {
            cap |= cap >> x;
        }
        cap++;

        alloc();
        max_probe = 0;

        for (size_t i = 0; i < old_cap; ++i)
        {
            if (old_data[i].hash != 0 && !is_deleted(old_data[i].hash))
            {
                insert_helper(std::move(old_data[i]));
            }
        }
    }
    else
    {
        data = nullptr;
        cap = 0;
    }

    for (size_t i = 0; i < old_cap; ++i)
    {
        if (old_data[i].hash != 0)
        {
            old_data[i].~entry();
        }
    }
    free(old_data);
}

template<typename K, typename V, typename Hasher>
inline auto hashmap<K, V, Hasher>::get(lookup_type key) const -> optional_value_cref
{
    if (auto idx = lookup_index(key))
    {
        if constexpr(std::is_same<V, void>::value)
            return true;
        else
            return data[idx].value;
    }
    return{};
}

template<typename K, typename V, typename Hasher>
inline auto hashmap<K, V, Hasher>::get_mut(lookup_type key) const -> optional_value_ref
{
    if (auto idx = lookup_index(key))
    {
        if constexpr(std::is_same<V, void>::value)
            return true;
        else
            return data[idx].value;
    }
    return{};
}

template<typename K, typename V, typename Hasher>
template<typename Q>
inline auto hashmap<K, V, Hasher>::hash_key(const Q &key) const -> hash_t
{
    constexpr hash_t mask = ~hash_t(0) ^ (hash_t(1) << (hash_bits - 1));
    auto state = hash_state;
    hash_apply(key, state);
    auto hash = static_cast<hash_t>(state);
    if (hash == 0) hash = 1;
    return hash & mask;
}

template<typename K, typename V, typename Hasher>
inline bool hashmap<K, V, Hasher>::is_deleted(hash_t hash)
{
    return (hash >> (hash_bits - 1)) != 0;
}

template<typename K, typename V, typename Hasher>
inline size_t hashmap<K, V, Hasher>::desired_pos(hash_t hash) const
{
    constexpr hash_t mask = ~hash_t(0) ^ (hash_t(1) << (hash_bits - 1));
    return (hash & mask) % cap;
}

template<typename K, typename V, typename Hasher>
inline size_t hashmap<K, V, Hasher>::probe_distance(hash_t hash, size_t slot_index) const
{
    return (slot_index + cap - desired_pos(hash)) % cap;
}

template<typename K, typename V, typename Hasher>
inline void hashmap<K, V, Hasher>::alloc()
{
    data = (entry *)calloc(cap, sizeof(entry));
}

template<typename K, typename V, typename Hasher>
inline void hashmap<K, V, Hasher>::insert_helper(entry &&insert_entry)
{
    size_t pos = desired_pos(insert_entry.hash);
    size_t dist = 0;

    for (;;)
    {
        entry &e = data[pos];
        
        if (e.hash == 0)
        {
            new (&e) entry(std::move(insert_entry));
            return;
        }

        size_t e_probe_dist = probe_distance(e.hash, pos);
        if (e_probe_dist < dist)
        {
            if (is_deleted(e.hash))
            {
                e.~entry();
                new (&e) entry(std::move(insert_entry));
                return;
            }

            std::swap(e, insert_entry);
            dist = e_probe_dist;
        }

        pos = (pos + 1) % cap;
        dist++;

        if (dist > max_probe)
        {
            max_probe = dist;
        }
    }
}

template<typename K, typename V, typename Hasher>
inline std::optional<size_t> hashmap<K, V, Hasher>::lookup_index(lookup_type key) const
{
    constexpr size_t TOMB_MASK = size_t(1) << (hash_bits - 1);

    if (len == 0)
    {
        return std::nullopt;
    }

    hash_t hash = hash_key(key);
    size_t pos = desired_pos(hash);
    size_t dist = 0;

    for (;;)
    {
        entry &e = data[pos];

        if (e.hash == 0 || dist > probe_distance(e.hash, pos))
        {
            return std::nullopt;
        }
        else if (e.hash == hash && e.key == key)
        {
            return pos;
        }
        else
        {
            pos = (pos + 1) % cap;
            dist++;
        }
    }
}

template<typename K, typename V, typename Hasher>
inline void hashmap<K, V, Hasher>::erase(size_t idx)
{
    constexpr size_t MASK = size_t(1) << (hash_bits - 1);
    entry &e = data[idx];
    { entry temp = std::move(e); }
    e.hash |= MASK;
    len--;
}

template<typename K, typename V, typename Hasher>
inline void hashmap<K, V, Hasher>::grow()
{
    entry *old_data = data;
    size_t old_cap = cap;

    cap = cap == 0 ? 16 : cap * 2;
    alloc();
    max_probe = 0;

    for (int i = 0; i < old_cap; ++i)
    {
        entry &e = old_data[i];
        if (e.hash != 0 && !is_deleted(e.hash))
        {
            insert_helper(std::move(e));
        }
        if (e.hash != 0)
        {
            e.~entry();
        }
    }

    free(old_data);
}

template <typename K>
struct hashmap_key_traits
{
    // The lookup type must have identical Hash behavior to K
    using lookup_type = const K &;
};

#ifdef STRING_VIEW_INCLUDED
template <typename Elem, typename Traits, typename Alloc>
struct hashmap_key_traits<std::basic_string<Elem, Traits, Alloc>>
{
    using lookup_type = const std::basic_string_view<Elem, Traits> &;
};
#endif

template <typename V>
struct hashmap_value_traits
{
    using value_type = V;
    using optional_value_type = std::optional<value_type>;
    using optional_value_ref = std::optional<value_type &>;
    using optional_value_cref = std::optional<const value_type &>;
};

template <>
struct hashmap_value_traits<void>
{
    using value_type = struct {};
    using optional_value_type = bool;
    using optional_value_ref = bool;
    using optional_value_cref = bool;
};
