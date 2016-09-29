#pragma once

#include <stdint.h>
#include <type_traits>
#include <memory>
#include <vector>

template <size_t obj_size, size_t obj_align, uint32_t objects_per_bucket>
class object_pool;

struct pool_allocation
{
    void *memory;

private:
    void *_reserved;
    template <size_t S, size_t A, uint32_t O>
    friend class object_pool;
};

template <size_t obj_size, size_t obj_align, uint32_t objects_per_bucket>
class object_pool
{
public:
    using allocation = ::pool_allocation;

    auto alloc() -> allocation;
    auto free(const allocation &alloc) -> void;
    auto collect() -> void;

private:
    static const uint32_t FREE_END = ~((uint32_t)0);
    using obj_storage = std::aligned_storage_t<(obj_size < 4 ? 4 : obj_size), (obj_align < 4 ? 4 : obj_align)>;
    struct bucket_t
    {
        obj_storage objects[objects_per_bucket];
        uint32_t free_head = FREE_END;
        uint32_t end = 0;
        uint32_t remaining = objects_per_bucket;

        struct free_node
        {
            uint32_t next;
        };

        free_node *head()
        {
            if (free_head == FREE_END)
                return nullptr;
            return (free_node *)&objects[free_head];
        }
    };

    std::vector<std::unique_ptr<bucket_t>> buckets;
    std::vector<bucket_t *> free_buckets;
};

// Default to 4MB allocations
template <typename T>
using object_pool_t = object_pool<sizeof(T), alignof(T), 4 * 1024 * 1024 / sizeof(T)>;

template<size_t obj_size, size_t obj_align, uint32_t objects_per_bucket>
inline auto object_pool<obj_size, obj_align, objects_per_bucket>::alloc() -> allocation
{
    if (free_buckets.empty())
    {
        std::unique_ptr<bucket_t> new_bucket{ new bucket_t };
        free_buckets.push_back(new_bucket.get());
        buckets.push_back(std::move(new_bucket));
    }

    auto &bucket = *free_buckets.back();
    if (bucket.remaining == 1)
        free_buckets.pop_back();

    allocation alloc;
    if (bucket.free_head != FREE_END)
    {
        auto *head = bucket.head();
        bucket.free_head = head->next;
        alloc.memory = head;
        alloc._reserved = &bucket;
    }
    else
    {
        auto *mem = &bucket.objects[bucket.end++];
        alloc.memory = mem;
        alloc._reserved = &bucket;
    }

    bucket.remaining--;
    return alloc;
}

template<size_t obj_size, size_t obj_align, uint32_t objects_per_bucket>
inline auto object_pool<obj_size, obj_align, objects_per_bucket>::free(const allocation & alloc) -> void
{
    auto &bucket = *(bucket_t *)alloc._reserved;
    if (bucket.remaining == 0)
    {
        free_buckets.push_back(&bucket);
    }

    auto obj = (obj_storage *)alloc.memory;
    auto idx = uint32_t(obj - &bucket.objects[0]);
    
    if (idx == bucket.end + 1)
    {
        bucket.end--;
    }
    else
    {
        auto node = (typename bucket_t::free_node *)obj;
        node->next = bucket.free_head;
        bucket.free_head = idx;
    }

    bucket.remaining++;
}

template<size_t obj_size, size_t obj_align, uint32_t objects_per_bucket>
inline auto object_pool<obj_size, obj_align, objects_per_bucket>::collect() -> void
{
    for (int i = 0; i < free_buckets.size(); ++i)
    {
        bucket_t &bucket = free_buckets[i];
        if (bucket.remaining == objects_per_bucket)
        {
            for (auto iter = buckets.begin(); iter != buckets.end(); ++iter)
            {
                if (iter->get() == &bucket)
                {
                    buckets.erase(iter);
                    break;
                }
            }

            free_buckets.erase(free_buckets().begin() + i);
            --i;
        }
    }
}
