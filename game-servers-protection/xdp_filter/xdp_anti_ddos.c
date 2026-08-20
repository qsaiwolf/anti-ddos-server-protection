#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/ipv6.h>
#include <linux/in.h>
#include <linux/udp.h>
#include <bpf/bpf_helpers.h>

#ifndef __constant_htons
#define __constant_htons(x) __builtin_bswap16(x)
#endif
#ifndef __constant_ntohs
#define __constant_ntohs(x) __builtin_bswap16(x)
#endif

// Limits
#define MAX_UDP_PPS_PER_IP 5000
#define MAX_GLOBAL_UDP_PPS 1000000
#define ONE_SEC_NS 1000000000ULL

struct rate_state {
    __u64 last_time;
    __u64 count;
};

struct ipv6_key {
    __u32 addr[4];
};

// 1. Whitelist Map (Pass traffic unconditionally)
struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 1024);
    __type(key, __u32); // IPv4 Address
    __type(value, __u8); // 1 = whitelisted
} whitelist_map SEC(".maps");

struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 1024);
    __type(key, struct ipv6_key); // IPv6 Address
    __type(value, __u8); // 1 = whitelisted
} whitelist_map_ipv6 SEC(".maps");

// 2. IPv4 Rate Limit Map
struct {
    __uint(type, BPF_MAP_TYPE_LRU_HASH);
    __uint(max_entries, 100000);
    __type(key, __u32);
    __type(value, struct rate_state);
} ip_rate_limit_map SEC(".maps");

// 3. IPv6 Rate Limit Map
struct {
    __uint(type, BPF_MAP_TYPE_LRU_HASH);
    __uint(max_entries, 100000);
    __type(key, struct ipv6_key);
    __type(value, struct rate_state);
} ip6_rate_limit_map SEC(".maps");

// 4. Global UDP Rate Limit Map
struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, struct rate_state);
} global_rate_limit_map SEC(".maps");

// 5. Statistics Map for Dropped Packets
struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, __u64); // Drop count
} xdp_stats_map SEC(".maps");

static __always_inline void increment_drop_count() {
    __u32 key = 0;
    __u64 *drop_count = bpf_map_lookup_elem(&xdp_stats_map, &key);
    if (drop_count) {
        __sync_fetch_and_add(drop_count, 1);
    }
}

SEC("xdp")
int xdp_prog(struct xdp_md *ctx) {
    void *data_end = (void *)(long)ctx->data_end;
    void *data = (void *)(long)ctx->data;
    
    struct ethhdr *eth = data;
    if (data + sizeof(struct ethhdr) > data_end)
        return XDP_PASS;

    __u16 h_proto = eth->h_proto;
    __u64 now = bpf_ktime_get_ns();
    
    // Adaptive Limit logic: if global traffic is high, restrict per-IP even more
    __u64 current_adaptive_limit = MAX_UDP_PPS_PER_IP;
    __u32 global_key = 0;
    struct rate_state *global_state = bpf_map_lookup_elem(&global_rate_limit_map, &global_key);
    
    if (h_proto == __constant_htons(ETH_P_IP)) {
        struct iphdr *ip = data + sizeof(struct ethhdr);
        if ((void *)(ip + 1) > data_end)
            return XDP_PASS;

        // Check Whitelist
        __u32 src_ip = ip->saddr;
        __u8 *is_whitelist = bpf_map_lookup_elem(&whitelist_map, &src_ip);
        if (is_whitelist && *is_whitelist == 1) {
            return XDP_PASS;
        }

        if (ip->protocol != IPPROTO_UDP)
            return XDP_PASS;

        if (ip->frag_off & __constant_htons(IP_OFFSET)) {
            increment_drop_count();
            return XDP_DROP;
        }

        struct udphdr *udp = (void *)ip + (ip->ihl * 4);
        if ((void *)(udp + 1) > data_end)
            return XDP_PASS;

        if (__constant_ntohs(ip->tot_len) > 1200) {
            increment_drop_count();
            return XDP_DROP;
        }

        if (global_state) {
            if (now - global_state->last_time > ONE_SEC_NS) {
                global_state->count = 1;
                global_state->last_time = now;
            } else {
                __sync_fetch_and_add(&global_state->count, 1);
                if (global_state->count > MAX_GLOBAL_UDP_PPS) {
                    increment_drop_count();
                    return XDP_DROP; 
                }
                if (global_state->count > 500000) {
                    current_adaptive_limit = 1000;
                } else if (global_state->count > 100000) {
                    current_adaptive_limit = 2500;
                }
            }
        }

        struct rate_state *ip_state = bpf_map_lookup_elem(&ip_rate_limit_map, &src_ip);
        if (ip_state) {
            if (now - ip_state->last_time > ONE_SEC_NS) {
                ip_state->count = 1;
                ip_state->last_time = now;
            } else {
                ip_state->count++;
                if (ip_state->count > current_adaptive_limit) {
                    increment_drop_count();
                    return XDP_DROP;
                }
            }
        } else {
            struct rate_state new_state = { .last_time = now, .count = 1 };
            bpf_map_update_elem(&ip_rate_limit_map, &src_ip, &new_state, BPF_ANY);
        }

    } else if (h_proto == __constant_htons(ETH_P_IPV6)) {
        struct ipv6hdr *ip6 = data + sizeof(struct ethhdr);
        if ((void *)(ip6 + 1) > data_end)
            return XDP_PASS;

        struct ipv6_key src_ip6;
        __builtin_memcpy(&src_ip6.addr, &ip6->saddr.in6_u.u6_addr32, sizeof(src_ip6.addr));

        __u8 *is_whitelist6 = bpf_map_lookup_elem(&whitelist_map_ipv6, &src_ip6);
        if (is_whitelist6 && *is_whitelist6 == 1) {
            return XDP_PASS;
        }

        if (ip6->nexthdr != IPPROTO_UDP)
            return XDP_PASS;

        struct udphdr *udp6 = (void *)(ip6 + 1);
        if ((void *)(udp6 + 1) > data_end)
            return XDP_PASS;

        if (__constant_ntohs(ip6->payload_len) > 1200) {
            increment_drop_count();
            return XDP_DROP;
        }

        if (global_state) {
            if (now - global_state->last_time > ONE_SEC_NS) {
                global_state->count = 1;
                global_state->last_time = now;
            } else {
                __sync_fetch_and_add(&global_state->count, 1);
                if (global_state->count > MAX_GLOBAL_UDP_PPS) {
                    increment_drop_count();
                    return XDP_DROP; 
                }
                if (global_state->count > 500000) {
                    current_adaptive_limit = 1000;
                } else if (global_state->count > 100000) {
                    current_adaptive_limit = 2500;
                }
            }
        }

        struct rate_state *ip6_state = bpf_map_lookup_elem(&ip6_rate_limit_map, &src_ip6);
        if (ip6_state) {
            if (now - ip6_state->last_time > ONE_SEC_NS) {
                ip6_state->count = 1;
                ip6_state->last_time = now;
            } else {
                ip6_state->count++;
                if (ip6_state->count > current_adaptive_limit) {
                    increment_drop_count();
                    return XDP_DROP;
                }
            }
        } else {
            struct rate_state new_state = { .last_time = now, .count = 1 };
            bpf_map_update_elem(&ip6_rate_limit_map, &src_ip6, &new_state, BPF_ANY);
        }
    }

    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
